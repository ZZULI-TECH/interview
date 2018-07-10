# ThreadLocal

记得去年学习Spring MVC的时候自己学着写了一个小小的框架，用了一个AppContext来表示应用上下文，每个请求都应该有各自独立的AppContext，里面可以存储一些数据，比如数据库连接Connection等，此时考虑数据库的事务问题，即在一个线程内，一个事务的多个操作拿到的是一个Connection，该如何实现呢？此时就需要使用ThreadLocal来解决。

### ThreadLocal介绍

**ThreadLocal能干啥？**

ThreadLocal是基于线程的一个本地变量的支持类，用户可以将对象与线程绑定，每一个线程都拥有一个自己的对象，例如对于上面的需求来说，可以将AppContext存入到ThreadLocal，代码如下：

```Java
public class AppContext {
    private static ThreadLocal<AppContext> appContextMap = new ThreadLocal<AppContext>();
    private Map<String, Object> objects = new HashMap<String, Object>();

    private AppContext() {};

    // 部分代码省略
    
    public void clear() {
        AppContext context = appContextMap.get();
        if (context != null) {
            context.objects.clear();
        }
        context = null;
    }

    public static AppContext getAppContext() {
        AppContext appContext = appContextMap.get();
        if (appContext == null) {
            appContext = new AppContext();
            appContextMap.set(appContext);
        }
        return appContextMap.get();

    }

}
```

对于数据库的Connection，可以有以下实现

```Java
public Class ConnectionManager {

   // 创建一个私有静态的并且是与事务相关联的局部线程变量  
   private static ThreadLocal<Connection> connectionHolder = new ThreadLocal<Connection>;

   public static Connection getConnection() {
       // 获得线程变量connectionHolder的值conn  
       Connection conn = connectionHolder.get();
       if (conn == null){
           // 如果连接为空，则创建连接，另一个工具类，创建连接  
           conn = DbUtil.getConnection();
           // 将局部变量connectionHolder的值设置为conn  
           connectionHolder.set(conn);
       }
       return conn;
   }  
｝
```

### ThreadLocal原理分析

ThreadLocal有如下成员变量和方法，如下图所示

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/threadlocal.png?raw=true)

其中经常用到的是以下几个方法：

```Java
public T get() { }
public void set(T value) { }
public void remove() { }
protected T initialValue() { }
```
由于ThreadLocal里面需要存值和取值，又需要与线程相关，那么数据存在哪里，用哪种数据结构呢？由于Map可以存储很多类型，这里又不需要对外提供服务，所以这里就用了静态内部类的Map来搞存储，来存储真实的变量实例。

#### get()流程
那么， ThreadLocal是如何工作的呢？我们先从get方法看起，下面是get方法的源码


```Java
public T get() {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    return setInitialValue();
}

```

首先获得当前线程，然后通过getMap(t)方法获取到一个map，map的类型为ThreadLocalMap。接下来根据<key,value>从map中获取Entry，注意这里获取键值对传进去的是this，而不是当前线程t。如果获取成功，则返回value值。如果map为空，则调用setInitialValue方法返回value。

getMap()方法是如何获取到ThreadLocalMap的呢？来看看源码

```Java
ThreadLocalMap getMap(Thread t) {
    return t.threadLocals;
}

```

发现是直接获取当前线程的threadLocals成员变量，那么接下来就到Thread类里面去看一下

```Java
/* ThreadLocal values pertaining to this thread. This map is maintained
 * by the ThreadLocal class. */
ThreadLocal.ThreadLocalMap threadLocals = null;
```
实际上就是ThreadLocalMap，这个类型是ThreadLocal类的一个内部类，我们来看看ThreadLocalMap内部的Entry类，源码如下：


```Java
static class Entry extends WeakReference<ThreadLocal<?>> {
    /** The value associated with this ThreadLocal. */
    Object value;

    Entry(ThreadLocal<?> k, Object v) {
        super(k);
        value = v;
    }
}
```

Entry继承自WeakReference，这里弱引用为Map的key，也就是ThreadLocal，弱引用就是只要JVM垃圾回收器发现了它，就会将之回收。


回到get()方法， 如果通过getMap()方法获取的map为空，就会调用setInitialValue() 方法，下面是该方法的源码


```Java
private T setInitialValue() {
    T value = initialValue();
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
    return value;
}
```

