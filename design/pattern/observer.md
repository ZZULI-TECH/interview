# 观察者模式

我们在生活中会遇到这样一些例子，比如你订阅了某人的博客，那么这个人发布博客的时候会将消息推送给你，而且不是只推送你自己一人，只要订阅了该人的博客，那么订阅者都会收到通知，像这样的例子生活中实在是太多了。其实这种操作可以抽象一下，A对象（观察者）对B对象（被观察者）的某种变化高度敏感，需要在B变化的一瞬间做出反应，同时在B对象中维护着所有A的集合。我们在实际编程中称这种模式为观察者模式，有时也称为发布/订阅(Publish/Subscribe)模型。

在JDK的util包中已经帮我们实现了观察者模式，不过我们还是先通过自己写代码来看看观察者到底是怎么回事，自己该如何简单的实现，相信通过自己的简单实现，来理解JDK的观察者模式的实现是十分容易的。

在观察者模式中，首先要有两个角色，观察者与被观察者，这两者拥有的功能是不同的。对于观察者，需要有一个方法来接收被观察者发出的信息(update)，而对于被观察者而言，需要在其内部维护一个观察者的列表，用来记录需要通知的观察者(list)，所以需要一个添加观察者的方法(addWatcher），同时还要有一个方法可以用来移除观察者(removeWatcher), 最后我们需要一个用来通知所有观察者的方法(notifyWatchers), 一切准备就绪，那么我们来看代码吧。

先定义两个接口，观察者(Watcher)和被观察者(Watched),代码如下：

首先是观察者接口，定义了update方法用来接收通知

```java
/**
 * 观察者
 * @author mingshan
 *
 */
public interface Watcher {

    /**
     * 用来接收通知
     */
    void  update();
}


```

然后是被观察者接口，定义了三个方法：

```java
/**
 * 被观察者
 * @author mingshan
 *
 */
public interface Watched {

    /**
     * 添加观察者
     * @param watcher
     */
    void addWatcher(Watcher watcher);

    /**
     * 移除观察者
     * @param watcher
     */
    void removeWatcher(Watcher watcher);

    /**
     * 通知观察者
     */
    void notifyWatchers();
}
```

我们先实现被观察者，重写接口的方法，在其内部维护一个列表，用来存放所有的观察者，当需要通知观察者时，我们就可以调用notifyWatchers方法了，遍历通知所有观察者。

```java
import java.util.ArrayList;
import java.util.List;

public class Thief implements Watched {

    private List<Watcher> list = new ArrayList<Watcher>();

    @Override
    public void addWatcher(Watcher watcher) {
        list.add(watcher);
    }

    @Override
    public void removeWatcher(Watcher watcher) {
        list.remove(watcher);
    }

    @Override
    public void notifyWatchers() {
        for (Watcher watcher: list) {
            watcher.update();
        }
    }

}
```

我们再实现观察者，重写update方法

```java
public class Police implements Watcher {

    @Override
    public void update() {
        System.out.println("小偷正在偷东西，警察行动！");
    }

}

------------------------------

public class Inspector implements Watcher {

    @Override
    public void update() {
        System.out.println("小偷正在偷东西，城管行动！");
    }

}
```

最后我们写个测试类测试一下


```java
import org.junit.Test;

public class ObserverTest {

    @Test
    public void test() {
        Thief thief = new Thief();
        Police police = new Police();
        Inspector inspector = new Inspector();
        thief.addWatcher(police);
        thief.addWatcher(inspector);

        thief.notifyWatchers();
    }
}
```

* * *

以上是我们自己实现的观察者模式，前面说过了在JDK中已经帮我们实现好了观察者模式，那么我们来用一下：

观察者：


```java
/**
 * 被观察者 (JDK)
 * @author mingshan
 *
 */
public class Thief extends Observable {

    @Override
    public String toString() {
        return "我是小偷-_-";
    }

    public void work() {
        System.out.println("ss准备下手偷东西了！");
        setChanged();
        notifyObservers("-小偷说话：哈哈，你猜我是谁-");
    }
}
```

观察者：


```java
import java.util.Observable;
import java.util.Observer;

public class Police implements Observer {

    @Override
    public void update(Observable o, Object arg) {
        System.out.println(o + "小偷正在偷东西，警察行动！"+ arg);
    }

}

——————————————————————————————————————

import java.util.Observable;
import java.util.Observer;

public class Inspector implements Observer  {

    @Override
    public void update(Observable o, Object arg) {
        System.out.println(o + "小偷正在偷东西，城管行动！" + arg);
    }

}
```

测试类：

```java
import org.junit.Test;

public class ObserverTest {

    @Test
    public void test() {
        Thief thief = new Thief();
        Police police = new Police();
        Inspector inspector = new Inspector();
        thief.addObserver(police);
        thief.addObserver(inspector);
        thief.work();
    }
}
```
在Observable类源码中，我们可以看到有个changed的布尔值成员变量，用来标志当前对象是否已经被改变，所有在通知观察者之前我们将其置为true


```java
public class Observable {
    private boolean changed = false;
    private Vector<Observer> obs;

    /** Construct an Observable with zero Observers. */

    public Observable() {
        obs = new Vector<>();
    }

    /**
     * 添加观察者，并且一个观察者只能被添加一次
     */
    public synchronized void addObserver(Observer o) {
        if (o == null)
            throw new NullPointerException();
        if (!obs.contains(o)) {
            obs.addElement(o);
        }
    }

    /**
     * 移除观察者
     */
    public synchronized void deleteObserver(Observer o) {
        obs.removeElement(o);
    }

    /**
     * 通知所有的观察者
     */
    public void notifyObservers() {
        notifyObservers(null);
    }

    /**
     * 通知所有的观察者(遍历)，同时可以将一些信息传递给观察者，实际上是调用观察** 者的update方法
     */
    public void notifyObservers(Object arg) {
        /*
         * a temporary array buffer, used as a snapshot of the state of
         * current Observers.
         */
        Object[] arrLocal;

        synchronized (this) {

            if (!changed)
                return;
            arrLocal = obs.toArray();
            clearChanged();
        }

        for (int i = arrLocal.length-1; i>=0; i--)
            ((Observer)arrLocal[i]).update(this, arg);
    }

    /**
     * 删除观察者
     */
    public synchronized void deleteObservers() {
        obs.removeAllElements();
    }

    /**
     * 将判断当前对象是否改变的flag设置为true
     */
    protected synchronized void setChanged() {
        changed = true;
    }

    /**
     *  将判断当前对象是否改变的flag设置为false
     */
    protected synchronized void clearChanged() {
        changed = false;
    }

    /**
     * 判断当前对象是否改变
     *
     */
    public synchronized boolean hasChanged() {
        return changed;
    }

    /**
     * 统计观察者数量
     */
    public synchronized int countObservers() {
        return obs.size();
    }
}
```
