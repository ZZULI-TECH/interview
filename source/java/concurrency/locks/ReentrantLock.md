## ReentrantLock 学习 - 获取锁（JDK 1.8）
* * *
ReentrantLock 提供非公平锁与公平锁两种加锁方式, 默认加锁方式为非公平锁。

### ReentrantLock类的结构为：<br>
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/ReentrantLock.png?raw=true)

从图中可以看出，ReentrantLock类包含三个静态内部类：
- Sync
- NonfairSync
- FairSync

其中Sync类继承AbstractQueuedSynchronize（AQS), NonfairSync和FairSync继承Sync。

### ReentrantLock的基本用法：

```java
class X {
    private final ReentrantLock lock = new ReentrantLock();
    // ...

    public void m() {
      lock.lock();  // block until condition holds
      try {
        // ... method body
      } finally {
        lock.unlock()
      }
    }
  }
```

### ReentrantLock的创建
- 非公平锁

```java
Lock lock = new ReentrantLock();
```
- 公平锁

```java
Lock lock = new ReentrantLock(true);
```
由于默认创建的为非公平锁，所以想创建公平锁，就需要向其构造方法传入true。

1. 创建非公平锁的构造方法为：

```java
/**
 * Creates an instance of {@code ReentrantLock}.
 * This is equivalent to using {@code ReentrantLock(false)}.
 */
public ReentrantLock() {
    sync = new NonfairSync();
}
```

2. 创建公平锁的构造方法为：

```java
/**
 * 根据传入的布尔值来判断创建哪种锁
 * Creates an instance of {@code ReentrantLock} with the
 * given fairness policy.
 *
 * @param fair {@code true} if this lock should use a fair ordering policy
 */
public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
```

### 非公平锁

#### 非公平锁的用法

```java
lock.lock();
```
在ReetrantLock类的内部提供了一个加锁的方法：

```java
public void lock() {
    sync.lock();
}

```
在这个方法里又调用了==sync==的==lock==方法，又因为Sync这个类为一个抽象类，在ReentrantLock类实例化的时候，根据参数来判断调用哪个具体的类。

这里先谈谈非公平锁的加锁实现。

#### **非公平锁实现简单步骤**：

 基予CAS(Compare And Swap)将state由0设置为1。<br>
- 如果设置成功，那么直接获得锁，并设置独占锁的线程为当前线程。<br>
- 如果设置失败，原先内存state的值不是0，已经有其他线程获得锁，那么就会再获取一次state。<br>
  1. 如果state为0， 那么就会再次利用CAS将state的值由0设置为1，如果成功，设置独占锁的线程为当前线。<br>
  2. 如果state不为0，那么需要判断当前线程是否是独占锁的线程，如果是，那么就将state加1， 并且判断当前state的值不能小于0；如果不是，那么就将该线程封装在一个Node(AQS里面)里,并加入到等待列队里，等其他线程唤醒。

#### 具体流程如下：

首先通过ReentrantLock的lock方法调用到其内部类NonFairLock的lock方法

```java
final void lock() {
    if (compareAndSetState(0, 1))
        setExclusiveOwnerThread(Thread.currentThread());
    else
        acquire(1);
}

```
在lock方法中，先调用compareAndSetState方法来将state由0设置为1，如果设置成功，设置当前线程为独占锁线程，如果失败，则调用AbstractQueuedSynchronizer类的acquire(1)方法。


```java
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```
向aquire方法传入参数1，此方法是线程获取临界资源的顶层入口， 如果获得到资源则直接返回，如果失败，则将当前先后才能放入到等待列队，直到获取到资源才返回。此过程忽略中断影响，模式为独占模式。

因为这个方法涉及到线程的入队操作，下面来看看AbstractQueuedSynchronizer类内部封装的Node.

