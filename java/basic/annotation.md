> 本文转载自 [Java:Annotation(注解)--原理到案例](https://www.jianshu.com/p/28edf5352b63)

------

# 1. Annotation为何而来

## What：Annotation干嘛的

JDK5开始，java增加了对元数据(MetaData)的支持，怎么支持？答：通过Annotation(注解）来实现。Annotation提供了为程序元素设置元数据的方法。元数据：描述数据的数据。

Annotation可以为哪些程序元素设置元数据呢？ Annotation提供了一种为程序元素设置元数据的方法，包括修饰包、类、构造器、方法、成员变量、参数、局部变量的声明。元数据的信息被存储在Annotation的“name=value”对中。

Annotation怎么实现设置元数据？程序如何读取这些元数据？答：元数据的信息被存储在Annotation的“name=value”对中。Annotation是一个接口，程序可以通过反射来获取指定程序元素的Annotation对象，然后通过Annotation对象来取得注解里的元数据。

Annotation不影响程序代码的执行，无论增加、删除Annotation，代码都始终如一的执行。如果希望让程序中的Annotation在运行时起一定的作用，只有通过某种配套工具对Annotation中的信息进行访问和处理。jdk7之前访问和处理Annotation的工具统称APT（Annotation Processing Tool)(jdk7后就被废除了），jdk7及之后采用了JSR 269 API。相关原因官方说明 、 原因

结论：java想给程序元素提供元数据支持，于是创造了Annotation来实现这个目标。

**注解的使用案例**


```Java
@Entity
public class Book {
    @Id
    @GeneratedValue(strategy=GenerationType.AUTO)
    private Long id;
}
```


## Why:为什么要提供元数据支持

**通过Annotation设置的元数据在什么时候被读取？读取能干嘛？**答：Annotation就像代码里的特殊标记，这些标记可以在编译、类加载、运行时被读取。读取到了程序元素的元数据，就可以执行相应的处理。通过注解，程序开发人员可以在不改变原有逻辑的情况下，在源代码文件中嵌入一些补充信息。代码分析工具、开发工具和部署工具可以通过解析这些注解获取到这些补充信息，从而进行验证或者进行部署等。

比如：上面代码，读取到id变量上面有`@GeneratedValue(strategy=GenerationType.AUTO)`注解，并且注解提供了`strategy=GenerationType.AUTO`这样的元数据信息，那么程序就会为id设置一个自增的值。读取到Book类上面有一个`@Entity`注解，程序就会认为这是一个持久化类，就会做一些持久化的处理。

**不使用Annotation怎么为程序元素提供元数据**
看来元数据在编程中还是能起到很大的作用的，如果没有元数据还真的不好办，比如上面代码中id成员变量的元数据是“`strategy=GenerationType.AUTO`即采用自增策略”，如果没有这个元数据支持，程序中怎么才能为id赋一个自增的值呢？忧愁。

**提供元数据只有通过Annotation才可以吗？**答：不是，通过配置文件也可以。比如还是上面代码id这个变量，我现在想为它添加描述数据即元数据，内容是：采用自增策略。这个信息通过Annotation来实现就是上面代码的样子。通过配置文件实现的话，比如采用xml格式配置文件。那么我可以在文件中配置`<property-MetaData class="Book " property="id" metadata="auto">`。哈哈！比如我就定一个规则：class表示类，property表示类的某个属性，metadata是属性的元数据。程序在启动时通过读取这个文件的信息就可以知道id变量的元数据了，知道元数据就可以做相应处理了。当然，通过配置文件还是没有注解方便。

-----

知道元数据在编程中的重要性和提供元数据的方法Annotation了，那么就来学习Annotation吧。

提示：有些注解只是为了防止我们犯低级错误，通过这些注解，让编译器在编译期就可以检查出一些低级错误，对于这些注解，可以加或者不加，当然还有很多其他注解都是起辅助编程作用。但是有一些注解的作用很重要，不加的话就实现不了一些功能，比如，数据持久化操作中，通过@Entity注解来标识持久化实体类，如果不使用该注解程序就识别不了持久化实体类。

# 2. 基本Annotation

**Java提供了5个基本的Annotation的用法，在使用Annotation时要在其前面增加@符号。**

- @Override ：限定重写父类方法

- @Deprecated：表示已过时

- @SuppressWarnings：抑制编译警告

- @SafeVarargs (java7新增）：去除“堆污染”警告

- @Functionlnterface （java8新增）：修饰函数式接口

- @Override ：用来指定方法覆载的，它可以强制一个子类必须覆盖父类的方法。写在子类的方法上，在编译期，编译器检查这个方法，保证父类包含被该方法重写的方法，否则编译出错。该注解只能修饰方法，在编译期被读取。

- @Deprecated：用于表示某个程序元素（类、方法等）已过时。编译时读取，编译器编译到过时元素会给出警告。

- @SuppressWarnings：抑制编译警告，被该注解修饰的程序元素（以及该程序元素中的所有子元素）取消显示指定的编译警告。
比如：取消如果程序使用没有泛型限制的集合会引起编译器警告，为了避免这种警告使用该注解。
    - unchecked异常：运行时异常。是RuntimeException的子类，不需要在代码中显式地捕获unchecked异常做处理。Java异常

```Java
@SuppressWarnings(value="unchecked")
public class SuppressWarningTest {
   public static void main(String[] args) {
       List<String> myList = new ArrayList();
   }
}
@SuppressWarnings("deprecation")   //取消过时警告
public HibernateTemplate getHt() {
    return ht;
}
```
- @SafeVarargs (java7新增）：java7的“堆污染”警告与@SafeVarargs
[堆污染](https://blog.csdn.net/palmtale/article/details/9302711)：把一个不带泛型的对象赋给一个带泛型的变量是，就会发生堆污染。
例如：下面代码引起堆污染，会给出警告

```Java
List l2 = new ArrayList<Number>();
List<String> ls = l2;
```

**3中方式去掉这个警告**
> - 使用注解@SafeVarargs修饰引发该警告的方法或构造器。
> - 使用@SuppressWarnings("unchecked") 修饰。
> - 使用编译器参数命令：-Xlint:varargs

- @Functionlnterface （java8新增）：修饰函数式接口
**使用该注解修饰的接口必须是函数式接口，不然编译会出错。那么什么是函数式接口？**答：如果接口中只有一个抽象方法（可以包含多个默认方法或static方法），就是函数式接口。如：

```Java
@Functionlnterface
public interface FunInterface {
  static void foo() {
   System.out.println("foo类方法");
  }
  default void bar() {
   System.out.println("bar默认方法");
  }
  void test();//只定义一个抽象方法，默认public
}
```
# 3. JDK的元Annotation
元注解(Meta Annotation)：和元数据一样，修饰注解的注解。
java提供了6个元注解（Meta Annotation)，在`java.lang.annotation`中。其中5个用于修饰其他的Annonation定义。而`@Repeatable`专门用于定义Java8新增的重复注解。所以要定义注解必须使用到5个元注解来定义。

## @Retention（英文：保留）

用于指定被修饰的Annotation可以保留多长时间，只能修饰Annotation定义。@Retention包含一个RetentionPolicy类型的value成员变量，使用@Retention必须为该value成员变量指定值。value成员变量的值有3个选择：


> - RetentionPolicy.CLASS:编译器将把Annotation记录在class文件中。当运行java程序时，JVM不可获取Annotation信息。（默认值）
> - RetentionPolicy.RUNTIME:编译器将把Annotation记录在class文件中。当运行java程序时，JVM也可获取Annotation信息，程序可以通过反射获取该Annotation信息
> - RetentionPolicy.SOURCE:Annotation只保留在源代码中（.java文件中），编译器直接丢弃这种Annotation。

**案例：**

```Java
//定义下面的Testable Annotation保留到运行时，也可以使用value=RetentionPolicy.RUNTIME
@Retention(RetentionPolicy.RUNTIME)
public @interface Testable{}
```

## @Target ( 目标)

用于指定被修饰的Annotation能用于修饰哪些程序单元，只能修饰Annotation定义。它包含一个名为value的成员变量，取值如下：

> - @Target(ElementType.ANNOTATION_TYPE)：指定该该策略的Annotation只能修饰Annotation.
> - @Target(ElementType.TYPE) //接口、类、枚举、注解 
> - @Target(ElementType.FIELD) //成员变量（字段、枚举的常量） 
> - @Target(ElementType.METHOD) //方法
> - @Target(ElementType.PARAMETER) //方法参数
> - @Target(ElementType.CONSTRUCTOR) //构造函数
> - @Target(ElementType.LOCAL_VARIABLE)//局部变量
> - @Target(ElementType.PACKAGE) ///修饰包定义
> - @Target(ElementType.TYPE_PARAMETER) //java8新增，后面Type Annotation有介绍
> - @Target(ElementType.TYPE_USE) ///java8新增，后面Type Annotation有介绍

**案例：**

```Java
@Target(ElementType.FIELD)
public @interface ActionListenerFor{}
```

## @Documented

>用于指定被修饰的Annotation将被javadoc工具提取成文档。即说明该注解将被包含在javadoc中。

## @Inherited

用于指定被修饰的Annotation具有继承性。即子类可以继承父类中的该注解。---》注解@WW被元注解@Inherited修饰，把@WW添加在类Base上，则Base的所有子类也将默认使用@WW注解。

# 4. 自定义注解
使用`@interface`关键字，注解放在修饰元素的上面

## 4.1 一个简单的注解

```Java
//定义一个简单的注解Test
public @interface Test{}

默认情况下，Annotation可以修饰任何程序元素:类、接口、方法等。

@Test
public class MyClass{

}
```

## 4.2 带成员变量的注解

以无形参的方法形式来声明Annotation的成员变量，方法名和返回值定义了成员变量名称和类型。使用default关键字设置初始值。没设置初始值的变量则使用时必须提供，有初始值的变量可以设置也可以不设置。

```Java
//定义带成员变量注解MyTag
@Rentention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface MyTag {
  //定义两个成员变量，以方法的形式定义
  String name();
  int age() default 32;
}

//使用
public class Test {
  @MyTag(name="liang")
  public void info(){}
}
```

## 4.3 结论

没带成员变量的Annotation被称为标记，这种注解仅利用自身的存在与否来提供信息，如@Override等。包含成员变量的Annotation称为元数据Annotation,因为他们提供更多元数据。

## 4.4 提取Annotation信息

使用Annotation修饰了类、方法、成员变量等程序元素之后，这些Annotation不会自己生效，必须由开发者通过API来提取并处理Annotation信息。

Annotation接口是所有注解的父接口。

> 思路：通过反射获取Annotation，将Annotation转换成具体的注解类，在调用注解类定义的方法获取元数据信息。

**获取Annotation**

`AnnotatedElement`接口(`java.lang.reflect`反射包中)代表程序中可以接受注解的程序元素。即所有可以接受注解的程序元素都会实现该接口。而该接口就提供了获取Annotation的方法，它的所有实现类也便拥有了这些方法。常见的实现类：

 > - Class:类定义。
   
 > - Constructor:构造器定义
   
 > - Field:类的成员变量定义
   
 > - Method:类的方法定义。
   
 > - Package:类的包定义。

由此可见，`AnnotatedElement`接口的实现类都是一些反射技术设计到的类，所以访问Annotation信息也是通过反射技术来实现的。

`java.lang.reflect`包下还包含实现反射功能的工具类，java5开始，`java.lang.reflect`包提供的反射API增加了读取允许Annotation的能力。但是，只有定义Annotation时使用了`@Rentention(RetentionPolicy.RUNTIME)`修饰，该Annotation才会在运行时可见，JVM才会在装载``.class`文件时读取保存在class文件中的Annotation。

**AnnotatedElement接口获取Annotation信息的方法：**

```Java
<T extends Annotation> T getAnnotation(Class<T> annotationClass)：返回修饰该程序元素的指定类型的注解，不存在则返回 null。

<T extends Annotation> T getDeclaredAnnotation(Class<T> annotationClass)：返回直接修饰该程序元素的指定类型的注解，不存在则返回 null。 （java8新增）

Annotation[] getAnnotations()：返回此元素上存在的所有注解。

Annotation[] getDeclaredAnnotations()：返回直接存在于此元素上的所有注解。

boolean isAnnotationPresent (Class< ? extends Annotation> annotationClass)：如果指定类型的注解存在于此元素上，则返回 true，否则返回 false。
java8新增了重复注解功能，所以下面两个方法在java8之后才有：

<T extends Annotation> T[] getAnnotationsByType(Class<T> annotationClass)：返回修饰该程序元素的指定类型的多个注解，不存在则返回 null。

<T extends Annotation> T[] getDeclaredAnnotationsByType(Class<T> annotationClass)：返回直接修饰该程序元素的指定类型的多个注解，不存在则返回 null。
```

**案例**

需求：获取Test类的info方法上的所有注解，并打印出来，如果包含MyTag注解，则再输出MyTag注解的元数据。

实现：正如我们所知，仅在程序中使用注解是不起任何作用的，必须使用注解处理工具来处理程序中的注解。下面就写一个注解处理类。处理注解的思路如下：通过反射获取Test的类描述类Class，然后在获取其info方法描述类`Method`，因为`Method`实现了`AnnotatedElement`接口，所以调用`getAnnotations`方法获取所有注解，再遍历打印。

**MyTag注解处理器**

```Java
public class MyTagAnnotationProcessor {
    public static void process(String className) throws ClassNotFoundException{
        try {
             Class clazz =Class.forName(className);
             Annotation[] aArray= clazz.getMethod("info").getAnnotations();
             for( Annotation an :aArray){
                 System.out.println(an);//打印注解
                 if( an instanceof MyTag){
                     MyTag tag = (MyTag) an;
                     System.out.println("tag.name():"+tag.name());
                     System.out.println("tag.age():"+tag.age());
                 }
             }
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (SecurityException e) {
            e.printStackTrace();
        }
    }
}
```

**场景测试**

```Java
public static void main(String[] args) {
    try {
        MyTagAnnotationProcessor.process("annotation.Test");
    } catch (ClassNotFoundException e) {
        e.printStackTrace();
    }
}
```
**测试结果**

```
@annotation.MyTag(age=25, name=liang)
tag.name():liang
tag.age():25
```
# 5. Java8新增的重复注解

在java8以前，同一个程序元素只能使用一个相同类型的Annotation。如下代码是错误的。

```Java
// 代码错误，不可以使用相同注解在一个程序元素上。
@MyTag(name="liang")
@MyTag(name="huan")
public void info(){
}
```

## 5.1 java8之前实现思路

要想达到使用多个注解的目的，可以使用注解”容器“：其实就是新定义一个注解DupMyTag，让这个DupMyTag 注解的成员变量value的类型为注解MyTag数组。这样就可以通过注解DupMyTag 使用多个注解MyTag了。换个思路实现，只是书写形式不一样而已。

操作步骤2步：
1. 编写需要重复的注解`@MyTag`，上面定义过了。
2. 编写”容器“注解DupMyTag 。

如下DupMyTag 注解：

```Java
@Retention(RetentionPolicy.RUNTIME)
@Target(value=ElementType.METHOD)
public @interface DupMyTag {
    //成员变量为MyTag数组类型
    MyTag[] value();
}
```

使用`@DupMyTag`，为`@DupMyTag` 注解的成员变量设置多个`@MyTag`注解，从而达到效果。

```Java
// 代码正确，换个思路实现，在同一个程序元素上使用了多个相同的注解MyTag
@DupMyTag ({ @MyTag(name="liang"),@MyTag(name="huan",age=18)})
public void info() {
}
```

打印注解输出内容如下：
```
@annotation.DupMyTag(value=[@annotation.MyTag(age=25, name=liang), @annotation.MyTag(age=18, name=huan)])
```

结论：通过新定义一个容器注解，来实现使用多个相同注解的目的，只是书写形式不能达到期待效果而已，要想书写形式能达到期待效果需要使用java8之后的`@Repeatable`元注解。

注：”容器“注解的保留期Retention必须比它所包含注解的保留期更长，否则编译报错

## 5.2 java8之后

java8之后新增了`@Repeatable`元注解，用来开发重复注解，其有一个必填Class类型变量value。

同样，还是需要新定义一个注解`@DupMyTag`。和上面定义的一样。不一样的是`@Repeatable`元注解需要加在`@MyTag`上，value值设置为`DupMyTag.class`，开发便完成。

操作步骤2步：
1. 编写需要重复的注解@MyTag，如下。
2. 编写”容器“注解DupMyTag，上面定义过了

如下：通过@Repeatable定义了一个重复注解@MyTag。

```Java
//定义带成员变量注解MyTag
@Repeatable(DupMyTag.class)
@Rentention(RetentionPolicy.RUNTIME)
@Method(ElementType.METHOD)
public @interface MyTag {
  //定义两个成员变量，以方法的形式定义
  String name();
  int age() default 32;
}
```

使用,书写形式达到了理想效果，当然上面的形式依然可以使用

```Java
@MyTag(name="liang")
@MyTag(name="huan",age =18)
public void info() {
}
//两种形式都可以
@DupMyTag ({ @MyTag(name="liang"),@MyTag(name="huan",age=18)})
public void info() {
}
```

原理：系统依然还是将两个MyTag注解作为DupMyTag的value成员变量的数组元素，只是书写形式多了一种而已

**获取注解方法**
上面代码通过`getDeclaredAnnotationsByType(MyTag.class)和getDeclaredAnnotation(DupMyTag.class)`两个方法都能获取到值，只是结果不一样如下：

```
@annotation.MyTag(age=25, name=liang)
@annotation.MyTag(age=18, name=huan)
@annotation.DupMyTag(value=[@annotation.MyTag(age=25, name=liang), @annotation.MyTag(age=18, name=huan)])
```

# 6. Java8新增的Type Annotation注解

## 6.1 介绍

目的：以前的注解只能用在`包、类、构造器、方法、成员变量、参数、局部变量`。如果想在：创建对象（通过new创建）、类型转换、使用`implements`实现接口、使用`throws`声明抛出异常的位置使用注解就不行了。而`Type Annotation`注解就为了这个而来。

抽象表述： java为`ElementType`枚举增加了`TYPE_PARAMETER`、`TYPE_USE`两个枚举值。`@Target(TYPE_USE)`修饰的注解称为`Type Annotation`(类型注解），`Type Annotation`可用在任何用到类型的地方。*

## 6.2 案例

**定义一个类型注解NotNull**

```Java
@Target(ElementType.TYPE_USE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface NotNull {
    String value() default "";
}
```

**使用**

```Java
//implements实现接口中使用Type Annotation
public class Test implements @NotNull(value="Serializable") Serializable {
    
        //泛型中使用Type Annotation  、   抛出异常中使用Type Annotation
    public  void foo(List<@NotNull String> list) throws @NotNull(value="ClassNotFoundException") ClassNotFoundException {
        //创建对象中使用Type Annotation
        Object obj =new @NotNull String("annotation.Test");
        //强制类型转换中使用Type Annotation
        String str = (@NotNull String) obj;
    }
}
```

**编写处理注解的处理器。**

java8提供AnnotatedType接口，该接口用来代表被注解修饰的类型。该接口继承AnnotatedElement接口。同时多了一个public Type getType()方法，用于返回注解修饰的类型。

以下处理器只处理了类实现接口处的注解和throws声明抛出异常处的注解。

``` Java
/**
 * 类说明 NotNull注解处理器，只处理了implements实现接口出注解、throws声明抛出异常出的注解。
 */
public class NotNullAnnotationProcessor {
    
    public static void process(String className) throws ClassNotFoundException{
        try {
            Class clazz =Class.forName(className);
            //获取类继承的、带注解的接口
            AnnotatedType[] aInterfaces =clazz.getAnnotatedInterfaces();
            print(aInterfaces);
            
            Method method = clazz.getMethod("foo");
            //获取方法上抛出的带注解的异常
            AnnotatedType[] aExceptions =method.getAnnotatedExceptionTypes();
            print(aExceptions);
            
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (SecurityException e) {
            e.printStackTrace();
        }
    }
    /**
     * 打印带注解类型
     * @param array
     */
    public static void print(AnnotatedType[] array) {
        for (AnnotatedType at : array) {
            Type type =at.getType();//获取基础类型
            Annotation[] ans =at.getAnnotations();//获取注解
            //打印类型
            System.out.println(type);
            //打印注解
            for(Annotation an : ans) {
                System.out.println(an);
            }
            System.out.println("------------");
        }
    }
}
```

**打印结果**

```
interface java.io.Serializable
@annotation.NotNull(value=Serializable)
------------
class java.lang.ClassNotFoundException
@annotation.NotNull(value=ClassNotFoundException)
------------
```

# 参考文章：

- [Java注解(3)-注解处理器（编译期|RetentionPolicy.SOURCE）](https://blog.zenfery.cc/archives/78.html)
- [jar 打包命令详解](https://blog.csdn.net/marryshi/article/details/50751764)
- [如何用javac 和java 编译运行整个Java工程](https://blog.csdn.net/huagong_adu/article/details/6929817)
- [深入理解Java：注解（Annotation）自定义注解入门](http://www.cnblogs.com/peida/archive/2013/04/24/3036689.html)
- [深入理解Java：注解（Annotation）--注解处理器](http://www.cnblogs.com/peida/archive/2013/04/26/3038503.html)