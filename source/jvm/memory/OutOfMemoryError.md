Java虚拟机定义了程序执行期间使用的各种运行时数据区域。如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/java_memory.png?raw=true)

在Java虚拟机规范的描述中，虚拟机栈、本地方法栈和程序计数器是线程私有的，而像堆、方法区(Jdk8之前)、元空间（JDK8之后）属于所有线程共享区域。除了程序计数器外，虚拟机内存的其他几个运行时区域都有可能发生OutOfMemoryError(OOM)异常的可能，Java doc对OutOfMemoryError的描述是没有空闲内存，并且垃圾回收器也无法提供更多内存。

对内存区域发生OOM的情况分四个部分简单介绍：

**Java堆溢出**

>  If a computation requires more heap than can be made available by the automatic storage management system, the Java Virtual Machine throws an OutOfMemoryError.

Java堆用于存储对象实例，只要不断地创建对象，并且保证GC Root到对象间有可达路径来避免垃圾回收机制清除这些对象，那么在对象数量达到最大堆内存的容量限制后就会发生OOM。总结来说，例如可能存在内存泄露问题；也有可能堆大小设置不合理，比如要处理比较多的数据，但没有显示指定JVM堆大小或设定值偏小；或者出现JVM处理引用不及时，导致堆积，内存无法释放。

通过设置JVM参数最小堆内存-Xms， 最大堆内存-Xmx（将两者设置一样避免堆自动扩展）可以模拟堆溢出。如果出现此异常，需要分析是内存泄露和内存溢出，采取相应的手段来避免堆溢出。

测试代码：

```Java
/**
 * 堆内存泄露
 * 
 * VM Args: -Xms20m -Xmx20m -XX:+HeapDumpOnOutOfMemoryError
 * 
 * @author mingshan
 *
 */
public class HeapOOM {

    static class OOMObject {

    }

    public static void main(String[] args) {
        List<OOMObject> list = new ArrayList<>();

        while (true) {
            list.add(new OOMObject());
        }
    }
}
```

异常信息：


```
java.lang.OutOfMemoryError: Java heap space
```

**虚拟机栈和本地方法栈溢出**

> - If the computation in a thread requires a larger Java Virtual Machine stack than is permitted, the Java Virtual Machine throws a **StackOverflowError**.
> - If Java Virtual Machine stacks can be dynamically expanded, and expansion is attempted but insufficient memory can be made available to effect the expansion, or if insufficient memory can be made available to create the initial Java Virtual Machine stack for a new thread, the Java Virtual Machine throws an **OutOfMemoryError**.

关于虚拟机栈和本地方法栈，在Java虚拟机规范中描述了两种异常：

- 如果线程请求的栈深度大于虚拟机所允许的最大深度，将抛出StackOverflowError异常。
- 如果虚拟机在扩展栈时无法申请到足够的内存空间，则抛出OutOfMemoryError异常异常。

每个线程栈的大小，默认1M，我们可以调小JVM参数`-Xss`来模拟内存溢出，代码如下：

```Java
/**
 * Java 虚拟机栈内存溢出
 * 
 * VM Args: -Xss128k（减少栈的容量）
 * 
 * @author mingshan
 *
 */
public class JavaVMStackSOF {
    private int length = 0;

    private void recursion() {
        length++;
        recursion();
    }

    public static void main(String[] args) {
        JavaVMStackSOF sof = new JavaVMStackSOF();

        try {
            sof.recursion();
        } catch (Throwable e) {
            System.out.println("length = " + sof.length);
            e.printStackTrace();
        }
    }
}
```


**方法区和运行时常量池溢出**
>  If memory in the method area cannot be made available to satisfy an allocation request, the Java Virtual Machine throws an OutOfMemoryError.

在JDK8之前，方法区是所有线程共享的一块内存区域，用于存储已被虚拟机加载的类信息、常量、静态变量等信息。

运行时常量池是方法区的一部分，在分析Class类文件结构中，我们会知道Class文件除了有类的版本、字段、方法、接口等描述信息之外，还有一项是常量池（constant_pool），存放编译期生成的字面量及符号引用。

所以在方法区中，如果在运行时动态生成类的情况下，可能会造成方法区的OOM，intern在运行时字符串缓存占用太多的空间，也会出现OOM。下面是调用`String.intern()`发生OOM：

```Java
/**
 * 运行时常量池内存溢出(jdk1.8下 不会报错)
 * 
 * VM Args: -XX:PermSize=10M -XX:MaxPermSize=10M
 * 
 * @author mingshan
 *
 */
public class RuntimeConstantPoolOOM {
    
    public static void main(String[] args) {
        List<String> list = new ArrayList<String>();
        int i = 0;
        while (true) {
            list.add(String.valueOf(i++).intern());
        }
    }
}
```

异常信息：


```
java.lang.OutOfMemoryError: PermGen space
```

**元空间内存溢出**

从JDK1.8之后，移除了方法区，同时添加了元空间(Metaspace)，由于元空间并不在虚拟机中，而是使用本地内存，因此，默认情况下，元空间的大小仅受本地内存限制，但可以控制JVM相关参数来控制：

> -XX:MetaspaceSize，初始空间大小
>
> -XX:MaxMetaspaceSize，最大空间

我们可以控制元空间的最大值来模拟OOM，利用CGLIB不断动态生成代理类，注意在JDK8以后版本运行。

```Java
/**
 * JDK1.8 元空间 内存溢出
 * VM Args: -XX:MaxMetaspaceSize=10m
 * @author mingshan
 *
 */
public class JavaMethodAreaOOM {
    public static void main(String[] args) {
        while (true) {
            Enhancer enhancer = new Enhancer();
            enhancer.setSuperclass(OOMObject.class);
            enhancer.setUseCache(false);
            enhancer.setCallback(new MethodInterceptor() {
   
                @Override
                public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
                    return proxy.invokeSuper(obj, args);
                }
            });
            enhancer.create();
        }
    }
 
    static  class  OOMObject{}
}

```

异常信息：

```
java.lang.OutOfMemoryError: Metaspace
```

**本机直接内存溢出**

直接内存并不虚拟机运行时内存区域的一部分，虽然不受Java虚拟机控制，但是还是受本地总内存的限制（包括RAM及SWAP等），也会出现OOM。

NIO中提供了DirectBuffer来直接分配堆外内存，避免在Java堆和Native堆中来回复制数据，减少内存的拷贝和上下文的切换，缺点是易发生OOM。

下面直接地调用Unsafe实例分配内存，模拟OOM。

```Java
/**
 * 本机直接内存溢出
 * 
 * VM Args: -Xmx20M -XX:MaxDirectMemorySize=10M
 * 
 * @author mingshan
 *
 */
public class DirectMemoryOOM {
    private static final int SIZE = 1024 * 1024;

    public static void main(String[] args) throws IllegalArgumentException, IllegalAccessException {
        Field unsafeField = sun.misc.Unsafe.class.getDeclaredFields()[0];
        unsafeField.setAccessible(true);
        sun.misc.Unsafe unsafe = (sun.misc.Unsafe) unsafeField.get(null);
        while (true) {
            unsafe.allocateMemory(SIZE);
        }
    }
}
```

**参考：**

- [OutOfMemoryError API](https://docs.oracle.com/javase/10/docs/api/java/lang/OutOfMemoryError.html)
- 周志明，深入理解Java虚拟机:JVM高级特性与最佳实践（第2版）
- 杨晓峰，谈谈JVM内存区域的划分，哪些区域可能发生OutOfMemoryError?
