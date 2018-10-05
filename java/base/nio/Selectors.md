# Selector介绍

Selector是Java NIO中实现多路复用的关键，用于检查一个或多个NIO Channel 的状态是否处于可连接、可接收、可读、可写状态。单个线程通过Selector来管理多个Channel，减少线程上下文切换带来的性能开销。 Selector是一个抽象类，具体是通过SelectorProvider实现的。对于Windows和Linux，SelectorProvider有着不同的实现。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/nio-selector.png?raw=true)

在Selector存在着三种selection keys的集合，分别是：

- key set 所有注册到Selector的Channel所表示的SelectionKey都会存在于该集合中。
- selected-key set 包含着一部分selectionKeys，其中的每个selectionKey所关联的channel在selection operation期间被检测出至少准备好了一个可以在interest set中匹配到的操作。这个集合可以通过调用selector.selectedKeys()方法返回。该集合是key set的一个子集。
- cancelled-key set 执行了取消操作的SelectionKey会被放入到该集合中。该集合是key set的一个子集。

注意对于一个新创建的selector其中这三个集合都是空着的。

## Selector使用步骤

**创建Selector**

我们想要获取Selector对象，通过调用Selector类的open静态方法来获取，如下：

```Java
// 获取Selector
selector = Selector.open();
```

在open方法中，调用了SelectorProvider类里面的方法，这是个抽象类，如下：

```Java
public static Selector open() throws IOException {
    return SelectorProvider.provider().openSelector();
}
```

我们来看看provider()方法，在该方法中，实际上是调用了`sun.nio.ch.DefaultSelectorProvider.create()`方法，那么这个方法在哪里呢？对于不同的操作系统实现方式其实是不一样的，例如在Windows版本中是实例化`sun.nio.ch.WindowsSelectorProvider`类来实现的，在Linux版本中，是实例化`EPollSelectorProvider`类来实现的，也就是epoll，这里使用了SPI机制。


```Java
public static SelectorProvider provider() {
    synchronized (lock) {
        if (provider != null)
            return provider;
        return AccessController.doPrivileged(
            new PrivilegedAction<>() {
                public SelectorProvider run() {
                        if (loadProviderFromProperty())
                            return provider;
                        if (loadProviderAsService())
                            return provider;
                        provider = sun.nio.ch.DefaultSelectorProvider.create();
                        return provider;
                    }
                });
    }
}
```

