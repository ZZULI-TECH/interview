# RabbitMQ

## RabbitMQ简介
RabbitMQ实现了AMQP(Advanced Message Queuing Protocol)协议，AMQP是一种消息传递协议，是应用层协议的一个开放标准，为面向消息的中间件设计。具体介绍参考[：AMQP介绍](http://www.rabbitmq.com/tutorials/amqp-concepts.html)

## RabbitMQ概念介绍
RabbitMQ有许多重要的概念，了解这些概念对了解RabbitMQ是十分有必要的，下面简单介绍一下：

RabbitMQ 消息模型

	RabbitMQ消息发送时，生产者是不知道消息是否发送到某个队列中去了，生产者仅仅只能将消息发送给某个交换器。

ConnectionFactory

	连接工厂类。可以创建一个连接。
Connection

	在客户创建一个到某个虚拟主机的连接。

Channel

	消息通道，包含了大量的API可用于编程。在客户端的每个连接里，可建立多个channel，每个channel代表一个会话任务。

Broker

	RabbbitMQ消息队列代理服务器实体。

Producer

	发送消息的应用程序。

Consumer

	接收消息的用户程序。

Exchange

	交换器，生产者直接将消息发送给交换器。交换器将消息分发给指定的队列。它指定消息按什么规则，路由到哪个队列。

Binding

	绑定，指的是交换器和队列之间的关系。它的作用就是把exchange和queue按照路由规则绑定起来。

Routing Key

	路由关键字，exchange根据这个关键字进行消息投递。

vhost

	虚拟主机，一个broker里可以开设多个vhost，用作不同用户的权限分离。

Excahnge Types

    RabbitMQ常用的Exchange Type有fanout、direct、topic、headers这四种，下面分别进行介绍。

## Exchange Types 简单介绍

下面对这四种Exchange Types进行简单介绍，由于用到maven来组织项目，所以需要先添加依赖


```xml
<dependency>
  <groupId>com.rabbitmq</groupId>
  <artifactId>amqp-client</artifactId>
  <version>5.0.0</version>
</dependency>
```


### fanout
fanout类型的Exchange路由规则非常简单，它会把所有发送到该Exchange的消息路由到所有与它绑定的Queue中。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mq_fanout.png?raw=true)

上图中，生产者（P）发送到Exchange（X）的所有消息都会路由到图中的两个Queue，并最终被两个消费者（C1与C2）消费。

**生产者代码：**

```java
/**
 * 生产者
 * Exchange Types为fanout
 *
 * fanout类型的Exchange路由规则非常简单，它会把所有发送到该Exchange的消息路由到所有与它绑定的Queue中。
 * @author mingshan
 *
 */
public class Producer {
    private final static String EXCHANGE_NAME = "logs";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        // 声明exchange，Exchange Types为fanout
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.FANOUT);

        String message = "Info-hello world";
        channel.basicPublish(EXCHANGE_NAME, "", null, message.getBytes("UTF-8"));
        channel.close();
        connection.close();
    }
}

```
由于fanout不需要选择将消息路由到哪个Queue，所以channel.basicPublish方法的第二个参数routingKey就不需要设置。

**消费者代码：**

```java
/**
 * 消费者
 * @author mingshan
 *
 */
public class ConsumerA {
    private final static String EXCHANGE_NAME = "logs";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.FANOUT);

        String queueName = channel.queueDeclare().getQueue();
        channel.queueBind(queueName, EXCHANGE_NAME, "");
        System.out.println("A Waiting for messages. To exit press CTRL+C");

        Consumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, BasicProperties properties, byte[] body)
                    throws IOException {
                String message = new String(body, "UTF-8");
                System.out.println("A Recv '" + message + "'");
            }
        };

        channel.basicConsume(queueName, true, consumer);
    }
}
```

在消费者代码中，我们的EXCHANGE_NAME需要与生产者的保持一致，channel.queueDeclare().getQueue()创建临时queue，channel.queueBind(queueName, EXCHANGE_NAME, "")将exchange绑定到指定的queue上，第三个参数为routingKey，由于此处为fanout，所以为空。

