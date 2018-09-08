# 自己实现简单的动态代理

经过对JDK动态代理实现原理的解析，我们会对动态代理的实现流程有个根本的认识，具体分析过程参考[JDK动态代理实现原理](http://mingshan.me/2018/07/10/JDK%E5%8A%A8%E6%80%81%E4%BB%A3%E7%90%86%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86/#more)这篇文章，这里就不多谈了。这篇文章主要思考如何去实现一个简易的动态代理，以便加深对其的理解。

模仿着JDK动态代理，我们需要一个代理`Proxy`类，一个`InvocationHandler`接口，同时实现一个类加载器，下面为定义的类。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/my-dynamic-proxy-class.png?raw=true)

具体实现流程为：

首先定义一个`InvocationHandler`接口，代码如下：


```Java
public interface MyInvocationHandler {
    /**
     * proxy: 正在返回的代理对象，一般情况下，都不使用该对象
     * method: 正在被调用的方法
     * args: 调用方法时传入的参数
     */
    Object invoke(Object proxy, Method method, Object[] args) throws Throwable;
}
```
接口中有一个invoke方法，方法中有三个参数，分别是：

- proxy: 正在返回的代理对象，一般情况下，都不使用该对象
- method: 正在被调用的方法
- args: 调用方法时传入的参数


下面就需要实现代理类`Proxy`，动态代理的核心就是在这个类中实现的，主要功能包括如下几点：

- 动态生成代理类，类似`$Proxy0.java`
- 调用Java编译器，编译生成的代理类
- 将生成的class文件利用类加载器加载到内存中，然后进行实例化
- 调用自定义`InvocationHandler`的invoke方法

详细代码如下：

```Java
/**
 *
 * 定义自己的 Proxy代理
 */
public class MyProxy {
    protected MyInvocationHandler h;

    // 定义回车键
    static String rt = "\r\t";

    // 用户的当前工作目录,包含项目名
    static String workspace = System.getProperty("user.dir");

    // 当前类包名
    static String packageName = MyProxy.class.getPackage().getName();

    /**
     * 私有构造器，该类禁止被实例化
     */
    @SuppressWarnings("unused")
    private MyProxy() {}

    /**
     * 由于 MyProxy 内部从不直接调用构造函数，所以 protected 意味着只有子类可以调用
     * @param h
     */
    protected MyProxy(MyInvocationHandler h) {
        this.h = h;
    }

    /**
     * 在内存中创建$proxy0 的实例
     * @param loader
     * @param interfaces
     * @param h
     * @return
     * @throws IllegalArgumentException
     * @throws IOException
     */
    @SuppressWarnings({ "rawtypes", "resource", "unchecked" })
    public static Object createProxyInstance(ClassLoader loader,
            Class interfaces,
            MyInvocationHandler h) throws IllegalArgumentException, IOException {

        Objects.requireNonNull(h);

        //实际运行这个动态类构造一个对象
        System.out.println("=====自定义:类构造一个代理类的java对象");
        Method[] methods = interfaces.getMethods();

        String proxyClassString = "package pers.han;" + rt
                + "import java.lang.reflect.Method;" + rt
                + "public class $Proxy0 implements " + interfaces.getName() + "{" + rt
                + "protected MyInvocationHandler h;" + rt
                + "public $Proxy0(MyInvocationHandler h){" + rt
                + "this.h=h;" + rt + "}" + rt + getMethodString(methods,interfaces)
                + rt + "}";

        //我们将自定义的代理类转化为文件
        String fileName = workspace+"/src/pers/han/$Proxy0.java";
        File file = new File(fileName);

        //向文件写内容
        FileWriter fw = new FileWriter(file);
        fw.write(proxyClassString);
        fw.flush();
        //编译这个文件
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        System.out.println("comiler-" + compiler);
        StandardJavaFileManager fileManager = compiler.getStandardFileManager(null, null, null);
        Iterable units = fileManager.getJavaFileObjects(fileName);
        //编译这个任务
        CompilationTask compTask = compiler.getTask(null, fileManager, null, null, null, units);
        compTask.call();
        fileManager.close();
        //编译完成后，是不是.java
        file.delete();
        //编译后就是class文件，那么接下来就把这个class文件 加到内存
        MyClassLoader classLoader = new MyClassLoader(workspace + "/src/pers/han");

        try {
            Class<?> proxy0Class = classLoader.findClass("$Proxy0");
            //等类加载完之后 ，删除
            File classFile = new File(workspace + "/src/pers/han/$Proxy0.class");
            if (classFile.exists()) {
                classFile.delete();
            }

            Constructor<?> m = proxy0Class.getConstructor(MyInvocationHandler.class);
            Object object = m.newInstance(h);
            return object;
        } catch(Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * 实现的方法
     * @param methods
     * @param interfaces
     * @return
     */
    private static String getMethodString(Method[] methods, Class<?> interfaces) {
        String proxyMe = "";

        for (Method m : methods) {
            proxyMe += "public void " + m.getName() + "() throws Throwable {" + rt
                    + "Method md=" + interfaces.getName() + ".class.getMethod(\""
                    + m.getName() + "\", new Class[]{});" + rt
                    + "this.h.invoke(this,md,null);" + rt + "}" + rt;
        }
        return proxyMe;
    }
}

```

将类加载到内存中需要自定义类加载器，这里继承`ClassLoader`类，然后重写`findClass`方法，代码如下：

```Java
/**
 * 自己的类加载器
 * @author mingshan
 *
 */
public class MyClassLoader extends ClassLoader {
    private File dir;

    public MyClassLoader(String path) {
        dir = new File( path );
    }

    @Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {

        if (dir != null) {
            File classFile = new File(dir, name + ".class");
            if (classFile.exists()) {
                FileInputStream input = null;
                try {
                    input = new FileInputStream(classFile);
                    ByteArrayOutputStream baos = new ByteArrayOutputStream();
                    byte[] buffer = new byte[1024];
                    int len;
                    while ((len=input.read(buffer)) != -1) {
                        baos.write(buffer, 0, len);
                    }
                    return defineClass("pers.han." + name, baos.toByteArray(), 0, baos.size());
                } catch(Exception e) {
                    e.printStackTrace();
                } finally {
                    if (input != null) {
                        try {
                            input.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                }
            }
        }
        return null;
    }
}
```

生成的代理类`$Proxy0.java`：

```
package pers.han;
	import java.lang.reflect.Method;
	public class $Proxy0 implements pers.han.Person{
	protected MyInvocationHandler h;
	public $Proxy0(MyInvocationHandler h){
	this.h=h;
	}
	public void say() throws Throwable {
	Method md=pers.han.Person.class.getMethod("say", new Class[]{});
	this.h.invoke(this,md,null);
	}
	
	}
```
