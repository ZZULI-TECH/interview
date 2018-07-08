# 单例模式

我们在项目中会遇到这样一些情况，比如一个类，我们想让这个类在系统中有且仅有一个对象，不能够重复创建类的实例，因为这种类是无状态的，我们只需要有过一个类的实例就行了。这时我们需要用到设计模式的单例模式。

单例模式分为饿汉式和懒汉式，下面对这两种模式简单介绍:
1. 饿汉式是指当系统启动或者类被加载时就已经创建了类的实例
2. 懒汉式是指当该类第一次被调用的时候才会去创建该类的实例

单例模式有很多实现，不同实现有优有劣，下面谈谈单例的具体的一些实现

## 单例模式  - 饿汉式
如果不实现懒加载的话，那么就用饿汉式实现单例就比较简单，首先让无参构造函数私有化，我们可以直接对该类进行实例化，然后将其赋值给类的成员变量instance，然后提供一个外部可以访问的方法来获取类的实例。下面是代码。

```java
/**
 * 单例模式  - 饿汉式
 * 线程安全，但未实现懒加载。
 * @author mingshan
 *
 */
public class SingletonDemo1 {
    private SingletonDemo1() {}
    private static final SingletonDemo1 instance = new SingletonDemo1();

    public static SingletonDemo1 getInstance() {
        return instance;
    }
}


```
## 单例模式  - 懒汉式
如果想实现懒加载，那么就要用到懒汉式了。懒汉式是当类第一次被调用的时候才被实例化，但这个时候就会出现线程安全问题，所以我们需要对进行类实例化的部分进行加锁，来保证类的实例只有一个，由于加锁的问题，性能就会降低。虽然做到了线程安全，并且解决了多实例的问题，但是它并不高效。因为在任何时候只能有一个线程调用 getInstance()方法。代码如下：

```java
/**
 * 单例模式  - 懒汉模式
 * 实现延迟加载 ，所以 getInstance() 方法必须同步
 *
 * 此方法实现单例模式 性能比饿汉式低
 * @author mingshan
 *
 */
public class SingletonDemo2 {
    private static SingletonDemo2 instance = null;

    private SingletonDemo2() {}    

    public static synchronized SingletonDemo2 getInstance() {
        if (instance == null) {
            instance = new SingletonDemo2();
        }

        return instance;
    }
}
```

还有一种实现懒加载的方式使用静态内部类来实现单例，由于静态内部类外部不能被访问到，这一种写法简单，比较容易理解，推荐使用。

```java
/**
 * 单例模式  使用静态内部类 实现延迟加载
 * 比较推荐
 * @author mingshan
 *
 */
public class SingletonDemo3 {

    private SingletonDemo3(){}

    private static class SingletonHolder {
        private static final SingletonDemo3 instance = new SingletonDemo3();
    }

    public static SingletonDemo3 getInstance() {
        return SingletonHolder.instance;
    }
}
```

上面写了一个线程安全的单例模式的懒汉式，但却不是十分理想，假如同时有好多线程去调用getInstance方法，那么同一时间只有一个线程能够获取到类的实例，其他的线程都要排队等待该线程释放锁，效率低下。所以此时引出了“双重检验锁”。现在同时有两个线程进入到getInstance方法中，那么两个线程都会进入到第一个判空语句块中，因为此时还没有创建类的实例，接下来只有一个线程能获取到锁，进入到synchronized (SingletonDemo4.class){}语句块中，创建类的实例后释放锁，当前等待线程就会获取到锁，此时如果没有第二次判空操作，那么第二个线程就会再创建一次类的实例，这样就违背了单例的原则，所以双重检验锁就是这么来的。因为上来不是直接就加锁，而是在进行判空后加锁，也就是只有该类还没有被实例化时才会被加锁，当有实例了就不用加锁了，自然就提高了性能。当代码如下：


```java
/**
 * 懒汉式的再次优化
 * 双重检验锁，解决线程安全问题
 * @author mingshan
 *
 */
public class SingletonDemo4 {
    private volatile static SingletonDemo4 instance = null;

    private SingletonDemo4() {}

    public static SingletonDemo4 getInstance() {
        if (instance == null) {
            synchronized (SingletonDemo4.class) {
                if (instance == null) {            
                    instance = new SingletonDemo4();
                }
            }
        }

        return instance;
    }
}
```
这里用到了volatile关键字，这里保证了不同线程对这个变量进行操作时的可见性。
