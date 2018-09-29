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

那么在JDK源码中是如何使用CAS的呢？我们先来看看AtomicInteger的源码实现。在JDK10版本中，CAS这部分操作是在`jdk.internal.misc.Unsafe`这个类中提供的，所以在AtomicInteger源码中，自增一是调用了Unsafe 的 getAndAddInt 方法。代码如下：

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




`weakCompareAndSetInt`最终调用`compareAndSetInt`方法，注意该方法为本地方法，如下。该方法有四个参数，分别是对象（这里是AtomicInteger）、对象的偏移地址、预期值、修改值。

```
@HotSpotIntrinsicCandidate
public final native boolean compareAndSetInt(Object o, long offset,
                                             int expected,
                                             int x);
```


参考：

- [Non-blocking algorithm](https://en.wikipedia.org/wiki/Non-blocking_algorithm)
- [The java.util.concurrent Synchronizer Framework
](http://gee.cs.oswego.edu/dl/papers/aqs.pdf)
- [无锁程序设计](http://www.berlinix.com/dev/lock-free.php)
- [JAVA CAS原理深度分析](https://www.cnblogs.com/kisty/p/5408264.html)