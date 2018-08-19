# Reflect

反射是Java语言中一个比较重要的特性，它允许对正在运行的Java进行观测，甚至动态修改程序，即在运行态，对于任意一个类，都能够知道这个类的所有属性和方法；对于任意一个对象，都能够调用它的任意方法和属性。

## 反射API介绍

### 获取Class对象

通常来说，使用反射API的第一步是获取Class对象，在Java中比较常见的有以下几种：

1. 已知具体的类，通过类的class属性获取，对于基本类型来说，它们的包装类型（wrapper classes）拥有一个名为“TYPE”的final静态字段，指向该基本类型对应的Class对象
2. 已知某个类的实例，调用对象的getClass()方法获取Class对象
3. 已知一个类的全类名，使用静态方法Class.forName来获取


例如，Integer.TYPE 指向 int.class。对于数组类型来说，可以使用类名 +“[ ].class”来访问，如 int[ ].class。

除此之外，Class 类和 java.lang.reflect 包中还提供了许多返回 Class 对象的方法。例如，对于数组类的 Class 对象，调用 Class.getComponentType() 方法可以获得数组元素的类型。

我们还可以利用自定义Classloader来加载我们的类，然后可以获取到该类的Class对象。类似于下面的代码，注意代码可能会抛出异常。

```Java
MyClassLoader classLoader = new MyClassLoader(workspace + "/src/me/mingshan");
Class<?> proxy0Class = classLoader.findClass("$Proxy0");
```

### 其他操作

拿到Class对象后，我们可以进行很多操作，比如生成该类的实例，访问字段的值，调用方法等。

#### 生成类的实例

通过类的Class对象可以生成类的实例，有两种方式

1. 调用的是无参数的构造函数进行实例化


```Java
clazz.newInstance();
```

2. 可以选择调用哪个构造函数进行实例化，获取构造器可以传入参数来选择


```Java
Constructor c = clazz.getConstructor();
Object obj = c.newInstance(); 
```

#### 访问类的成员

通过调用`getFiles()/getgetConstructors()/getMethods()`来访问该类的成员。同时我们会发现有些方法会带上Declared，这表示调用该方法不会返回父类的成员。

当然我们也可以直接获取类的某个成员，比如成员和方法。


```Java
// 获取字段
Field field = clazz.getField("name");

// 获取方法
Method method=clazz.getMethod("studyHard", new Class[]{String.class});
```

还有一点，我们可以获取该类实现的接口

```Java
// 获取该类所实现的所有接口
Class<?> interfaces[] = clazz.getInterfaces();
```

##### 对类成员操作

当获取到类成员后，我们可以进行下一步操作。

- 使用 Constructor/Field/Method.setAccessible(true) 来绕开 Java 语言的访问限制。
- 使用 Constructor.newInstance(Object[]) 来生成该类的实例。
- 使用 Field.get/set(Object) 来访问字段的值。
- 使用 Method.invoke(Object, Object[]) 来调用方法。

### 获取泛型

在Java中泛型有擦除机制，那么我们在运行时可不可以获取泛型的具体类型呢？答案是可以的。原因是Class类文件结构中有一个叫Signature的属性。它的作用是存储一个方法在字节码层面的特征签名。这个属性中保存的参数参数类型并不是原生类型，而是包括了参数化类型的信息。

#### 获取成员变量的泛型信息

比如在一个类Test中，有一个成员变量list，如下：


```Java
private List<String> list;
```

现在我想直接想获取List的泛型，怎么获取呢？实现代码如下：

```Java
Type t = Test.class.getDeclaredField("list").getGenericType();  
if (ParameterizedType.class.isAssignableFrom(t.getClass())) {
    for (Type t1 : ((ParameterizedType) t).getActualTypeArguments()) {
        System.out.print(t1 + ",");
    }
}
```

由于可能会有多个泛型参数，例如Map，所以返回是一个数组。


