# 基本知识

### 面对对象的特性

- 抽象
- 继承
- 封装
- 多态性

### final，finally，finalize的区别

final 是一个修饰符，可以修饰变量、方法和类。如果 final 修饰变量，意味着该变量的值在初始化后不能被改变。finalize  方法是在对象被回收之前调用的方法，给对象自己最后一个复活的机会，但是什么时候调用 finalize 没有保证。finally 是一个关键字，与  try 和 catch 一起用于异常的处理。finally 块一定会被执行，无论在 try 块中是否有发生异常。

### int 和 Integer有什么区别

- int是基本数据类型可直接使用，Integer是包装类需要实例化后使用
- int初始化为0， Integer初始化为null
- Integer可以拆箱为int，并且会将数据进行缓存（-128~127）

参考：
[Java基础之int和Integer有什么区别](https://blog.csdn.net/chenliguan/article/details/53888018)


### JAVA中的几种基本类型，各占用多少字节？


数据类型 | 大小 | 范围 | 默认值
---|---|---|---
byte(字节) | 8 | -128 ~ 127 | 0
short(短整型) | 16 | -32768 ~ 32678 | 0
int(整型) | 32 | -2,147,483,648 ~ 2,147,483,647 | 0
long(长整型) | 64 |  -9,223,372,036,854,775,808 ~ 9,223,372,036,854,775,807 | 0
float(浮点型) | 32 | -3.40292347E+38 ~ 3.40292347E+38 | 0
double(双精度) | 64 |  -1.79769313486231576E+308 ~ 1.79769313486231576E+308 | 0
char(字符型) | 16 | '\u0000~\uFFFF' | '\u0000'
boolean(布尔型) | 1 | true/false | false

### String， Stringbuffer， StringBuilder 的区别

String 字符串常量(final修饰，不可被继承)，String是常量，当创建之后即不能更改。(可以通过StringBuffer和StringBuilder创建String对象(常用的两个字符串操作类)。) 
```
String s1 = "a";//数据存储在栈，字符串常量池  
String s2 = new String("a");//数据存储在堆  
String s3 = "a";  
s1 == s2;//false  
s1 == s3;//true
```
String的特性：

- 不可变。是指String对象一旦生成，则不能再对它进行改变。不可变的主要作用在于当第一个对象需要被多线程共享，并且频繁访问时，可以省略同步和锁等待的时间，从而大幅度提高系统性能。不可变模式是一个可以提高多线程程序的性能，并可降低其复杂度的设计模式。

- 针对常量池的优化。当两个String对象拥有相同的值时，它们只引用常量池的同一个拷贝。可有效降低内存消耗和对象创建的开销。

StringBuffer   字符串变量（线程安全），其也是final类别的，不允许被继承，其中的绝大多数方法都进行了同步处理，包括常用的append方法也做了同步处理(`synchronized`修饰)。其自jdk1.0起就已经出现。其toString方法会进行对象缓存，以减少元素复制开销。

```Java
public synchronized String toString() { 
  if (toStringCache == null) { 
    toStringCache = Arrays.copyOfRange(value, 0, count); 
  } 
   return new String(toStringCache, true); 
}
```


StringBuilder 字符串变量（非线程安全）其自jdk1.5起开始出现。与StringBuffer一样都继承和实现了同样的接口和类，方法除了没使用`synchorized`修饰以外基本一致，不同之处在于最后toString的时候，会直接返回一个新对象。 

```Java
public String toString() { 
  // Create a copy, don’t share the array 
  return new String(value, 0, count); 
}
```

应用场景：
- 在字符串内存不经常发生变化的业务场景优先使用String类。例如常量声明、少量字符串拼接操作等。如果多个字符串变量进行“+”操作，会产生大量的无用的中间对象，耗费空间且效率低下。

- 在频繁进行字符串的运算（如拼接、替换、删除等），并且运行在多线程环境下，建议使用StringBuffer，例如XML解析、HTTP参数解析与封装。

- 在频繁进行字符串的运算（如拼接、替换、删除等），并且运行在多线程环境下，建议使用StringBuilder，例如SQL语句拼接、JSON封装。

### 重载和重写区别

**方法重写(overriding)：**

1. 也叫子类的方法覆盖父类的方法，要求返回值、方法名和参数都相同。
2. 子类抛出的异常不能超过父类相应方法抛出的异常。(子类异常不能超出父类异常)
3. 子类方法的的访问级别不能低于父类相应方法的访问级别(子类访问级别不能低于父类访问级别)

**方法重载(overloading)：**

重载是在同一个类中的两个或两个以上的方法，拥有相同的方法名，但是参数却不相同，方法体也不相同，最常见的重载的例子就是类的构造函数，可以参考API帮助文档看看类的构造方法

重载条件：两同三不同。（返回值不同没影响）
- 同一个类，相同方法名
- 参数个数不同，参数类型不同，参数顺序不同


### 抽象类和接口区别

**1. 语法层面上的区别**

- 抽象类可以提供成员方法的实现细节，而接口中只能存在public abstract 方法；
- 抽象类中的成员变量可以是各种类型的，而接口中的成员变量只能是public static final类型的；
- 接口中不能含有静态代码块以及静态方法，而抽象类可以有静态代码块和静态方法；
- 一个类只能继承一个抽象类，而一个类却可以实现多个接口。


**2. 设计层面上的区别**

- 抽象类是对一种事物的抽象，即对类抽象，而接口是对行为的抽象。抽象类是对整个类整体进行抽象，包括属性、行为，但是接口却是对类局部（行为）进行抽象。

- 设计层面不同，抽象类作为很多子类的父类，它是一种模板式设计。而接口是一种行为规范，它是一种辐射式设计。也就是说对于抽象类，如果需要添加新的方法，可以直接在抽象类中添加具体的实现，子类可以不进行变更；而对于接口则不行，如果接口进行了变更，则所有实现这个接口的类都必须进行相应的改动。
<br/>　
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/interface-abstractclass.png?raw=true)