```java
/**
 * 同步等待队列（双向链表）节点
 */
static final class Node {

    static final Node SHARED = new Node();
    // 一个标记：用于表明该节点在独占模式下进行等待
    static final Node EXCLUSIVE = null;

    // 线程被取消了
    static final int CANCELLED =  1;
    // 节点等待触发
    static final int SIGNAL    = -1;
    // 节点等待条件
    static final int CONDITION = -2;
    // 节点状态需要向后传播
    static final int PROPAGATE = -3;

    volatile int waitStatus;

    // 前驱节点
    volatile Node prev;

    // 后继节点
    volatile Node next;

    // 线程
    volatile Thread thread;


    Node nextWaiter;


    final boolean isShared() {
        return nextWaiter == SHARED;
    }


    final Node predecessor() throws NullPointerException {
        Node p = prev;
        if (p == null)
            throw new NullPointerException();
        else
            return p;
    }

    Node() {    // Used to establish initial head or SHARED marker
    }

    Node(Thread thread, Node mode) {     // Used by addWaiter
        this.nextWaiter = mode;
        this.thread = thread;
    }

    Node(Thread thread, int waitStatus) { // Used by Condition
        this.waitStatus = waitStatus;
        this.thread = thread;
    }
}
```
tryAcquire方法会调用ReentrantLock中NonfairSync内部类中的tryAcquire方法

```java
protected final boolean tryAcquire(int acquires) {
    return nonfairTryAcquire(acquires);
}
```
然后调用nonfairTryAcquire方法进行再一次尝试获取锁

```java
final boolean nonfairTryAcquire(int acquires) {
    // 当前线程
    final Thread current = Thread.currentThread();
    // 再一次获取state
    int c = getState();
    // 如果state为0，说明其他线程已经释放了锁，可以尝试获取锁
    if (c == 0) {
        // 利用CAS来设置当前state的值
        if (compareAndSetState(0, acquires)) {
            // 如果成功则设置当前线程为独占锁线程，然后直接返回
            setExclusiveOwnerThread(current);
            return true;
        }
    } // 如果当前state不是0，则判断当前线程是否为独占锁线程
    else if (current == getExclusiveOwnerThread()) {
        // 将state进行+1操作，判断state值后返回
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;  // 获取锁失败，考虑将线程加入等待队列
}
```
在nonfairTryAcquire方法为再一次尝试获取锁，这个过程可能获取锁的线程已经释放了锁，所以再一次判断state的值，如果state的值为0，那么利用CAS将state由0设值为1，如果成功，获取锁成功，设值当前线程为独占锁线程，直接返回；如果state不为0，则判断当前线程是否为独占锁线程（可重入锁来源，state每加一次1，那么就需要释放锁的次数也要+1，这样才能保证state最终在线程释放锁的情况下值为0），如果是，将state加1，然后返回；其他情况返回false，获取锁失败。

如果当前线程获取锁失败，就需要将该线程加入等待队列的末尾。
该等待列队是CLH队列，队列的示意图如下：


```
     +------+  prev +-----+       +-----+
head |      | <---- |     | <---- |     |  tail
     +------+       +-----+       +-----+
```


接下来就会调用AQS的addWaiter(Node.EXCLUSIVE)方法

```java
private Node addWaiter(Node mode) {
    // 根据当前线程创建一个Node节点，并设置为独占模式
    Node node = new Node(Thread.currentThread(), mode);
    // 试图进行快速入队操作，仅尝试一次
    // 将队列的尾节点tail赋给pred
    Node pred = tail;
    // 判断尾节点是否为空
    if (pred != null) {
        // 将尾节点作为创造出来的节点的前驱节点，即将创造出来的节点
        // 链接到为尾节点后
        node.prev = pred;
        // 利用CAS将尾节点tail由pred设置为node
        // 此时队列 node1 <-> node
        // 再加上 node1 <-> prev
        // 所以此时队列应为  node1 <-> prev <-> node
        if (compareAndSetTail(pred, node)) {
            // 如果成功，则将pred的后继节点为node
            pred.next = node;
            return node;
        }
    }
    enq(node); // 正常入队
    return node;
}
```
具体的实现流程已在代码中注释，如果不是快速入队，那么就进行正常入队，即调用AQS的enq(node)方法

