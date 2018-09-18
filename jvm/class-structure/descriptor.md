# 全限定名、简单名称和描述符是什么东西？

在看Class文件的结构时，我们会遇到这样几个概念，全限定名（Fully Qualified Name）、简单名称（Simple Name）和描述符（Descriptor），那么这些是什么东东呢？

首先来说全限定名，一个类的全限定名是将类全名的`.`全部替换为`/`，示例如下：

```
me/mingshan/cglib/SampleClass
```

简单名称是指没有类型和参数修饰的方法或字段名称，比如一个类的test()方法，它的简单名称是`test`。

那么描述符是什么呢？下面是JVM规范的定义：

> A descriptor is a string representing the type of a field or method. 

注意描述符的概念是针对Java字节码的。描述符的作用是用来描述字段的数据类型、方法的参数列表（包括数量、类型以及顺序）和返回值。在JVM规范中，定义了两种类型的描述符，Field Descriptors 和 Method Descriptors。

**Field Descriptors**

> A field descriptor represents the type of a class, instance, or local variable.

字段描述符包含BaseType、ObjectType、ArrayType三部分，对于基本数据类型(byte、char、double、float、int、long、short、boolean)都用一个大写字母来表示，而对象用字符L加对象的全限定名和`；`来表示，具体表示如下：

FieldType term | Type | Interpretation 
---|---|---
B	| byte	    | signed byte
C	| char      | Unicode character code point in the Basic Multilingual Plane, encoded with UTF-16
D	| double    |	double-precision floating-point value
F	| float     |	single-precision floating-point value
I	| int  	    | integer
J	| long	    | long integer
L ClassName ; |	reference |	an instance of class ClassName
S	| short     |	signed short
Z	| boolean   |	true or false
[	| reference | 	one array dimension

对于数组类型，每一个维度使用一个前置的`[`来描述，如一个定义为java.lang.String[][]类型的二维数组，将被记录为`[[Ljava/lang/String;`，一个double型数组`double[][][]`将被记录为`[[[D`。

**Method Descriptors**

> A method descriptor contains zero or more parameter descriptors, representing the types of parameters that the method takes, and a return descriptor, representing the type of the value (if any) that the method returns.

方法描述符用来描述方法，一个方法既有参数，又有返回值，那么在用描述符描述方法时，按照先参数列表，后返回值的顺序描述。参数列表按照参数的严格顺序放在一组小括号`()`内，如下：

```
( {ParameterDescriptor} ) ReturnDescriptor
```

注意如果返回值为void，那么就是一个大写字母`V`表示。

例如，一个方法的定义如下：

```
Object m(int i, double d, Thread t) {...}
```

那么它的描述符就是：

```
(IDLjava/lang/Thread;)Ljava/lang/Object;
```

又如方法的参数列表和返回值为空，如下：

```
void test()
```
它的描述符为：

```
()V
```

**最后上代码分析一波**

我们新建Test类，包含一个成员变量和方法。

```Java
package me.mingshan.cglib;

public class Test {
    private int a;

    public String inc(int b) {
        int c = a + b;
        return c + "666";
    }
}
```

利用`javap -c Test`来查看字节码，如下：

```
public class me.mingshan.cglib.Test {
  public me.mingshan.cglib.Test();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return

  public java.lang.String inc(int);
    Code:
       0: aload_0
       1: getfield      #2                  // Field a:I
       4: iload_1
       5: iadd
       6: istore_2
       7: iload_2
       8: invokedynamic #3,  0              // InvokeDynamic #0:makeConcatWithConstants:(I)Ljava/lang/String;
      13: areturn
}
```

可以看到`Field a:I`和`(I)Ljava/lang/String;`， 没什么错^_^


**参考：**

- [jls](https://docs.oracle.com/javase/specs/jls/se10/html/jls-6.html#jls-6.7)
- [JVM Descriptor](https://docs.oracle.com/javase/specs/jvms/se10/html/jvms-4.html#jvms-4.3)
- 深入理解Java虚拟机：JVM高级特性与最佳实践（第2版）