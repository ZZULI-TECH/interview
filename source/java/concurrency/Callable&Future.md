# Callable&Future及FutureTask实现分析(JDK11)

## Callable

在Java中我们知道创建一个线程可以继承`Thread`类或者实现`Runnable`接口，JDK1.5之后在`java.util.concurrent`提供了`Callable`接口，该接口设计类似`Runnable`接口，不过`Callable`接口可以返回任务执行的结果，并且在执行任务过程中可能会抛出异常，而`Runnable`却不会。下面是`Callable`接口的定义：

```Java
@FunctionalInterface
public interface Callable<V> {
    /**
     * Computes a result, or throws an exception if unable to do so.
     *
     * @return computed result
     * @throws Exception if unable to compute a result
     */
    V call() throws Exception;
}
```

`Callable`接口中只定义了一个`call() `方法，该方法会返回一个计算结果，类型与传入的泛型一致。既然是接口，那么在哪里用到呢？下面是一个与`FutureTask`结合的例子，代码如下：

```Java
public class CallableTest implements Callable<String> {

    @Override
    public String call() throws Exception {
        return "hello";
    }

    public static void main(String[] args) throws InterruptedException,
        ExecutionException {
        FutureTask<String> future = new FutureTask<>(new CallableTest());
        new Thread(future).start();
        System.out.println(future.get());
    }

}

```

我们可以发现将 `Callable`的实现类传给`FutureTask`，然后利用线程来运行`FutureTask`，最终调用`get()`方法获取计算结果。

## Future

`FutureTask`是一个可取消的异步计算，该类提供了`Future`的基本实现，那么`Future`是怎么回事呢？`Future`接口提供了如下方法：

```Java
public interface Future<V> {
    /**
     * 试图取消此任务的执行。
     */
    boolean cancel(boolean mayInterruptIfRunning);

    /**
     * 如果此任务在正常完成之前被取消，则返回true。
     */
    boolean isCancelled();

    /**
     * 如果任务完成，返回true。完成可能是由于正常终止、异常或取消——在所有这些情况下，该方法将返回true。
     */
    boolean isDone();

    /**
     * 等待计算完成，返回计算结果
     */
    V get() throws InterruptedException, ExecutionException;

    /**
     * 在给定的时间内等待计算完成，然后返回计算结果
     */
    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}

```

`Future`表示异步计算的结果，同时提供了用于检查计算是否完成、等待其完成以及检索计算结果的方法。下面是对这些方面的具体描述：

- `cancel(boolean mayInterruptIfRunning)`：试图取消任务的执行。如果任务已经完成、已被取消或由于其他原因无法取消，则此尝试将失败。如果成功，并且在调用cancel时该任务尚未启动，则该任务永远不会运行。参数mayInterruptIfRunning表示是否允许取消正在执行却没有执行完毕的任务。在此方法返回后，对`isDone`的后续调用将始终返回`true`。如果该方法返回`true`，则对`isCancelled`的后续调用将始终返回`true`。
- `isCancelled` : 如果此任务在正常完成之前被取消，则返回true。
- `isDone`：如果任务完成，返回true。在正常终止、异常或取消情况下导致任务完成，该方法将返回true。
- `get`：等待计算完成，返回计算结果，期间会被阻塞。注意该方法会抛出异常，
   - CancellationException - 如果计算被取消
   - ExecutionException - 如果在计算抛出异常
   - InterruptedException - 如果当前线程在等待时被中断
- `get(long timeout, TimeUnit unit)`：在给定的时间内等待计算完成，然后返回计算结果。注意该方法也会抛出异常：
    - CancellationException - 如果计算被取消
    - ExecutionException - 如果在计算抛出异常
    - InterruptedException - 如果当前线程在等待时被中断
    - TimeoutException - 等待超时

