# 垃圾回收器

Java有九种类型的垃圾回收器：

- **Serial Garbage Collector**（串行运行；作用于新生代；复制算法；响应速度优先；适用于单CPU环境下的client模式。）
- **ParNew Garbage Collector**（并行运行；作用于新生代；复制算法；响应速度优先；多CPU环境Server模式下与CMS配合使用。）
- **Parallel Garbage Collector**（并行运行；作用于新生代；复制算法；吞吐量优先；适用于后台运算而不需要太多交互的场景。）
- **Serial Old Garbage Collector**（串行运行；作用于老年代；标记-整理算法；响应速度优先；单CPU环境下的Client模式。）
- **Parallel Old Garbage Collector**（并行运行；作用于老年代；标记-整理算法；吞吐量优先；适用于后台运算而不需要太多交互的场景。）
- **CMS Garbage Collector**（并发运行；作用于老年代；标记-清除算法；响应速度优先；适用于互联网或B/S业务。）
- **G1 Garbage Collector**（并发运行；可作用于新生代或老年代；标记-整理算法+复制算法；响应速度优先；面向服务端应用。）
- **Epsilon GC**
- **The Z Garbage Collector**（并发）

**Serial Garbage Collector**

Serial收集器是最基本、最古老的收集器，在JDK5和6中是Client模式下默认的垃圾收集器，它是一个单线程的垃圾收集器，它在进行垃圾收集时，必须暂停其他所有工作的线程，就是所谓的“Stop-The-World”，直到它工作结束。根据内存年代的不同，其在新生代采用复制算法，老年代的实现单独被称为Serial Old，采用标记-整理算法（Mark-Compact）。Serial对应的JVM参数是：

```
-XX:+UseSerialGC
```

**ParNew Garbage Collector**

ParNew收集器是Serial收集器的多线程版本，除了使用多线程进行垃圾收集以外，其他行为和Serial收集器一致。最常见的应用场景是配合老年代的 CMS GC 工作，其JVM参数如下：

```
-XX:+UseConcMarkSweepGC -XX:+USeParNewGC
```

**Parallel Garbage Collector**

Parallel收集器是一个新生代的收集器，采用复制算法，在早期 JDK 8 等版本中，它是 server 模式的默认GC，其特点是吞吐量优先。所谓吞吐量就是CPU用于运行代码的时间与CPU总消耗的时间比值，吞吐量计算公式为

```
吞吐量 = 运行用户代码时间 / (运行用户代码时间 + 垃圾收集时间)
```

开启选项是：

```
-XX:+UseParallelGC
```

Parallel 收集器提供了两个参数用于精确控制吞吐量，分别是控制最大垃圾收集停顿时间和直接设置吞吐量大小，如下所示：

```
-XX:MaxGCPauseMillis=value
-XX:GCTimeRatio=N // GC 时间和用户时间比例 = 1 / (N+1)
```

除此之外，Parallel 收集器还提供了一个`-XX:+UseAdaptiveSizePolicy`参数，虚拟机会根据当前系统运行的情况，动态调整JVM相关参数以提供最合适的停顿时间及最大的吞吐量，这种调节方式被称为GC自适应调节策略（GC Ergonomics）。


**Serial Old Garbage Collector**

Serial Old是Serial的老年代版本，它同样是一个单线程收集器，使用“标记-整理”算法。

**Parallel Old Garbage Collector**

Parallel Old是Parallel的老年代版本，使用多线程和“标记-整理”算法，它是JDK1.6开始提供的。

**CMS Garbage Collector**

CMS(Concurrent Mark Sweep)收集器是一种以获取最短回收停顿时间为目标的收集器，基于“标记清除”算法（Mark Sweep），是一款比较优秀的收集器。但是，CMS 采用的标记 - 清除算法，存在着内存碎片化问题，所以难以避免在长时间运行等情况下发生 Full GC，导致导致恶劣的停顿。CMS同时对CPU资源非常敏感，会占用更多的CPU资源。


**G1垃圾回收器**

G1垃圾回收器适用于堆内存很大的情况，他将堆内存分割成不同的区域，并且并发的对其进行垃圾回收。G1也可以在回收内存之后对剩余的堆内存空间进行压缩。并发扫描标记垃圾回收器在STW情况下压缩内存。G1垃圾回收会优先选择第一块垃圾最多的区域

JVM参数参数如下：

```
–XX:+UseG1GC
``` 

**Epsilon GC**

一个不做垃圾收集的收集器，在JDK11发布，具体参考：

http://openjdk.java.net/jeps/318


**ZGC**

一种可扩展的低延迟垃圾收集器，在JDK11中发布，它是一种全新的垃圾收集器，使用了Load Barriors技术来跟踪堆的状态和对象的状态。详细参考：[zgc](http://openjdk.java.net/projects/zgc/)

通过以下参数开启ZGC，目前仅支持Linux/x86_64。

```
-XX:+UnlockExperimentalVMOptions -XX:+UseZGC
```

**GC的优化配置**

配置 | 描述
---|---
-Xms | 初始化堆内存大小
-Xmx | 堆内存最大值
-Xmn | 新生代大小
-XX:PermSize | 初始化永久代大小
-XX:MaxPermSize | 永久代最大容量


参考：

- 深入理解Java虚拟机：JVM高级特性与最佳实践（第2版）
- 杨晓峰，Java常见的垃圾收集器有哪些？
- [Garbage Collection in Java](https://plumbr.io/handbook/garbage-collection-in-java)
- [Java Garbage Collection Basics](https://www.oracle.com/webfolder/technetwork/tutorials/obe/java/gc01/index.html)