### direct
direct类型的Exchange路由规则也比较简单，它会把消息路由到那些binding key与routing key完全匹配的Queue中。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mq_direct.png?raw=true)

以上图为例，假设我们在生产者配置的routingKey为error，那么两个消费者都可以收到消息，如果是info，那么c2可以接收到消息，c2便接收不到消息了。

**生产者代码：**

```java
/**
 * 生产者
 * Exchange Types为direct
 *
 * direct类型的Exchange路由规则也很简单，它会把消息路由到那些binding key与routing key完全匹配的Queue中。
 * @author mingshan
 *
 */
public class Producer {
    private final static String EXCHANGE_NAME = "logs-direct";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        // 声明exchange，Exchange Types为direct
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.DIRECT);
        System.out.println("Please enter message --->");
        String message = "";
        String routeKey = "error";
        Scanner scanner = new Scanner(System.in);

        while (scanner.hasNext()) {
            message = scanner.nextLine();
            System.out.println(" ----- " + message);
            channel.basicPublish(EXCHANGE_NAME, routeKey, null, message.getBytes("UTF-8"));
        }

        channel.close();
        connection.close();
        scanner.close();
    }

}
```

此时生产者Exchange Tyoes设置为direct，并且routingKey设置的为error

**消费者代码：**

```java
/**
 * 消费者
 * @author mingshan
 *
 */
public class ConsumerA {
    private final static String EXCHANGE_NAME = "logs-direct";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.DIRECT);

        String queueName = channel.queueDeclare().getQueue();
        // 此时routeKey 为 info
        String routeKey = "info";
        channel.queueBind(queueName, EXCHANGE_NAME, routeKey);
        System.out.println("A Waiting for messages. To exit press CTRL+C");

        Consumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, BasicProperties properties, byte[] body)
                    throws IOException {
                String message = new String(body, "UTF-8");
                System.out.println("A Recv '" + message + "'");
            }
        };

        channel.basicConsume(queueName, true, consumer);
    }
}
```

在消费者中，我们设置的routeKey为info，此时消费者A接受不到消息了，如果routingKey为error，那么就可以接收到消息。

### topic

由于direct的匹配规则需要完全配置，没有灵活性，所以topic就弥补了这一缺点，  routingKey 必须是由点分隔的单词列表。这些单词可以是任何东西，但通常它们指定连接到消息的一些功能。一些有效的路由键例子：“ stock.usd.nyse ”，“ nyse.vmw ”，“ quick.orange.rabbit ”。在路由选择键中可以有任意数量的字，最多255个字节。

绑定键也必须是相同的形式。binding key中可以存在两种特殊字符“*”与“#”，用于做模糊匹配：

- "*" 可以代替一个字。
- "#" 可以代替零个或多个单词。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mq_topic.png?raw=true)

**生产者代码：**

```java
/**
 * 生产者
 * Exchange Types为topic
 * <ul>
 *   <li>routing key为一个句点号“. ”分隔的字符串（我们将被句点号“. ”分隔开的每一段独立的字符串称为一个单词），
 *     如“stock.usd.nyse”、“nyse.vmw”、“quick.orange.rabbit”</li>
 *   <li>binding key与routing key一样也是句点号“. ”分隔的字符串</li>
 *   <li>binding key中可以存在两种特殊字符“*”与“#”，用于做模糊匹配，其中“*”用于匹配一个单词，“#”用于匹配多个单词（可以是零个）</li>
 * </ul>
 * @author mingshan
 *
 */
public class Producer {
    private final static String EXCHANGE_NAME = "logs-topic";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        // 声明exchange，Exchange Types为headers
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.TOPIC);
        System.out.println("Please enter message --->");
        String message = "";
        String routeKey = "quick.orange.rabbit";
        Scanner scanner = new Scanner(System.in);

        while (scanner.hasNext()) {
            message = scanner.nextLine();
            System.out.println(" ----- " + message);
            channel.basicPublish(EXCHANGE_NAME, routeKey, null, message.getBytes("UTF-8"));
        }

        channel.close();
        connection.close();
        scanner.close();
    }

}
```

