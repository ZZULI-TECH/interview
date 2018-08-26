# NIO

JDK 1.4中的java.nio.*包中引入新的Java I/O库，被称为 no-blocking io (NIO)。

Java NIO 由以下几个核心部分组成：

- Buffers
- Channels
- Selectors
- Charsets 

那么简单介绍下上面核心组件

**Buffers**

Buffer，高效的数据容器，除了布尔类型，所有原始类型都有相应的Buffer实现。下面是官方文档中所有Buffer实现及相关描述（MappedByteBuffer表示内存映射文件）


Buffers |	Description
---|---
Buffer | 	Position, limit, and capacity; clear, flip, rewind, and mark/reset
ByteBuffer | 	Get/put, compact, views; allocate, wrap
MappedByteBuffer | 	A byte buffer mapped to a file
CharBuffer |	Get/put, compact; allocate, wrap
DoubleBuffer |	Get/put, compact; allocate, wrap
FloatBuffer |	Get/put, compact; allocate, wrap
IntBuffer | 	Get/put, compact; allocate, wrap
LongBuffer |	Get/put, compact; allocate, wrap
ShortBuffer |	Get/put, compact; allocate, wrap
ByteOrder | Typesafe enumeration for byte orders


**Channels**

Channel, 通道,用于源节点与目标节点的连接。在Java NIO中负责缓冲区的数据传输，Channel本身不存储数据，需要与缓冲区配合使用。File或者Socket，通常被认为是比较高层的抽象，而Channel则是更加操作系统底层的一种抽象，这也使得NIO得以充分利用现代操作系统底层机制，获得特定场景的性能优化，例如，DMA（Direct Memory Access）等。主要实现类如下：

- FileChannel 
- SocketChannel
- ServerSocketChannel
- DatagramChannel

**Selectors**

Selector，是NIO实现多路复用的基础，它提供了一种高效的机制，可以检测到注册在Selector上的多个Channel，是否有Channel处于就绪状态，进而实现单线程对多Channel的高效管理。

Selector同样是基于底层操作系统机制，不同的操作系统、不同的模式都存在区别，例如在最新的代码库中，

Linux 上依赖于 epoll（http://hg.openjdk.java.net/jdk/jdk/file/d8327f838b88/src/java.base/linux/classes/sun/nio/ch/EPollSelectorImpl.java）。

Windows 上 NIO2（AIO）模式则是依赖于 iocp（http://hg.openjdk.java.net/jdk/jdk/file/d8327f838b88/src/java.base/windows/classes/sun/nio/ch/Iocp.java）


**Charsets**

Charset，用来在字节和 Unicode 字符之间转换的 charset、解码器和编码器。

参考：

- [NIO API](https://docs.oracle.com/javase/10/docs/api/java/nio/package-summary.html)
- 杨晓峰 Java提供了哪些IO方式？NIO如何实现多路复用
- [Scalable IO in Java](https://github.com/ZZULI-TECH/interview/tree/master/doc/nio.pdf)