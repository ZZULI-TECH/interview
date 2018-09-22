# JDK动态代理（JDK8之前）

平时接触动态代理比较多，例如Spring等框架如何使用了动态代理经常听到，本文主要介绍JDK动态代理的基本实现原理(JDK8版本)，当了解了这些实现细节后，再次使用动态代理就会十分容易和清楚，知其然也知其所以然。

### 动态代理Demo

先来看一下利用JDK动态代理写的Demo，下面会根据这个Demo进行分析

首先定义一个接口

```Java
public interface Calculator {

    int add(int a, int b);
    int sub(int a, int b);
    int mul(int a, int b);
    int div(int a, int b);
}

```

然后是上面接口的实现类

```Java
public class CalculatorImpl implements Calculator {

    @Override
    public int add(int a, int b) {
        System.out.println(a+b);
        return a+b;
    }

    @Override
    public int sub(int a, int b) {
        return a-b;
    }

    @Override
    public int mul(int a, int b) {
        return a*b;
    }

    @Override
    public int div(int a, int b) {
        return a/b;
    }

}

```
现在有个需求，就是在每个方法执行前后都实现一段逻辑，这个时候就要用到JDK的动态代理了。

我们首先定义一个类实现`InvocationHandler`接口，将要代理的对象通过构造方法传入，并实现`invoke`方法。

```Java
public class MyProxyHandler implements InvocationHandler {

    //要代理的对象
    private Calculator target;

    public MyProxyHandler(Calculator h) {
        this.target = h;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        //获取参数
        System.out.println("beginWith---方法的参数是--" + Arrays.asList(args));

        before();
        Object result = method.invoke(target,args);
        after();
        return result;
    }

    /**
     * 前置
     */
    public void before() {
        System.out.println("before---");
    }

    /**
     * 后置
     */
    public void after() {
        System.out.println("after---");
    }
}
```

最后我们利用JDK提供的Proxy类来实现我们想要的功能


```Java
/**
 * jdk动态代理测试
 * @author mingshan
 *
 */
public class Test {

    public static void main(String[] args) {
       Calculator target = new CalculatorImpl();
       Calculator proxy = (Calculator) Proxy.newProxyInstance(Calculator.class.getClassLoader(),
               new Class<?>[]{Calculator.class},
               new MyProxyHandler(target));

       proxy.add(1, 2);
    }
}

```
### 代理类与被代理类关系

代理类是JDK自动帮我们生成的一个类，该类实现了与被代理类相同的接口，同时继承了Proxy类。

### 具体实现流程

动态代理之所以被称为动态代理，那是因为代理类是在运行过程中被Java动态生成的，我们可以看到这个被生成的代理类，需要在运行运行配置加上`-Dsun.misc.ProxyGenerator.saveGeneratedFiles=true`这个虚拟机参数，那么就会在当前项目`com.sun.proxy`包路径下生成`$Proxy0.class`这个class文件，其中文件名的数字是可变的。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/dynamic-proxy-vm-options.png?raw=true)

代理类生成的过程主要包括两部分：

- 代理类字节码生成
- 把字节码通过传入的类加载器加载到虚拟机中

我们首先从Proxy类的newProxyInstance方法入手，开始分析实现流程。


```Java
public static Object newProxyInstance(ClassLoader loader,
                                      Class<?>[] interfaces,
                                      InvocationHandler h)
    throws IllegalArgumentException
{
   // 检查空指针异常
    Objects.requireNonNull(h);

    final Class<?>[] intfs = interfaces.clone();
    // 安全检查
    final SecurityManager sm = System.getSecurityManager();
    if (sm != null) {
        checkProxyAccess(Reflection.getCallerClass(), loader, intfs);
    }

    // 生成代理类
    Class<?> cl = getProxyClass0(loader, intfs);

    /*
     * Invoke its constructor with the designated invocation handler.
     */
    try {
        if (sm != null) {
            checkNewProxyPermission(Reflection.getCallerClass(), cl);
        }

        final Constructor<?> cons = cl.getConstructor(constructorParams);
        final InvocationHandler ih = h;
        if (!Modifier.isPublic(cl.getModifiers())) {
            AccessController.doPrivileged(new PrivilegedAction<Void>() {
                public Void run() {
                    cons.setAccessible(true);
                    return null;
                }
            });
        }
        return cons.newInstance(new Object[]{h});
    } catch (IllegalAccessException|InstantiationException e) {
        throw new InternalError(e.toString(), e);
    } catch (InvocationTargetException e) {
        Throwable t = e.getCause();
        if (t instanceof RuntimeException) {
            throw (RuntimeException) t;
        } else {
            throw new InternalError(t.toString(), t);
        }
    } catch (NoSuchMethodException e) {
        throw new InternalError(e.toString(), e);
    }
}
```