感觉`Future`的API设计的十分简洁明了，定义了对异步计算的常用操作，由于`Future`只是接口，刚才提到的`FutureTask`是JDK提供的一种实现，所以我们需要了解一下`Future`接口的方法是如何实现异步计算并拿到结果的。

## FutureTask
`FutureTask`的类图如下所示，该类实现了`RunnableFuture`
接口，`RunnableFuture`接口继承自`Runnable`和`Future`，所以该类既可以交给Thread去执行，又可以作为`Future`来获取计算结果。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/FutureTask_class.png?raw=true)

### 构造函数及state 

打开`FutureTask`类的源码，我们首先来看看其构造函数的实现：

```Java
public FutureTask(Callable<V> callable) {
    if (callable == null)
        throw new NullPointerException();
    this.callable = callable;
    this.state = NEW;       // ensure visibility of callable
}

public FutureTask(Runnable runnable, V result) {
    this.callable = Executors.callable(runnable, result);
    this.state = NEW;       // ensure visibility of callable
}
```
对于第一个构造函数，传入Callable的实现类，将其赋给FutureTask成员变量`callable`，同时设置state为`NEW`，state字段用来保存FutureTask内部的任务执行状态，一共有7中状态，每种状态及其对应的值如下：

```Java
private volatile int state;
private static final int NEW          = 0;
private static final int COMPLETING   = 1;
private static final int NORMAL       = 2;
private static final int EXCEPTIONAL  = 3;
private static final int CANCELLED    = 4;
private static final int INTERRUPTING = 5;
private static final int INTERRUPTED  = 6;
```
注意state是用`volatile`修饰，保证其在线程之间的可见性。在源码注释中，我们可以发现state所代表状态转换如下：

```Java
NEW -> COMPLETING -> NORMAL
NEW -> COMPLETING -> EXCEPTIONAL
NEW -> CANCELLED
NEW -> INTERRUPTING -> INTERRUPTED
```
用图表示如下：
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/FutureTask_state_transitions.png?raw=true)

从图中仿佛可以看出该类通过改变state的状态来反映最后计算的结果。

### run 

在创建了一个FutureTask实例之后，接下来就是在另一个线程中执行此Task，无论是直接创建Thead还是通过线程池，执行的都是`run()`方法，该方法代码如下：

```Java
public void run() {
    if (state != NEW ||
        !RUNNER.compareAndSet(this, null, Thread.currentThread()))
        return;
    try {
        Callable<V> c = callable;
        if (c != null && state == NEW) {
            V result;
            boolean ran;
            try {
                result = c.call();
                ran = true;
            } catch (Throwable ex) {
                result = null;
                ran = false;
                setException(ex);
            }
            if (ran)
                set(result);
        }
    } finally {
        // runner must be non-null until state is settled to
        // prevent concurrent calls to run()
        runner = null;
        // state must be re-read after nulling runner to prevent
        // leaked interrupts
        int s = state;
        if (s >= INTERRUPTING)
            handlePossibleCancellationInterrupt(s);
    }
}
```

在run方法中，首先会判断state是否等于`NEW`，如果不等于`NEW`，说明此任务已经被执行过，或者由于其他原因被取消了，直接返回；

