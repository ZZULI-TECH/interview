`javap`命令可以用来查阅字节码文件，可以将指定的字节码文件反编译，反解析出当前类对应基本信息、常量池（Constant pool）、字段区域、
方法区（Code[JVM指令集]）、异常表（Exception table）、本地变量表（LocalVariableTable）、行数表（LineNumberTable）和字节码操作数栈的映射表（StackMapTable）等信息。

## javap命令格式

`javap`命令格式如下：

```
javap [options] classes...
```

其中`options`为命令的参数，主要参数有以下：

```
-help , --help , or -?  输出javap命令的使用信息
-version                版本信息
-verbose or -v          输出附加信息（包括行号、本地变量表，反汇编等详细信息）
-l                      输出行号和本地变量表
-public                 仅显示公共类和成员
-protected              显示受保护的/公共类和成员
-package                显示 package/protected/public 类和成员
-private or -p          显示所有类和成员
-c                      对代码进行反编译
-s                      输出内部类型签名
-sysinfo                显示正在处理的类的系统信息 (路径, 大小, 日期, MD5 散列)
-constants              显示static final常量
--module module or -m module  指定反编译的类的模块
--module-path path            指定模块的路径
--system jdk                  
--class-path path, -classpath path , or -cp path 指定查找用户类文件的位置
-bootclasspath path     覆盖引导类文件的位置
-Joption                将指定的参数传递给JVM 
```