[Windows](https://github.com/unofficial-openjdk/openjdk/blob/531ef5d0ede6d733b00c9bc1b6b3c14a0b2b3e81/src/java.base/windows/classes/sun/nio/ch/DefaultSelectorProvider.java)
```
public class DefaultSelectorProvider {

    /**
     * Prevent instantiation.
     */
    private DefaultSelectorProvider() { }

    /**
     * Returns the default SelectorProvider.
     */
    public static SelectorProvider create() {
        return new sun.nio.ch.WindowsSelectorProvider();
    }

}
```

[Linux](https://github.com/unofficial-openjdk/openjdk/blob/531ef5d0ede6d733b00c9bc1b6b3c14a0b2b3e81/src/java.base/linux/classes/sun/nio/ch/DefaultSelectorProvider.java)

```
public class DefaultSelectorProvider {

    /**
     * Prevent instantiation.
     */
    private DefaultSelectorProvider() { }

    /**
     * Returns the default SelectorProvider.
     */
    public static SelectorProvider create() {
        return new EPollSelectorProvider();
    }
}
```

**将Channel注册到Selector上**

创建完Selector之后，需要将ServerSocketChannel注册到Selector上，并指定事件OP_ACCEPT,会返回SelectionKey，注意ServerSocketChannel需要设置为非阻塞模式

```Java
server.register(selector, SelectionKey.OP_ACCEPT);
```

其中SelectionKey有四个事件可用：

- SelectionKey.OP_CONNECT
- SelectionKey.OP_ACCEPT
- SelectionKey.OP_READ
- SelectionKey.OP_WRITE

**监听Selector事件变化**

当Selector与Channel建立好联系后，调用Selector的select方法会返回socket的个数，只有当个数大于0时我们才需要处理，调用selector的selectedKeys方法会返回SelectionKey集合，我们可以遍历集合进行处理自己的逻辑处理，如下：


```Java
while (true) {
    // 满足可连接，可读，可写 三中状态
    int eventCount = selector.select();
    if (eventCount == 0) {
        continue;
    }
    Set<SelectionKey> keys = selector.selectedKeys();
    // 迭代
    final Iterator<SelectionKey> iteratorKeys = keys.iterator();
    while (iteratorKeys.hasNext()) {
        // 处理业务方法
        dispatch(iteratorKeys.next());
        iteratorKeys.remove();
    }
}
```

**处理事件**

我们可以拿到一个回SelectionKey的集合，可以从SelectionKey取到哪些信息呢？首选先看看这个类的介绍，在该类源码中，我们可以发现以下方法：

- selector() // 返回创建SelectionKey的selector
- channel() // 返回创建SelectionKey的channel
- interestOps() // 检索感兴趣的事件
- readyOps() // 检索通道已经准备就绪的事件。
- attachment() // 返回SelectionKey的attachment，attachment可以在注册channel的时候指定。

在该类中，我们可以调用以下方法来判断通道是否具备可接收、可连接、可读、可写，如下：

- isAcceptable() // 是否可读
- isWritable() // 是否可写
- isConnectable() // 是否可连接
- isAcceptable() // 是否可接收


## 完整示例

**服务端**

```Java
/**
 *  nio服务端
 * @author mingshan
 *
 */
public class NIOServer {
    private int port = 8080;
    // 创建两个缓冲池
    private ByteBuffer seBuffer = ByteBuffer.allocate(1024);
    private ByteBuffer receiveBuffer = ByteBuffer.allocate(1024);
    // 创建服务器高速通道，发给客户端
    private ServerSocketChannel server;
    // 多路复用注册器
    private Selector selector;
    // 消息缓存队列
    private Map<SelectionKey, String> sessionMsgs = new HashMap<SelectionKey, String>();
    // 客户端编号
    private static final AtomicInteger CLIENT_NO = new AtomicInteger(499445428);

    public NIOServer(int port) throws IOException {
        this.port = port;
        server = ServerSocketChannel.open();
        // 绑定端口地址
        server.socket().bind(new InetSocketAddress(port));
        // 设置非阻塞
        server.configureBlocking(false);

        // 获取Selector
        selector = Selector.open();
        // 注册 事件驱动模型
        server.register(selector, SelectionKey.OP_ACCEPT);
        System.out.println("NIO服务初始化完毕，监听端口为:" + this.port);
    }

    /**
     * 服务内部要不断监听selector事件变化
     */
    private void listener() throws IOException {
        while (true) {
            // 满足可连接，可读，可写 三中状态
            int eventCount = selector.select();
            if (eventCount == 0) {
                continue;
            }
            Set<SelectionKey> keys = selector.selectedKeys();
            // 迭代
            final Iterator<SelectionKey> iteratorKeys = keys.iterator();
            while (iteratorKeys.hasNext()) {

                // 处理业务方法
                dispatch(iteratorKeys.next());
                iteratorKeys.remove();
            }
        }
    }

    /**
     * 真正处理业务的方法 key里面 携带的是client信息封装的Channel
     * @param key
     */
    private void dispatch(SelectionKey key) {
        SocketChannel client = null;
        try {
            if(key.isValid() && key.isAcceptable()){
                // 服务端接收到客户端的Channel
                client = server.accept();
                client.configureBlocking(false);
                client.register(selector, SelectionKey.OP_READ);
                CLIENT_NO.incrementAndGet();
            }

            if (key.isValid() && key.isReadable()) {
                // 将客户端高速通道里面的信息读到缓冲池里
                receiveBuffer.clear();
                
                client = (SocketChannel) key.channel();
                int len = client.read(receiveBuffer);
                if (len > 0) {
                    String msgString = new String(receiveBuffer.array(), 0, len);
                    // 将消息存到缓存队列
                    sessionMsgs.put(key, msgString);
                    System.out.println("当前处理线程:" + Thread.currentThread().getName()
                            + "读到客户端编号：" + CLIENT_NO.get() + "；信息: " + msgString);

                    // 响应处理
                    client.register(selector, SelectionKey.OP_WRITE);
                }
            }

            if (key.isValid() && key.isWritable()) {
                // 判断消息队列里面有没有这个key
                if (!sessionMsgs.containsKey(key)) {
                    return;
                }
                client = (SocketChannel) key.channel();
                seBuffer.clear();
                seBuffer.put((sessionMsgs.get(key)+"服务器已经处理").getBytes());
                
                // 切换读写
                /*
                 *  limit = position; 
                 *  position = 0;
                 *  mark = -1;
                 */
                seBuffer.flip();
                client.write(seBuffer);
                System.out.println("当前处理线程名称：" + Thread.currentThread().getName() + "写到客户端编号为"
                + CLIENT_NO + "信息为：" + sessionMsgs.get(key));
                
                client.register(selector, SelectionKey.OP_READ);
            }
            
        } catch (Exception e) {
            // TODO: handle exception
        }
    }

    public static void main(String[] args) throws IOException {
        // 调用通信服务
        new NIOServer(8088).listener();
    }
}
```

**服务端**

```
/**
 * NIO 客户端
 * @author mingshan
 *
 */
public class NIOClient {

    private SocketChannel client;
    private InetSocketAddress serverAddress = new InetSocketAddress("localhost", 8088);
    private Selector selector;
    private ByteBuffer receiveBuffer = ByteBuffer.allocate(1024);
    private ByteBuffer sendBuffer = ByteBuffer.allocate(1024);

    public NIOClient() throws IOException {
        // 构造client实例
        client = SocketChannel.open();
        // 设置为非阻塞式
        client.configureBlocking(false);
        client.connect(serverAddress);
        // 构造selector实例
        selector = Selector.open();
        // 注册连接事件
        client.register(selector, SelectionKey.OP_CONNECT);
    }

    private void session() throws IOException{
        if (client.isConnectionPending()) {
            client.finishConnect();
            client.register(selector, SelectionKey.OP_WRITE);
            System.out.println("已经连接到服务器，可以向服务器端发消息了");
            
        }

        Scanner scan = new Scanner(System.in);
        while (scan.hasNextLine()) {
            //输入键盘的内容
            String msg = scan.nextLine();
            if ("".equals(msg)) {
                continue;
            }
            if ("exit".equalsIgnoreCase(msg)) {
                System.exit(0);
            }

            handler(msg);
        }
    }

    /**
     * 处理输入的消息
     * @param name
     * @throws IOException
     */
    private void handler(String msg) throws IOException {
        boolean waitHelp = true;
        Iterator<SelectionKey> iterator = null;
        Set<SelectionKey> keys = null;
        while (waitHelp) {
            try{
                int readys = selector.select();
                //如果没有人，继续轮询
                if (readys == 0) {
                    continue;
                }
                keys = selector.selectedKeys();
                iterator = keys.iterator();
                // 一个一个key迭代检查
                while (iterator.hasNext()) {
                    SelectionKey key = iterator.next();
                    if (key.isValid() && key.isWritable()) {
                        sendBuffer.clear();
                        sendBuffer.put(msg.getBytes());
                        sendBuffer.flip();

                        client.write(sendBuffer);
                        client.register(selector, SelectionKey.OP_READ);
                    }
                    if (key.isValid() && key.isReadable()) {
                        receiveBuffer.clear();
                        int len = client.read(receiveBuffer);
                        if (len > 0) {
                            receiveBuffer.flip();
                            System.out.println("服务端反馈消息 " + new String(receiveBuffer.array(), 0, len) );
                            client.register(selector, SelectionKey.OP_WRITE);
                            waitHelp = false;
                        }
                    }

                    // 移除SelectKey
                    iterator.remove();
                }
            } catch (Exception e) {
                ((SelectionKey) keys).cancel();
                client.socket().close();
                client.close();
                return;
            }
        }
    }

    public static void main(String[] args) {
        try {
            new NIOClient().session();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```



参考

- [NIO API](https://docs.oracle.com/javase/10/docs/api/java/nio/channels/Selector.html)
- [Scalable IO in Java](http://gee.cs.oswego.edu/dl/cpjslides/nio.pdf)
- [JSR 51: New I/O APIs for the JavaTM Platform](https://www.jcp.org/en/jsr/detail?id=51)
