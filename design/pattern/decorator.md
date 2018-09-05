# 装饰模式

装饰模式作为常用的设计模式用到很多，比如在Java中，io包下的很多类就是典型的装饰者模式的体现，如下代码：

```Java
new BufferedOutputStream(OutputStream out)
new BufferedInputStream(InputStream in);
new PrintWriter(OutputStream out)
new FilterReader(Reader in);
```
那么，什么是装饰模式呢？

在实际应用中我们可能会有这样的需求，需要动态地为一个类增加一些功能，这些功能动态地撤销，继承虽然也可以对类进行功能扩展，但是静态的，为了扩展性和动态性，就需要引入装饰模式。

装饰模式的定义是： 动态地给一些对象添加一些额外的职责。就增加功能来说，装饰模式相比生成子类更加灵活。

装饰模式的通用类图如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/decorator.png)

在类图中，有四个角色需要说明：

- 抽象构件（Component） 

    给出一个抽象的接口，用以规范准备接收附加责任的对象。
    
- 具体构件（ConcreteComponent） 

    ConcreteComponent是最核心、最原始、最基本的接口或抽象类的实现，要装饰的就是它。
    
- 装饰角色（Decorator） 

    有一个构件（Conponent）对象的实例，并定义一个和抽象构件一致的接口。

- 具体装饰角色（ConcreteDecorator） 

    具体的装饰类，要增加的功能当然要在这里写啦。


**具体代码实现:**

抽象构件:

```Java
/**
 * 抽象构建
 * 
 * @author mingshan
 *
 */
public abstract class Component {
    public abstract void operate();
}

```

具体构件:

```Java
/**
 * 具体构件
 * 
 * @author mingshan
 *
 */
public class ConcreteComponent extends Component {

    @Override
    public void operate() {
        System.out.println("do something");
    }

}

```

装饰角色, 持有一个抽象构件的引用

```Java
/**
 * 抽象装饰者
 * 
 * @author mingshan
 *
 */
public class Decorator extends Component {
    private Component component;

    public Decorator(Component component) {
        super();
        this.component = component;
    }

    @Override
    public void operate() {
        this.component.operate();
    }

}

```


具体装饰角色

```Java
/**
 * 装饰者1
 * 
 * @author mingshan
 *
 */
public class ConcreteDecorator1 extends Decorator {

    /**
     * 定义被修饰者
     * @param component
     */
    public ConcreteDecorator1(Component component) {
        super(component);
    }

    /**
     * 定义自己的修饰方法
     */
    private void method1() {
        System.out.println("decorator A");
    }

    /**
     * 重写父类的方法
     */
    @Override
    public void operate() {
        this.method1();
        super.operate();
    }
}

```

测试一下：

```Java
/**
 * 测试
 * 
 * @author mingshan
 *
 */
public class Test {

    public static void main(String[] args) {
        Component component = new ConcreteComponent();
        // 第一次装饰
        component = new ConcreteDecorator1(component);
        // 第二次装饰
        component = new ConcreteDecorator2(component);
        component.operate();
    }
}

```

**代码参考：**

https://github.com/mstao/java-explore/tree/master/DesignPattern/src/pers/han/decorator