```java
private Node enq(final Node node) {
    // 等待，直到插入到队列位置
    for (;;) {
        // 将尾节点tail赋给t
        Node t = tail;
        // 判断尾节点是否为空，如果尾节点为空，说明队列为空
        if (t == null) { // Must initialize
            // 生成一个新节点，将head由null设置为新节点的值
            // 如果设置失败，说明在这个过程中已经有其他线程设置过head了
            // 当成功的将这个dummy节点设置到head节点上去时，我们又将这个head节点// 设置给了tail节点，即head与tail都是当前这个dummy节点，
            // 之后有新节点入队的话，就插入到该dummy之后
            if (compareAndSetHead(new Node()))
                tail = head;
        } else { //如果尾节点不为空，则按照快速入队操作进行操作
            node.prev = t;
            if (compareAndSetTail(t, node)) { // 尝试将尾节点设置为node
                t.next = node; // 将node节点设置为尾节点,即将尾节点的后继节点设置为node节点
                return t;  // 返回原先的尾节点
            }
        }
    }
}
```
入队成功之后需要调用AQS的acquireQueued(addWaiter(Node.EXCLUSIVE), arg))方法

```java
/**
  * 队列中的结点在独占且忽略中断的模式下获取锁
  * 如果获取成功则返回false
  * 如果获取失败
  */
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true; // 失败标志
    try {
        boolean interrupted = false; //中断标志
        for (;;) { // 无限等待
            final Node p = node.predecessor(); // 获取插入节点的前一个节点p
            // 仅当当前的节点的前驱节点并且
            // 尝试获取锁成功，跳出循环
            // 当第一次循环就获取成功了，interrupted为false，不需要中断

            if (p == head && tryAcquire(arg)) {
                setHead(node); // 设置头结点
                p.next = null; // help GC
                failed = false;
                return interrupted;
            } // 当获取(锁)失败后，检查并且更新结点状态, 挂起当前节点并检查中断
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}

```
如果acquireQueued方法没有跳出循环（获取锁失败），那么就要判断当前节点是否可以安全的挂起（park），下面就会调用AQS的shouldParkAfterFailedAcquire(Node pred, Node node) 方法
```java
/**
 * 当获取(资源)失败后，检查并且更新结点状态
 */
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    int ws = pred.waitStatus; // 获取前驱节点的状态
     // 当且仅当状态为SIGNAL时，表示当前节点在以后可以被唤醒，那么就可以进行挂起// （park）操作了
     // 此时 ws的值为-1
    if (ws == Node.SIGNAL)
        /*
         * This node has already set status asking a release
         * to signal it, so it can safely park.
         */
        return true;
    // ws大于零说明前驱节点的状态为CANCEL, 即为1
    // 即前驱节点的线程被取消了，需要将其从队列中除去，最终返回false
    // 不能被安全的挂起
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
        pred.next = node; // 将该节点的后继节点设置为当前节点
    } else { // waitStatus 为PROPAGATE -3 或者是0 表示无状态,(为CONDITION -2时，表示此节点在condition queue中)
        /*
         * waitStatus must be 0 or PROPAGATE.  Indicate that we
         * need a signal, but don't park yet.  Caller will need to
         * retry to make sure it cannot acquire before parking.
         */
        // 利用CAS来将当前节点的前驱节点的状态设置为SIGNAL
        // 如果设置成功的话，下次再来访问 状态就为SIGNAL了
        compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    }
    return false; // 如果ws不为SIGNAL, 其他情况全部返回false
}
```
在该方法中需要判断当前节点的前驱节点的状态，如果状态为SIGNAL时，表示当前节点在以后可以被唤醒，那么就可以进行挂起了<br>
**如果不是**
- 那么就需要判断该前驱节点（线程）是否被取消了，如果被取消，那么这个前驱节点应该从队列中除去，再经过while循环找到pred结点前面最近的一个状态不为CANCELLED的结点，并将当前节点的前驱节点设置为该节点；
- 如果该前驱节点的waitStatus不为CANCELLED,那么利用CAS将当前节点的前驱节点的状态设置为SIGNAL

接下来就会执行AQS 中的parkAndCheckInterrupt()方法

```java
/**
  * 进行挂起（park）操作并且返回该线程是否被中断
  */
private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this); //挂起当前线程
    return Thread.interrupted(); // 如果当前线程已经被中断了，返回true
}
```
parkAndCheckInterrupt方法首先执行挂起（park）操作，然后返回该线程是否已经被中断。

此时回到acquireQueued(final Node node, int arg)方法，看finally语句块中的cancelAcquire(node)方法，该方法在挂起失败后执行


