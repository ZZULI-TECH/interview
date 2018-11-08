Apache ServiceComb (incubating) Saga 是一个微服务应用的数据最终一致性解决方案。

Saga Pack 架构是由 alpha 和 omega组成，其中：

- alpha充当协调者的角色，主要负责对事务进行管理和协调。
- omega是微服务中内嵌的一个agent，负责对网络请求进行拦截并向alpha上报事务事件。

下图展示了alpha, omega以及微服务三者的关系： 

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/pack.png?raw=true)

看了它的架构方案，我们需要用例子来理解它的机制和使用方式，Saga为我们提供了一系列Demo，包含与Spring、Dubbo等结合使用的例子，下面就用与Spring结合的例子


## 编译

首先我们需要从[github 仓库](https://github.com/apache/incubator-servicecomb-saga)克隆源代码到本地，然后在项目根目录执行如下命令：

```
mvn clean package -DskipTests -Pdemo
```

该命令会编译源代码，跳过单元测试，并且编译demo项目。


## 运行Alpha Server

从上面的架构图看出，alpha充当协调者的角色，所以我们需要先运行Alpha Server，Alpha Server是需要数据库支持，默认用的PostgreSQL数据库，我们在项目中使用MySQL较多，所以需要切换为MySQL数据库。

先在`alpha/alpha-server/pom.xml` 文件中添加MySQL数据库驱动依赖，然后重新编译

```
<dependency>
  <groupId>mysql</groupId>
  <artifactId>mysql-connector-java</artifactId>
</dependency>
```
接下来创建数据库`saga`和表，数据库Schema[在这里](https://github.com/apache/incubator-servicecomb-saga/blob/master/alpha/alpha-server/src/main/resources/schema-mysql.sql)，首先执行该数据库脚本，创建相应的表
，包括`TxEvent`、`Command`、`TxTimeout`、`tcc_global_tx_event`、`tcc_participate_event`、`tcc_tx_event`这几张表。

接下来运行Alpha Server，进入到`alpha\alpha-server\target\saga`文件夹，运行如下命令：

```
java -Dspring.profiles.active=mysql -D"spring.datasource.url=jdbc:mysql://127.0.0.1:3306/saga?useSSL=false&allowPublicKeyRetrieval=true" -D"spring.datasource.username=root" -D"spring.datasource.password=admin" -jar alpha-server-0.3.0-SNAPSHOT-exec.jar
```

该命令指明了数据库的`url`、`username`、`password`, 同时指定spring的profile为mysql，注意`alpha-server-0.3.0-SNAPSHOT-exec.jar` 该jar包为本目录下的jar包。

 默认情况下，8080端口用于处理omega处发起的gRPC的请求，而8090端口用于处理查询存储在alpha处的事件信息。

## 运行Demo

由于上面我们已经对demo项目进行了编译，下面我们就可以来执行了，demo分为三个项目，booking、car、hotel，流程是通过booking可以预定车和房间，分别调用car和hotel两个服务，来模拟分布式事务的流程。

下面启动hotel服务，这里做个控制，不允许预定超过二个房间，否则报错：

```
java -Dserver.port=8081 -Dalpha.cluster.address=127.0.0.1:8080 -jar hotel-0.3.0-SNAPSHOT-exec.jar
```

然后启动car服务：

```
java -Dserver.port=8082 -Dalpha.cluster.address=127.0.0.1:8080 -jar car-0.3.0-SNAPSHOT-exec.jar
```

最后启动booking服务：

```
java -Dserver.port=8083 -Dalpha.cluster.address=127.0.0.1:8080 -Dcar.service.address=http://127.0.0.1:8082 -Dhotel.service.address=http://127.0.0.1:8081 -jar booking-0.3.0-SNAPSHOT-exec.jar
```

三个服务启动后，首先预定2个车和2个房间，用curl或者postman发送请求：


```
curl -X POST http://127.0.0.1:8083/booking/test/2/2
```

结果会预定成功，分别查询car 和 hotel 均会返回预定成功：

[hotel]

```
curl -X http://127.0.0.1:8081/bookings

[{"name":"test","amount":2,"confirmed":true,"cancelled":false}]
```

[car]
```
curl -X http://127.0.0.1:8082/bookings

[{"name":"test","amount":2,"confirmed":true,"cancelled":false}
```

接下来要预定2个车和3个房间，此时会预定失败


```
curl -X POST http://127.0.0.1:8083/booking/test/3/2
```

分别查询car 和 hotel ，如下所示：

[hotel]
```
curl -X http://127.0.0.1:8081/bookings

[{"name":"test","amount":2,"confirmed":true,"cancelled":false}]
```

[car]
```
curl -X http://127.0.0.1:8082/bookings

[{"name":"test","amount":2,"confirmed":true,"cancelled":false},
{"name":"test","amount":2,"confirmed":false,"cancelled":true}]
```

我们知道预定三个房间会失败报错，这是预定的car就要进行回滚，不能预定成功，因为这是在一个预定事务里，所以查询car的预定情况，第二条记录就会显示**cancel:true**

下图是上面操作的结果界面：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/saga-demo-result.png?raw=true)

## 实现方式

1. 在应用入口添加 `@EnableOmega` 的注解来初始化omega的配置并与alpha建立连接。

```Java
@SpringBootApplication
@EnableOmega
public class Application {
  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }
}
```

2. 在全局事务的起点添加 `@SagaStart` 的注解。这里是在booking项目的预定方法加此注解，该方法包括预定车和房间。

```Java
@SagaStart
@PostMapping("/booking/{name}/{rooms}/{cars}")
public String order(@PathVariable String name,  @PathVariable Integer rooms, @PathVariable Integer cars) {
    template.postForEntity(
        carServiceUrl + "/order/{name}/{cars}",
        null, String.class, name, cars);
    
    postCarBooking();
    
    template.postForEntity(
        hotelServiceUrl + "/order/{name}/{rooms}",
        null, String.class, name, rooms);
    
    postBooking();
    
    return name + " booking " + rooms + " rooms and " + cars + " cars OK";
}
```

3. 在子事务处添加 `@Compensable` 的注解并指明其对应的补偿方法。注意这里两个子事务都要加。

```Java
@Compensable(compensationMethod = "cancel")
void order(CarBooking booking) {
    booking.confirm();
    bookings.put(booking.getId(), booking);
}

void cancel(CarBooking booking) {
    Integer id = booking.getId();
    if (bookings.containsKey(id)) {
      bookings.get(id).cancel();
    }
}
```
**注意:** 
1. 实现的服务和补偿必须满足幂等的条件。
2. 默认情况下，超时设置需要显式声明才生效。
3. 若全局事务起点与子事务起点重合，需同时声明 `@SagaStart` 和 `@Compensable` 的注解。

**对于`@Compensable`方法及`compenstation`方法的要求**
1. 这两个方法的参数列表完全一致。
2. 这两个方法在写在同一个类中。
3. 参数要能够序列化。
4. 这两个方法是可交换的，即如果参数相同，这两个方法无论以什么顺序执行结果都是一样的

## 设计思路和运行机制

后面再深入研究(￣▽￣)~*

参考：

- [聊聊分布式事务，再说说解决方案](https://www.cnblogs.com/savorboard/p/distributed-system-transaction-consistency.html)
- [Saga DOC](https://docs.servicecomb.io/saga/en_US/index.html)
