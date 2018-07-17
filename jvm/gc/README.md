# 垃圾回收

## 理解GC日志

### 输出GC日志

通过阅读GC日志，我们可以了解Java虚拟机内存分配与回收策略。
先来看一个简单的示例。

下面是GC日志：

```
0.115: [GC (System.gc()) [PSYoungGen: 3020K->600K(38400K)] 3020K->608K(125952K), 0.0012295 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
0.117: [Full GC (System.gc()) [PSYoungGen: 600K->0K(38400K)] [ParOldGen: 8K->554K(87552K)] 608K->554K(125952K), [Metaspace: 2773K->2773K(1056768K)], 0.0060759 secs] [Times: user=0.00 sys=0.00, real=0.01 secs] 
Heap
 PSYoungGen      total 38400K, used 333K [0x00000000d5f00000, 0x00000000d8980000, 0x0000000100000000)
  eden space 33280K, 1% used [0x00000000d5f00000,0x00000000d5f534a8,0x00000000d7f80000)
  from space 5120K, 0% used [0x00000000d7f80000,0x00000000d7f80000,0x00000000d8480000)
  to   space 5120K, 0% used [0x00000000d8480000,0x00000000d8480000,0x00000000d8980000)
 ParOldGen       total 87552K, used 554K [0x0000000081c00000, 0x0000000087180000, 0x00000000d5f00000)
  object space 87552K, 0% used [0x0000000081c00000,0x0000000081c8aab8,0x0000000087180000)
 Metaspace       used 2779K, capacity 4486K, committed 4864K, reserved 1056768K
  class space    used 300K, capacity 386K, committed 512K, reserved 1048576K

```

上面的GC日志是由下面的Java代码产生的：

```java
/**
 * GC 日志
 * @author mingshan
 *
 */
public class GCLogDemo {

    public static void main(String[] args) {
        int _1m = 1024 * 1024;
        byte[] data = new byte[_1m];
        // 将data置为null即让它成为垃圾
        data = null;
        // 通知垃圾回收器回收垃圾（help gc）
        System.gc();
    }
}

```

在Eclipse中以运行配置方式运行上面的代码，并设置VM参数：

```
-XX:+PrintGCTimeStamps
-XX:+PrintGCDetails
```

### GC日志说明：

先看这两行GC日志

```
0.115: [GC (System.gc()) [PSYoungGen: 3020K->600K(38400K)] 3020K->608K(125952K), 0.0012295 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
0.117: [Full GC (System.gc()) [PSYoungGen: 600K->0K(38400K)] [ParOldGen: 8K->554K(87552K)] 608K->554K(125952K), [Metaspace: 2773K->2773K(1056768K)], 0.0060759 secs] [Times: user=0.00 sys=0.00, real=0.01 secs] 

```

通过观察这两行日志发现，它们的格式相同，下面是对其格式的描述：

GC发生时间: [垃圾收集停顿类型: [GC发生区域: GC前该内存区域已使用容量 -> GC后该内存区域已使用容量(该内存区域总容量)] 该内存区域GC所占用的时间] GC前Java堆已使用容量 -> GC后Java堆已使用容量(Java堆总容量)] [user表示用户态消耗的CPU时间，sys表示内核态消耗的CPU时间，real表示操作从开始到结束所经过的墙钟时间]。

### GC日志解读

最前面的数字“0.115:”和“0.117:”代表GC发生的时间，是从Java虚拟机启动以来经过的秒数。

GC日志开头的"[GC" 和"[Full GC"说明这个GC的停顿类型，而不是用来判断是新生代GC还是老年代GC，其中“[Full GC”说明发生了Stop-The-World。这里出现了“(System.gc())”，说明是调用了System.gc()方法所触发的搜集。

接下来的“[PSYoungGen:”代表GC发生的区域，而且这里显示的区域名称与使用的GC收集器名称密切相关。PSYoungGen，表示新生代使用的是多线程垃圾收集器Parallel Scavenge。

方括号内部的“3020K->600K(38400K)”代表“GC前该内存区域已使用容量 -> GC后该内存区域已使用容量(该内存区域总容量)”。而在方括号外面的“3020K->608K(125952K)”表示"该内存区域GC所占用的时间] GC前Java堆已使用容量 -> GC后Java堆已使用容量(Java堆总容量)"。

再往后的“0.0012295 secs”代表该内存区域GC所占用的时间，单位为秒。后面的“[Times: user=0.00 sys=0.00, real=0.00 secs] ”为具体的时间信息。其中user表示用户态消耗的CPU时间，sys表示内核态消耗的CPU时间，real表示操作从开始到结束所经过的墙钟时间（Wall Clock Time）。钟时间包括各种非运算的等待耗时，如IO等待、线程阻塞。CPU时间不包括等待时间，当系统有多核或者多个CPU时，多线程操作会叠加这些CPU时间，所以user或sys时间会超过real时间。

### 堆详细信息解读：

下面是堆详细信息的日志：

```
Heap
 PSYoungGen      total 38400K, used 333K [0x00000000d5f00000, 0x00000000d8980000, 0x0000000100000000)
  eden space 33280K, 1% used [0x00000000d5f00000,0x00000000d5f534a8,0x00000000d7f80000)
  from space 5120K, 0% used [0x00000000d7f80000,0x00000000d7f80000,0x00000000d8480000)
  to   space 5120K, 0% used [0x00000000d8480000,0x00000000d8480000,0x00000000d8980000)
 ParOldGen       total 87552K, used 554K [0x0000000081c00000, 0x0000000087180000, 0x00000000d5f00000)
  object space 87552K, 0% used [0x0000000081c00000,0x0000000081c8aab8,0x0000000087180000)
 Metaspace       used 2779K, capacity 4486K, committed 4864K, reserved 1056768K
  class space    used 300K, capacity 386K, committed 512K, reserved 1048576K
```

先了解下Java memory划分：

Java memory主要分heap memory 和 non-heap memory，如下图：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/java-memory.jpg?raw=true)


第一行为新生代的大小，大小为38400K。而新生代又分为三个区域分别叫Eden，和俩个Survivor spaces。Eden用来存放新的对象，Survivor spaces用于 新对象 升级到 Tenured area时的 拷贝。默认的，Edem : from : to = 8 : 1 : 1 ( 可以通过参数 –XX:SurvivorRatio 来设定 )，即： Eden = 8/10 的新生代空间大小，from = to = 1/10 的新生代空间大小。

默认的，新生代 ( Young ) 与老年代 ( Old ) 的比例的值为 1:2 ( 该值可以通过参数 –XX:NewRatio 来指定 )，即：新生代 ( Young ) = 1/3 的堆空间大小。老年代 ( Old ) = 2/3 的堆空间大小。其中，新生代 ( Young ) 被细分为 Eden 和 两个 Survivor 区域，这两个 Survivor 区域分别被命名为 from 和 to，以示区分。 

 ParOldGen 为老年代，大小为87552K，大约为PSYoungGen内存大小的2倍。 从JDK8开始，永久代(PermGen)的概念被废弃掉了，取而代之的是一个称为Metaspace的存储空间。Metaspace与PermGen之间最大的区别在于：Metaspace并不在虚拟机中，而是使用本地内存。
 
 
### 参考

- 深入理解Java虚拟机：JVM高级特性与最佳实践（第2版）
- [聊聊jvm的PermGen与Metaspace](https://segmentfault.com/a/1190000012577387)