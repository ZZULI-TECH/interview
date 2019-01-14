# Java虚拟机的监控及诊断工具（GUI）

前面我们总结了[Java虚拟机的监控及诊断工具(命令行)](http://mingshan.me/2018/10/21/Java%E8%99%9A%E6%8B%9F%E6%9C%BA%E7%9A%84%E7%9B%91%E6%8E%A7%E5%8F%8A%E8%AF%8A%E6%96%AD%E5%B7%A5%E5%85%B7%EF%BC%88%E5%91%BD%E4%BB%A4%E8%A1%8C%EF%BC%89/)相关命令的使用，用命令行虽然说比较方便，但不够直观，要是有图形显示JVM运行的一些情况就好了。`eclipse MAT` 和 ` Java Mission Control` 是两个使用比较广泛的GUI虚拟机的监控及诊断工具，下面让我们来用用吧。

## Eclipse MAT

在命令行那篇，我们已经知道可以用`jmap` 命令来生成Java虚拟机堆dump文件，那么我们就可以用Eclipse的[Memory Analyzer (MAT)](https://www.eclipse.org/mat/)工具来解析了。

MAT 支持自己获取dump 文件，它是利用`jps`命令来列出正在运行的虚拟机进程信息，然后进行选择将要分析的虚拟机进程，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_acquire_heap_dump.png?raw=true)

我们来选择刚启动的SpringBoot应用，点击对应的选项后，MAT会加载堆快照信息，完成后主界面将会有一个饼状图，列举占据的 `Retained heap` 最多的几个对象。如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_overview.png?raw=true)

`Retained heap`是什么意思，感觉好陌生啊。。不慌，我们来查一下，在Eclipse documentation的Memory Analyzer章节中，介绍了MAT计算内存占用的两种方式，[Shallow Heap 和 Retained Heap](https://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.mat.ui.help%2Fconcepts%2Fshallowretainedheap.html&cp=46_2_1)，简单地了解下：

**Shallow Heap**

Shallow Heap 是一个对象所占用的内存，不包括它所引用对象的内存，根据32/64位操作系统的不同，该值的计算结果可能有所不同。

**Retained Heap**

Retained Heap 是一个对象不再被引用时，GC所能回收的总内存，包括对象自身占用的内存，以及仅能通过该对象引用的其他对象所占据的内存。即一些对象需要依赖该对象而存活，GC Roots 不直接引用。下面放一张官方介绍的图解析一下（如下图所示），由于H还被F直接引用，所以E的Retaned Set 只包括E 和 G，不包括H，其他同理。上面饼状图所显示的就是Retained Heap。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_shallow_retained.png?raw=true)

Mat包含了几种比较重要的视图，`Histogram`（直方图）和`dominator tree`（支配树），也提供了线程总览视图。

### `Histogram`（直方图）

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_histogram.png?raw=true)

点击直方图按钮，样式如上图所示。包含各类的对象数量以及Shallow Heap的大小，还统计了Retained Heap的大小，只不过该值为近似值。支持对图中的四个列进行排序，默认是Shallow Heap。

当我们点击具体的类名时，在下面的Inspector面板显示该类的相关信息，比如包名、类名、类加载等信息，如下图所示：
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_histogram_inspector.png?raw=true)


### `dominator tree`（支配树）

下面讨论一下支配树视图，说这个之前首先要知道在Java中是通过可达性分析（Reachability Analysis）来判定对象是否存活的。这个算法是基于被称为“GC Roots”的对象作为起点，从这些节点开始向下搜索，所走过的路径被称为引用链（Reference Chain），当一个对象到GC Roots没有任何引用链，则这个对象是不可用的。这种概念源自于图论。如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/gc_root.png?raw=true)

在Java语言中，可以作为GC Roots的对象有以下几种：

- 所有Java线程当前活跃的栈帧里指向GC堆里的对象的引用；换句话说，当前所有正在被调用的方法的引用类型的参数/局部变量/临时值。
- VM的一些静态数据结构里指向GC堆里的对象的引用，例如说HotSpot VM里的Universe里有很多这样的引用。
- JNI handles，包括global handles和local handles
- （看情况）所有当前被加载的Java类
- （看情况）Java类的引用类型静态变量
- （看情况）Java类的运行时常量池里的引用类型常量（String或Class类型）
- （看情况）String常量池（StringTable）里的引用


好了，掌握了这么多姿势，来看看支配树的样子，MAT 将默认按照每个对象 Retained heap 的大小排列支配树，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_dominator_tree.png?raw=true)

从图中可以看出，对象的引用呈链式引用，垃圾回收器回收第一个对象，那么处于链式引用的对象也可以被回收。

### 定位溢出源

我们还可以利用MAT 提供 的 `Path To GC Roots`功能来反推出该对象到GC Roots的引用路径，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_path_to_gc_roots.png?raw=true)

MAT 还提供了`Merge Shortest Paths to GC Roots` 来显示GC根节点到选中对象的引用路径，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_dominator_tree_merge.png?raw=true)

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/mat/mat_dominator_tree_merge_result.png?raw=true)

