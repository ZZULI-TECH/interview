#  Java虚拟机的监控及诊断工具（命令行篇）

对于普通的开发人员来说，可以阅读帮助文档或者源码来对JDK的设计以及JVM的内存管理获取一定的了解，但对于线上运行的程序，如何对程序进行监控和诊断呢？比如一个程序挂了，怎么通过分析堆栈信息、GC日志、线程快照等信息来快速定位问题？JDK的大佬早就为我们考虑到这一点，所以在JDK中包含了许多用于监控及诊断的工具，主要分为两类，**命令行工具**和**GUI工具**，这些工具在平时的开发中用到的频率非常高，我们一起来总结了解下。

常用的命令行工具以及作用：

名称 | 主要作用
---|---
jps | JVM Process Status Tool,  列出指定系统内正在运行的虚拟机进程
jstat | JVM Statistics Monitoring Tool，允许用户查看目标 Java 进程的类加载、即时编译以及垃圾回收相关信息。常用来检测垃圾回收及内存泄露问题。
jinfo | 打印目标 Java 进程的配置参数，并能够改动其中 manageabe 的参数。
jmap | 统计用户统计目标 Java 进程的堆中存放的 Java 对象，生成堆转储快照（heapdump文件）
jstack | 打印目标 Java 进程中各个线程的栈轨迹、线程状态、锁状况等信息，它还将自动检测死锁。
jcmd | 实现前面除了jstat之外所有命令的功能

## jps