`newProxyInstance`方法需要三个参数，分别是类加载器，接口类型的数组和自定义的InvocationHandler。首选会检测空指针异常和安全检查，然后调用`getProxyClass0`方法，`getProxyClass0`源码如下：


```Java
private static Class<?> getProxyClass0(ClassLoader loader,
                                       Class<?>... interfaces) {
    if (interfaces.length > 65535) {
        throw new IllegalArgumentException("interface limit exceeded");
    }

    // If the proxy class defined by the given loader implementing
    // the given interfaces exists, this will simply return the cached copy;
    // otherwise, it will create the proxy class via the ProxyClassFactory
    return proxyClassCache.get(loader, interfaces);
}

```
代码里面的注释很清楚，如果实现当前接口的代理类存在，直接从缓存中返回，如果不存在，则通过ProxyClassFactory来创建。这里可以明显看到有对interface接口数量的限制，不能超过65535。其中proxyClassCache具体初始化信息如下：


```Java
proxyClassCache = new WeakCache<>(new KeyFactory(), new ProxyClassFactory());
```

其中创建代理类的具体逻辑是通过ProxyClassFactory的apply方法来创建的，ProxyClassFactory类中还包含代理类名称生成相关的两个静态常量，源码如下：

```Java
// prefix for all proxy class names
private static final String proxyClassNamePrefix = "$Proxy";

// next number to use for generation of unique proxy class names
private static final AtomicLong nextUniqueNumber = new AtomicLong();


@Override
public Class<?> apply(ClassLoader loader, Class<?>[] interfaces) {

    Map<Class<?>, Boolean> interfaceSet = new IdentityHashMap<>(interfaces.length);
    for (Class<?> intf : interfaces) {
        /*
         * Verify that the class loader resolves the name of this
         * interface to the same Class object.
         */
        Class<?> interfaceClass = null;
        try {
            interfaceClass = Class.forName(intf.getName(), false, loader);
        } catch (ClassNotFoundException e) {
        }
        if (interfaceClass != intf) {
            throw new IllegalArgumentException(
                intf + " is not visible from class loader");
        }
        /*
         * Verify that the Class object actually represents an
         * interface.
         */
        if (!interfaceClass.isInterface()) {
            throw new IllegalArgumentException(
                interfaceClass.getName() + " is not an interface");
        }
        /*
         * Verify that this interface is not a duplicate.
         */
        if (interfaceSet.put(interfaceClass, Boolean.TRUE) != null) {
            throw new IllegalArgumentException(
                "repeated interface: " + interfaceClass.getName());
        }
    }

    String proxyPkg = null;     // package to define proxy class in
    int accessFlags = Modifier.PUBLIC | Modifier.FINAL;

    /*
     * Record the package of a non-public proxy interface so that the
     * proxy class will be defined in the same package.  Verify that
     * all non-public proxy interfaces are in the same package.
     */
    for (Class<?> intf : interfaces) {
        int flags = intf.getModifiers();
        if (!Modifier.isPublic(flags)) {
            accessFlags = Modifier.FINAL;
            String name = intf.getName();
            int n = name.lastIndexOf('.');
            String pkg = ((n == -1) ? "" : name.substring(0, n + 1));
            if (proxyPkg == null) {
                proxyPkg = pkg;
            } else if (!pkg.equals(proxyPkg)) {
                throw new IllegalArgumentException(
                    "non-public interfaces from different packages");
            }
        }
    }

    if (proxyPkg == null) {
        // if no non-public proxy interfaces, use com.sun.proxy package
        proxyPkg = ReflectUtil.PROXY_PACKAGE + ".";
    }

    /*
     * Choose a name for the proxy class to generate.
     */
    long num = nextUniqueNumber.getAndIncrement();
    String proxyName = proxyPkg + proxyClassNamePrefix + num;

    /*
     * Generate the specified proxy class.
     */
    byte[] proxyClassFile = ProxyGenerator.generateProxyClass(
        proxyName, interfaces, accessFlags);
    try {
        return defineClass0(loader, proxyName,
                            proxyClassFile, 0, proxyClassFile.length);
    } catch (ClassFormatError e) {
        /*
         * A ClassFormatError here means that (barring bugs in the
         * proxy class generation code) there was some other
         * invalid aspect of the arguments supplied to the proxy
         * class creation (such as virtual machine limitations
         * exceeded).
         */
        throw new IllegalArgumentException(e.toString());
    }
}
```

