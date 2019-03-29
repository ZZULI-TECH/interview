我们在使用ReentrantLock进行加锁和释放锁时可能会有好奇，这种加锁释放锁的操作和synchronized有什么区别，所以就会去翻源码，一翻源码才发现这里面的知识别有洞天，因为涉及到并发编程最基础最难理解的部分，其中AbstractQueuedSynchronizer这个类是java.util.concurrent的核心，被称为AQS，是一个同步器框架，Doug Lea大神专门写了一篇[论文](http://gee.cs.oswego.edu/dl/papers/aqs.pdf)来介绍该框架。那么在Java世界中，同步器是一个什么概念呢？在并发世界里，涉及到对共享资源的同步操作，加锁释放锁是非常常用的，此外还需要对锁进行细粒度的控制，比如加锁时间控制、共享锁的需求等，这些复杂的需求synchronized都没有提供，那么Doug Lea就给我们提供了，而且代码写的十分优美，值得每一个Java程序员阅读和探究一番。好吧，我们开始阅读源码！在阅读源码前请先学习[链式队列](https://mingshan.fun/2017/12/21/link-queue-structure/)和[CAS](https://mingshan.fun/2018/10/01/cas)的有关知识。（**本文基于JDK11版本**）

<!-- more -->

## 同步器的概念

上面提到同步器（Synchronizer），似乎很玄乎，不知道包含哪些内容。我们直接来阅读Doug Lea的[论文](http://gee.cs.oswego.edu/dl/papers/aqs.pdf)，在论文的INTRODUCTION中，是这样描述的：

> Among these components are a set of synchronizers –
abstract data type (ADT) classes that maintain an internal
synchronization state (for example, representing whether a lock
is locked or unlocked), operations to update and inspect that
state, and at least one method that will cause a calling thread to
block if the state requires it, resuming when some other thread
changes the synchronization state to permit it.

上面的描述大意是：

同步器是一种抽象的数据类型（ADT），在该结构内部，维护以下内容：

1. 一个内部的同步状态（synchronization state），该变量的不同取值可以表征不同的同步状态语义（例如表示一个锁已经被线程持有了还是没有任何线程持有）；
2. 能够更新和检查该同步状态的方法集合；
3. 至少一种获取（acquire）操作来阻塞当前线程，除非/直到同步状态允许许它继续执行; 并且至少有一个释放（release）操作去更改同步状态：可能允许一个或多个被阻塞的线程取消阻塞状态。

最后一条更精确的描述（论文的Functionality部分）如下：

> Synchronizers possess two kinds of methods : at least one
acquire operation that blocks the calling thread unless/until the
synchronization state allows it to proceed, and at least one
release operation that changes synchronization state in a way that
may allow one or more blocked threads to unblock.

真费劲啊，简单地了解了什么是同步器，那么我们就很迫切想了解AbstractQueuedSynchronizer到底是怎么维护上面的内容的，以及其他的同步器（ReentrantLock、CyclicBarrier、Semaphore等）是如何利用AQS来实现自己的需求的。

## AQS结构

AbstractQueuedSynchronizer简称AQS，是用abstract修饰的，基于队列（CLH）实现的一个类，在AQS的内部，使用CLH队列来管理多个抢占资源失败的线程。其中上面提到的acquire和release操作其实是在内部更改同步状态的值。

AQS是一个抽象类，当我们继承AQS去实现自己的同步器时，要做的仅仅是根据自己同步器需要满足的性质实现线程获取和释放资源的方式（修改同步状态变量的方式）即可，至于具体线程等待队列的维护（如获取资源失败入队、唤醒出队、以及线程在队列中行为的管理等），AQS在其顶层已经帮我们实现好了，AQS的这种设计使用的正是模板方法模式。

AQS支持两种模式：

- 独占模式（exclusive mode）：同一时刻只允许一个线程访问共享资源，如ReentrantLock等
  - 公平模式：获取锁失败的线程需要按照顺序排列，前面的先拿到锁
  - 非公平模式： 当线程需要获取锁时，会尝试直接获取锁
- 共享模式（shared mode）：同一时刻允多个线程访问共享资源

**state语义**

在AQS内部维护了一个叫CLH（Craig, Landin, and Hagersten）的队列，它是一个FIFO的队列，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs-clh.png?raw=true)

注意，阻塞队列不包含Head节点，不存储线程及锁相关信息，上面的Node节点代表AQS内部Node的内部静态类。

在AQS内部，维护了一个volatile修饰的整形变量state，该变量具有[volatile](https://en.wikipedia.org/wiki/Volatile_(computer_programming)#In_Java)语义，这是比较关键的一点（保证线程间该值的可见性）。该变量代表共享资源的共享状态，在AQS内部采用CAS更新该变量的值。代码声明如下：

```Java
/**
 * The synchronization state.
 */
private volatile int state;
```

AQS中可以修改或者获取该state值的方法有：

- protected final int getState() // 获取state的值
- protected final void setState(int newState) // 设置state的值
- protected final boolean compareAndSetState(int expect, int update) // CAS 更新state的值

注意这三个方法被protected修饰，说明子类可以直接调用这个三个方法来更改state的值，并且又被final修饰，说明这个三个方法不允许重写，只能够使用。

对于ReentrantLock来说，state的值可以用来表示当前线程获取锁的可重入次数；对于读写锁ReentrantReadWriteLock来说，state的高16位表示读状态，也就是获取读锁的次数，低16位表示表示获取到写锁的线程的可重入次数；对于Semaphore，state表示当前可用信号的个数；对于CountDownLatch，state表示计数器当前的值。

**可重写方法**

如果想自己实现同步器，只需继承AbstractQueuedSynchronizer类，然后重写该类的方法，可以重写哪些方法呢？如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs_override_methods.png?raw=true)

所以，总结来说，子类可以重写以下方法：

- protected boolean tryAcquire(int arg) // 独占模式。 尝试获取资源
- protected boolean tryRelease(int arg) // 独占模式。 尝试释放资源
- protected int tryAcquireShared(int arg) // 共享模式。 尝试获取资源
- protected boolean tryReleaseShared(int arg) // 共享模式。 尝试释放资源
- protected boolean isHeldExclusively() // 当前线程是否独占资源

从上面的可重写的方法可以看出，自定义同步器在实现时只需要实现共享资源state的获取与释放即可，其他的无需子类关心。从这里可以看出AbstractQueuedSynchronizer定义为abstract的好处，只重写自己需要实现的逻辑，比如ReentrantLock，只需重写与独占模式相关的方法即可，共享模式的方法无需关心，编程更方便。

## 源码阅读与流程分析

上面说到CLH中的Node，Node是AQS中的一个静态内部类，该类的源码如下：

```Java
static final class Node {
    /** Marker to indicate a node is waiting in shared mode */
    // 标识当前节点在共享模式
    static final Node SHARED = new Node();
    /** Marker to indicate a node is waiting in exclusive mode */
    // 标识当前节点在独占模式
    static final Node EXCLUSIVE = null;

    /** waitStatus value to indicate thread has cancelled. */
    // 表示当前节点所代表的的线程放弃抢占锁，并且以后不会再变，后续会被gc回收
    static final int CANCELLED =  1;
    /** waitStatus value to indicate successor's thread needs unparking. */
    // 当前线程对应的节点进行入队至队尾（挂起之前），那么其前驱节点的状态就必须为SIGNAL，以便后者取消或释放时将当前节点唤醒。
    static final int SIGNAL    = -1;
    /** waitStatus value to indicate thread is waiting on condition. */
    // Condition队列中结点的状态,CLH队列中结点没有该状态,当Condition的signal方法被调用,
    Condition队列中的结点被转移进CLH队列并且状态变为0
    static final int CONDITION = -2;
    /**
     * waitStatus value to indicate the next acquireShared should
     * unconditionally propagate.
     */
     // 与共享模式相关,当线程以共享模式去获取或释放锁时,对后续线程的释放动作需要不断往后传播
    static final int PROPAGATE = -3;

    // 节点的状态值
    // 取值为上面的1、-1、-2、-3，或者0
    volatile int waitStatus;

    // 前驱节点
    volatile Node prev;
    
    // 后继节点
    volatile Node next;

    // 当前线程
    volatile Thread thread;

    // Condition队列中指向结点在队列中的后继;在CLH队列中共享模式下值取SHARED,独占模式下为null
    Node nextWaiter;

    /**
     * Returns true if node is waiting in shared mode.
     * 判断当前节点是否处于共享模式
     */
    final boolean isShared() {
        return nextWaiter == SHARED;
    }

    /**
     * Returns previous node, or throws NullPointerException if null.
     * Use when predecessor cannot be null.  The null check could
     * be elided, but is present to help the VM.
     * 返回前驱节点
     * @return the predecessor of this node
     */
    final Node predecessor() {
        Node p = prev;
        if (p == null)
            throw new NullPointerException();
        else
            return p;
    }

    /** Establishes initial head or SHARED marker. */
    Node() {}

    /** Constructor used by addWaiter. */
    Node(Node nextWaiter) {
        this.nextWaiter = nextWaiter;
        THREAD.set(this, Thread.currentThread());
    }

    /** Constructor used by addConditionWaiter. */
    Node(int waitStatus) {
        WAITSTATUS.set(this, waitStatus);
        THREAD.set(this, Thread.currentThread());
    }

    /** CASes waitStatus field. */
    final boolean compareAndSetWaitStatus(int expect, int update) {
        return WAITSTATUS.compareAndSet(this, expect, update);
    }

    /** CASes next field. */
    final boolean compareAndSetNext(Node expect, Node update) {
        return NEXT.compareAndSet(this, expect, update);
    }

    final void setPrevRelaxed(Node p) {
        PREV.set(this, p);
    }

    // JDK9 出现的代替Unsafe类，详细参考：https://mingshan.fun/2018/10/05/use-variablehandles-to-replace-unsafe/
    // VarHandle mechanics
    private static final VarHandle NEXT;
    private static final VarHandle PREV;
    private static final VarHandle THREAD;
    private static final VarHandle WAITSTATUS;
    static {
        try {
            MethodHandles.Lookup l = MethodHandles.lookup();
            NEXT = l.findVarHandle(Node.class, "next", Node.class);
            PREV = l.findVarHandle(Node.class, "prev", Node.class);
            THREAD = l.findVarHandle(Node.class, "thread", Thread.class);
            WAITSTATUS = l.findVarHandle(Node.class, "waitStatus", int.class);
        } catch (ReflectiveOperationException e) {
            throw new ExceptionInInitializerError(e);
        }
    }
}
```

在Node类中，我们发现内部用SHARED和EXCLUSIVE来标识当前节点处于哪种模式下，声明如下：

```Java
// 标识当前节点在共享模式
static final Node SHARED = new Node();
// 标识当前节点在独占模式
static final Node EXCLUSIVE = null;
```

接着声明了四种常量值：

**CANCELLED =  1**

表示当前节点所代表的的线程放弃抢占锁，并且以后不会再变，后续会被gc回收。并且状态处于该值的线程会被直接忽略掉。

**SIGNAL    = -1**

当前线程对应的节点进行入队至队尾（挂起之前），那么其前驱节点的状态就必须为SIGNAL，以便后者取消或释放时将当前节点唤醒。

**CONDITION = -2**

Condition队列中结点的状态,CLH队列中结点没有该状态,当Condition的signal方法被调用,
Condition队列中的结点被转移进CLH队列并且状态变为0。

**PROPAGATE = -3**

与共享模式相关,当线程以共享模式去获取或释放锁时,对后续线程的释放动作需要不断往后传播。

**waitStatus**代表当前节点的状态值，取值为上面的四个常量。

下面的是一些方法和属性，看注释就好，就不列出来了。需要说明的是在JDK9之前，Node内部类的源码不是这样的，因为在JDK9引入了[Variable Handles](http://openjdk.java.net/jeps/193)，用来代替sun.misc.Unsafe类，Variable Handles主要是提供java.util.concurrent.atomic 和 sun.misc.Unsafe相似的功能，但会更加安全和易用，并且在并发方面提高了性能。并且AQS与CAS相关的操作全部换成了Variable Handles，具体信息可参考：[用Variable Handles来替换Unsafe](https://mingshan.fun/2018/10/05/use-variablehandles-to-replace-unsafe/)。

总结来说，Node是CLH队列的一个节点，相信对队列这种数据结构熟悉的同学都不会很陌生，只不过加入了一些与锁有关的属性和方法，简化来说就是thread + waitStatus + pre + next 这几个属性和利用CAS改变这几个属性的方法而已，其具体作用在后面的源码分析中会逐渐凸显出来。

### 独占模式

首先我们来分析互斥模式，互斥模式作为最常用的模式使用范围很广，比如ReentrantLock，加锁和释放锁就是使用互斥模式来实现的，下面我们就以一个使用了AbstractQueuedSynchronizer来实现的互斥锁的例子来一步步地阅读互斥模式实现的源码，互斥锁代码如下：

```Java
/**
 * 互斥锁
 */
public class Mutex implements Lock, Serializable {

    // Our internal helper class
    private static class Sync extends AbstractQueuedSynchronizer {
        // Acquires the lock if state is zero
        public boolean tryAcquire(int acquires) {
            assert acquires == 1; // Otherwise unused
            if (compareAndSetState(0, 1)) {
                setExclusiveOwnerThread(Thread.currentThread());
                return true;
            }
            return false;
        }

        // Releases the lock by setting state to zero
        protected boolean tryRelease(int releases) {
            assert releases == 1; // Otherwise unused
            if (!isHeldExclusively())
                throw new IllegalMonitorStateException();
            setExclusiveOwnerThread(null);
            setState(0);
            return true;
        }

        // Reports whether in locked state
        public boolean isLocked() {
            return getState() != 0;
        }

        public boolean isHeldExclusively() {
            // a data race, but safe due to out-of-thin-air guarantees
            return getExclusiveOwnerThread() == Thread.currentThread();
        }

        // Provides a Condition
        public Condition newCondition() {
            return new ConditionObject();
        }

        // Deserializes properly
        private void readObject(ObjectInputStream s)
                throws IOException, ClassNotFoundException {
            s.defaultReadObject();
            setState(0); // reset to unlocked state
        }
    }

    // The sync object does all the hard work. We just forward to it.
    private final Sync sync = new Sync();

    public boolean isLocked()       { return sync.isLocked(); }
    public boolean isHeldByCurrentThread() {
        return sync.isHeldExclusively();
    }
    public boolean hasQueuedThreads() {
        return sync.hasQueuedThreads();
    }

    @Override
    public void lock() {
        sync.acquire(1);
    }

    @Override
    public void lockInterruptibly() throws InterruptedException {
        sync.acquireInterruptibly(1);
    }

    @Override
    public boolean tryLock() {
        return sync.tryAcquire(1);
    }

    @Override
    public boolean tryLock(long timeout, TimeUnit unit) throws InterruptedException {
        return sync.tryAcquireNanos(1, unit.toNanos(timeout));
    }

    @Override
    public void unlock() {
        sync.release(1);
    }

    @Override
    public Condition newCondition() {
        return sync.newCondition();
    }
}
```

上面的互斥锁在摘取自AQS这个类的注释，通过实现一个简单的互斥锁来说明AQS的使用方式。Mutex内部类Sync的类实现了Lock接口，所以需实现与锁有关的方法，比如lock、unlock。在Mutex内部，有一个静态内部类Sync继承AbstractQueuedSynchronizer，重写了tryAcquire、tryRelease等相关方法。所以我们分析AQS独占模式的获取与释放资源时，只需从Mutex的lock、unlock方法开始即可。

## 获取资源

lock方法的代码如下：

```Java
public void lock() {
    sync.acquire(1);
}
```

lock方法体内只调用了sync的acquire方法，并传入参数1，acquire方法的实现在AQS中，代码如下：

```Java
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```

### sync#tryAcquire方法

在acquire方法体内，首先会调用tryAcquire方法，来尝试获取锁，注意该方法在AQS中是这样的：

```Java
protected boolean tryAcquire(int arg) {
    throw new UnsupportedOperationException();
}
```

可以看出该方法AQS并没有提供实现，说明子类在使用独占模式时，必须提供该方法的实现。tryRelease方法也是如此。所以我们来看Mutex内部类Sync的tryAcquire方法的实现：

```Java
public boolean tryAcquire(int acquires) {
    assert acquires == 1; // Otherwise unused
    if (compareAndSetState(0, 1)) {
        setExclusiveOwnerThread(Thread.currentThread());
        return true;
    }
    return false;
}
```

在子类的tryAcquire方法体内，首先会调用compareAndSetState方法将state的值由0设置为1，该方法是在AQS中的，代码如下：


```Java
protected final boolean compareAndSetState(int expect, int update) {
    return STATE.compareAndSet(this, expect, update);
}
```

在compareAndSetState方法中，我们可以发现是直接调用了STATE的compareAndSet方法，这个又是什么呢？这个是使用了JDK9新引入的Variable Handles，来实现CAS操作，详细信息请参考：[用Variable Handles来替换Unsafe](https://mingshan.fun/2018/10/05/use-variablehandles-to-replace-unsafe/)。我们现在可以知道，对于compareAndSetState方法，cas成功，返回true；cas失败，返回false。

回到Sync的tryAcquire方法，如果state由0设置为1，返回true；否则返回失败。如果成功的话，调用setExclusiveOwnerThread方法设置独占模式下的线程为当前线程，同时返回true；否则返回false。

### AQS#addWaiter方法

Sync的tryAcquire方法走完，再次回到AQS中的acquire方法，如果tryAcquire返回true，说明尝试获取锁成功，此时acquire方法直接返回，当前线程获取独占资源成功，流程结束；当tryAcquire返回false，说明尝试获取锁失败，接着就会调用`acquireQueued(addWaiter(Node.EXCLUSIVE), arg)`，注意这里的arg为1。在调用acquireQueued方法的时候，首先会调用`addWaiter(Node.EXCLUSIVE)`方法，并将其返回值作为参数。`addWaiter(Node.EXCLUSIVE)`方法的实现如下：

```Java
private Node addWaiter(Node mode) {
    Node node = new Node(mode);

    for (;;) {
        Node oldTail = tail;
        if (oldTail != null) {
            node.setPrevRelaxed(oldTail);
            if (compareAndSetTail(oldTail, node)) {
                oldTail.next = node;
                return node;
            }
        } else {
            initializeSyncQueue();
        }
    }
}
```

addWaiter方法与JDK8版本有所改动。首先根据传入的参数调用Node的构造函数创建一个Node对象，Node的构造函数如下：

```Java
/** Constructor used by addWaiter. */
Node(Node nextWaiter) {
    this.nextWaiter = nextWaiter;
    THREAD.set(this, Thread.currentThread());
}
```

注意nextWaiter参数的值是Node.EXCLUSIVE，而Node.EXCLUSIVE的值为null，所以nextWaiter等于未赋值，然后调用TH`READ.set(this, Thread.currentThread())`将刚才新建的Node节点的thread属性通过CAS赋值为当前线程。

回到addWaiter方法，创建完Node节点后，就进入了一个无限循环体，在无限循环体内，首先获取CLH的尾节点，并且判断是否为null，所以就有两种情况：

- **尾节点为null**

我们先看为null的情况，此时调用initializeSyncQueue方法初始化CLH队列，initializeSyncQueue方法的实现如下：

```Java
/**
 * Initializes head and tail fields on first contention.
 */
private final void initializeSyncQueue() {
    Node h;
    if (HEAD.compareAndSet(this, null, (h = new Node())))
        tail = h;
}
```

在initializeSyncQueue方法中，有一个Node类型的h局部变量，然后利用CAS将CLH的head节点由null设置为一个初始化Node对象，注意此时无任何参数，此时将会调用Node的无参构造函数，且Node的无参构造函数没有其他实现：

```Java
/** Establishes initial head or SHARED marker. */
Node() {}
```
如果CAS设置成功，将CLH的尾节点也设置为刚才的h对象。注意在CLH中，head为null，tail也必为null，所以tail直接赋值即可。

- **尾节点不为null**

当尾节点不为null时，会调用刚才创建node节点的`node.setPrevRelaxed(oldTail)`方法，setPrevRelaxed的实现如下：

```Java
final void setPrevRelaxed(Node p) {
    PREV.set(this, p);
}
```

即当前的节点node的前驱节点CAS设置为原来CLH的尾节点，就是把node放在CLH队列的队尾。

接着走compareAndSetTail(oldTail, node)方法，其实此时不看源码我们就可以知道这个方法在干嘛，就是更新CLH的尾节点为当前节点（CAS），成功返回true，失败返回false。代码如下：

```Java
/**
 * CASes tail field.
 */
private final boolean compareAndSetTail(Node expect, Node update) {
    return TAIL.compareAndSet(this, expect, update);
}
```

然后回到addWaiter方法，如果compareAndSetTail返回true，将原来的尾节点的next字段更新为的刚才新建的节点，最后返回刚才新建的节点，跳出无限for循环。

**注意上述操作是在无限for循环里面的，跳出无限for循环的条件为CLH不为空，并且新创建的节点（携带当前线程）成功入队至队尾，最后返回该新建的节点，这也是addWaiter方法的作用。**

从上面的流程可以看出，CLH的头节点不包含线程信息。

### AQS#acquireQueued方法

ok，addWaiter方法执行完毕，携带当前线程的节点已经成功入队了，让我们返回到AQS的acquire方法，接着执行`acquireQueued(addWaiter(Node.EXCLUSIVE), arg)`方法，注意此时`addWaiter(Node.EXCLUSIVE)`的返回值为刚才已经入队的Node节点（携带当前线程），arg的值为1。下面来看acquireQueued方法的实现：

```Java
/**
 * Acquires in exclusive uninterruptible mode for thread already in
 * queue. Used by condition wait methods as well as acquire.
 *
 * @param node the node
 * @param arg the acquire argument
 * @return {@code true} if interrupted while waiting
 */
final boolean acquireQueued(final Node node, int arg) {
    boolean interrupted = false;
    try {
        for (;;) {
            final Node p = node.predecessor();
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                return interrupted;
            }
            if (shouldParkAfterFailedAcquire(p, node))
                interrupted |= parkAndCheckInterrupt();
        }
    } catch (Throwable t) {
        cancelAcquire(node);
        if (interrupted)
            selfInterrupt();
        throw t;
    }
}
```

这个方法是什么作用呢？前面分析的addWaiter方法只是将线程包装为Node节点入队，但对当前线程没有任何操作，是不是需要将刚才入队的线程挂起呢？后面如何唤醒该线程，依据是什么？可见该方法之重要性，一定要弄明白。

首先有一个interrupted标志，默认为false，下面又来了一个无线循环，不过是在try语句块内。在无线循环体内，先调用node节点的predecessor方法，predecessor方法的源码如下：

```Java
final Node predecessor() {
    Node p = prev;
    if (p == null)
        throw new NullPointerException();
    else
        return p;
}
```
predecessor方法是获得node节点的前驱节点p，接着判断p是否等于head头节点，并且又调用了tryAcquire(arg)方法。`p == head` 说明当前节点虽然进到了阻塞队列，但是阻塞队列的第一个，因为它的前驱是head，head不持有线程信息。所以这里可以试着再获取下资源，因为前面已经没有持有线程的节点了，为什么不抢^_^。

**如果上面两个操作都返回true**

说明当前节点为阻塞队列CLH的第一个持有线程的节点，并且获取资源成功。接着会执行setHead方法，代码如下：

```Java
/**
 * Sets head of queue to be node, thus dequeuing. Called only by
 * acquire methods.  Also nulls out unused fields for sake of GC
 * and to suppress unnecessary signals and traversals.
 *
 * @param node the node
 */
private void setHead(Node node) {
    head = node;
    node.thread = null;
    node.prev = null;
}
```

这个操作是啥意思？在addWaiter方法中不是已经设置head节点了吗，怎么又设置了一遍？看注释是让刚才创建的头节点gc掉，用node替代。注意此时的node的waitStatus在后面会变，所以head的waitStatus值也会变。

接着设置node的next后继节点为null，返回false，退出无限for循环。

**如果上面两个操作有一个返回false或者都返回false**

说明当前节点不是阻塞队列CLH的第一个持有线程的节点，或者没有抢占资源成功，再或者两者都没有。就会接着执行`shouldParkAfterFailedAcquire(p, node)`方法，`shouldParkAfterFailedAcquire`的源码如下：

```Java
/**
 * Checks and updates status for a node that failed to acquire.
 * Returns true if thread should block. This is the main signal
 * control in all acquire loops.  Requires that pred == node.prev.
 *
 * @param pred node's predecessor holding status
 * @param node the node
 * @return {@code true} if thread should block
 */
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    int ws = pred.waitStatus;// 获取前驱节点的状态
    // 当且仅当状态为SIGNAL时，表示当前节点在以后可以被唤醒，那么就可以进行挂起（park）操作了
    // 此时 ws的值为-1
    if (ws == Node.SIGNAL)
        /*
         * This node has already set status asking a release
         * to signal it, so it can safely park.
         */
        return true;
    
    // ws大于零说明前驱节点的状态为CANCEL, 即为1
    // 即前驱节点的线程被取消了，需要将其从队列中除去
    // 如果返回false, 说明当前线程不需要被挂起
    if (ws > 0) {
        /*
         * Predecessor was cancelled. Skip over predecessors and
         * indicate retry.
         */
        do {
            // 这句话node.prev = pred = pred.prev;
            // 相当于
            // pred = pred.prev;
            // node.prev = pred;
            node.prev = pred = pred.prev; 
        } while (pred.waitStatus > 0); // 找到pred结点前面最近的一个状态不为CANCELLED的结点
        // 将该节点的后继节点设置为当前节点
        pred.next = node;
    } else { // waitStatus 为PROPAGATE -3 或者是0 表示无状态,(为CONDITION -2时，表示此节点在condition queue中)
        /*
         * waitStatus must be 0 or PROPAGATE.  Indicate that we
         * need a signal, but don't park yet.  Caller will need to
         * retry to make sure it cannot acquire before parking.
         */
        // 利用CAS来将当前节点的前驱节点的状态设置为SIGNAL
        // 如果设置成功的话，下次再来访问 状态就为SIGNAL了,将会退出该方法
        pred.compareAndSetWaitStatus(ws, Node.SIGNAL);
    }
    return false; // 如果ws不为SIGNAL, 其他情况全部返回false
}
```

注意第一个参数p为当前新创建节点的前驱节点，第二个参数node为当前新创建节点。上面方法的逻辑在注释里面已经写清楚了我们总结一下：

shouldParkAfterFailedAcquire（注意该方法是在循环里面） 这个方法最终会返回true或者false，从这个方法的名称可以看出，该方法的作用是在当前线程获取资源失败后是否挂起当前线程，显然：

- 返回true，说明前驱节点的waitStatus==-1，是正常情况，那么当前线程需要被挂起，等待以后被唤醒。当前节点是被前驱节点唤醒，就等着前驱节点拿到锁，然后释放锁的时候通知当前线程
- 返回false，说明当前线程不需要被挂起，因为不符合挂起的条件。

让我们返回到acquireQueued方法，如果shouldParkAfterFailedAcquire(p, node)返回true，接下来就会执行下面这段代码：

```Java
interrupted |= parkAndCheckInterrupt();
```
是不是很懵逼？这是啥操作，其实上面这段代码等价于：

```Java
interrupted = interrupted | parkAndCheckInterrupt();
```
这下清楚了吧，按位或`|`属于位运算，有一得1。那么布尔值占用多少字节呢？在Java虚拟机中，布尔类型在虚拟机规范中用int代替，只有0和1两个值，所以应该是4字节。所以只要interrupted 和 parkAndCheckInterrupt()有一个返回true，最终interrupted的值就是true了。

接着就是parkAndCheckInterrupt方法，用来挂起当前的线程，返回中断标志。代码如下:

```Java
/**
 * Convenience method to park and then check if interrupted.
 *
 * @return {@code true} if interrupted
 */
private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this);
    return Thread.interrupted();
}
```

注意入队与挂起线程操作不响应中断，只是返回线程中断标志，这一点从上面的代码就可以看出来。

在acquireQueued方法中，for循环是在try语句块里面的，所以这块代码会出现异常，下面有catch语句块。在JDK8中，没有catch语句块，有一个finally语句块，这是两个版本之间的差异。

此时我们可能会思考，那个地方会出现异常呢？于是乎我们查看上面我们分析过的代码，发现没有方法会抛出异常，在
acquireQueued方法上方，有这样一段注释：

```
/*
 * Various flavors of acquire, varying in exclusive/shared and
 * control modes.  Each is mostly the same, but annoyingly
 * different.  Only a little bit of factoring is possible due to
 * interactions of exception mechanics (including ensuring that we
 * cancel if tryAcquire throws exception) and other control, at
 * least not without hurting performance too much.
 */
```

发现了啥？`tryAcquire`可能会抛出异常，注意这个方法是由继承AQS的子类重写的，AQS框架不保证调用该方法会不会出问题，所以只要`tryAcquire`抛异常，就会走到catch语句块里，代码如下：

```Java
cancelAcquire(node);
if (interrupted)
    selfInterrupt();
throw t;
```

首先会调用cancelAcquire方法取消继续获取锁，cancelAcquire方法的源码如下：


```Java
/**
 * Cancels an ongoing attempt to acquire.
 *
 * @param node the node
 */
private void cancelAcquire(Node node) {
    // Ignore if node doesn't exist
    if (node == null)
        return;

    // node节点内的线程置为空
    node.thread = null;

    // 该节点的前驱节点
    // Skip cancelled predecessors
    Node pred = node.prev;
    // 找到pred结点前面最近的一个状态不为CANCELLED的结点
    while (pred.waitStatus > 0)
        node.prev = pred = pred.prev;

    // predNext is the apparent node to unsplice. CASes below will
    // fail if not, in which case, we lost race vs another cancel
    // or signal, so no further action is necessary, although with
    // a possibility that a cancelled node may transiently remain
    // reachable.
    Node predNext = pred.next;

    // Can use unconditional write instead of CAS here.
    // After this atomic step, other Nodes can skip past us.
    // Before, we are free of interference from other threads.
    node.waitStatus = Node.CANCELLED;

    // node结点为尾结点，则利用CAS设置尾结点为pred结点
    // If we are the tail, remove ourselves.
    if (node == tail && compareAndSetTail(node, pred)) {
        pred.compareAndSetNext(predNext, null);
    } else {
        // If successor needs signal, try to set pred's next-link
        // so it will get one. Otherwise wake it up to propagate.
        int ws;
        // （pred结点不为头结点，并且pred结点的状态为SIGNAL）或者
        //  ws小于0，并且比较并设置等待状态为SIGNAL成功，并且pred结点内的线程不为空
        if (pred != head &&
            ((ws = pred.waitStatus) == Node.SIGNAL ||
             (ws <= 0 && pred.compareAndSetWaitStatus(ws, Node.SIGNAL))) &&
            pred.thread != null) {
            Node next = node.next;
            // 如果后继节点不为空 并且后继节点的等待状态小于等于0
            if (next != null && next.waitStatus <= 0)
                pred.compareAndSetNext(predNext, next);
        } else {
            unparkSuccessor(node);// 释放节点的后继节点
        }

        node.next = node; // help GC
    }
}
```

在该方法中会调用一个方法unparkSuccessor，该方法的作用就是为了释放node节点的后继结点。

```Java
/**
 * Wakes up node's successor, if one exists.
 *
 * @param node the node
 */
private void unparkSuccessor(Node node) {
    /*
     * If status is negative (i.e., possibly needing signal) try
     * to clear in anticipation of signalling.  It is OK if this
     * fails or if status is changed by waiting thread.
     */
    // 获取节点的状态
    int ws = node.waitStatus;
    if (ws < 0)
        node.compareAndSetWaitStatus(ws, 0);// 利用CAS 将状态设置为0

    /*
     * Thread to unpark is held in successor, which is normally
     * just the next node.  But if cancelled or apparently null,
     * traverse backwards from tail to find the actual
     * non-cancelled successor.
     */
    // 获取节点的后继节点
    Node s = node.next;
    // 判断后继节点是否为空 或者 后者后继节点的状态为CANCELLED
    if (s == null || s.waitStatus > 0) {
        s = null; // 将后继节点置为null
         // 从尾节点从后向前开始遍历知道节点为空或者当前节点为止
        for (Node p = tail; p != node && p != null; p = p.prev)
            if (p.waitStatus <= 0) // 如果此时节点的状态小于等于0
                s = p; // 将此节点赋给传入节点的后继节点
    }
    if (s != null) // 节点不为空，唤醒s的线程
        LockSupport.unpark(s.thread);
}
```

### 总结

上面说了这么多，看起来云里雾里，下面就整张流程图吧，看到比较清晰：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs_exclusive_acquire.png?raw=true)

**CLH流程：**

现在我们就可以梳理一下互斥锁获取锁时CLH队列的变化。假设现在有一个线程通过tryAcquire直接获取了锁，并未进CLH队列，所以CLH队列尚未初始化。当线程还未释放锁（unlock），线程1来获取锁了，此时就需要初始化CLH队列（new Node()）：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs_acquire_flow_step1.png?raw=true)

初始化CLH后，就会将线程1包装成Node节点，入队至队尾，此时Head的节点变更为线程1的Node节点，此时的 waitStatus 没有设置， java 默认会设置为 0，但是到 shouldParkAfterFailedAcquire 这个方法的时候，线程1 会把前驱节点，也就是head的waitStatus设置为-1。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs_acquire_flow_step2.png?raw=true)