接下来会利用CAS将该类`volatile`修饰的`runner`成员变量设置为当前线程，注意在设置之前`runner`必须为null，设置失败也直接返回。由于我看的版本是JDK11，所以这里的CAS操作用的是JDK9引入的`VarHandle`(方法句柄)，用来代替`UnSafe`类，详情参考：[用Variable Handles来替换Unsafe](http://mingshan.me/2018/10/05/%E7%94%A8Variable%20Handles%E6%9D%A5%E6%9B%BF%E6%8D%A2Unsafe/)，在FutureTask类中实现代码如下：

```Java
// VarHandle mechanics
private static final VarHandle STATE;
private static final VarHandle RUNNER;
private static final VarHandle WAITERS;
static {
    try {
        MethodHandles.Lookup l = MethodHandles.lookup();
        STATE = l.findVarHandle(FutureTask.class, "state", int.class);
        RUNNER = l.findVarHandle(FutureTask.class, "runner", Thread.class);
        WAITERS = l.findVarHandle(FutureTask.class, "waiters", WaitNode.class);
    } catch (ReflectiveOperationException e) {
        throw new ExceptionInInitializerError(e);
    }

    // Reduce the risk of rare disastrous classloading in first call to
    // LockSupport.park: https://bugs.openjdk.java.net/browse/JDK-8074773
    Class<?> ensureLoaded = LockSupport.class;
}

```

检测过`state`和`runner`后，接着会调用传入的callable的`call()`方法，执行任务。如果抛出异常，将结果设置为`null`，调用`setException()`方法保存异常信息，下面是代码：

```Java
protected void setException(Throwable t) {
    if (STATE.compareAndSet(this, NEW, COMPLETING)) {
        outcome = t;
        STATE.setRelease(this, EXCEPTIONAL); // final state
        finishCompletion();
    }
}
```

在`setException`方法中，有以下流程：
- 利用CAS操作将state状态由`NEW`改为`COMPLETING`，如果操作成功；
- 把异常原因保存在`outcome`字段中，`outcome`字段用来保存任务执行结果或者异常原因；
- 利用CAS把当前任务状态从`COMPLETING`变更为`EXCEPTIONAL`，可以参考上面转换的图；
- 调用`finishCompletion()`通知和移除等待线程


如果没发生异常，任务执行结束，调用`set(result)`方法设置计算结果，代码如下：

```Java
protected void set(V v) {
    if (STATE.compareAndSet(this, NEW, COMPLETING)) {
        outcome = v;
        STATE.setRelease(this, NORMAL); // final state
        finishCompletion();
    }
}
```

我们发现`set()`方法实现流程和`setException()`真像，只不过是state状态变化的差异，流程如下：

- 利用CAS操作将state状态由`NEW`改为`COMPLETING`，如果操作成功；
- 把计算结果保存在outcome字段中，outcome字段用来保存任务执行结果或者异常原因；
- 利用CAS把当前任务状态从`COMPLETING`变更为`NORMAL`，可以参考上面转换的图；
- 调用`finishCompletion()`通知和移除等待线程


计算完后，无论是否发生异常，都要执行finally语句块的方法，首先将runner设置为`null`，释放值等待gc回收，同时判断state的状态是否为`INTERRUPTING`，如果任务被中断，执行中断处理。

看完了run方法的实现，总结来说，利用CAS根据任务的执行情况更改state的值，其他方法再根据state的值做出相应的处理。


### get

由于FutureTask是Future的一个实现，所以它提供了获取计算结果的`get()`方法，代码如下：

```Java
/**
 * @throws CancellationException {@inheritDoc}
 */
public V get() throws InterruptedException, ExecutionException {
    int s = state;
    /**
     * state小于等于COMPLETING，表示计算任务还未完成，
     * 所以调用awaitDone方法，让当前线程等待
     */
    if (s <= COMPLETING)
        s = awaitDone(false, 0L);
    // 返回计算结果或抛出异常
    return report(s);
}
```

FutureTask运行在一个线程里来执行计算任务，由于Future设计的是异步计算模式，那么当然应该考虑其他线程获取计算的结果，从get方法看到，如果state的值如果小于等于`COMPLETING`，说明计算任务还没完成，那么获取计算结果的线程必须等待，也就是被阻塞，具体的实现在`awaitDone`方法里，该方法有两个参数，第一个参数为是否有超时限制timed，第二个为等待时间nanos，代码如下：

```Java
private int awaitDone(boolean timed, long nanos)
    throws InterruptedException {
    // The code below is very delicate, to achieve these goals:
    // - call nanoTime exactly once for each call to park
    // - if nanos <= 0L, return promptly without allocation or nanoTime
    // - if nanos == Long.MIN_VALUE, don't underflow
    // - if nanos == Long.MAX_VALUE, and nanoTime is non-monotonic
    //   and we suffer a spurious wakeup, we will do no worse than
    //   to park-spin for a while
    long startTime = 0L;    // Special value 0L means not yet parked
    WaitNode q = null;
    boolean queued = false;
    for (;;) {
        int s = state;
        // 计算已完成，直接返回
        if (s > COMPLETING) {
            if (q != null)
                q.thread = null;
            return s;
        }// 正在计算，让出时间片等待计算完成
        else if (s == COMPLETING)
            // We may have already promised (via isDone) that we are done
            // so never return empty-handed or throw InterruptedException
            Thread.yield();
        else if (Thread.interrupted()) {
            //  当前线程被中断（中断标志位为true），
            //  那么从列表中移除节点q，并抛出InterruptedException异常
            removeWaiter(q);
            throw new InterruptedException();
        } // 判断当前线程包装的等待节点是否为空
        else if (q == null) {
            // 如果设置等待，但等待时间为0，直接返回
            if (timed && nanos <= 0L)
                return s;
            // 新建等待节点
            q = new WaitNode();
        }// 判断是否入队
        else if (!queued)
            //未入队时，使用CAS将新节点添加到链表中，如果添加失败，那么queued为false
            queued = WAITERS.weakCompareAndSet(this, q.next = waiters, q);
        // 判断是否设置超时
        else if (timed) {
            final long parkNanos;
            // 第一次执行，初始化 startTime
            if (startTime == 0L) { // first time
                startTime = System.nanoTime();
                if (startTime == 0L)
                    startTime = 1L;
                parkNanos = nanos;
            } else {
                // 计算当前已用时间
                long elapsed = System.nanoTime() - startTime;
                // 如果当前已用时间大于设置的超时时间，移除队列中的结点，直接返回
                if (elapsed >= nanos) {
                    removeWaiter(q);
                    return state;
                }
                // 计算剩余时间
                parkNanos = nanos - elapsed;
            }
            // nanoTime may be slow; recheck before parking
            // 挂起当前线程，让当前线程等待nanos时间
            if (state < COMPLETING)
                LockSupport.parkNanos(this, parkNanos);
        }
        else // 未设置等待时间，那就等着吧
            LockSupport.park(this);
    }
}
```

在FutureTask类中有一个成员变量`waiters`，声明如下：

```Java
/** Treiber stack of waiting threads */
private volatile WaitNode waiters;
```

`WaitNode`是一个静态内部类，数据结构为单链表，用来记录等待的线程，代码如下：

```Java
/**
 * Simple linked list nodes to record waiting threads in a Treiber
 * stack.  See other classes such as Phaser and SynchronousQueue
 * for more detailed explanation.
 */
static final class WaitNode {
    volatile Thread thread;
    volatile WaitNode next;
    WaitNode() { thread = Thread.currentThread(); }
}
```


从上面的代码来看，在`awaitDone`方法内部存在着一个死循环，死循环内部流程如下：

1. 首先判断state的值，
    - 如果值大于`COMPLETING`，代表计算已完成（包括抛出异常等），直接返回；
    - 如果值等于`COMPLETING`，代表正在执行计算，调用`Thread.yield()`让出时间片等待计算完成
2. 如果当前线程被中断（中断标志位为true），那么从列表中移除节点q，并抛出`InterruptedException`；
3. 如果当前线程包装的等待节点为空，判断是否设置等待，并且等待时间为0，直接返回，否则创建等待节点；
4. 如果没有入队，使用CAS将新节点添加到链表中，如果添加失败，那么queued为false
5. 如果设置超时，判断当前计算任务是否在超时时间内，
    - 如果不在，移除队列中的结点，直接返回
    - 如果在，计算剩余时间，挂起当前线程，让当前线程等待剩下的时间
6. 未设置等待时间，直接进行线程挂起操作，线程状态变为等待。

当线程被解除挂起，或计算已经完成后，在`get`方法中将会调用`report`方法返回结果，其实现如下：

```Java
/**
 * Returns result or throws exception for completed task.
 *
 * @param s completed state value
 */
@SuppressWarnings("unchecked")
private V report(int s) throws ExecutionException {
    Object x = outcome;
    if (s == NORMAL)
        return (V)x;
    if (s >= CANCELLED)
        throw new CancellationException();
    throw new ExecutionException((Throwable)x);
}
```

1. 如果state等于`NORMAL`，代表计算正常结束，返回结果；
2. 如果state等于`CANCELLED`，代表计算被取消，抛出`CancellationException`；
3. 如果计算以异常结束，即状态是`EXCEPTIONAL`，那么抛出`ExecutionException`。

### finishCompletion

在`run`方法中调用`set`和`setException`时最后一步是执行`finishCompletion`方法，那么这个方法是来干什么的呢？我们来看看它的实现吧：

```Java
/**
 * Removes and signals all waiting threads, invokes done(), and
 * nulls out callable.
 */
private void finishCompletion() {
    // assert state > COMPLETING;
    for (WaitNode q; (q = waiters) != null;) {
        if (WAITERS.weakCompareAndSet(this, q, null)) {
            for (;;) {
                Thread t = q.thread;
                if (t != null) {
                    q.thread = null;
                    LockSupport.unpark(t);
                }
                WaitNode next = q.next;
                if (next == null)
                    break;
                q.next = null; // unlink to help gc
                q = next;
            }
            break;
        }
    }

    done();

    callable = null;        // to reduce footprint
}
```

刚才我们看`get`方法的实现时，发现有一个`WaitNode`的单链表结构，里面存储着等待着的线程，所以在计算完成时，需要唤醒那些还在等待着的线程，毕竟计算任务都做完了（异常也算结束），总不能让那些阻塞的线程干等着吧，所以在`finishCompletion`方法中就遍历单链表，利用CAS将FutureTask中的waiters设置为`null`，调用`LockSupport.unpark`唤醒线程，当线程被释放后，那么在awaitDone的死循环中就会进入下一个循环，由于状态已经变成了`NORMAL`或者`EXCEPTIONAL`，将会直接跳出循环。

当所有等待线程都唤醒后，直接调用`done`方法，`done`方法是个`protected`修饰的方法，FutureTask没有做相关实现，所以如果在计算完成后需要特殊处理，子类可以重写`done`方法。

### cancel

从Future接口的描述来看，它提供了`cancel`方法来取消正在执行的任务，FutureTask实现了`cancel`方法，我们来看看它的代码吧：

```Java
public boolean cancel(boolean mayInterruptIfRunning) {
    if (!(state == NEW && STATE.compareAndSet
          (this, NEW, mayInterruptIfRunning ? INTERRUPTING : CANCELLED)))
        return false;
    try {    // in case call to interrupt throws exception
        if (mayInterruptIfRunning) {
            try {
                Thread t = runner;
                if (t != null)
                    t.interrupt();
            } finally { // final state
                STATE.setRelease(this, INTERRUPTED);
            }
        }
    } finally {
        finishCompletion();
    }
    return true;
}
```

参数`mayInterruptIfRunning`指明是否应该中断正在运行的任务，
- 如果参数为false，代表不需要中断，那么state的转换过程由`NEW->CANCELLED`
- 如果参数为true，代表需要中断，那么state的转换过程将为`NEW->INTERRPUTING->INTERRUPTED`，并给当前线程设中断标志。

无论是否中断，最终都会调用`finishCompletion()`方法来释放等待线程。

参考：

- [Callable DOC](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/concurrent/Callable.html)
- [深入学习 FutureTask](http://www.importnew.com/25286.html)