apply方法需要两个参数，类加载器和接口类型的数组。该方法包含验证类加载器和接口相关逻辑，包名的创建逻辑，调用`ProxyGenerator. generateProxyClass`生成代理类，把代理类字节码加载到JVM。


1. 包名默认是`com.sun.proxy`，如果被代理类是 non-public proxy interface ，则用和被代理类接口一样的包名，类名默认是$Proxy 加上一个自增的整数值，如$Proxy0，$Proxy1。
2. 包名类名准备好后，就是通过`ProxyGenerator. generateProxyClass`根据具体传入的接口创建代理字节码，`-Dsun.misc.ProxyGenerator.saveGeneratedFiles=true` 这个VM参数就是在该方法起到作用，如果为true则保存字节码到磁盘。代理类中，所有的代理方法逻辑都一样都是调用invocationHander的invoke方法，这个我们可以看后面具体代理反编译结果。
3. 把字节码通过传入的类加载器加载到JVM中: `defineClass0(loader, proxyName,proxyClassFile, 0, proxyClassFile.length)`。

我们继续来看看`generateProxyClass`方法是如何实现的，下面是该类的源码


```Java
public static byte[] generateProxyClass(final String var0, Class<?>[] var1, int var2) {
    ProxyGenerator var3 = new ProxyGenerator(var0, var1, var2);
    // 生成代理类字节码文件的真正方法
    final byte[] var4 = var3.generateClassFile();
    // 保存文件操作
    if (saveGeneratedFiles) {
        AccessController.doPrivileged(new PrivilegedAction<Void>() {
            public Void run() {
                try {
                    int var1 = var0.lastIndexOf(46);
                    Path var2;
                    if (var1 > 0) {
                        Path var3 = Paths.get(var0.substring(0, var1).replace('.', File.separatorChar));
                        Files.createDirectories(var3);
                        var2 = var3.resolve(var0.substring(var1 + 1, var0.length()) + ".class");
                    } else {
                        var2 = Paths.get(var0 + ".class");
                    }

                    Files.write(var2, var4, new OpenOption[0]);
                    return null;
                } catch (IOException var4x) {
                    throw new InternalError("I/O exception saving generated file: " + var4x);
                }
            }
        });
    }

    return var4;
}
```

在`generateProxyClass`方法中，通过调用`ProxyGenerator`类的`generateClassFile`方法，来生成代理类字节码文件，然后保存文件。

接下来我们看看`generateClassFile`方法干了些什么，下面是该方法的源码（方法有点长~）：