**消费者代码：**


```java
/**
 * 消费者
 * @author mingshan
 *
 */
public class ConsumerA {
    private final static String EXCHANGE_NAME = "logs-topic";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.TOPIC);

        String queueName = channel.queueDeclare().getQueue();
        // 此时routeKey 为 *.orange.*
        String routeKey = "*.orange.*";
        channel.queueBind(queueName, EXCHANGE_NAME, routeKey);
        System.out.println("A Waiting for messages. To exit press CTRL+C");

        Consumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, BasicProperties properties, byte[] body)
                    throws IOException {
                String message = new String(body, "UTF-8");
                System.out.println("A Recv '" + message + "'");
            }
        };

        channel.basicConsume(queueName, true, consumer);
    }
}

```


### headers

headers类型的Exchange不依赖于routing key与binding key的匹配规则来路由消息，而是根据发送的消息内容中的headers属性进行匹配。
在绑定Queue与Exchange时指定一组键值对；当消息发送到Exchange时，RabbitMQ会取到该消息的headers（也是一个键值对的形式），消费者会根据设置x-match设置的配置类型(all,any)来进行匹配。

**生产者代码：**

```java
/**
 * 生产者
 * Exchange Types为headers
 *
 * Headers是一个键值对，可以定义成HashMap。发送者在发送的时候定义一些键值对，接收者也可以再绑定时候传入一些键值对，
 * 两者匹配的话，则对应的队列就可以收到消息。匹配有两种方式all和any。这两种方式是在接收端必须要用键值"x-mactch"来定义
 * 。all代表定义的多个键值对都要满足，而any则代码只要满足一个就可以了。fanout，direct，topic exchange的routingKey都需要要字符串形式的，
 * 而headers exchange则没有这个要求，因为键值对的值可以是任何类型。
 * @author mingshan
 *
 */
public class Producer {
    private final static String EXCHANGE_NAME = "logs-headers";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        // 声明exchange，Exchange Types为headers
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.HEADERS);

        Map<String,Object> headers =  new HashMap<String, Object>();
        headers.put("xiaoming", "123456");
        AMQP.BasicProperties.Builder builder = new AMQP.BasicProperties.Builder();
        builder.deliveryMode(MessageProperties.PERSISTENT_TEXT_PLAIN.getDeliveryMode());
        builder.priority(MessageProperties.PERSISTENT_TEXT_PLAIN.getPriority());
        builder.headers(headers);
        AMQP.BasicProperties theProps = builder.build();

        System.out.println("Please enter message --->");
        Scanner scanner = new Scanner(System.in);
        String message = "";

        while (scanner.hasNext()) {
            message = scanner.nextLine();
            channel.basicPublish(EXCHANGE_NAME, "", theProps, message.getBytes("UTF-8"));
        }

        channel.close();
        connection.close();
        scanner.close();
    }

}
```

**消费者代码：**

```java
/**
 * 消费者
 * @author mingshan
 *
 */
public class ConsumerA {
    private final static String EXCHANGE_NAME = "logs-headers";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.HEADERS);

        String queueName = channel.queueDeclare().getQueue();

        Map<String, Object> headers = new HashMap<String, Object>();
        headers.put("x-match", "any");//all any  
        headers.put("xiaoming", "123456");
        headers.put("bbb", "56789");
        channel.queueBind(queueName, EXCHANGE_NAME, "", headers);

        System.out.println("A Waiting for messages. To exit press CTRL+C");
        Consumer consumer = new DefaultConsumer(channel) {

            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, BasicProperties properties, byte[] body)
                    throws IOException {
                String message = new String(body, "UTF-8");
                System.out.println("A Recv '" + message + "'");
            }
        };

        channel.basicConsume(queueName, true, consumer);
    }
}

```
## 源码链接
你可以在这个地方看到本篇源码：

https://github.com/mstao/rabbitmq-learning

参考:

- [RabbitMQ Doc](http://www.rabbitmq.com/getstarted.html)
- [AMQP 0-9-1 Model Explained](http://www.rabbitmq.com/tutorials/amqp-concepts.html)