如果再有一个线程2获取锁，同样也会入队，同时将前驱节点即线程1的Node节点的waitStatus设置为-1。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs_acquire_flow_step3.png?raw=true)

## 释放资源

前面获取到资源后，必须释放已获得的资源。

独占模式下首先执行AbstractQueuedSynchronizer（AQS）的release方法，在这个方法中首先会调用子类的Sync的tryRelease方法，来进行尝试释放锁，如果返回true，那么获取CLH队列的头结点，判断头结点不为空并且头结点的状态不为0（None），那么就调用AQS的unparkSuccessor方法。

```Java
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);
        return true;
    }
    return false;
}
```

在tryRelease方法里，判断当前线程是不是获取独占锁的线程，如果不是，直接抛出异常；如果是，设置独占锁线程为null，最后设置下state的值（注意这里c为0不为0都会设置）

```
// Releases the lock by setting state to zero
protected boolean tryRelease(int releases) {
    assert releases == 1; // Otherwise unused
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    setExclusiveOwnerThread(null);
    setState(0);
    return true;
}
```

接下来来看方法unparkSuccessor，该方法的作用就是为了唤醒node节点的后继结点。

```Java
/**
 * Wakes up node's successor, if one exists.
 *
 * @param node the node
 */
private void unparkSuccessor(Node node) {
    /*
     * If status is negative (i.e., possibly needing signal) try
     * to clear in anticipation of signalling.  It is OK if this
     * fails or if status is changed by waiting thread.
     */
    // 获取节点的状态
    int ws = node.waitStatus;
    if (ws < 0)
        node.compareAndSetWaitStatus(ws, 0);// 利用CAS 将状态设置为0

    /*
     * Thread to unpark is held in successor, which is normally
     * just the next node.  But if cancelled or apparently null,
     * traverse backwards from tail to find the actual
     * non-cancelled successor.
     */
    // 获取节点的后继节点
    Node s = node.next;
    // 判断后继节点是否为空 或者 后者后继节点的状态为CANCELLED
    if (s == null || s.waitStatus > 0) { // 如果为空或已取消
        s = null; // 将后继节点置为null
        // 从尾节点从后向前开始遍历直到节点为空或者当前节点为止
        for (Node p = tail; p != node && p != null; p = p.prev)
            if (p.waitStatus <= 0)// 如果此时节点的状态小于等于0
                s = p;// 将此节点赋给传入节点的后继节点
    }
    if (s != null) // 节点不为空，唤醒节点的线程
        LockSupport.unpark(s.thread);
}
```