```java
/**
  * 取消继续获取锁
  */
private void cancelAcquire(Node node) {
    // Ignore if node doesn't exist
    // node为空，返回
    if (node == null)
        return;
    // node节点内的线程置为空
    node.thread = null;

    // Skip cancelled predecessors
    // 该节点的前驱节点
    Node pred = node.prev;
    // 找到pred结点前面最近的一个状态不为CANCELLED的结点
    while (pred.waitStatus > 0)
        node.prev = pred = pred.prev;

    // node结点为尾结点，则利用CAS设置尾结点为pred结点
    if (node == tail && compareAndSetTail(node, pred)) {
        compareAndSetNext(pred, predNext, null);
    } else {// node结点不为尾结点，或者CAS设置不成功
        // If successor needs signal, try to set pred's next-link
        // so it will get one. Otherwise wake it up to propagate.
        int ws;
        // （pred结点不为头结点，并且pred结点的状态为SIGNAL）或者
        //  ws小于0，并且比较并设置等待状态为SIGNAL成功，并且pred结点内的线程不为空
        if (pred != head &&
            ((ws = pred.waitStatus) == Node.SIGNAL ||
             (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
            pred.thread != null) {
            Node next = node.next; // 获取节点的后继节点
            // 如果后继节点不为空 并且后继节点的等待状态小于等于0
            if (next != null && next.waitStatus <= 0)
                compareAndSetNext(pred, predNext, next); // 比较并设置pred.next = next;
        } else {
            unparkSuccessor(node); // 释放节点的后继节点
        }

        node.next = node; // help GC
    }
}
```
在该方法中取消继续获取锁。

在该方法中会调用一个方法unparkSuccessor，该方法的作用就是为了释放node节点的后继结点。

```java
private void unparkSuccessor(Node node) {
    /*
     * If status is negative (i.e., possibly needing signal) try
     * to clear in anticipation of signalling.  It is OK if this
     * fails or if status is changed by waiting thread.
     */
     // 获取节点的状态
    int ws = node.waitStatus;
    if (ws < 0)
        compareAndSetWaitStatus(node, ws, 0); // 利用CAS 将状态设置为0

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
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0) // 如果此时节点的状态小于等于0
                s = t; // 将此节点赋给传入节点的后继节点
    }
    if (s != null)  // 节点不为空，释放
        LockSupport.unpark(s.thread);
}
```

至此，ReentrantLock获取非公平锁的步骤就结束了。

### 公平锁
如果需要使用公平锁，那么在创建ReentrantLock实例的时候需要向其构造函数传入布尔值true，然后在构造方法里利用三元运算创建公平锁的实例

```java
public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
```
#### 公平锁的用法
```java
lock.lock();
```
#### 公平锁加锁的简单步骤：
获取一次state的值
- 如果state为0，查看CLH队列中是否还有其他线程在等待获取锁，如果有，则获取锁失败；如果没有，则利用CAS将state的值由0设置为1，如果成功，设置独占锁的线程为当前线。
- 如果state不为0或者CLH队列中还有其他线程在等待获取锁，查看当前线程是不是已经是独占锁的线程了，如果是，则将当前的锁数量+1；如果不是，则将该线程封装在一个Node内，并加入到等待队列中去。等待被其前一个线程节点唤醒。

此过程严格遵守“先到先得”策略。
#### 公平锁与非公平锁的重要区别是：
非公平锁在要获取锁的时候，首先会尝试直接获取锁，而公平锁则需要判断CLH队列中是否还有其他线程在等待获取锁。

#### 公平锁具体获取流程：

首先调用FairSync静态内部类的lock方法，在这个方法中直接调用AQS的acquire方法
```java
final void lock() {
    acquire(1);
}
```
AQS的acquire方法如下：

```java
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```
然后会调用FairSync的tryAcquire方法

```java
/**
  * 和非公平锁的区别：即使当前锁是空闲的，也要查看CLH队列中是否还有其他线程在等
  * 待获取锁，如果有则获取失败，严格遵守“先到先得”的策略  
  */
protected final boolean tryAcquire(int acquires) {
    // 当前线程
    final Thread current = Thread.currentThread();
    // 获取state
    int c = getState();
    // 判断state的值是否为0
    if (c == 0) {
        // 这一步是判断CLH队列中是否还有其他等待获取锁的线程，如果有返回true，没有则返回false
        // 同时还需要利用CAS将state由0设置为1
        // 如果上述两步都返回true，那么设置独占锁线程为当前线程
        if (!hasQueuedPredecessors() &&
            compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }  // 如果当前state不是0，则判断当前线程是否为独占锁线程
    else if (current == getExclusiveOwnerThread()) {
        // 将state进行+1操作，判断state值后返回
        int nextc = c + acquires;
        if (nextc < 0)
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false; // 获取锁失败，考虑将线程加入等待队列
}
```