### 说说反射的用途及实现

通过反射，我们可以在运行时获得程序或程序集中每一个类型成员和成员变量的信息。
程序中一般的对象类型都是在编译期就确定下来的，而Java 反射机制可以动态的创建对象并调用其属性，这样对象的类型在编译期是未知的。所以我们可以通过反射机制直接创建对象即使这个对象在编译期是未知的。

反射的核心：是 JVM 在运行时 才动态加载的类或调用方法或属性，它不需要事先（写代码的时候或编译期）知道运行对象是谁。

**用途：**
- 当我们在使用 IDE（如Eclipse\IDEA）时，当我们输入一个类名并向调用它的属性和方法时，一按(“.”)点号，编译器就会自动列出她的属性或方法，这里就会用到反射。
- 反射最重要的用途就是开发各种通用框架。很多框架（比如 Spring）都是配置化的（比如通过 XML文件配置 JavaBean，Action之类的），为了保证框架的通用性，他们可能根据配置文件加载不同的对象或类，调用不同的方法，这个时候就必须用到反射——运行时动态加载需要加载的对象。

**实现:**

1. 获取Class对象

- 已知具体的类，通过类的class属性获取，对于基本类型来说，它们的包装类型（wrapper classes）拥有一个名为“TYPE”的final静态字段，指向该基本类型对应的Class对象
- 已知某个类的实例，调用对象的getClass()方法获取Class对象
- 已知一个类的全类名，使用静态方法Class.forName来获取

例如，Integer.TYPE 指向 int.class。对于数组类型来说，可以使用类名 +“[ ].class”来访问，如 int[ ].class。

除此之外，Class 类和 java.lang.reflect 包中还提供了许多返回 Class 对象的方法。例如，对于数组类的 Class 对象，调用 Class.getComponentType() 方法可以获得数组元素的类型。

我们还可以利用自定义Classloader来加载我们的类，然后可以获取到该类的Class对象。类似于下面的代码，注意代码可能会抛出异常。

2. 创建对象，两种方式
- 调用构造方法来创建对象，例如：`Object student1= clazz.newInstance();`
- 通过构造方法创建对象，例如：`Constructor c= clazz.getConstructor();  Object student2=c.newInstance();`

3. 获取该类所有的方法 `clazz.getMethods()`
4. 获取属性  `clazz.getSuperclass().getDeclaredField("name")`
5. 获取接口  `clazz.getInterfaces()[0].getName()`

### 什么是泛型、为什么要使用以及泛型擦除

泛型：泛指一切类型。一般在编码的时候可以指定任意引用数据类型（对象数据类型）增强程序的扩展性和灵活性。泛型是一种标识，可以是任意字符。可以设置成员变量、参数、方法返回值，有泛型类、泛型接口、泛型方法等等

使用原因：
数据元素存储的安全性问题
避免类型强制转换

泛型擦除:
泛型信息只存在于代码编译阶段，在进入 JVM 之前，与泛型相关的信息会被擦除掉，专业术语叫做类型擦除。在泛型类被类型擦除的时候，之前泛型类中的类型参数部分如果没有指定上限，如` <T> `则会被转译成普通的 Object 类型，如果指定了上限如 `<T extends String> `则类型参数就被替换成类型上限，即String。

在Class类文件结构中，有一个Signature属性，Signature属性就是为了弥补类型擦除带来的缺陷(运行期进行反射时无法获得到泛型信息)而增设的，现在Java的反射API能够获取泛型类型，最终的数据来源也就是这个属性。
 