具体参数详解，请参阅`javap`[文档](https://docs.oracle.com/en/java/javase/11/tools/javap.html#GUID-BE20562C-912A-4F91-85CF-24909F212D7F)。

## 查阅字节码

下面是一段简单的Java代码，我们利用`javac -g`编译该文件

```
package me.mingshan.util;

public class Demo {
    private static final int FLAG = 1; 
    private int tryBlock;
    private int catchBlock;
    private int finallyBlock;
    private int methodExit;

    public void test() {
        try {
            tryBlock = 0;
        } catch (Exception e) {
            catchBlock = 1;
        } finally {
            finallyBlock = 2;
        }
        methodExit = 3;
    }
}

```

然后利用`javap`命令反编译字节码文件：

```
$ javap -p -v Demo 
```

执行过后，会在屏幕输出详细的字节码信息，如下所示：

```
Classfile /D:/code/hutils/src/test/java/me/mingshan/util/Demo.class
  Last modified 2019年1月5日; size 732 bytes
  MD5 checksum 65cd84534ad3fb03f7b077f88d4d1408
  Compiled from "Demo.java"
public class me.mingshan.util.Demo
  minor version: 0
  major version: 55
  flags: (0x0021) ACC_PUBLIC, ACC_SUPER
  this_class: #7                          // me/mingshan/util/Demo
  super_class: #8                         // java/lang/Object
  interfaces: 0, fields: 5, methods: 2, attributes: 1
Constant pool:
   #1 = Methodref          #8.#31         // java/lang/Object."<init>":()V
   #2 = Fieldref           #7.#32         // me/mingshan/util/Demo.tryBlock:I
   #3 = Fieldref           #7.#33         // me/mingshan/util/Demo.finallyBlock:I
   #4 = Class              #34            // java/lang/Exception
   #5 = Fieldref           #7.#35         // me/mingshan/util/Demo.catchBlock:I
   #6 = Fieldref           #7.#36         // me/mingshan/util/Demo.methodExit:I
   #7 = Class              #37            // me/mingshan/util/Demo
   #8 = Class              #38            // java/lang/Object
   #9 = Utf8               FLAG
  #10 = Utf8               I
  #11 = Utf8               ConstantValue
  #12 = Integer            1
  #13 = Utf8               tryBlock
  #14 = Utf8               catchBlock
  #15 = Utf8               finallyBlock
  #16 = Utf8               methodExit
  #17 = Utf8               <init>
  #18 = Utf8               ()V
  #19 = Utf8               Code
  #20 = Utf8               LineNumberTable
  #21 = Utf8               LocalVariableTable
  #22 = Utf8               this
  #23 = Utf8               Lme/mingshan/util/Demo;
  #24 = Utf8               test
  #25 = Utf8               e
  #26 = Utf8               Ljava/lang/Exception;
  #27 = Utf8               StackMapTable
  #28 = Class              #39            // java/lang/Throwable
  #29 = Utf8               SourceFile
  #30 = Utf8               Demo.java
  #31 = NameAndType        #17:#18        // "<init>":()V
  #32 = NameAndType        #13:#10        // tryBlock:I
  #33 = NameAndType        #15:#10        // finallyBlock:I
  #34 = Utf8               java/lang/Exception
  #35 = NameAndType        #14:#10        // catchBlock:I
  #36 = NameAndType        #16:#10        // methodExit:I
  #37 = Utf8               me/mingshan/util/Demo
  #38 = Utf8               java/lang/Object
  #39 = Utf8               java/lang/Throwable
{
  private static final int FLAG;
    descriptor: I
    flags: (0x001a) ACC_PRIVATE, ACC_STATIC, ACC_FINAL
    ConstantValue: int 1

  private int tryBlock;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE

  private int catchBlock;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE

  private int finallyBlock;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE

  private int methodExit;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE

  public me.mingshan.util.Demo();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 6: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lme/mingshan/util/Demo;

  public void test();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=2, locals=3, args_size=1
         0: aload_0
         1: iconst_0
         2: putfield      #2                  // Field tryBlock:I
         5: aload_0
         6: iconst_2
         7: putfield      #3                  // Field finallyBlock:I
        10: goto          35
        13: astore_1
        14: aload_0
        15: iconst_1
        16: putfield      #5                  // Field catchBlock:I
        19: aload_0
        20: iconst_2
        21: putfield      #3                  // Field finallyBlock:I
        24: goto          35
        27: astore_2
        28: aload_0
        29: iconst_2
        30: putfield      #3                  // Field finallyBlock:I
        33: aload_2
        34: athrow
        35: aload_0
        36: iconst_3
        37: putfield      #6                  // Field methodExit:I
        40: return
      Exception table:
         from    to  target type
             0     5    13   Class java/lang/Exception
             0     5    27   any
            13    19    27   any
      LineNumberTable:
        line 15: 0
        line 19: 5
        line 20: 10
        line 16: 13
        line 17: 14
        line 19: 19
        line 20: 24
        line 19: 27
        line 20: 33
        line 21: 35
        line 22: 40
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
           14       5     1     e   Ljava/lang/Exception;
            0      41     0  this   Lme/mingshan/util/Demo;
      StackMapTable: number_of_entries = 3
        frame_type = 77 /* same_locals_1_stack_item */
          stack = [ class java/lang/Exception ]
        frame_type = 77 /* same_locals_1_stack_item */
          stack = [ class java/lang/Throwable ]
        frame_type = 7 /* same */
}
SourceFile: "Demo.java"
```

`javap`命令默认打印非私有的字段和方法，`-p`参数会显示所有的字段和方法，`-v`会输出附加信息（包括行号、本地变量表，反汇编等详细信息），更方便理解字节码的结构。

`javap -v`输出的信息包含以下几块：

### 基本信息

在输出信息的最上面部分，包含字节码的基本信息。主要包括以下信息：

**class文件的版本号**，包括minor version和major version， major version是主版本号，55代表该Class文件利用JDK11编译，minor version为次版本号，低版本的class文件无法在新版本的JVM中运行。

**`flags`代表访问标识**，Class类文件的访问标识通常右`ACC_`开头，ACC_PUBLIC, ACC_SUPER代表这个类是public的，具体信息可以参考JVM规范。

该类（this_class: #7）以及父类（super_class: #8）后面显示其名称，接着显示所实现接口（interfaces: 0）、字段（fields：5）、方法（methods: 2）、属性（attributes: 1）相关数量。

```
public class me.mingshan.util.Demo
  minor version: 0
  major version: 55
  flags: (0x0021) ACC_PUBLIC, ACC_SUPER
  this_class: #7                          // me/mingshan/util/Demo
  super_class: #8                         // java/lang/Object
  interfaces: 0, fields: 5, methods: 2, attributes: 1
```

### 常量池

接着就是常量池（Constant pool）了，常量池用来存放字面量（Literal）和 符号引用（Symbolic Reference）。

常量池的每一项都有一个对应的索引（#1 = Methodref），并且可能引用常量池其他的项（#1 = Methodref #8.#23）

下面是输出的具体的常量池信息，从常量池信息来看，Fieldref等引用的都在我们代码中出现了，但例如`I`、`Code`、 `<init>` 、`LineNumberTable`、 `StackMapTable` 这些在我们的代码中都没有出现过，这些常量会在字段表（field_info）、方法表（method_info）、属性表（attribute_info）中用到。

```
Constant pool:
   #1 = Methodref          #8.#26         // java/lang/Object."<init>":()V
   #2 = Fieldref           #7.#27         // me/mingshan/util/Demo.tryBlock:I
   #3 = Fieldref           #7.#28         // me/mingshan/util/Demo.finallyBlock:I
   #4 = Class              #29            // java/lang/Exception
   #5 = Fieldref           #7.#30         // me/mingshan/util/Demo.catchBlock:I
   #6 = Fieldref           #7.#31         // me/mingshan/util/Demo.methodExit:I
   #7 = Class              #32            // me/mingshan/util/Demo
   #8 = Class              #33            // java/lang/Object
   #9 = Utf8               FLAG
  #10 = Utf8               I
  #11 = Utf8               ConstantValue
  #12 = Integer            1
  #13 = Utf8               tryBlock
  #14 = Utf8               catchBlock
  #15 = Utf8               finallyBlock
  #16 = Utf8               methodExit
  #17 = Utf8               <init>
  #18 = Utf8               ()V
  #19 = Utf8               Code
  #20 = Utf8               LineNumberTable
  #21 = Utf8               test
  #22 = Utf8               StackMapTable
  #23 = Class              #34            // java/lang/Throwable
  #24 = Utf8               SourceFile
  #25 = Utf8               Demo.java
  #26 = NameAndType        #17:#18        // "<init>":()V
  #27 = NameAndType        #13:#10        // tryBlock:I
  #28 = NameAndType        #15:#10        // finallyBlock:I
  #29 = Utf8               java/lang/Exception
  #30 = NameAndType        #14:#10        // catchBlock:I
  #31 = NameAndType        #16:#10        // methodExit:I
  #32 = Utf8               me/mingshan/util/Demo
  #33 = Utf8               java/lang/Object
  #34 = Utf8               java/lang/Throwable
```

上面提到，常量池的每一项可能引用常量池的其他项，举例来说，上面输出的常量池信息中的 1 号常量池项是一个指向 Object类构造器的符号引用。它是由另外两个常量池项所构成。如果将它看成一个树形结构的话，那么它的子结点会是字符串常量，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/jvm/constant_pool_reference.png?raw=true)

