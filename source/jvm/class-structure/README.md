# 类文件结构

> 代码编译的结果从本地机器码转变为字节码，是存储格式发展的一小步，却是编程语言的一大步。

在Java平台中，实现语言无关性基础是虚拟机和存储格式。Java虚拟机不和Java等运行在其上的语言绑定，它只是与Class文件这种特殊的字节码文件所关联，每一个类文件包含单个类、接口或模块的定义。

## ClassFile的structure

Class文件由一组8位字节为基础的二进制流。在最新的Java虚拟机规范中，Class文件由叫做ClassFile的structure组成。class文件结构在JVM占有重要地位，具体位于第四章，标题是“The class File Format”，总共五百多页的虚拟机规范，类文件结构就写了三百多页，是不是很可怕^_^

那么这个东西长什么样呢？如下：

```
ClassFile {
    u4 magic;
    u2 minor_version;
    u2 major_version;
    u2 constant_pool_count;
    cp_info constant_pool[constant_pool_count-1];
    u2 access_flags;
    u2 this_class;
    u2 super_class;
    u2 interfaces_count;
    u2 interfaces[interfaces_count];
    u2 fields_count;
    field_info fields[fields_count];
    u2 methods_count;
    method_info methods[methods_count];
    u2 attributes_count;
    attribute_info attributes[attributes_count];
}

```

咦？怎么这么像C语言的结构体呢，说的没错，虚拟机规范这是这么描述的(pseudostructures 伪结构)，刚才说了，它的真实结构是一组以8位字节为基础单位的二进制流，包含多个数据项，各个数据项严格按照顺序紧凑的排列在Class文件中（后面再进行分析）。下面我们来看看这个伪结构包含了什么。

从上面的伪结构来看，u2、u4是什么鬼？后面的看着像是属性，那么u2、u4似乎是类型的样子，呃，，没错，这种东西被称为数据类型，而且在**伪结构中只有两种数据类型，无符号数（unsigned quantity）和表（table）**。

无符号数属于基本的数据类型，u2、u4分别代表2个字节、4个字节的无符号数。无符号数可以用来描述数字、索引引用、数量值或者按照UTF-8编码的字符串。

那么`cp_info`、`field_info`、`method_info`和`attribute_info`就是所谓的table了，可以看出都是以`_info`结尾，这些存些什么数据呢？在一个类中，总有字段吧，那么就存到`field_info`里面，总有些方法吧，存到`method_info`，或许还会有常量什么的，存到`cp_info`里面，在Class文件、字段表、方法表都可以携带自己的attribute_info，用于描述某些场景专有的信息。

说完了伪结构的数据类型，uX和*_info后面那些类似字段名称的东西是什么意思呢？在虚拟机规范中，被称作`item`，原话这么说的：

>  the contents of the structures describing the class file format are
referred to as items

好吧，不知道叫啥，就叫item吧，大家知道就行了(￣.￣)。

在介绍上面的`items`之前，我们先来一个简单的Java类编译后的Class的十六进制文件，源代码如下：

```Java
public class Demo {
    private int i;

    public int inc() {
        return i + 1;
    }
}
```

用`javac`编译后，我选择Hexpad这个编辑器来打开class文件，如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/class_16.png?raw=true)

## magic与class文件的版本

**magic**

每个Class文件的头四个字节被称为魔数（Magic Number），默认值为`0xCAFEBABE`，用于确定一个文件是否能被JVM接受。

**minor_version, major_version**

紧接着四个字节就是`minor_version`和`major_version`，看着像是版本号的意思，没错，这四个字节存储的是Class文件的版本号，第5和6个字节存储的是次版本号（Minor Version），第7个和8个字节存储的是主版本号（Major Version）。由上面的图片可知，`minor_version`为0x0000，`major_version`为0x0036，转为是十进制为54，即我用JDK10编译的。下面为各个版本JVM能接受Class文件版本号的范围：

Java SE | class file format version range
---     |        ---
1.0.2   | 45.0 ≤ v ≤ 45.3
1.1     | 45.0 ≤ v ≤ 45.65535
1.2     | 45.0 ≤ v ≤ 46.0
1.3     | 45.0 ≤ v ≤ 47.0
1.4     | 45.0 ≤ v ≤ 48.0
5.0     | 45.0 ≤ v ≤ 49.0
6       | 45.0 ≤ v ≤ 50.0
7       | 45.0 ≤ v ≤ 51.0
8       | 45.0 ≤ v ≤ 52.0
9       | 45.0 ≤ v ≤ 53.0
10      | 45.0 ≤ v ≤ 54.0