在这个方法中，首先获取state的值，判断当前是否可以获取锁
- 如果state为0，说明锁没有被其他线程获取，但由于是公平锁，那么需要判断CLH队列中是否还有其他线程在等待获取锁，如果有，那么就获取锁失败了；如果没有，则需要利用CAS将state由0设置为1，这两步都返回true，那么设置独占锁线程为当前线程
- 如果当前state不是0，则判断当前线程是否为独占锁线程，如果是，将state加1，然后返回
- 其他情况返回false，获取锁失败。

判断CLH队列中是否还有其他等待获取锁的线程需要调用CAS的hasQueuedPredecessors方法
```java
/**
 * 判断CLH队列中是否还有其他等待获取锁的线程
 * 如果当前线程之前有一个排队的线程，返回true
 * 如果当前线程在队列的头部或队列为空，返回false
 */
public final boolean hasQueuedPredecessors() {
    // The correctness of this depends on head being initialized
    // before tail and on head.next being accurate if the current
    // thread is first in queue.
    Node t = tail; // Read fields in reverse initialization order
    Node h = head;
    Node s;
    return h != t &&
        ((s = h.next) == null || s.thread != Thread.currentThread());
}
```

接下来的流程和非公平一样。

### 总结：非公平锁与公平锁获取锁对比：

- NonfairSync： 非公平锁在要获取锁的时候，首先会尝试直接获取锁
- FairSync： 而公平锁则需要判断CLH队列中是否还有其他线程在等待获取锁

ReentrantLock是基于AbstractQueuedSynchronizer（AQS）实现的，AQS可以实现独占锁也可以实现共享锁，ReentrantLock只是使用了其中的独占锁模式。

### 参考：
http://www.cnblogs.com/java-zhao/p/5131544.html


## ReentrantLock源码学习 - 释放锁（unlock）
* * *
上次谈到了利用ReentrantLock的非公平和公平加锁方式，那么接下来看看释放锁的流程

首先调用ReentrantLock的unlock方法

```java
public void unlock() {
    sync.release(1);
}

```
然后会调用AbstractQueuedSynchronizer（AQS）的release方法，在这个方法中首先会调用ReentrantLock的Sync的tryRelease方法，来进行尝试释放锁，如果返回true，那么获取CLH队列的头结点，判断头结点不为空并且头结点的状态不为0（None），那么就调用AQS的unparkSuccessor方法。

```java
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

在tryRelease方法里，首先让当前的state与传入的值（这里为1）进行相减，然后得到c，判断当前线程是不是获取独占锁的线程，如果不是，直接抛出异常；如果是，那么需要判断c是否为0，因为只有c为0时，才符合释放独占锁的条件，这是设置独占锁线程为null，最后设置下state的值（注意这里c为0不为0都会设置）

```java
protected final boolean tryRelease(int releases) {
    int c = getState() - releases;
    if (Thread.currentThread() != getExclusiveOwnerThread())
        throw new IllegalMonitorStateException();
    boolean free = false;
    if (c == 0) {
        free = true;
        setExclusiveOwnerThread(null);
    }
    setState(c);
    return free;
}
```

接下来来看方法unparkSuccessor，该方法的作用就是为了释放node节点的后继结点。

```java
private void unparkSuccessor(Node node) {
    /*
     * If status is negative (i.e., possibly needing signal) try
     * to clear in anticipation of signalling.  It is OK if this
     * fails or if status is changed by waiting thread.
     */
     // 获取节点的状态
    int ws = node.waitStatus;
    if (ws < 0)
        compareAndSetWaitStatus(node, ws, 0); // 利用CAS 将状态设置为0

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
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0) // 如果此时节点的状态小于等于0
                s = t; // 将此节点赋给传入节点的后继节点
    }
    if (s != null)  // 节点不为空，释放
        LockSupport.unpark(s.thread);
}
```

### 参考：
http://blog.csdn.net/luonanqin/article/details/41871909