释放资源流程图如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs_exclusive_release.png?raw=true)


## 疑点总结

1. acquireInterruptibly 和 acquire 方法，带`Interruptibly`后缀区别？

在AQS源码中，带`Interruptibly`后缀的方法会响应线程中断，即如果当前被中断了，就会抛出`InterruptedException`，而不带`Interruptibly`后缀的方法不会响应线程中断，仅是设置线程中断标志

2. unparkSuccessor 方法为何要从后往前遍历？

在上面的释放资源的源码中，我们注意到unparkSuccessor方法是从后向前遍历CLH队列的，来寻找满足唤醒条件的线程，这样做的目的是当线程进入CLH队列时，需要进行前驱与后继的绑定，在addWaiter方法中，如下所示：

```Java
private Node addWaiter(Node mode) {
    Node node = new Node(mode);

    for (;;) {
        Node oldTail = tail;
        if (oldTail != null) {
            node.setPrevRelaxed(oldTail);
            if (compareAndSetTail(oldTail, node)) {
                oldTail.next = node;
                return node;
            }
        } else {
            initializeSyncQueue();
        }
    }
}
```

首先会执行`node.setPrevRelaxed(oldTail)`，这个是当前节点设置前驱节点为上一个节点，这个操作不会出问题，下面的`compareAndSetTail(oldTail, node)`是一个CAS操作，用来设置CLH队列的尾节点，如果设置成功了，才会将当前节点的上一个节点的next字段设置为当前节点，否则还会进行for循环，直至设置成功为止。试想如果从前往后遍历CLH队列来进行唤醒操作，可能会出现无法扫描到当前最新节点的问题，从尾部扫描则不会有这个问题。