```Java
private byte[] generateClassFile() {
    // addProxyMethod系列方法就是将接口的方法和Object的hashCode,equals,toString方法添加到代理方法Map(proxyMethods),
    // 其中方法签名作为key,proxyMethod作为value
    // 后面经过反编译生成的代理类看出，hashCode，equals，toString这三个方法相当于从Object拿过来，
    // m0 = Class.forName("java.lang.Object").getMethod("hashCode", new Class[0]);
    this.addProxyMethod(hashCodeMethod, Object.class);
    this.addProxyMethod(equalsMethod, Object.class);
    this.addProxyMethod(toStringMethod, Object.class);
    Class[] var1 = this.interfaces;
    int var2 = var1.length;

    int var3;
    Class var4;
    // 获得所有接口中的所有方法，并将方法添加到代理方法中
    for(var3 = 0; var3 < var2; ++var3) {
        var4 = var1[var3];
        Method[] var5 = var4.getMethods();
        int var6 = var5.length;

        for(int var7 = 0; var7 < var6; ++var7) {
            Method var8 = var5[var7];
            this.addProxyMethod(var8, var4);
        }
    }

    // 迭代存储在map中的ProxyMethod
    Iterator var11 = this.proxyMethods.values().iterator();

    List var12;
    while(var11.hasNext()) {
        var12 = (List)var11.next();
        checkReturnTypes(var12);
    }

    Iterator var15;
    try {
        // 生成代理类的构造函数
        this.methods.add(this.generateConstructor());
        var11 = this.proxyMethods.values().iterator();

        while(var11.hasNext()) {
            var12 = (List)var11.next();
            var15 = var12.iterator();

            while(var15.hasNext()) {
                ProxyGenerator.ProxyMethod var16 = (ProxyGenerator.ProxyMethod)var15.next();
                // 向代理类添加字段
                // 将代理字段声明为Method，10为ACC_PRIVATE和ACC_STATAIC的与运算，表示该字段的修饰符为private static
                // 所以代理类的字段都是private static Method XXX
                this.fields.add(new ProxyGenerator.FieldInfo(var16.methodFieldName, "Ljava/lang/reflect/Method;", 10));
                // 向代理类添加方法
                this.methods.add(var16.generateMethod());
            }
        }

        // 为代理类生成静态代码块，对一些字段进行初始化
        this.methods.add(this.generateStaticInitializer());
    } catch (IOException var10) {
        throw new InternalError("unexpected I/O Exception", var10);
    }

    // 限制方法和字段数量
    if (this.methods.size() > 65535) {
        throw new IllegalArgumentException("method limit exceeded");
    } else if (this.fields.size() > 65535) {
        throw new IllegalArgumentException("field limit exceeded");
    } else {
        this.cp.getClass(dotToSlash(this.className));
        this.cp.getClass("java/lang/reflect/Proxy");
        var1 = this.interfaces;
        var2 = var1.length;

        for(var3 = 0; var3 < var2; ++var3) {
            var4 = var1[var3];
            this.cp.getClass(dotToSlash(var4.getName()));
        }

        this.cp.setReadOnly();
        ByteArrayOutputStream var13 = new ByteArrayOutputStream();
        DataOutputStream var14 = new DataOutputStream(var13);

        try {
            var14.writeInt(-889275714);
            var14.writeShort(0);
            var14.writeShort(49);
            this.cp.write(var14);
            var14.writeShort(this.accessFlags);
            var14.writeShort(this.cp.getClass(dotToSlash(this.className)));
            var14.writeShort(this.cp.getClass("java/lang/reflect/Proxy"));
            var14.writeShort(this.interfaces.length);
            Class[] var17 = this.interfaces;
            int var18 = var17.length;

            for(int var19 = 0; var19 < var18; ++var19) {
                Class var22 = var17[var19];
                var14.writeShort(this.cp.getClass(dotToSlash(var22.getName())));
            }

            var14.writeShort(this.fields.size());
            var15 = this.fields.iterator();

            while(var15.hasNext()) {
                ProxyGenerator.FieldInfo var20 = (ProxyGenerator.FieldInfo)var15.next();
                var20.write(var14);
            }

            var14.writeShort(this.methods.size());
            var15 = this.methods.iterator();

            while(var15.hasNext()) {
                ProxyGenerator.MethodInfo var21 = (ProxyGenerator.MethodInfo)var15.next();
                var21.write(var14);
            }

            var14.writeShort(0);
            return var13.toByteArray();
        } catch (IOException var9) {
            throw new InternalError("unexpected I/O Exception", var9);
        }
    }
}
```

那么自定义的InvocationHandler是如何在代理中使用的呢？ 在上面的方法中向代理类添加方法调用了`generateMethod()`方法，所以这个添加方法的步骤就是在`generateMethod()`方法中实现的。
由于这个方法太长，这里就不贴全部代码了，方法里面有一段代码如下：


```Java
var9.writeShort(ProxyGenerator.this.cp.getFieldRef("java/lang/reflect/Proxy", "h", "Ljava/lang/reflect/InvocationHandler;"));
```

原来在代理方法中通过Proxy类引用了自定义InvocationHandler，由于通过Proxy的newProxyInstance方法将InvocationHandler传入，生成的代理类通过继承Proxy类，拿到InvocationHandler，
最后调用invoke方法来实现。

明白了JDK动态代理的大致流程，让我们来反编译下生成的代理类，反编译后的`$Proxy0.java`的代码如下：