首先调用initialValue() 方法进行初始化value，默认为null，接下来获取当前线程，获取map，判断map是否为空，不为空将ThreadLocal类的对象为key，设定value，为空则创建map，调用createMap(t, value)方法，createMap代码如下：


```Java
void createMap(Thread t, T firstValue) {
    t.threadLocals = new ThreadLocalMap(this, firstValue);
}
```

#### set(T value)流程

接下来看看set方法如何实现的，下面是源码：


```Java
public void set(T value) {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
}
```
首先获取当前线程，然后获取map，判断map是否为空，不为空将ThreadLocal类的对象为key，设定value，为空则创建map，调用createMap(t, value)方法。

至此，我们就可以知道大致知道ThreadLocal的工作流程：

1. Thread类中有一个成员变量属于ThreadLocalMap类(一个定义在ThreadLocal类中的内部类)，它是一个Map，它的key是ThreadLocal实例对象。

2. 当为ThreadLocal类的对象set值时，首先获得当前线程的ThreadLocalMap类属性，然后以ThreadLocal类的对象为key，设定value。get值时则类似。


### 一个线程多个ThreadLocal，如何区分？
既然ThreadLocal内部用map存储数据，一个线程可以对应多个ThreadLocal对象，那么这些ThreadLocal对象是如何区分的呢？上面只是大致分析了ThreadLocal的工作原理，并未涉及ThreadLocalMap的存值和取值，接下来我们继续来看源码


```Java
/**
 * ThreadLocals rely on per-thread linear-probe hash maps attached
 * to each thread (Thread.threadLocals and
 * inheritableThreadLocals).  The ThreadLocal objects act as keys,
 * searched via threadLocalHashCode.  This is a custom hash code
 * (useful only within ThreadLocalMaps) that eliminates collisions
 * in the common case where consecutively constructed ThreadLocals
 * are used by the same threads, while remaining well-behaved in
 * less common cases.
 */
private final int threadLocalHashCode = nextHashCode();

/**
 * The next hash code to be given out. Updated atomically. Starts at
 * zero.
 */
private static AtomicInteger nextHashCode =
    new AtomicInteger();

/**
 * The difference between successively generated hash codes - turns
 * implicit sequential thread-local IDs into near-optimally spread
 * multiplicative hash values for power-of-two-sized tables.
 */
private static final int HASH_INCREMENT = 0x61c88647;

/**
 * Returns the next hash code.
 */
private static int nextHashCode() {
    return nextHashCode.getAndAdd(HASH_INCREMENT);
}

```
在ThreadLocal类内部定义了一个final的变量threadLocalHashCode，这个变量是干什么的？看注释，在ThreadLocalMap存储数据时，ThreadLocal对象作为key，通过threadLocalHashCode进行搜索，threadLocalHashCode通过原子类AtomicInteger，提供原子操作，由于nextHashCode为类变量，保证每次生成的hashCode都不一致，每次生成hashCode都会有HASH_INCREMENT的差值。threadLocalHashCode会在ThreadLocalMap中用到，下面继续分析。

前面分析get()流程，对于如何从ThreadLocalMap取数据并未提及，现在看看源码如何实现的：

```Java
private Entry getEntry(ThreadLocal<?> key) {
    int i = key.threadLocalHashCode & (table.length - 1);
    Entry e = table[i];
    if (e != null && e.get() == key)
        return e;
    else
        return getEntryAfterMiss(key, i, e);
}
```
通过调用ThreadLocalMap的getEntry方法，传入当前ThreadLocal对象，然后获取ThreadLocal的threadLocalHashCode， 然后通过位运算与(&) 将 threadLocalHashCode和ThreadLocal内部存储数据的table的长度减一进行位运算得到i，利用i在table中直接进行搜索。


在ThreadLocalMap如何存值？下面看ThreadLocalMap.set()源码


```Java
private void set(ThreadLocal<?> key, Object value) {

    // We don't use a fast path as with get() because it is at
    // least as common to use set() to create new entries as
    // it is to replace existing ones, in which case, a fast
    // path would fail more often than not.

    Entry[] tab = table;
    int len = tab.length;
    int i = key.threadLocalHashCode & (len-1);

    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        ThreadLocal<?> k = e.get();

        if (k == key) {
            e.value = value;
            return;
        }

        if (k == null) {
            replaceStaleEntry(key, value, i);
            return;
        }
    }

    tab[i] = new Entry(key, value);
    int sz = ++size;
    if (!cleanSomeSlots(i, sz) && sz >= threshold)
        rehash();
}
```