### 字段区域

接下来是字段区域，显示类中的字段信息，这里主要显示两类信息：字段的描述符（descriptor）和访问权限（flags），有关描述符的概念可以参考[全限定名、简单名称和描述符是什么东西？](https://mingshan.fun/2018/09/18/fully-qualified-name-simple-name-descriptor/)。注意如果是`static final`修饰的字段，如果它是基本类型或者字符串类型，那么字段区域还将包括它的常量值，如下所示：

```
  private static final int FLAG;
    descriptor: I
    flags: (0x001a) ACC_PRIVATE, ACC_STATIC, ACC_FINAL
    ConstantValue: int 1

  private int tryBlock;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE

  private int catchBlock;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE

  private int finallyBlock;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE

  private int methodExit;
    descriptor: I
    flags: (0x0002) ACC_PRIVATE
```

### 方法区域

再接着就是方法区域了。顾名思义，该区域用来描述方法的信息，除了描述符（descriptor）和访问标志（flags）外，每个方法还包含最重要的代码区域（Code），了解该区域对阅读字节码文件是十分重要的，并且是学习字节码执行引擎内容的必要基础。

从上面的Code区域来看，包括两个方法信息，其中一个是实例构造器<init>()方法，下面是该方法的详细信息：

```
  public me.mingshan.util.Demo();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 6: 0
```

在Code区域中，一开始就会声明该方法中的操作数栈（stack=1）和局部变量最大数目（locals=1）以及该方法接受参数的数目值（args_size=1），注意这里的局部数量是指字节码中的局部变量，并非Java代码中的局部变量。

我们此时可能会感到奇怪，args_size为什么会是1呢，无论是参数列表还是局部变量，统统没有自己定义，locals为什么也是1呢？我们在方法中使用`this`关键字使用方法所属类的对象，这个访问机制的实现其实是javac编译器编译的时候把this关键字的访问转为对一个普通方法的参数的访问，然后在虚拟机调用该实例方法时传入此参数而已。所以在实例方法的局部变量表至少有一个指向当前对象的局部变量，不过对于static方法就没有了。

接下来就是该方法的**字节码**，每条字节码均标注了对应的偏移量（bytecode index BCI），比如在上面的字节码中，偏移量为10的`goto 35`指令跳转至偏移量为35的`aload_0`指令。这里不探讨具体指令的意义，详细请参考[The Java Virtual Machine Instruction Set](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5)。后面再专门研究Java字节码。


然后后面是**异常表**（Exception table），这个表是干什么的呢？我们可以下面的异常表的输出信息看出，有from、to、target和type四列，从这几个列的含义我们可以知道使用偏移量来定位每个异常处理器所监控的范围（由 from 到 to 的代码区域），以及异常处理器的起始位置（target），type指的是捕捉的异常类型，any代表任意异常类型。其实我们在Code区域会发现有好几个goto 指令，因为程序在运行的时候才会知道到底跳转到那个catch，所以需要提前罗列出所有跳转的goto语句，当抛出异常的时候匹配到某个异常，直接goto到某个catch块。这个在后面分析字节码的时候专门分析一下JVM的异常处理。


```
Exception table:
         from    to  target type
             0     5    13   Class java/lang/Exception
             0     5    27   any
            13    19    27   any
```

异常表下面是**行数表**（LineNumberTable），用于表示指令与代码行数的偏移对应关系，每一行第一个数字对应代码行数，第二个数字对应前面Code中指令前面的数字。

```
LineNumberTable:
        line 15: 0
        line 19: 5
        line 20: 10
        line 16: 13
        line 17: 14
        line 19: 19
        line 20: 24
        line 19: 27
        line 20: 33
        line 21: 35
        line 22: 40
```

异常表下面显示的**本地变量表**（LocalVariableTable），注意如果要显示局部变量表的信息，需要用`javac -g`编译java文件。上面我们分析了`this`关键字，在这里我们看到了该关键字的踪迹。start+length表示这个变量在字节码中的偏移位置（this生命周期从头0到结尾41），slot就是这个变量在局部变量表中的槽位（槽位可复用），name就是变量名称，Signatur为局部变量描述符。

```
LocalVariableTable:
        Start  Length  Slot  Name   Signature
           14       5     1     e   Ljava/lang/Exception;
            0      41     0  this   Lme/mingshan/util/Demo;
```

最后是**字节码操作数栈的映射表**（StackMapTable: number_of_entries = 3），主要被用来验证所加载的类，下面是JVM规范中的描述：
> A StackMapTable attribute is used during the process of verification by type checkin


```
StackMapTable: number_of_entries = 3
        frame_type = 77 /* same_locals_1_stack_item */
          stack = [ class java/lang/Exception ]
        frame_type = 77 /* same_locals_1_stack_item */
          stack = [ class java/lang/Throwable ]
        frame_type = 7 /* same */
```


## 总结

我们用`javap`命令来查阅字节码，可以发现其实所涉及的知识非常多，比如本文并没有讨论字节码的详解结构，操作数栈的相关知识以及JVM的指令集，但这些无疑是详细了解JVM的必备知识点，需要阅读很多的材料和时间来研究。

## References：

- [javap](https://docs.oracle.com/en/java/javase/11/tools/javap.html#GUID-BE20562C-912A-4F91-85CF-24909F212D7F)
- [javap](https://docs.oracle.com/javase/8/docs/technotes/tools/windows/javap.html)
- [常用工具介绍](https://time.geekbang.org/column/article/12423)
- [Java字节码（基础篇）](https://time.geekbang.org/column/article/14794)
- [The ClassFile Structure](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-4.html#jvms-4.1)
- [全限定名、简单名称和描述符是什么东西？](https://mingshan.fun/2018/09/18/fully-qualified-name-simple-name-descriptor/)
- [The Java Virtual Machine Instruction Set](https://docs.oracle.com/javase/specs/jvms/se11/html/jvms-6.html#jvms-6.5)
- 深入理解Java虚拟机：JVM高级特性与最佳实践（第2版）