jps命令（[帮助文档](https://docs.oracle.com/en/java/javase/11/tools/jps.html#GUID-6EB65B96-F9DD-4356-B825-6146E9EEC81E)）用于列出正在运行的虚拟机进程信息，它的命令格式如下：

```
jps [ -q ] [ -mlvV ][hostid ]
jps [ -help ]
```
在默认情况下，jps的输出信息包括 Java 进程的进程ID以及主类名。jps还提供一些参数用于打印详细的信息。

其中 `-q`仅显示虚拟机的进程id， `-mlvV` 的意义如下：

- `-m` 将打印传递给主类的参数
- `-l` 将打印模块名以及包名
- `-v` 将打印传递给虚拟机的参数
- `-V` 将打印传递给主类的参数、jar文件名等


具体jps示例如下：

```
$ jps -l
11988
48932
32696 org.jetbrains.idea.maven.server.RemoteMavenServer
26140 jdk.jcmd/sun.tools.jps.Jps

```

添加`-mlvV`打印更加详细的信息：

```
$ jps -mlvV
32696 org.jetbrains.idea.maven.server.RemoteMavenServer -Djava.awt.headless=true -Didea.version==2018.2.5 -Xmx768m -Didea.maven.embedder.version=3.5.4 -Dfile.encoding=GBK
26924 jdk.jcmd/sun.tools.jps.Jps -mlvV -Dapplication.home=F:\develope\Java\Java11 -Xms8m -Djdk.module.main=jdk.jcmd

...
```

## jstat

`jstat`（[帮助文档](https://docs.oracle.com/en/java/javase/11/tools/jstat.html#GUID-5F72A7F9-5D5A-4486-8201-E1D1BA8ACCB5)）是用于监视虚拟机各种运行状态信息的命令行工具，它可以显示本地或者远程虚拟机进程中的类装载、内存、垃圾收集等信息，它的命令格式如下：

```
jstat generalOptions
jstat -outputOptions [ -t] [-hlines] vmid [interval [count] ]
```

其中`vmid`全称是Virtual Machine Identifier，就是`jps`命令显示的进程id，如果是远程虚拟机进程，`vmid`的格式如下：

```
[protocol:][//]lvmid[@hostname[:port]/servername]
```

`jstat`命令包含很多的子命令，主要分为3类：
- 类加载（`-class`）
- 即时编译（`-compiler`和`-printcompilation`）
- 垃圾回收（`-gc*`）

输入`jstat -options`显示如下：

```
$ jstat -options
-class
-compiler
-gc
-gccapacity
-gccause
-gcmetacapacity
-gcnew
-gcnewcapacity
-gcold
-gcoldcapacity
-gcutil
-printcompilation
```

参数`interval`和`count`代表查询间隔和次数，如果省略，默认查询一次。

现在我们要查询进程id 为26792的垃圾收集情况，并且是每隔2秒打印一次，共打印2次，命令和输出示例如下：

```
$ jstat -gc 26792 2s 2
 S0C    S1C    S0U    S1U      EC       EU        OC         OU       MC     MU    CCSC   CCSU   YGC     YGCT    FGC    FGCT    CGC    CGCT     GCT
5120.0 5120.0  0.0   5095.1 33280.0  30033.1   87552.0     2573.4   15232.0 14724.4 1920.0 1782.4      3    0.027   1      0.032   -          -    0.059
5120.0 5120.0  0.0   5095.1 33280.0  30033.1   87552.0     2573.4   15232.0 14724.4 1920.0 1782.4      3    0.027   1      0.032   -          -    0.059
```

在上面的示例中，输出了一大堆东西，那么这些是什么意思呢？前面说了，`jstat`有很多的关于垃圾回收的子命令，每个子命令的输出结果也不一样，具体可参考（[帮助文档](https://docs.oracle.com/en/java/javase/11/tools/jstat.html#GUID-5F72A7F9-5D5A-4486-8201-E1D1BA8ACCB5)）。我们知道JVM堆是分代的，前四个 表示Survivor 区的容量（Capacity）和已使用量（Utilization），EC表示当前Eden的容量，剩下的就不说了。

在翻阅文档的时候，发现没有CGC 和 CGCT的解释，它们分别代表并发 GC Stop-The-World 的次数和时间。

`-t` 参数会显示时间戳列作为输出的第一列，它将在每行数据之前打印目标 Java 进程的启动以来的时间，示例如下：

```
$ jstat -gc -t 26792 2s 2
Timestamp        S0C    S1C    S0U    S1U      EC       EU        OC         OU       MC     MU    CCSC   CCSU   YGC     YGCT    FGC    FGCT    CGC    CGCT     GCT
         1949.1 5120.0 5120.0  0.0   5095.1 33280.0  31206.1   87552.0     2573.4   15232.0 14724.4 1920.0 1782.4      3    0.027   1      0.032   -          -   0.059
         1951.1 5120.0 5120.0  0.0   5095.1 33280.0  31206.1   87552.0     2573.4   15232.0 14724.4 1920.0 1782.4      3    0.027   1      0.032   -          -   0.059

```

## jmap

`jmap`命令（[帮助文档](https://docs.oracle.com/en/java/javase/11/tools/jmap.html#GUID-D2340719-82BA-4077-B0F3-2803269B7F41)）用于生成堆转储快照，用于分析Java虚拟机堆中的对象。

它的命令格式为：

```
jmap [options] pid
```

`jmap`命令的参数选项也包括很多种，具体如下：

**1. -clstats**

连接到正在运行的进程并打印Java堆被加载类的统计信息

**2. -finalizerinfo**

连接到正在运行的进程并打印所有待 finalize 的对象。

**3. -histo[:live]**

连接到正在运行的进程并统计各个类的实例数目以及占用内存，并按照内存使用量从多至少的顺序排列。此外，-histo:live只统计堆中还在存活的对象。

**4. -dump**

连接到正在运行的进程并导出Java虚拟机堆内存的快照。该子命令该包含如下参数：

- live  只保存堆中存活的对象
- format=b 将使jmap导出与hprof（在 Java 9 中已被移除）-XX:+HeapDumpAfterFullGC、-XX:+HeapDumpOnOutOfMemoryError格式一样的文件
- file=filename 指定导出堆内存快照的位置

综合以上参数，示例命令如下：

```
jmap -dump:live,format=b,file=heap.bin pid
```

## jinfo

`jinfo`命令（[帮助文档](https://docs.oracle.com/en/java/javase/11/tools/jinfo.html#GUID-69246B58-28C4-477D-B375-278F5F9830A5)）用来实时地查看和调整虚拟机的各项参数。我们可以使用`jps -v`来查看传递给虚拟机的参数，即`System.getProperty`获取的`-D`参数，现在我们可以利用`jinfo`命令来获取了。

它的命令格式如下：

```
jinfo [option] pid
```

它也包括了许多子命令，具体如下：

**1. -flag name**

打印指定的虚拟机参数的名称和值

**2. -flag [+|-]name**

用来修改目标 Java 进程的“manageable”虚拟机参数。其中`+`代表开启，`-`代表关闭。

输入`java -XX:+PrintFlagsFinal -version | grep manageable`来查看“manageable”虚拟机参数，如下：

```
$ java -XX:+PrintFlagsFinal -version | grep manageable
     intx CMSAbortablePrecleanWaitMillis           = 100                                    {manageable} {default}
     intx CMSTriggerInterval                       = -1                                     {manageable} {default}
     intx CMSWaitDuration                          = 2000                                   {manageable} {default}
     bool HeapDumpAfterFullGC                      = false                                  {manageable} {default}
     bool HeapDumpBeforeFullGC                     = false                                  {manageable} {default}
     bool HeapDumpOnOutOfMemoryError               = false                                  {manageable} {default}
    ccstr HeapDumpPath                             =                                        {manageable} {default}
    uintx MaxHeapFreeRatio                         = 70                                     {manageable} {default}
    uintx MinHeapFreeRatio                         = 40                                     {manageable} {default}
     bool PrintClassHistogram                      = false                                  {manageable} {default}
     bool PrintConcurrentLocks                     = false                                  {manageable} {default}
java version "11" 2018-09-25
Java(TM) SE Runtime Environment 18.9 (build 11+28)
Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11+28, mixed mode)
```

**3. -flag name=value**

设置指定的虚拟机参数的值

**4. -flags**

打印全部的虚拟机参数，例如：

```
$ jinfo -flags 26792
VM Flags:
-XX:CICompilerCount=3 -XX:InitialHeapSize=134217728 -XX:MaxHeapSize=805306368 -XX:MaxNewSize=268435456 -XX:MinHeapDeltaBytes=524288 -XX:NewSize=44564480 -XX:OldSize=89653248 -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:-UseLargePagesIndividualAllocation -XX:+UseParallelGC
```

**5. -sysprops**

打印java系统参数（Java System Properties）

## jstack

`jstack`命令（[帮助文档](https://docs.oracle.com/en/java/javase/11/tools/jstack.html#GUID-721096FC-237B-473C-A461-DBBBB79E4F6A)）可以用来打印目标 Java 进程中各个线程的栈轨迹，以及这些线程所持有的锁。通过线程的栈轨迹可以定位线程长时间停顿的原因，如线程间死锁、死循环、请求外部资源导致长时间等待等。

它的命令格式如下：

```
jstack [options] pid
```

它也有子命令：

**-l**

输出关于锁的附加信息，例如属于java.util.concurrent的ownable synchronizers列表


下面是一个示例，如下:

```
$ jstack -l 42680
2018-10-21 23:09:17
Full thread dump OpenJDK 64-Bit Server VM (25.152-b19 mixed mode):

"ApplicationImpl pooled thread 35" #142 daemon prio=4 os_prio=-1 tid=0x0000000018422000 nid=0xafe8 waiting on condition [0x00000000458bf000]
   java.lang.Thread.State: TIMED_WAITING (parking)
        at sun.misc.Unsafe.park(Native Method)
        - parking to wait for  <0x00000000e1506488> (a java.util.concurrent.SynchronousQueue$TransferStack)
        at java.util.concurrent.locks.LockSupport.parkNanos(LockSupport.java:215)
        at java.util.concurrent.SynchronousQueue$TransferStack.awaitFulfill(SynchronousQueue.java:460)
        at java.util.concurrent.SynchronousQueue$TransferStack.transfer(SynchronousQueue.java:362)
        at java.util.concurrent.SynchronousQueue.poll(SynchronousQueue.java:941)
        at java.util.concurrent.ThreadPoolExecutor.getTask(ThreadPoolExecutor.java:1066)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1127)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
        at java.lang.Thread.run(Thread.java:745)

   Locked ownable synchronizers:
        - None
```

在输出的信息中，会包含线程的状态，下面是常见的线程状态：

1. RUNNABLE，线程处于执行中
2. BLOCKED，线程被阻塞
3. WAITING，线程正在等待
4. TIMED_WAITING 超时等待

## jcmd

`jcmd`命令（[帮助文档](https://docs.oracle.com/en/java/javase/11/tools/jcmd.html#GUID-59153599-875E-447D-8D98-0078A5778F05)）可以向运行中的Java虚拟机(JVM)发送诊断命令。

它的命令格式如下：

```
jcmd <pid | main class> <command ... | PerfCounter.print | -f  file>
jcmd -l
jcmd -h
```
**pid**

虚拟机的进程id

**main class**

接收诊断命令请求的进程的main类。

**command**

该命令必须是针对所选JVM的有效jcmd命令。jcmd的可用命令列表是通过运行help命令(jcmd pid help)获得的，其中pid是运行Java进程的进程ID。如果pid为0，命令将被发送到所有的Java进程。main class参数将用于部分或完全匹配用于启动Java的类。如果没有提供任何选项，它会列出正在运行的Java进程标识符以及用于启动进程的主类和命令行参数(与使用-l相同)。

**Perfcounter.print**

打印目标Java进程上可用的性能计数器。性能计数器的列表可能会随着Java进程的不同而产生变化。

**-f file**

从文件file中读取命令，然后在目标Java进程上调用这些命令。

**-l**

查看所有的进程列表信息。

**-h**
查看帮助信息。（同 -help）


jcmd的可用命令列表如下：

```
$ jcmd 26792 help
26792:
The following commands are available:
VM.native_memory
ManagementAgent.stop
ManagementAgent.start_local
ManagementAgent.start
GC.rotate_log
Thread.print
GC.class_stats
GC.class_histogram
GC.heap_dump
GC.run_finalization
GC.run
VM.uptime
VM.flags
VM.system_properties
VM.command_line
VM.version
help

For more information about a specific command use 'help <command>'.

```


PS: 以后用到了再详细补充。。

参考：

- [Monitoring Tools and Commands](https://docs.oracle.com/en/java/javase/11/tools/monitoring-tools-and-commands.html)
- [Troubleshooting Tools and Commands](https://docs.oracle.com/en/java/javase/11/tools/troubleshooting-tools-and-commands.html)
- [Java虚拟机的监控及诊断工具（命令行篇）](https://time.geekbang.org/column/article/40520)
- 周志明，深入理解Java虚拟机:JVM高级特性与最佳实践（第二版）
