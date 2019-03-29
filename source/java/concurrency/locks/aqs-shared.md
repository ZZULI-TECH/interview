上篇文章[AQS源码分析-独占模式](https://mingshan.fun/2019/01/25/aqs-exclusive/)分析了AQS的结构以及独占模式下资源的获取与释放流程，啰嗦了AQS的基本结构和独占模式。这篇文章主要是探讨下AQS在共享模式下资源的获取与释放，同时比较下两种模式的差异（**本文基于JDK11版本**）。

<!-- more -->

## 流程分析 - 获取资源
这篇文章以CountDownLatch为例，和独占模式一样，AQS同样提供了资源的获取与释放的方法供子类进行重写，如下所示：

```Java
protected int tryAcquireShared(int arg)
protected boolean tryReleaseShared(int arg)
```

[CountDownLatch](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/concurrent/CountDownLatch.html)的官方描述如下：

> A synchronization aid that allows one or more threads to wait until a set of operations being performed in other threads completes.

简单来说，CountDownLatch是一个同步器，用来使一个或者多个线程等待其他线程完成各自的工作后再执行。是不是像一个计数器？本来就是一个计数器，只不过支持并发操作。

注意CountDownLatch提供构造函数用来初始化需要等待的线程数量，其实就是设置AQS中state的具体值，如下：

```Java
public CountDownLatch(int count) {
    if (count < 0) throw new IllegalArgumentException("count < 0");
    this.sync = new Sync(count);
}

Sync(int count) {
    setState(count);
}
```

### AQS#acquireSharedInterruptibly

CountDownLatch提供了await方法用来阻塞当前线程直到CountDownLatch内部计数为0。所以我们先从await方法开始：

```Java
public void await() throws InterruptedException {
    sync.acquireSharedInterruptibly(1);
}
```

`acquireSharedInterruptibly(1)`方法是AQS类中的，源码如下：

```
public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    if (tryAcquireShared(arg) < 0)
        doAcquireSharedInterruptibly(arg);
}
```

从acquireSharedInterruptibly方法的实现中可以看出，该方法响应中断，如果当前线程被中断，抛出中断异常。然后调用`tryAcquireShared(arg)`方法，注意该方法的返回值是一个整数，这个限定了返回值的语义，如果小于0，证明获取共享资源失败，需要进入阻塞队列。我们来看看CountDownLatch提供的tryAcquireShared实现：

```Java
protected int tryAcquireShared(int acquires) {
    return (getState() == 0) ? 1 : -1;
}
```

从上面的方法中可以看出，调用了getState方法获取state的值，如果值为0，返回1，代表获取共享资源成功；否则返回-1，代表获取共享资源失败。

总结来说，子类在tryAcquireShared的实现上需要注意以下几点：

1. 检查当前是否支持在共享模式下获取资源
2. 返回值语义
   1. 如果返回值小于0，说明获取资源失败，需要进入阻塞队列
   2. 返回值等于0，说明获取资源成功，但后续的节点携带的线程无法唤醒，无法继续获取资源
   3. 返回值大于0，说明获取资源成功，但会唤醒后续节点然后尝试获取资源


### AQS#doAcquireSharedInterruptibly

我们回到AQS的acquireSharedInterruptibly方法，当tryAcquireShared返回值小于0，就会执行`doAcquireSharedInterruptibly(1)`方法，代码如下：

```Java
/**
 * Acquires in shared interruptible mode.
 * @param arg the acquire argument
 */
private void doAcquireSharedInterruptibly(int arg)
    throws InterruptedException {
    final Node node = addWaiter(Node.SHARED);
    try {
        for (;;) {
            final Node p = node.predecessor();
            if (p == head) {
                int r = tryAcquireShared(arg);
                if (r >= 0) {
                    setHeadAndPropagate(node, r);
                    p.next = null; // help GC
                    return;
                }
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                throw new InterruptedException();
        }
    } catch (Throwable t) {
        cancelAcquire(node);
        throw t;
    }
}
```

在doAcquireSharedInterruptibly方法中，首先会调用`addWaiter(Node.SHARED)`方法，该方法在[AQS源码分析-独占模式#AQS#addWaiter方法](https://mingshan.fun/2019/01/25/aqs-exclusive/#AQS-addWaiter%E6%96%B9%E6%B3%95)已经说过，主要作用是初始化CLH队列或将新创建的节点（携带当前线程）成功入队至队尾，最后返回该新建的节点。只不过此时的参数是Node.SHARED，代表共享模式。

接着就是一个无限for循环（这个非常常见），在循环体内，首先获取当前节点的前驱节点p，如果p为头结点，说明当前节点为阻塞队列第一个持有线程的节点，那么就调用tryAcquireShared(1)直接尝试获取资源，因为前面已经没有持有线程的节点了。如果返回值大于等于0，说明此时state的值已为0，获取资源成功了，接下来调用`setHeadAndPropagate(node, r)`方法，代码如下：

### AQS#setHeadAndPropagate

```Java
/**
 * Sets head of queue, and checks if successor may be waiting
 * in shared mode, if so propagating if either propagate > 0 or
 * PROPAGATE status was set.
 *
 * @param node the node
 * @param propagate the return value from a tryAcquireShared
 */
private void setHeadAndPropagate(Node node, int propagate) {
    Node h = head; // Record old head for check below
    setHead(node);
    /*
     * Try to signal next queued node if:
     *   Propagation was indicated by caller,
     *     or was recorded (as h.waitStatus either before
     *     or after setHead) by a previous operation
     *     (note: this uses sign-check of waitStatus because
     *      PROPAGATE status may transition to SIGNAL.)
     * and
     *   The next node is waiting in shared mode,
     *     or we don't know, because it appears null
     *
     * The conservatism in both of these checks may cause
     * unnecessary wake-ups, but only when there are multiple
     * racing acquires/releases, so most need signals now or soon
     * anyway.
     */
    if (propagate > 0 || h == null || h.waitStatus < 0 ||
        (h = head) == null || h.waitStatus < 0) {
        Node s = node.next;
        if (s == null || s.isShared())
            doReleaseShared();
    }
}
```

setHeadAndPropagate方法有两个参数，第一个参数node为已经成功获取资源的节点，第二个参数propagate为tryAcquireShared方法的返回值，注意此时进入该方法时propagate的值大于或者等于0。

首先会记录原来CLH队列旧的头结点，然后调用`setHead(node)`方法设置头结点，这个方法如下：

```Java
private void setHead(Node node) {
    head = node;
    node.thread = null;
    node.prev = null;
}
```

接下来有一个if判断，貌似很长的样子，我们来具体分析一下：

首先`propagate > 0`代表当前线程已经获取到了资源，并且需要唤醒后面阻塞的节点；`h.waitStatus < 0` 代表旧的头节点后面的节点可以被唤醒；`(h = head) == null || h.waitStatus < 0` 这个操作是说新的头节点后面的节点可以被唤醒，总结来说：

1. `propagate > 0`代表当前线程已经获取到了资源，并且需要唤醒后面阻塞的节点
2. 无论新旧头节点，只要其`waitStatus < 0`，那么其后面的节点可以被唤醒

如果上面if返回true，接着获取当前节点的后继节点，这里又会有一个判断，如果后继节点是共享模式或者现在还看不到后继的状态，则都继续唤醒后继节点中的线程。上面if返回true，接着执行doReleaseShared方法，代码如下：

### AQS#doReleaseShared

```Java
/**
 * Release action for shared mode -- signals successor and ensures
 * propagation. (Note: For exclusive mode, release just amounts
 * to calling unparkSuccessor of head if it needs signal.)
 */
private void doReleaseShared() {
    /*
     * Ensure that a release propagates, even if there are other
     * in-progress acquires/releases.  This proceeds in the usual
     * way of trying to unparkSuccessor of head if it needs
     * signal. But if it does not, status is set to PROPAGATE to
     * ensure that upon release, propagation continues.
     * Additionally, we must loop in case a new node is added
     * while we are doing this. Also, unlike other uses of
     * unparkSuccessor, we need to know if CAS to reset status
     * fails, if so rechecking.
     */
    for (;;) {
        // 获取CLH队列头节点
        Node h = head;
        // 判断头节点是否为null，h == tail 代表CLH刚进行初始化，CLH队列中并未有携带线程的节点
        if (h != null && h != tail) {
            int ws = h.waitStatus;
            // 判断头节点的waitStatus是否为SIGNAL，
            // 如果为SIGNAL，该值必为其后继节点设置的，说明后继节点等待被唤醒
            if (ws == Node.SIGNAL) {
                // CAS 将头节点的waitStatus由SIGNAL设置为0, 相当于重置
                // 这个进行CAS主要是考虑release时也会调用该方法，需要并发控制
                if (!h.compareAndSetWaitStatus(Node.SIGNAL, 0))
                    continue;            // loop to recheck cases
                // 唤醒后继节点
                unparkSuccessor(h);
            } // 如果后继节点还未设置前驱节点的waitStatus为SIGNAL，代表目前无需唤醒或者不存在。
              // 那么就将头节点的waitStatus设置为PROPAGATE，代表在下次acquireShared时无条件地传播
            else if (ws == 0 &&
                     !h.compareAndSetWaitStatus(0, Node.PROPAGATE))
                continue;                // loop on failed CAS
        }
        // 如果头节点未发生变化，则代表当前尙未有其他线程获取到资源，直接退出。
        // 如果头节点已经发生变化，代表已经有线程获取到资源，
        // 那么就需要重新进入到for循环中，将唤醒传递下去
        if (h == head)                   // loop if head changed
            break;
    }
}
```

doReleaseShared是一个相当重要的方法，注意该方法在获取资源时会被调用，在释放资源时也会被调用。首先内部有一个无限for循环，在循环体内，会获取当前CLH队列的头节点，判断头节点是否为null，并且判断头节点和尾节点是否相等，相等代表CLH刚进行初始化，CLH队列中并未有携带线程的节点。

然后获取头节点的waitStatus，接着**判断waitStatus是否为SIGNAL**：

**如果为SIGNAL**，该值必为其后继节点设置的，说明后继节点等待被唤醒，那么就利用CAS先将头节点的waitStatus设置为0，设置失败，就继续for循环；设置成功的话，就调用unparkSuccessor唤醒其后继节点，该方法已经在[AQS源码分析-独占模式](https://mingshan.fun/2019/01/25/aqs-exclusive/)分析过，这里略过。如果后继节点成功获取资源，会造成head的改变，

**如果不为SIGNAL**，接着会进行判断当前头节点的waitStatus是否为0，如果不为0，进行执行for循环；如果为0，代表已经当前头节点的后继节点已经被唤醒。


我们回到doAcquireSharedInterruptibly方法，当setHeadAndPropagate方法执行完时，将p（头节点）的next置空，然后返回。如果p不为头节点，接下来就会将执行下面这段代码：

```Java
if (shouldParkAfterFailedAcquire(p, node) &&
    parkAndCheckInterrupt())
    throw new InterruptedException();
```

shouldParkAfterFailedAcquire方法在[AQS源码分析-独占模式](https://mingshan.fun/2019/01/25/aqs-exclusive/)已经说过了，该方法的作用是在当前线程获取资源失败后是否挂起当前线程，返回true则代表可以挂起，会执行parkAndCheckInterrupt方法，源码如下：

```Java
private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this);
    return Thread.interrupted();
}
```
parkAndCheckInterrupt方法将当前线程挂起，并返回当前线程是否中断。

## 流程分析 - 释放资源

前面说到，在setHeadAndPropagate会调用doReleaseShared方法来唤醒节点，doReleaseShared方法当然在释放资源时也会被调用。对于CountDownLatch的countDown方法来说，入口是AQS的releaseShared方法，arg的值为1，代码如下：


```Java
public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        doReleaseShared();
        return true;
    }
    return false;
}
```

主要tryReleaseShared方法是AQS的子类实现的，在CountDownLatch中，tryReleaseShared的实现如下：

```Java
protected boolean tryReleaseShared(int releases) {
    // Decrement count; signal when transition to zero
    for (;;) {
        int c = getState();
        if (c == 0)
            return false;
        int nextc = c - 1;
        if (compareAndSetState(c, nextc))
            return nextc == 0;
    }
}
```

发现这是一个自旋操作，在无限循环体内，首先获取state的值c，如果c的值为0，证明无资源可释放，返回false；否则计算`c - 1`的值nextc，然后通过CAS将state的值由c设置为nextc，如果设置成功的话，返回`nextc == 0`的比较结果，即如果`nextc == 0`，返回true，否则返回false；如果设置失败，重新进入到for循环，直至符合上面退出for循环的条件退出 tryReleaseShared 方法。总结来说，只有当state能够设置为0时，tryReleaseShared返回true，其他返回false。

回到AQS的releaseShared方法，如果tryReleaseShared返回true，则调用doReleaseShared方法，这个方法的实现在上面的获取资源也调用了，具体实现说明参考上面部分。

纵观releaseShared方法，我们可以得出结论，在CountDownLatch类中，只有当state为0时，才会调用doReleaseShared方法，唤醒后继节点以及传播唤醒动作。当然，这需要考虑tryReleaseShared的子类具体实现，抽象来说，就是只有tryReleaseShared方法返回true时，才会进行唤醒动作。

## 总结


AQS共享模式获取资源、释放资源流程图如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/juc/aqs_shared.png?raw=true)

## References：

- [Java Concurrency Constructs](http://gee.cs.oswego.edu/dl/cpj/mechanics.html)
- [The java.util.concurrent Synchronizer Framework](http://gee.cs.oswego.edu/dl/papers/aqs.pdf)
- [A Java Fork/Join Framework](http://gee.cs.oswego.edu/dl/papers/fj.pdf)
- [AQS源码分析-独占模式](https://mingshan.fun/2019/01/25/aqs-exclusive/AQS源码分析-独占模式)
- [AQS深入理解与实战----基于JDK1.8](https://www.cnblogs.com/awakedreaming/p/9510021.html)
- [深入浅出java同步器AQS](https://www.jianshu.com/p/d8eeb31bee5c)
