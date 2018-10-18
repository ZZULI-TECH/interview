熟悉Java Stream API的同学可能知道可以利用`parallelStream`来实现并行操作，而Stream的并行操作依赖JDK1.7引入的Fork/Join框架，提供实现并行编程的一种方案。下面是Doug Lea对并行编程的描述：

```
(recursively) splitting them into subtasks that are solved in
parallel, waiting for them to complete, and then composing
results. 
```

Fork/Join框架的主要设计思想是采用了类似分治算法（ divide−
and−conquer algorithms），将任务分割成许多小任务并行执行，最后合并计算结果，这比串行化执行效率提高不少。伪代码如下所示：

```Java
Result solve(Problem problem) {
 if (problem is small)
 directly solve problem
 else {
 split problem into independent parts
 fork new subtasks to solve each part
 join all subtasks
 compose result from subresults
 }
}
```

这里涉及到两个词，fork和join，在Doug Lea的论文中，有以下描述：

Fork：开启一个新的子任务进行计算
> The fork operation starts a new parallel fork/join subtask. 

Join: 导致当前任务等待直至被fork的线程计算完成
> The join operation causes the current task not to proceed until the
forked subtask has completed.

从fork/join的描述来看，就是利用递归不断的划分子任务，直至任务被划分的足够小，直接串行执行足够简单，没有问题。

## 测试和性能对比

我们通过计算1 ~ 100000000相加求和问题，来模拟fork/join并行执行，并通过与串行化for循环执行，利用线程池多线程并发执行 的时间对比，来推测fork/join的计算效率。

### FOR串行

先考虑最简单的情况，直接利用for循环执行上面的计算任务，这是在单线程情况下来执行的，也就是串行执行，代码如下：

```Java
public class ForLoopCalculatorImpl implements Calculator {

    @Override
    public long sum(long[] numbers) {
        long result = 0L;
        for (int i = 0; i < numbers.length; i++) {
            result += numbers[i];
        }
        return result;
    }
}
```

这段代码相当简单，无需多言。

### 线程池并发

For循环执行时利用单线程来执行的，当计算任务较大时，我们可能会考虑使用多线程来处理计算任务，并且计算过程是异步的。首先考虑CPU核心数，将任务分割成与CPU核心数一样数量的子任务，避免CPU时间片的过度切换引起资源浪费。获取CPU核心数和初始化线程池的代码如下：

```Java
private static final int parallism = Runtime.getRuntime().availableProcessors();
private ExecutorService pool;

public ExecutorServiceCalculatorImpl() {
    int corePoolSize = Math.max(2, Math.min(parallism - 1, 4));
    int maximumPoolSize = parallism * 2 + 1;
    int keepAliveTime = 30;
    System.out.println(String.format("corePoolSize = %s, maximumPoolSize = %s", corePoolSize, maximumPoolSize));
    BlockingQueue<Runnable> workQueue = new LinkedBlockingDeque<>();
    // 线程的创建工厂
    ThreadFactory threadFactory = new ThreadFactory() {
        private final AtomicInteger mCount = new AtomicInteger(1);

        @Override
        public Thread newThread(Runnable r) {
            return new Thread(r, "AdvacnedAsyncTask #" + mCount.getAndIncrement());
        }
    };

    // 线程池任务满载后采取的任务拒绝策略
    RejectedExecutionHandler rejectHandler = new ThreadPoolExecutor.DiscardOldestPolicy();

    pool = new ThreadPoolExecutor(corePoolSize,
            maximumPoolSize,
            keepAliveTime,
            TimeUnit.SECONDS,
            workQueue,
            threadFactory,
            rejectHandler);
}
```

上面的代码是使用ThreadPoolExecutor来创建线程池的，这样会更加了解线程池使用的各种细节。

接下来我们就需要使用线程池，根据CPU核心数来划分一定数量的子任务，然后将这些子任务交给线程池里面的线程去执行。此时注意任务的划分不一定是均匀的，因为最后一份任务可能比其他的多或者少，需要特别处理一下，代码如下：

```Java
@Override
public long sum(long[] numbers) {
    List<Future<Long>> futures = new ArrayList<>();

    // 把任务分解为 n 份，交给 n 个线程处理，
    // 此时由于int类型丢失精度
    int part = numbers.length / parallism;
    for (int i = 0; i < parallism; i++) {
        // 进行任务分配
        int from = i * part;
        // 最后一份任务可能不均匀，直接分配给最后一个线程
        int to = (i == parallism - 1) ? numbers.length - 1 : (i + 1) * part - 1;
        // 提交计算任务
        futures.add(pool.submit(new SumTask(numbers, from, to)));
    }

    // 把每个线程的结果相加，得到最终结果
    long total = 0L;
    for (Future<Long> future : futures) {
        try {
            total += future.get();
        } catch (Exception ignore) {}
    }
    pool.shutdown();
    return total;
}
```

上面代码中涉及到一个计算任务`SumTask`，抽象出来用来计算从`from` 到 `to` 之间的数相加之和，代码如下：

```Java
private static class SumTask implements Callable<Long> {
    private long[] numbers;
    private int from;
    private int to;

    public SumTask(long[] numbers, int from, int to) {
        this.numbers = numbers;
        this.from = from;
        this.to = to;
    }

    @Override
    public Long call() throws Exception {
        long total = 0;
        for (int i = from; i <= to; i++) {
            total += numbers[i];
        }
        return total;
    }
}
```

看过上面的代码，我们主要是利用了线程池来并发来执行计算任务，同时利用了线程池异步的特性，从设计上来说比for循环串行执行要好，但由于涉及到CPU的时间片切换，执行耗时上可能会比串行执行要高。