在ThreadLocalMap.set()方法中，传入当前ThreadLocal对象和要存的值，然后通过位运算与(&) 将 threadLocalHashCode和ThreadLocal内部存储数据的table的长度减一进行位运算得到i，这个i在get()方法已经见过了，完全一样（不一样就出问题啦），接下来开始遍历table，判断有没有相同的key等处理，其实最核心的就是你得去new 一个entry然后设置到table数组中，就是下面这句：

```Java
tab[i] = new Entry(key, value);
```

### ThreadLocal会有内存泄露？

看了好多博客，里面提到ThreadLocal会有内存泄露问题，因为从ThreadLocalMap的设计来看，如下图，key被设计成弱引用，一旦JVM进行GC时，这个key就没了，那么与key对应的value还存在ThreadLocalMap，ThreadLocalMap与Entry存在着强引用，GC无法回收，造成内存泄露。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/threadlocal_weak.png?raw=true)

当然，这些都是分析出来的，既然我们考虑到了，那么Josh Bloch 和 Doug Lea肯定也为我们考虑过了，所以这个问题在源码中已经解决了，下面来看看相关源码

在ThreadLocalMap.set()方法中，如果key为null，此时会调用 replaceStaleEntry()方法，在这个方法中进行处理


```Java
private void replaceStaleEntry(ThreadLocal<?> key, Object value,
                               int staleSlot) {
    Entry[] tab = table;
    int len = tab.length;
    Entry e;

    // Back up to check for prior stale entry in current run.
    // We clean out whole runs at a time to avoid continual
    // incremental rehashing due to garbage collector freeing
    // up refs in bunches (i.e., whenever the collector runs).
    int slotToExpunge = staleSlot;
    for (int i = prevIndex(staleSlot, len);
         (e = tab[i]) != null;
         i = prevIndex(i, len))
        if (e.get() == null)
            slotToExpunge = i;

    // Find either the key or trailing null slot of run, whichever
    // occurs first
    for (int i = nextIndex(staleSlot, len);
         (e = tab[i]) != null;
         i = nextIndex(i, len)) {
        ThreadLocal<?> k = e.get();

        // If we find key, then we need to swap it
        // with the stale entry to maintain hash table order.
        // The newly stale slot, or any other stale slot
        // encountered above it, can then be sent to expungeStaleEntry
        // to remove or rehash all of the other entries in run.
        if (k == key) {
            e.value = value;

            tab[i] = tab[staleSlot];
            tab[staleSlot] = e;

            // Start expunge at preceding stale entry if it exists
            if (slotToExpunge == staleSlot)
                slotToExpunge = i;
            cleanSomeSlots(expungeStaleEntry(slotToExpunge), len);
            return;
        }

        // If we didn't find stale entry on backward scan, the
        // first stale entry seen while scanning for key is the
        // first still present in the run.
        if (k == null && slotToExpunge == staleSlot)
            slotToExpunge = i;
    }

    // If key not found, put new entry in stale slot
    tab[staleSlot].value = null;
    tab[staleSlot] = new Entry(key, value);

    // If there are any other stale entries in run, expunge them
    if (slotToExpunge != staleSlot)
        cleanSomeSlots(expungeStaleEntry(slotToExpunge), len);
}
```

其中我们可以看到这段代码：

```Java
// If key not found, put new entry in stale slot
tab[staleSlot].value = null;
```
如果key找不到，那么就将value置为null，help GC。这样问题解决。

当然在resize()方法中也有同样的操作，总之都会进行处理的。

最后，我们可以调用remove()方法将相关数据移除，这个肯定就不会有内存泄露啦。

参考：<br/>
[彻底理解ThreadLocal](https://www.cnblogs.com/xzwblog/p/7227509.html#_label0)<br/>
[对ThreadLocal实现原理的一点思考](https://www.jianshu.com/p/ee8c9dccc953)<br/>
[设计ThreadLocal的那段日子](https://mp.weixin.qq.com/s?__biz=MzA5MzQ2NTY0OA==&mid=2650796401&idx=1&sn=61f2d19bfb0e34c08206c6b31a1c2dd1&chksm=88562c2ebf21a5383ace3f52f336db9b53a714bb37d5f97a9d5746b43b6a3d30be113aca082a&mpshare=1&scene=23&srcid=1212TdJMnkHNCPTwVsPKSuao#rd)<br/>