#### 获取类的泛型信息

一个类是泛型类，在该类中我们可能需要获取这个泛型到底是啥，然后继续进行下面的逻辑，一个应用是Hibernate动态拼接HQL，需要知道泛型信息。
那么如何操作？代码如下：

```Java
/**
 * 通过反射获取泛型实例
 */
public class Genericity<T> {

    @SuppressWarnings("rawtypes")
    protected Class clazz;

    @SuppressWarnings("unchecked")
    /**
	 * 把泛型的参数提取出来的过程放入到构造函数中写，因为
	 * 当子类创建对象的时候，直接调用父类的构造函数
	 */
    public Genericity() {
    	// 通过反射机制获取子类传递过来的实体类的类型信息
        ParameterizedType type = (ParameterizedType) this.getClass().getGenericSuperclass();
        //得到t的实际类型
        clazz = (Class<T>) type.getActualTypeArguments()[0];
    }

    /**
     * 获取指定实例的所有属性名及对应值的Map实例 
     * @param entity 实例
     * @return 字段名及对应值的Map实例
     */
    protected Map<String, Object> getFieldValueMap(T entity) {
        // key是属性名，value是对应值
        Map<String, Object> fieldValueMap = new HashMap<String, Object>();

        // 获取当前加载的实体类中所有属性
        Field[] fields = this.clazz.getDeclaredFields();

        for (int i = 0; i < fields.length; i++) {
            Field f = fields[i];
            // 属性名 
            String key = f.getName();
            //属性值 
            Object value = null; 
            // 忽略序列化版本ID号
            if (! "serialVersionUID".equals(key)) {
            	// 取消Java语言访问检查
            	f.setAccessible(true);
                try {
                    value =f.get(entity);
                } catch (IllegalArgumentException e) {
                    e.printStackTrace();
                } catch (IllegalAccessException e) {
                    e.printStackTrace();
                }
                fieldValueMap.put(key, value);
            }
        }
        return fieldValueMap;
    }
}
```

在上面的代码中，`this.getClass().getGenericSuperclass()`返回表示此 Class 所表示的实体（类、接口、基本类型或 void）的直接超类的Type，然后将其转换`ParameterizedType`。
`getActualTypeArguments()`返回表示此类型实际类型参数的 Type 对象的数组。


### 反射Array相关API

reflect.Array类位于java.lang.reflect包下,它是个反射工具包，全是静态方法。我们可以利用这个类来对数组进行操作。

调用Class.getComponentType()获取数组元素的类型，代码如下：

```Java
int[] arr = {1,2,3,4,5};
Class<?> c = arr.getClass().getComponentType();
```
假设我们需要获取数组长度，用Array的静态方法获取：

```Java
int len = Array.getLength(arr);
```

当然我们可以用Array类来创建数组，向数组添加元素，修改元素等，具体可以参考官方API。

最后推荐一个[反射工具类](https://github.com/Blankj/AndroidUtilCode/blob/4b5d0852f8274583968a7fb36db3b25bf92aaa22/utilcode/src/main/java/com/blankj/utilcode/util/ReflectUtils.java)，可以参考参考。

**反射API参考：**

- https://docs.oracle.com/javase/tutorial/reflect/

- http://hg.openjdk.java.net/jdk10/jdk10/jdk/file/777356696811/src/java.base/share/classes/jdk/internal/reflect/ReflectionFactory.java#l80
 
- http://hg.openjdk.java.net/jdk10/jdk10/jdk/file/777356696811/src/java.base/share/classes/jdk/internal/reflect/ReflectionFactory.java#l78

- https://docs.oracle.com/javase/tutorial/reflect/class/classMembers.html

- https://docs.oracle.com/javase/10/docs/api/java/lang/reflect/package-summary.html

**文章参考：**

- 郑雨迪, JVM是如何实现反射的?
- 周志明，深入理解Java虚拟机:JVM高级特性与最佳实践（第2版）