```
package com.sun.proxy;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.lang.reflect.UndeclaredThrowableException;
import me.mingshan.dy.Calculator;

public final class $Proxy0 extends Proxy implements Calculator {

   private static Method m1;
   private static Method m2;
   private static Method m5;
   private static Method m3;
   private static Method m4;
   private static Method m6;
   private static Method m0;


   public $Proxy0(InvocationHandler var1) throws  {
      super(var1);
   }

   public final boolean equals(Object var1) throws  {
      try {
         return ((Boolean)super.h.invoke(this, m1, new Object[]{var1})).booleanValue();
      } catch (RuntimeException | Error var3) {
         throw var3;
      } catch (Throwable var4) {
         throw new UndeclaredThrowableException(var4);
      }
   }

   public final String toString() throws  {
      try {
         return (String)super.h.invoke(this, m2, (Object[])null);
      } catch (RuntimeException | Error var2) {
         throw var2;
      } catch (Throwable var3) {
         throw new UndeclaredThrowableException(var3);
      }
   }

   public final int mul(int var1, int var2) throws  {
      try {
         return ((Integer)super.h.invoke(this, m5, new Object[]{Integer.valueOf(var1), Integer.valueOf(var2)})).intValue();
      } catch (RuntimeException | Error var4) {
         throw var4;
      } catch (Throwable var5) {
         throw new UndeclaredThrowableException(var5);
      }
   }

   public final int add(int var1, int var2) throws  {
      try {
         return ((Integer)super.h.invoke(this, m3, new Object[]{Integer.valueOf(var1), Integer.valueOf(var2)})).intValue();
      } catch (RuntimeException | Error var4) {
         throw var4;
      } catch (Throwable var5) {
         throw new UndeclaredThrowableException(var5);
      }
   }

   public final int sub(int var1, int var2) throws  {
      try {
         return ((Integer)super.h.invoke(this, m4, new Object[]{Integer.valueOf(var1), Integer.valueOf(var2)})).intValue();
      } catch (RuntimeException | Error var4) {
         throw var4;
      } catch (Throwable var5) {
         throw new UndeclaredThrowableException(var5);
      }
   }

   public final int div(int var1, int var2) throws  {
      try {
         return ((Integer)super.h.invoke(this, m6, new Object[]{Integer.valueOf(var1), Integer.valueOf(var2)})).intValue();
      } catch (RuntimeException | Error var4) {
         throw var4;
      } catch (Throwable var5) {
         throw new UndeclaredThrowableException(var5);
      }
   }

   public final int hashCode() throws  {
      try {
         return ((Integer)super.h.invoke(this, m0, (Object[])null)).intValue();
      } catch (RuntimeException | Error var2) {
         throw var2;
      } catch (Throwable var3) {
         throw new UndeclaredThrowableException(var3);
      }
   }

   static {
      try {
         m1 = Class.forName("java.lang.Object").getMethod("equals", new Class[]{Class.forName("java.lang.Object")});
         m2 = Class.forName("java.lang.Object").getMethod("toString", new Class[0]);
         m5 = Class.forName("me.mingshan.dy.Calculator").getMethod("mul", new Class[]{Integer.TYPE, Integer.TYPE});
         m3 = Class.forName("me.mingshan.dy.Calculator").getMethod("add", new Class[]{Integer.TYPE, Integer.TYPE});
         m4 = Class.forName("me.mingshan.dy.Calculator").getMethod("sub", new Class[]{Integer.TYPE, Integer.TYPE});
         m6 = Class.forName("me.mingshan.dy.Calculator").getMethod("div", new Class[]{Integer.TYPE, Integer.TYPE});
         m0 = Class.forName("java.lang.Object").getMethod("hashCode", new Class[0]);
      } catch (NoSuchMethodException var2) {
         throw new NoSuchMethodError(var2.getMessage());
      } catch (ClassNotFoundException var3) {
         throw new NoClassDefFoundError(var3.getMessage());
      }
   }
}

```

代理类的结构大致如下:

- 静态字段：被代理的接口所有方法都有一个对应的静态方法变量；
- 静态块：主要是通过反射初始化静态方法变量；
- 具体每个代理方法：逻辑都差不多就是`h.invoke`，主要是调用我们自定义的InvocatinoHandler逻辑，触发目标对象target上对应的方法;
- 构造函数：从这里传入我们InvocationHandler逻辑

参考：<br/>
[JDK动态代理详解](http://www.importnew.com/23168.html)<br/>
[深度剖析JDK动态代理机制](https://www.cnblogs.com/MOBIN/p/5597215.html)