`exclude all phantom/weak/soft etc. reference` 意思是排除虚引用、弱引用和软引用，即只剩下强引用，因为除了强引用之外，其他的引用都可以被JVM GC掉，如果一个对象始终无法被GC，就说明有强引用存在，从而导致在GC的过程中一直得不到回收，最终就内存溢出了。

MAT 还提供查询等功能，简直是强大，有空要好好用下，嘻嘻~

## Java Mission Control

了解完Mat， 感觉已经很强大，Java 官方有没有提供类似的工具呢？
Java Mission Control(JMC) 和 Java Flight Recorder(飞行记录仪) 是从Java官方提供的一个完整的工具链用来收集JVM底层运行时的信息，可以在线监控JVM的运行情况和进行事后数据分析。

Java Mission Control是Java虚拟机平台的性能检测工具。它包含一个GUI客户端，以及众多众多用来收集JVM性能数据的插件，其中包括Java Flight Recorder。

Java Flight Recorder是一个内置在Oracle JDK中的分析和事件收集框架。它允许开发人员收集关于Java虚拟机(JVM)和Java应用程序行为的详细底层信息。

JMC 是从Java1.7 开始提供的，不过自Java 11开始，不再包含在Java的发行包中，需要单独下载。JFR 在JDK11 开源了，但在之前的 Java 版本，JFR 属于 Commercial Feature，需要通过 `-XX:+UnlockCommercialFeatures`开启。

启动JMC，然后选择我们要监控的Java的进程，稍等一会就显示出该进程的概览面板，包括当前当前进程的CPU占用率，堆内存情况等信息，注意这些都是实时监控。如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jmc_overview.png?raw=true)

我们也可以用它来查看当前进程所运行线程的相关情况，包括线程的状态，阻塞次数，CPU总体占用率，是否发生死锁以及分配的内存，挺详细的，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jmc_thread.png?raw=true)

### JFR

JFR 开启的方式主要有三种，

**第一种**是在运行目标 Java 程序时添加`-XX:StartFlightRecording=`参数。关于该参数的配置详情，你可以参考[该帮助文档](https://docs.oracle.com/en/java/javase/11/tools/java.html#GUID-3B1CE181-CD30-4178-9602-230B800D4FAE)（请在页面中搜索`-XX:StartFlightRecording`）。

下面的这条命令是在JVM启动后5秒（delay=5s），持续时间为20秒（duration=20s），当收集完后，将数据保存在`myrecored.jfr`文件中（filename=myrecored.jfr）

```
$ java -XX:StartFlightRecording=delay=5s,duration=20s,filename=myrecored.jfr,settings=profile MyApp
```

**第二种**是通过jcmd来让 JFR 开始收集数据、停止收集数据，或者保存所收集的数据，对应的子命令分别为JFR.start，JFR.stop，以及JFR.dump。


**第三种**就是我们要操作的，通过JMC的JFR插件来启动。下面是启动参数配置，在该配置选项中，可以配置记录文件的存放位置、持续收集时间等信息：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jfr_start.png?raw=true)


等待收集信息完毕，会出现outline界面，首先映入我们眼帘的是jfr的自动分析结果，CPU暂用率阿等信息，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jfr_overview.png?raw=true)

我们发现左边出现了一个outline界面，包括Java应用程序的信息（线程、内存等），JVM内部信息（GC、类加载、TLAB分配等），环境信息（环境变量、当前进程CPU占用情况等）和事件浏览器。如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jfr_outline.png?raw=true)


**查看Java应用程序的信息**

点击左侧outline的Java应用程序按钮，在右边会出现当前进程的相关数据总览，包括当前的线程、堆使用情况、CPU占用情况等信息，从下方的图中可以看出发生GC了：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jfr_application.png?raw=true)

当然你可以点击Java应用程序下的小按钮，例如点击内存按钮，显示内存的使用情况：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jfr_memory.png?raw=true)

**查看GC情况**

在虚拟机内部栏，点击垃圾收集按钮，会在右侧显示垃圾回收的情况，包含垃圾回收的次数及暂停时间，当点击具体的一次垃圾收集时，注意在左下角会显示当前垃圾收集的参数，包括类型、开始结束时间等信息。如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jmc/jfr_gc.png?raw=true)

其他的就不再一一介绍了。。贼多~

## jvisualvm

Java VisualVM（[帮助文档](https://docs.oracle.com/javase/8/docs/technotes/guides/visualvm/)）在JDK11中已被移除，暂时不用了。


参考：

- [Java虚拟机的监控及诊断工具（GUI篇）](https://time.geekbang.org/column/article/40821)
- [Shallow vs. Retained Heap](https://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.mat.ui.help%2Fconcepts%2Fshallowretainedheap.html&cp=46_2_1)
- [Garbage Collection Roots](https://help.eclipse.org/luna/index.jsp?topic=%2Forg.eclipse.mat.ui.help%2Fconcepts%2Fgcroots.html&cp=37_2_3)
- [java的gc为什么要分代？ - RednaxelaFX的回答 - 知乎](https://www.zhihu.com/question/53613423/answer/135743258)
- [Java Mission Control](http://jdk.java.net/jmc/)
- [ Java Mission Control User's Guide](https://docs.oracle.com/javacomponents/jmc-5-5/jmc-user-guide/)
- [Java VisualVM](https://docs.oracle.com/javase/8/docs/technotes/guides/visualvm/)