参考： [Java 泛型，你了解类型擦除吗？](https://blog.csdn.net/briblue/article/details/76736356)


### JAVA8 的 ConcurrentHashMap 为什么放弃了分段锁，有什么问题吗，如果你来设计，你如何设计。 

参考： [ConcurrentHashMap源码分析--Java8](https://yq.aliyun.com/articles/36781)


### equals与hashcode的关系 
equals相等两个对象，则hashcode一定要相等。但是hashcode相等的两个对象不一定equals相等。 


equals 和 == 区别
== 比较的是变量(栈)内存中存放的对象的(堆)内存地址，用来判断两个对象的地址是否相同，即是否是指相同一个对象。比较的是真正意义上的指针操作。
== 可以比较基本数据类型值是否相同

equals用来比较的是两个对象的内容是否相等，由于所有的类都是继承自java.lang.Object类的，所以适用于所有对象，如果没有对该方法进行覆盖的话，调用的仍然是Object类中的方法，而Object中的equals方法返回的却是==的判断。

如果hashCode相同，那么equals()返回true；
如果equals()返回true，那么hashCode必须一致，因此重写equals()方法，必须重写hashCode()方法。
String字符串变量的比较也要使用equals()方法。

### Java 四大引用及应用场景
Java中的引用分为以下四种：
- 强引用-FinalReference
- 软引用-SoftReference
- 弱引用-WeakReference
- 虚引用-PhantomReference

**强引用-FinalReference介绍：**
强引用是平常中使用最多的引用，强引用在程序内存不足（OOM）的时候也不会被回收，通过new 创建出来的是强引用。
使用场景：
这个就不用说了吧

**软引用-SoftReference介绍：**
软引用在程序内存不足时，会被回收，使用方式：

```Java
// 注意：wrf这个引用也是强引用，它是指向SoftReference这个对象的，
// 这里的软引用指的是指向`new String("str")`的引用，也就是SoftReference类中T
SoftReference<String> wrf = new SoftReference<String>(new String("str"));
```

使用场景：
创建缓存的时候，创建的对象放进缓存中，当内存不足时，JVM就会回收早先创建的对象。PS：图片编辑器，视频编辑器之类的软件可以使用这种思路。 

**弱引用-WeakReference介绍：**
弱引用就是只要JVM垃圾回收器发现了它，就会将之回收，使用方式：

```Java
WeakReference<String> wrf = new WeakReference<String>(str);
```

使用场景：
Java源码中的java.util.WeakHashMap中的key就是使用弱引用，我的理解就是，一旦我不需要某个引用，JVM会自动帮我处理它，这样我就不需要做其它操作。 
弱引用使用例子传送门: [十分钟理解Java中的弱引用](http://www.importnew.com/21206.html)

**虚引用-PhantomReference介绍：**
虚引用的回收机制跟弱引用差不多，但是它被回收之前，会被放入ReferenceQueue中。注意哦，其它引用是被JVM回收后才被传入ReferenceQueue中的。由于这个机制，所以虚引用大多被用于引用销毁前的处理工作。还有就是，虚引用创建的时候，必须带有ReferenceQueue

```Java
PhantomReference<String> prf = new PhantomReference<String>(new String("str"), new ReferenceQueue<>());
```

使用场景：
对象销毁前的一些操作，比如说资源释放等。

### Java异常的分类

Java标准库内建了一些通用的异常，这些类以Throwable为顶层父类。
Throwable又派生出Error类和Exception类。

**错误：** Error类以及他的子类的实例，代表了JVM本身的错误。错误不能被程序员通过代码处理，Error很少出现。因此，程序员应该关注Exception为父类的分支下的各种异常类。
异常：Exception以及他的子类，代表程序运行时发送的各种不期望发生的事件。可以被Java异常处理机制使用，是异常处理的核心。

**非检查异常（unckecked exception）：** Error 和 RuntimeException  以及他们的子类。javac在编译时，不会提示和发现这样的异常，不要求在程序处理这些异常。所以如果愿意，我们可以编写代码处理（使用try…catch…finally）这样的异常，也可以不处理。对于这些异常，我们应该修正代码，而不是去通过异常处理器处理   。这样的异常发生的原因多半是代码写的有问题。如除0错误ArithmeticException，错误的强制类型转换错误ClassCastException，数组索引越界ArrayIndexOutOfBoundsException，使用了空对象NullPointerException等等。

**检查异常（checked exception）：** 除了Error 和  RuntimeException的其它异常。javac强制要求程序员为这样的异常做预备处理工作（使用try…catch…finally或者throws）。在方法中要么用try-catch语句捕获它并处理，要么用throws子句声明抛出它，否则编译不会通过。这样的异常一般是由程序的运行环境导致的。因为程序可能被运行在各种未知的环境下，而程序员无法干预用户如何使用他编写的程序，于是程序员就应该为这样的异常时刻准备着。如SQLException  , IOException,ClassNotFoundException 等。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/throwable.png?raw=true)

参考：[Java 中的异常和处理详解](http://www.importnew.com/26613.html)

### OutofMemoryError异常

在Java虚拟机规范的描述中，除了程序计数器外，虚拟机内存的其他几个运行时区域都有可能发生OutOfMemoryError(OOM)异常的可能，分四个部分简单介绍：

#### Java堆溢出
Java堆用于存储对象实例，只要不断地创建对象，并且保证GC Root到对象间有可达路径来避免垃圾回收机制清除这些对象，那么在对象数量达到最大堆内存的容量限制后就会发生OOM。总结来说，例如可能存在内存泄露问题；也有可能堆大小设置不合理，比如要处理比较多的数据，但没有显示指定JVM堆大小或设定值偏小；或者出现JVM处理引用不及时，导致堆积，内存无法释放。

通过设置JVM参数最小堆内存-Xms， 最大堆内存-Xmx（将两者设置一样避免堆自动扩展）可以模拟堆溢出。如果出现此异常，需要分析是内存泄露和内存溢出，采取相应的手段来避免堆溢出。

测试：<br/>
[堆溢出测试代码](https://github.com/mstao/jvm-learning/blob/master/jvm-test/src/main/java/me/mingshan/jvm/oom/HeapOOM.java)

#### 虚拟机栈和本地方法栈溢出
关于虚拟机栈和本地方法栈，在Java虚拟机规范中描述了两种异常：
- 如果线程请求的栈深度大于虚拟机所允许的最大深度，将抛出StackOverflowError异常。
- 如果虚拟机在扩展栈时无法申请到足够的内存空间，则抛出OutOfMemoryError异常异常。

测试：<br/>
[虚拟机栈溢出测试代码](https://github.com/mstao/jvm-learning/blob/master/jvm-test/src/main/java/me/mingshan/jvm/oom/JavaVMStackSOF.java)

#### 方法区和运行时常量池溢出

参考：<br/>
[Java方法区和运行时常量池溢出问题分析（转）](https://www.cnblogs.com/softidea/archive/2016/05/15/5494924.html)

[方法区和运行时常量池-视频介绍](http://www.jikexueyuan.com/course/1793_4.html)

测试：<br/>
[运行时常量池溢出测试代码](https://github.com/mstao/jvm-learning/blob/master/jvm-test/src/main/java/me/mingshan/jvm/oom/RuntimeConstantPoolOOM.java)

JDK1.8 Metaspace:<br/>
[Metaspace溢出测试代码](https://github.com/mstao/jvm-learning/blob/master/jvm-test/src/main/java/me/mingshan/jvm/oom/JavaMethodAreaOOM.java)

#### 本机直接内存溢出

DirectMemory容量可通过-XX:MaxDirectMemorySize指定，如果不指定，则默认与Java堆最大值（-Xmx）一样

参考：<br/>
[本机直接内存溢出](https://blog.csdn.net/pfnie/article/details/52769517)

测试：<br/>
[本机直接内存溢出测试代码](https://github.com/mstao/jvm-learning/blob/master/jvm-test/src/main/java/me/mingshan/jvm/oom/DirectMemoryOOM.java)

### Minor GC、Major GC和Full GC之间的区别?

针对HotSpot VM的实现，它里面的GC其实准确分类只有两大种：

- Partial GC：并不收集整个GC堆的模式
    - Young GC：只收集young gen的GC
    - Old GC：只收集old gen的GC。只有CMS的concurrent collection是这个模式
    - Mixed GC：收集整个young gen以及部分old gen的GC。只有G1有这个模式
- Full GC：收集整个堆，包括young gen、old gen、perm gen（JDK8之后metaspace替代）等所有部分的模式。

Minor GC收集新生代（Young generation），包括Eden和两个Survivor。当Eden区没有足够空间进行分配时，虚拟机会触发Minor GC。

Full GC 触发条件：

- 当准备要触发一次young GC时，如果发现统计数据说之前young GC的平均晋升大小比目前old gen剩余的空间大，则不会触发young GC而是转为触发full GC（因为HotSpot VM的GC里，除了CMS的concurrent collection之外，其它能收集old gen的GC都会同时收集整个GC堆，包括young gen，所以不需要事先触发一次单独的young GC）；
- 如果有perm gen的话，要在perm gen分配空间但已经没有足够空间时，也要触发一次Full GC；
- 或者System.gc()、heap dump带GC，默认也是触发Full GC。

作者：RednaxelaFX
链接：https://www.zhihu.com/question/41922036/answer/93079526
