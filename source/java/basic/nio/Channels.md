## Channel介绍

Channel? 我们在使用Buffer的时候，需要往Buffer中放数据，再从Buffer中取数据，那么在NIO体系中，与Buffer交互是什么呢，没错，就是Channel。所有的NIO的I/O操作都是从Channel 开始的，读操作的时候将Channel中的数据填充到Buffer 中，而写操作时将Buffer中的数据写入到Channel中。

下面Channel的官方解释：

> A channel represents an open connection to an entity such as a hardware device, a file, a network socket, or a program component that is capable of performing one or more distinct I/O operations, for example reading or writing. As specified in the Channel interface, channels are either open or closed, and they are both asynchronously closeable and interruptible.


在官方文档中，Channels根据不同的使用场景实现不一样，官方文档Channels可以在以下场景使用：

- File channels
- Multiplexed, non-blocking I/O
- Asynchronous I/O


FileChannel类支持从连接到文件的通道中读取字节和将字节写入到通道。

多路复用、非阻塞I/O由`selector`、`selectable channels`和`SelectionKey`提供，它比阻塞I/O更具可伸缩性。

异步通道是一种能够进行异步I/O操作的特殊通道。异步通道是非阻塞的，并定义方法来启动异步操作，返回表示每个操作的Future。

目前使用较多Channel的实现类有：

- FileChannel：文件通道，用于文件的读和写
- DatagramChannel：用于 UDP 连接的接收和发送
- SocketChannel：TCP通道，用于TCP数据传输
- ServerSocketChannel：用于监听服务端某个端口进来的TCP请求

## FileChannel

Java针对支持通道的类提供了`getChannel()`方法来获取`FileChannel`，`FileChannel`是一个用来写、读、映射和操作文件的通道。下面是利用`FileChannel`读写文件的一个例子:

```Java
FileInputStream fis = null;
FileOutputStream fos = null;
FileChannel inChannel = null;
FileChannel outChannel = null;

try {
    fis = new FileInputStream("1.png");
    fos = new FileOutputStream("2.png");
    // 获取通道
    inChannel = fis.getChannel();
    outChannel = fos.getChannel();
    // 创建缓冲区
    ByteBuffer buffer = ByteBuffer.allocate(1024);
    while (inChannel.read(buffer) != -1) {
        // 切换到读数据模式
        buffer.flip();
        // 将缓冲区的内容写入通道
        outChannel.write(buffer);
        // 清空缓冲区
        buffer.clear();
    }
} catch (Exception e) {
    e.printStackTrace();
} finally {
    if (inChannel != null) {
        try {
            inChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    if (outChannel != null) {
        try {
            outChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    if (fis != null) {
        try {
            fis.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    if (fos != null) {
        try {
            fos.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

由于FileChannel是抽象类，它的read、write和map通过其实现类FileChannelImpl实现，注意
[FileChannelImpl](https://github.com/unofficial-openjdk/openjdk/blob/531ef5d0ede6d733b00c9bc1b6b3c14a0b2b3e81/src/java.base/share/classes/sun/nio/ch/FileChannelImpl.java)是在sun.nio.ch包中的，这里类需要在openjdk源码中看到，代码如下：


```Java
public int read(ByteBuffer dst) throws IOException {
    ensureOpen();
    if (!readable)
        throw new NonReadableChannelException();
    synchronized (positionLock) {
        if (direct)
            Util.checkChannelPositionAligned(position(), alignment);
        int n = 0;
        int ti = -1;
        try {
            beginBlocking();
            ti = threads.add();
            if (!isOpen())
                return 0;
            do {
                n = IOUtil.read(fd, dst, -1, direct, alignment, nd);
            } while ((n == IOStatus.INTERRUPTED) && isOpen());
            return IOStatus.normalize(n);
        } finally {
            threads.remove(ti);
            endBlocking(n > 0);
            assert IOStatus.check(n);
        }
    }
}
```

在这个方法中，会检测通道是否可用，如果操作position和size，会进行同步处理，加上对象锁，然后调用[IOUtil](https://github.com/unofficial-openjdk/openjdk/blob/531ef5d0ede6d733b00c9bc1b6b3c14a0b2b3e81/src/java.base/share/classes/sun/nio/ch/IOUtil.java)类的read方法，注意是while循环，条件IOStatus是INTERRUPTED（系统底层调用中断？），在[IOStatus](https://github.com/unofficial-openjdk/openjdk/blob/531ef5d0ede6d733b00c9bc1b6b3c14a0b2b3e81/src/java.base/share/classes/sun/nio/ch/IOStatus.java)类中，定义了一些常量，如下：

```Java

