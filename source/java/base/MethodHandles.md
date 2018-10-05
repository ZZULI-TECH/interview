# Method Handles(方法句柄)

在Java中，我们想在程序运行时调用其方法，可以用JDK提供的反射相关API来实现，代码如下：

```Java
Class clazz = Demo.class;
Method method = clazz.getMethod("studyHard", new Class[]{String.class});
Demo demo = clazz.newInstance();
method.invoke(demo, "哈哈");
```

这样的代码看起来也挺简洁，不过在JDK7之后，提供了`java.lang.invoke.MethodHandle`，它的功能与反射相似，下面是一个例子：

```Java
public class Demo {

    public String test1(int a, String b) {
        System.out.println("test1 -> " + a + b);
        return a + b;
    }

    public static String test2(int a, String b) {
        System.out.println("test2 -> " + a + b);
        return a + b;
    }

    public static void main(String[] args) throws Throwable {
        Class<?> clazz = Demo.class;
        MethodType signature = MethodType.methodType(String.class, int.class, String.class);
        MethodHandle mh = MethodHandles.lookup().findVirtual(clazz, "test1", signature);

        Object obj = clazz.getConstructor().newInstance();
        System.out.println(mh.bindTo(obj).invoke(1, "2"));
        System.out.println((String)mh.bindTo(obj).invokeExact(1, "2"));

        //--------------静态方法
        MethodHandle mh2 = MethodHandles.lookup().findStatic(clazz, "test2", signature);
        System.out.println(mh.bindTo(obj).invoke(1, "2"));
    }
}
```

从例子可以看出，我们先要通过`MethodType`来生成方法的签名，比如方法的参数类型，方法的返回值类型等。

```Java
MethodType signature = MethodType.methodType(String.class, int.class, String.class);
```

有了方法的签名，我们就可以利用方法签名、方法名称以及该方法所在的类来获取方法句柄（MethodHandle），代码如下：

```Java
 MethodHandle mh = MethodHandles.lookup().findVirtual(clazz, "test1", signature);
```

此时需要MethodHandles.lookup()静态方法来查找上下文对象，查找上下文对象有一些以“find”开头的方法，例如，findVirtual()、findSpecial()、findStatic()等。这些方法将会返回实际的方法句柄。

MethodHandle要先bindTo到某个对象实例上，然后调用invoke方法，传入参数就可以调用了。注意还有一个invokeExact方法，该方法与invoke方法的区别是方法参数、返回值匹配非常严格，调用时如果有数值参数隐式转换（如short转int/子类转父类）、装箱拆箱，会直接抛异常。比如函数返回值没有强制转换为String类型，就会抛异常：


```Java
Exception in thread "main" java.lang.invoke.WrongMethodTypeException: expected (int,String)String but found (int,String)Object
	at java.base/java.lang.invoke.Invokers.newWrongMethodTypeException(Unknown Source)
	at java.base/java.lang.invoke.Invokers.checkExactType(Unknown Source)
	at MethodHandles/me.mingshan.demo.Demo.main(Demo.java:26)
```

从目前接触到的API来看，似乎和以前用的反射区别并不大，其实不然，上面的特性包含在[JSR 292](https://jcp.org/en/jsr/detail?id=292)中，提供了比反射API更加强大的动态方法调用能力，并且新增了一个java虚拟机指令`invokedynamic`，`invokedynamic`指令通过引导方法（bootstrap method，BSM）机制来使用方法句柄。有关该指令更详细的信息可以参考Java虚拟机规范。


另外，在JDK9中新增了`Variable Handles`（变量句柄）相关功能，主要是用来取代`java.util.concurrent.atomic`包以及`sun.misc.Unsafe`类的功能，在Lookup类中，新增了`findVarHandle`方法来获取变量句柄，提供了各种细粒度的原子或有序性操作，更加安全和性能更高，毕竟`sun.misc.Unsafe`以后不推荐使用了，不安全。


参考：
- [JSR 292](https://jcp.org/en/jsr/detail?id=292)
- [Invokedynamic：Java的秘密武器](https://zhuanlan.zhihu.com/p/28124632)
- [Invokedynamic - Java’s Secret Weapon](https://www.infoq.com/articles/Invokedynamic-Javas-secret-weapon)