 # CAS分析

在JDK 1.5之后Java提供了并发包（`java.util.concurrent`）,加强对并发的支持。该包下的类大量使用 CAS（Compare and Swap）来实现原子操作、锁优化等。在`java.util.concurrent.atomic`包中，提供了对基本类型的原子封装，比如AtomicInteger，用来原子性访问和更新。我们十分熟悉的++i操作，在多线程环境下并非是线程安全的，因为它包含取值、相加与赋值三步操作，所以整体不是原子操作。
 
CAS是Java中所谓lock-free的基础。CAS有3个操作数，内存值V，旧的预期值A，要修改的新值B。当且仅当预期值A和内存值V相同时，将内存值V修改为B，否则什么都不做。CAS的描述如下（返回布尔值是为了让调用者知道是否更新成功）：

```Java
public boolean compareAndSwap(int destValue, int expectedValue, int newValue) {  
    if (destValue == expectedValue) {  
        destValue = newValue;  
        return true;  
    }  
    return false;  
}
```

那么在JDK源码中是如何使用CAS的呢？我们先来看看AtomicInteger(JDK10)的源码实现。在JDK10版本中，CAS这部分操作是在`jdk.internal.misc.Unsafe`这个类中提供的，所以在AtomicInteger源码中，自增一是调用了Unsafe 的 getAndAddInt 方法。代码如下：

```Java
private static final jdk.internal.misc.Unsafe U = jdk.internal.misc.Unsafe.getUnsafe();
private static final long VALUE = U.objectFieldOffset(AtomicInteger.class, "value");
private volatile int value;

public final int incrementAndGet() {
    return U.getAndAddInt(this, VALUE, 1) + 1;
}
```

`VALUE` 代表AtomicInteger对象value成员变量在内存中的偏移量，因为Unsafe是根据内存偏移地址获取数据的。`value`代表当前值，使用volatile修饰，保证多线程环境下值一致。

Unsafe这个类比较厉害，提供一些低级、不安全操作的方法， JDK不推荐我们直接调用这个类。下面getAndAddInt的代码：

```Java
@HotSpotIntrinsicCandidate
public final int getAndAddInt(Object o, long offset, int delta) {
    int v;
    do {
        v = getIntVolatile(o, offset);
    } while (!weakCompareAndSetInt(o, offset, v, v + delta));
    return v;
}
```

方法的执行流程如下：

1. 假设现在有两个线程同时进入getAndAddInt方法, 主内存的value假设为2，根据Java内存模型，线程A和线程B各自持有一份value的副本，值为2；
2. 线程A 执行`getIntVolatile(o, offset)`方法，拿到value值为2，线程A被挂起了；
3. 线程B执行`getIntVolatile(o, offset)`方法，拿到value值为2， 接着执行`weakCompareAndSetInt(o, offset, v, v + delta))`方法，发现内存值和获取的值都是2，成功修改value的值为1；
4. 线程A继续执行`weakCompareAndSetInt(o, offset, v, v + delta))`方法，发现自己获取的值2和内存中的值1不一样了，修改失败，继续循环执行
5. 继续上面同样的操作，由于value被volatile修饰，所以此时线程A的value的副本就为1了，执行`getIntVolatile(o, offset)`方法，获取的值也为1，最后执行`weakCompareAndSetInt(o, offset, v, v + delta))`，直至成功修改value的值。


`weakCompareAndSetInt`最终调用`compareAndSetInt`方法，注意该方法为本地方法，如下。该方法有四个参数，分别是对象（这里是AtomicInteger）、对象的偏移地址、预期值、修改值。

```
@HotSpotIntrinsicCandidate
public final native boolean compareAndSetInt(Object o, long offset,
                                             int expected,
                                             int x);
```

该方法根据操作系统的不同有不同的实现。在openjdk调用的c++代码为：[unsafe.cpp](https://github.com/unofficial-openjdk/openjdk/blob/4fb6d169db9c9732929ebbd5df01075b29105275/src/hotspot/share/prims/unsafe.cpp#L907)。。我也看不懂

**ABA问题**我也看不懂

从上面的分析可以看出，CAS涉及到修改值操作，如果一个值先被修改然后再修改为原值，那么就出现了ABA问题。具体流程如下：
1. 线程P1读取指定内存的值为A
2. 线程P1被挂起，线程P2运行
3. 线程P2将指定内存的值从A修改为B，再改回A。
4. 再次调度到线程P1
5. 线程P1发现指定内存的值没有变，于是继续执行。

`java.util.concurrent.atomic`包中，JDK提供了AtomicStampedReference，在该类中提供stamp来记录每次对值修改的操作，通过判断stamp来解决ABA问题的发生。示例如下：

```Java
/**
 * 使用版本号解决CAS中的ABA问题。
 * 每一次修改都记录下版本号, 此版本号+1.
 *
 */
public class AtomicStampedReferenceDemo {
    private static AtomicStampedReference<Integer> atomicStampedRef =
            new AtomicStampedReference<Integer>(1, 0);

    public static void main(String[] args){
        Thread main = new Thread(() -> {
            System.out.println("操作线程" + Thread.currentThread() +", 初始值 a = " 
                    + atomicStampedRef.getReference());
            // 获取当前Stamp
            final int stamp = atomicStampedRef.getStamp();
            try {
                // 等待2秒 ，以便让干扰线程执行
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            // 此时stamp已经被修改了, 所以CAS失败
            boolean isCASSuccess = atomicStampedRef.compareAndSet(1, 2, stamp, stamp + 1);
            System.out.println("操作线程" + Thread.currentThread() +", CAS操作结果: " + isCASSuccess);
        }, "主操作线程");

        Thread other = new Thread(() -> {
            // 干扰线程让出自己的cpu时间片，回到Runnable状态，让自己或主操作线程先执行
            Thread.yield();
            // 加一
            atomicStampedRef.compareAndSet(1, 2, 
                    atomicStampedRef.getStamp(),atomicStampedRef.getStamp() + 1);
            System.out.println("操作线程" + Thread.currentThread() + ", 【increment】, Reference = " 
                    + atomicStampedRef.getReference() + ", Stamp = " + atomicStampedRef.getStamp());

            // 然后减一
            atomicStampedRef.compareAndSet(2, 1, atomicStampedRef.getStamp(), 
                    atomicStampedRef.getStamp() + 1);
            System.out.println("操作线程" + Thread.currentThread() + ", 【decrement】, Reference = " 
                    + atomicStampedRef.getReference() + ", Stamp = " + atomicStampedRef.getStamp());
        }, "干扰线程");

        main.start();
        other.start();
    }

}
```

执行结果为：

```
操作线程Thread[主操作线程,5,main], 初始值 a = 1
操作线程Thread[干扰线程,5,main], 【increment】, Reference = 2, Stamp = 1
操作线程Thread[干扰线程,5,main], 【decrement】, Reference = 1, Stamp = 2
操作线程Thread[主操作线程,5,main], CAS操作结果: false
```

参考：

- [Non-blocking algorithm](https://en.wikipedia.org/wiki/Non-blocking_algorithm)
- [The java.util.concurrent Synchronizer Framework
](http://gee.cs.oswego.edu/dl/papers/aqs.pdf)
- [无锁程序设计](http://www.berlinix.com/dev/lock-free.php)
- [JAVA CAS原理深度分析](https://www.cnblogs.com/kisty/p/5408264.html)
- [JAVA中CAS-ABA的问题解决方案AtomicStampedReference](https://www.jianshu.com/p/8b227a8adbc1)
- 杨晓峰，AtomicInteger底层实现原理是什么？如何在自己的产品代码中应用CAS操作？