@Native public static final int EOF = -1;              // End of file
@Native public static final int UNAVAILABLE = -2;      // Nothing available (non-blocking)
@Native public static final int INTERRUPTED = -3;      // System call interrupted
@Native public static final int UNSUPPORTED = -4;      // Operation not supported
@Native public static final int THROWN = -5;           // Exception thrown in JNI code
@Native public static final int UNSUPPORTED_CASE = -6; // This case not supported
```

IOUtil的代码如下所示：

```
static int read(FileDescriptor fd, ByteBuffer dst, long position,
                    boolean directIO, int alignment, NativeDispatcher nd)
        throws IOException
    {
        if (dst.isReadOnly())
            throw new IllegalArgumentException("Read-only buffer");
        if (dst instanceof DirectBuffer)
            return readIntoNativeBuffer(fd, dst, position, directIO, alignment, nd);

        // Substitute a native buffer
        ByteBuffer bb;
        int rem = dst.remaining();
        if (directIO) {
            Util.checkRemainingBufferSizeAligned(rem, alignment);
            bb = Util.getTemporaryAlignedDirectBuffer(rem, alignment);
        } else {
            bb = Util.getTemporaryDirectBuffer(rem);
        }
        try {
            int n = readIntoNativeBuffer(fd, bb, position, directIO, alignment,nd);
            bb.flip();
            if (n > 0)
                dst.put(bb);
            return n;
        } finally {
            Util.offerFirstTemporaryDirectBuffer(bb);
        }
}
```

通过上面的代码可以大致了解到，FileChannel读取数据过程如下：

1. 判断用户传入的buffer是否是DirectBuffer，如果是直接由readIntoNativeBuffer进行读取
2. 如果不是（directIO为false），申请一块和缓存同大小的DirectByteBuffer bb
3. 读取数据到缓存bb，底层由NativeDispatcher的read实现
4. 把bb的数据读取到dst（用户定义的ByteBuffer，在jvm中分配内存）

其他方法的具体实现细节可参考openjdk的代码，就不再分析了。

## ServerSocketChannel和SocketChannel

ServerSocketChannel可以监听新进来的TCP连接，主要用于处理网络连接。对每一个新进来的连接都会创建一个SocketChannel。ServerSocketChannel可以被设置为阻塞或者非阻塞，

如果设置为阻塞，那么通道的读写等操作是阻塞的，该线程被阻塞，直到有一些数据被读取或写入，该线程在此期间不能执行其他任务

如果设置为非阻塞，那么读写请求并不会阻塞当前线程，在数据可读/写前当前线程可以继续做其它事情，所以一个单独的线程可以管理多个输入和输出通道。需要结合Selector使用。

下面仅介绍阻塞式的写法，非阻塞在Selector中详细探讨下。代码如下：

Server端：

```Java
// 创建通道
ServerSocketChannel server = ServerSocketChannel.open();
// 绑定端口
server.bind(new InetSocketAddress(9898));
FileChannel outChannel = FileChannel.open(Paths.get("2.png"), StandardOpenOption.WRITE,StandardOpenOption.READ,StandardOpenOption.CREATE);

// 获取客户端连接的通道
SocketChannel socketChannel = server.accept();
// 分配指定大小的缓冲区
ByteBuffer buffer = ByteBuffer.allocate(1024);

// 接受客户端的数据，并保存到本地
while(socketChannel.read(buffer) != -1){
    buffer.flip();
    outChannel.write(buffer);
    buffer.clear();
}

// 关闭通道
socketChannel.close();
outChannel.close();
server.close();
```

通过上面代码我们可以总结下Server端的流程：

1. 创建ServerSocketChannel通道
2. 绑定ip地址和端口号
3. 通过ServerSocketChannel的accept()方法创建一个SocketChannel对象，用户从客户端读/写数据
4. 创建读数据/写数据缓冲区对象来读取客户端数据或向客户端发送数据
5. 关闭SocketChannel和ServerSocketChannel


Client端：


```Java
// 获取通道
SocketChannel client = SocketChannel.open(new InetSocketAddress("127.0.0.1", 9898));
// 获取文件
FileChannel inChannel = FileChannel.open(Paths.get("1.png"), StandardOpenOption.READ);
        
// 分配缓冲区
ByteBuffer buffer = ByteBuffer.allocate(1024);

// 读取本地文件
while (inChannel.read(buffer) != -1) {
    buffer.flip();
    client.write(buffer);
    buffer.clear();
}

// 关闭
inChannel.close();
client.close();

```
总结下Client端的流程：

1. 获取SocketChannel，绑定ip和端口
2. 创建读数据/写数据缓冲区对象来读取服务端数据或向服务端发送数据
3. 关闭SocketChannel

## 参考

- [JDK API](https://docs.oracle.com/javase/10/docs/api/java/nio/channels/package-summary.html)
- [Java NIO 之 Channel（通道）](https://segmentfault.com/a/1190000014869494)
- [深入浅出NIO之Channel、Buffer](https://www.jianshu.com/p/052035037297)
- [Java进阶（五）Java I/O模型从BIO到NIO和Reactor模式 ](http://www.jasongj.com/java/nio_reactor/)