### Fokr/Join

写完线程池并发执行计算任务，如果让我们来设计并行执行任务的框架，可能会想到用线程池来做，既然Doug Lea写出了Fork/Join框架，肯定不是利用我们现在的方式来做，那么他是如何实现的呢？

Fork/Join框架抽象出了`ForkJoinTask`来代表要执行的计算任务，该类实现了`Future`接口，比`Thread`更加轻量级。不过我们通常不需要直接继承该类，Fork/Join框架给我们提供了两个抽象类供我们继承：

- `RecursiveTask` ：代表有返回值的计算任务 
- `RecursiveAction`：代表没有返回值的任务

我们的计算任务有返回值，所以我们直接继承`RecursiveTask`就好了，代码如下：

```Java
public class SumTask extends RecursiveTask<Long> {
    public static final int THRESHOLD = 2000000;
    private long[] numbers;
    private int start;
    private int end;

    public SumTask(long[] numbers, int start, int end) {
        this.numbers = numbers;
        this.start = start;
        this.end = end;
    }

    @Override
    protected Long compute() {

        // 判断问题规模
        if ((end - start) <= THRESHOLD) {
            long result = 0L;
            for (int i = start; i <= end; i++) {
                result += numbers[i];
            }
            return result;
        }

        // 将任务分割为多个小任务
        int middle = (start + end) / 2;
        SumTask taskLeft = new SumTask(numbers, start, middle);
        SumTask taskRight = new SumTask(numbers, middle + 1, end);
        invokeAll(taskLeft, taskRight);
        long result = taskLeft.join() + taskRight.join();

        return result;
    }
}
```

我们需要重写`RecursiveTask`类的`compute()`方法，在该方法中进行任务的分割操作。和开始我们见到的伪代码类似，先判断任务规模（其实也是递归终止条件），相当于一个阈值，任务规模小于这个阈值，直接进行计算；大于这个阈值，将任务一份为二，这样递归下去，直至任务不可再分。注意这里我们采用`invokeAll`来进行任务分割，不过很多网上的例子采用的是如下写法：

```
// 分别对子任务调用fork():
subTask1.fork();
subTask2.fork();
```

在JDK官方例子中，这种写法是没有出现过的，也是不正确的，原因后面再分析。

Fork/Join框架提供了`ForkJoinPool`来执行我们分割好的任务，`pool.invoke(task)`来提交一个Fork/Join任务并发执行，然后获得异步执行的结果。代码如下：

```Java
public class ForkJoinCalculatorImpl implements Calculator {
    private ForkJoinPool pool;

    @Override
    public long sum(long[] source) {
        pool = new ForkJoinPool();
        SumTask task = new SumTask(source, 0, source.length - 1);
        return pool.invoke(task);
    }
}
```

在利用Fork/Join计算任务时，可能会出现`StackOverflowError`，这是由于递归层数太深，导致超出JDK的设置，需要重新评估任务分割的程度或者调整大小。

如果任务分割不正确，还会抛出以下异常，需要关注：

```
java.lang.NoClassDefFoundError: Could not initialize class java.util.concurrent.locks.AbstractQueuedSynchronizer$Node
```

### 计算耗时

上面三种计算方式究竟计算效率怎么样呢？我们来写个测试类测试一把，代码如下：


```
long[] numbers = LongStream.rangeClosed(1L, 100000000L).toArray();

// 1 直接for循环
Calculator calculator = new ForLoopCalculatorImpl();
long currentTime1 = System.currentTimeMillis();
long result1 = calculator.sum(numbers);
long executedTime = System.currentTimeMillis() - currentTime1;
System.out.println("直接循环计算结果：" + result1 + ", 耗时：" + executedTime);

// 2 利用线程池
Calculator calculator2 = new ExecutorServiceCalculatorImpl();
long currentTime2 = System.currentTimeMillis();
long result2 = calculator2.sum(numbers);
long executedTime2 = System.currentTimeMillis() - currentTime2;
System.out.println("线程池计算结果：" + result2 + ", 耗时：" + executedTime2);

// 3 fork/join
Calculator calculator3 = new ForkJoinCalculatorImpl();
long currentTime3 = System.currentTimeMillis();
long result3 = calculator3.sum(numbers);
long executedTime3 = System.currentTimeMillis() - currentTime3;
System.out.println("Fork/Join计算结果：" + result3 + ", 耗时：" + executedTime3);
```

计算结果如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/concurrency/fj_calculator_result.png?raw=true)

我用的是Window10操作系统，CPU i5 7代、4核心，跑的时候CPU飙到了100%，由于是计算密集型任务，需要CPU的全力参与，也无可厚非。。如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/concurrency/fj_cpu.png?raw=true)


从上面的计算结果来看，Fork/Join耗时最少，线程池次之，直接For循环是耗时最多的，简直是难以置信啊，不过这个结果可能不稳定，至少也说明了Fork/Join在某些场景下比较优秀的事实。

## 原理分析

(暂无)

参考：

- [A Java Fork/Join Framework](http://gee.cs.oswego.edu/dl/papers/fj.pdf)
- [分解和合并：Java 也擅长轻松的并行编程！](https://www.oracle.com/technetwork/cn/articles/java/fork-join-422606-zhs.html)
- [Fork/Join tutorial](https://docs.oracle.com/javase/tutorial/essential/concurrency/forkjoin.html)
- [jdk1.8-ForkJoin框架剖析](https://www.jianshu.com/p/f777abb7b251)
- [Java 并发编程笔记：如何使用 ForkJoinPool 以及原理](http://blog.dyngr.com/blog/2016/09/15/java-forkjoinpool-internals/)