## constant_pool_count，constant_pool[]

**constant_pool_count**

接着主版本号之后是常量池容量计数值（constant_pool_count），由于常量池中常量的数量是不固定的，所以需要一个u2类型的数据来统计。注意该值计数从1开始而不是0。如上图所示，constant_pool_count值为0x0013，转为十进制为19，这就代表常量池中有18项常量，索引值范围为1~18（1 ~ constant_pool_count - 1）。

可能此时会有疑问，为啥我一个常量没定义，常量池这么多常量呢？有这个疑问就对了，原因是常量池中不仅存放`static final`修饰的字段，这个被称作字面量（Literal），还包括符号引用（Symbolic References），在虚拟机规范中是这样写的：

> constants, class and interface names, field names, and other constants that are
referred to within the ClassFile structure and its substructures. 

符号引用具体包括哪些呢？如下：

- 类和接口的全限定名
- 字段的名称和描述符
- 方法的名称和描述符

## access_flags

在常量池结束之后，紧接着2个字节表示访问标志（access_flags），这个标志用于识别一些类和接口层次的访问信息。具体列表如下：

Flag Name      |  Value  |  Interpretation
---            |  ---    |   ---
ACC_PUBLIC     | 0x0001  | Declared public; may be accessed from outside its package.
ACC_FINAL      | 0x0010  | Declared final; no subclasses allowed.
ACC_SUPER      | 0x0020  | Treat superclass methods specially when invoked by the invokespecial instruction.
ACC_INTERFACE  | 0x0200  | Is an interface, not a class.
ACC_ABSTRACT   | 0x0400  | Declared abstract; must not be instantiated.
ACC_SYNTHETIC  | 0x1000  | Declared synthetic; not present in the source code.
ACC_ANNOTATION | 0x2000  | Declared as an annotation type.
ACC_ENUM       | 0x4000  | Declared as an enum type.
ACC_MODULE     | 0x8000  | Is a module, not a class or interface.

**ACC_MODULE**

需要注意ACC_MODULE，这个是新增的，ACC_MODULE标志表示这个Class文件定义了一个模块，而不是一个类或接口。

**ACC_SUPER**

在jdk1.02之前，有个叫invokenonvirtual的指令。在1.02后，这个指令被改名叫做invokespecial。invokenonvirtual的时候没有invokespecial那样只允许调用superclass、private方法或<init>方法。于是在所有的1.02后的class 都必须设置ACC_SUPER这个标志，来表明强加给invokespecial的新的约束必须要被遵守。

## this_class, super_class, interfaces_count, interfaces[]

this_class（类索引）、super_class（父类索引）都是一个u2类型的数据，而interfaces（接口索引集合）是一组u2类型的数据集合。Class文件由这三项来确定这个类的继承关系。

**this_class（类索引）和 super_class（父类索引）**

类索引和父类索引表示，它们各自指向一个类型为CONSTANT_Class_info的类描述符常量，通过CONSTANT_Class_info类型的常量中的索引值可以找到定义在CONSTANT_Utf8_info类型的常量的全限定名字符串。大致如下：

```
this_class  ->  CONSTANT_Class_info  -> CONSTANT_Utf8_info
```

**interfaces_count（接口计数器）**

这个项的值表示当前类或接口的直接超接口的数量。

**interfaces[] （接口表）**

就是这个类所实现的接口。里边同样是常量池的索引值。接口表里边的顺序和源代码的接口顺序是一致的。


## fields_count，fields[]

field_info（字段表）用于描述接口或者类中声明的变量。fields表中只包含当前类或接口中的字段，不包含超类或super 接口中的字段，也不包括在方法内部声明的局部变量。

## methods_count，methods[]

method_info用来表示当前类或接口中的某个方法的完整描述。

## attributes_count, attributes[]

在Class文件、字段表、方法表都可以携带自己的attribute_info，用于描述某些场景专有的信息。

参考：

- [The Java® Virtual Machine Specification (Java SE 10 Edition)](https://docs.oracle.com/javase/specs/jvms/se10/jvms10.pdf)
- 深入理解Java虚拟机：JVM高级特性与最佳实践（第2版）
- [来自JVM的一封ClassFile介绍信](https://mp.weixin.qq.com/s/e3_5okrgFTctBTikRuJvhA)