## References：

- [Java Concurrency Constructs](http://gee.cs.oswego.edu/dl/cpj/mechanics.html)
- [The java.util.concurrent Synchronizer Framework](http://gee.cs.oswego.edu/dl/papers/aqs.pdf)
- [A Java Fork/Join Framework](http://gee.cs.oswego.edu/dl/papers/fj.pdf)
- [AQS等待队列流程图](https://processon.com/view/58eb4330e4b0a578cd63bb1b)
- [一行一行源码分析清楚AbstractQueuedSynchronizer](https://javadoop.com/post/AbstractQueuedSynchronizer)
- [Java 并发之AbstractQueuedSynchronizer(AQS)操作图解细节](https://www.jianshu.com/p/282bdb57e343)
- [AQS深入理解与实战----基于JDK1.8](https://www.cnblogs.com/awakedreaming/p/9510021.html)
- [Java并发之AQS详解](https://www.cnblogs.com/waterystone/p/4920797.html)
- [ReentrantLock源码笔记 - 获取锁（JDK 1.8）](https://mingshan.fun/2017/11/10/reentrantlock-get-lock/)
- [用Variable Handles来替换Unsafe](https://mingshan.fun/2018/10/05/use-variablehandles-to-replace-unsafe/)
- [CAS小窥](https://mingshan.fun/2018/10/01/cas)
- 翟陆续 薛宾田，《Java并发编程之美》
- [Primitive Data Types](http://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html)
- [AQS同步器源码分析-独占模式-获取资源](https://www.processon.com/view/link/5c4ed7e8e4b03334b512ae91)
- [AQS同步器源码分析-独占模式-释放资源](https://www.processon.com/view/link/5af3fa59e4b05f390c6b59f4)
