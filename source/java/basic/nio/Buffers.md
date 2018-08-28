Buffer？我们很容易想到缓冲区的概念，在NIO中，它是直接和Channel打交道的缓冲区，通常场景或是从Buffer写入Channel，或是从Channel读入Buffer。Buffer是一个抽象类，Java提供如下图的实现类，我是直接在Eclipse截出来的^_^

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/buffer_impl.png?raw=true)

其实核心是ByteBuffer，除了布尔类型，所有原始类型都有相应的Buffer实现，只是包装了一下ByteBuffer而已，我们使用最多的通常是ByteBuffer。

我们应该将Buffer理解为一个数组，IntBuffer、CharBuffer、DoubleBuffer 等分别对应int[]、char[]、double[]等。

上图没有包括MappedByteBuffer，该类用户内存映射文件，放到最后再说吧。

Buffer有四个重要的属性，分别为：mark、position、limit、capacity，和两个重要方法分别为：flip和clear。Buffer的底层存储结构为数组。这四个属性有以下特点：

```
mark <= position <= limit <= capacity
```

那么这几个属性分别起着什么作用呢？下面的介绍都以ByteBuffer为例，来分析ByteBuffer的使用流程和原理。

下面是这四个属性的简单介绍：

 - capacity ：缓冲区的容量大小
 - limit ：界限，表示缓冲区可以操作数据的大小。 （limit后数据不能进行读写）
 - position: 位置，代表下一次的写入位置，初始值是 0，每往 Buffer 中写入一个值，position 就自动加 1
 - mark : 标记，表示记录当前position 的位置可以通过reset()来恢复到 mark的位置，初始为 -1

对ByteBuffer操作主要包括读和写，向缓冲区写入数据和从缓冲区读取数据会影响以上四个属性的值的变化，我们分别对读和写以及之间切换进行分析。

**写操作**

首先分配1024字节的缓冲区，然后向缓冲区放入5字节的字符串“abcde”，代码如下：

```
String str="abcde";

// 分配一个指定大小的缓冲区
ByteBuffer buffer=ByteBuffer.allocate(1024);

System.out.println("---------allocate------");
System.out.println(buffer.position());
System.out.println(buffer.limit());
System.out.println(buffer.capacity());

// 利用put() 向缓冲区放数据
buffer.put(str.getBytes());

System.out.println("--------放数据------");
System.out.println(buffer.position());
System.out.println(buffer.limit());
System.out.println(buffer.capacity());
```

初始化position，limit，capacity位置如下图所示

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/bytebuffer_init.png?raw=true)

我们发现position为0，而limit和capacity均指向内存区域最大位置，代表此时缓存区内是空的，已放入capacity大小的数据。

当我们向缓冲区放入5个字节的数据，position，limit，capacity位置发生了变化，如下图所示

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/bytebuffer_put.png?raw=true)

从上图可以看出，在写入数据后，position会向后移动5个位置，指向第六个位置，代表下次写数据的位置，limit和capacity没有改变。


**切换到读操作**

由写模式切换到读模式需要调用`flip`方法，这个方法是什么意思呢？在JDK源码中，此方法的代码如下：


```Java
public final Buffer flip() {
    limit = position;
    position = 0;
    mark = -1;
    return this;
}
```

从代码中我们可以清晰的看出，limit被设置为当前position的大小，position归0，mark还是为默认值-1，我们还是看图比较直观，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/bytebuffer_flip.png?raw=true)


和上一张图片进行对比，我们可以发现limit替换了position的位置，代表当前可以操作的位置，在写的时候，limit的值代表最大的可写位置，在读的时候，limit的值代表最大的可读位置。很明显我们现在是要读数据，就代表最大可读位置。

**读操作**

