# Optional使用姿势

Optional类是在JDK8引入的比较有用的一个类，主要用来解决空指针（NullPointerException）问题，我们知道在平时写代码的时候，首先就要避免代码中出现空指针异常，如下面的代码：

```Java
List<Blog> blogs = ...;
 
if (blogs != null) {
    for (Blog blog : blogs) {
        List<Image> images = blog.getImages();
        if (images != null) {
            ...
        }
    }
}
```

当代码层数多的时候，这种代码看着是极其难受的，所在就引入了Optional，该类结合函数式编程进行链式调用，用着那是十分爽的^_^

首先来看看Optional类的API，截图如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/Optionals-api.png?raw=true)

我们先来关心这个类暴露的API，下面列举出该类常用的方法的签名，如下：

- public<U> Optional<U> map(Function<? super T, ? extends U> mapper)
- public T orElse(T other)
- public T orElseGet(Supplier<? extends T> other)
- public void ifPresent(Consumer<? super T> consumer)
- public Optional<T> filter(Predicate<? super T> predicate)
- public<U> Optional<U> flatMap(Function<? super T, Optional<U>> mapper)
- public <X extends Throwable> T orElseThrow(Supplier<? extends X> exceptionSupplier) throws X
- public Stream<T> stream()
- public void ifPresentOrElse(Consumer<? super T> action, Runnable emptyAction) 
- public Optional<T> or(Supplier<? extends Optional<? extends T>> supplier)

看到`Function`、`Supplier`、`Consumer`，如果对函数式编程熟悉的话就会知道Optional这个类的大部分方法支持lambda表达式，该类是经过官方精心设计的，目的是简化代码，优雅编程，哈哈，我们来看看该怎么用。

## 创建Optional实例

要使用Optional，首先就要有一个Optional的实例，现在有三种方法获得该类的实例，如下：

```
Optional<User> user = Optional.empty()
Optional<User> user = Optional.of(user)
Optional<User> user = Optional.ofNullable(user)
```

在该类的源码中，调用`empty()`方法会返回一个不带值的Optional实例。可以使用`of()` 和 `ofNullable()` 方法创建包含值的 Optional，区别是如果传入的值是`null`，`of()`方法会抛出空指针异常（NullPointerException），而`ofNullable()`会调用`empty()`方法，返回一个不带值的Optional实例。

看到这我们会有疑惑，该类不是要解决空指针异常吗，为什么还要向外暴露`of()`方法呢？官方把这个方法暴露出来可能考虑到使用者已经确定传入的参数不可能为`null`，但又想使用该类的其他的API；或者使用者想提前处理空指针异常，不想让空指针异常藏匿于Optional中，这也是一种设计上的考虑，只不过使用者要注意两个方法的异同，不要使用错误即可。

## orElse / orElseGet / orElseThrow

现在我们有了Optional实例，接下来我们可以通过`get()`访问Optional实例的值，如下:

```Java
Optional.of(user).get();
```

我们也可以利用`ifPresent()`来判断Optional实例所携带的值是否为`null`，我们一拍脑袋，就可以能写出如下代码：


```Java
Optional<User> user = Optional.ofNullable(user);
if (user.isPresent()) {
    User result = user.get();
} else {
    ...
}
```
上面代码貌似没什么问题，但仔细思考一下，这样写和直接进行空值判断有什么区别？答案是没区别，因为这样用完全没有体现到Optional的特性，JDK的作者肯定也不希望你这样用。所以`orElse` 和 `orElseGet`这两个方法就出现了，将上面的代码改写下，如果传入的值为`null`，就返回一个自己传入的值，代码如下：


```Java
User user = null;
User u = createNewUser();
// 使用orElse
User result = Optional.ofNullable(user).orElse(u);
assertEquals(u, result);
// 使用orElseGet
User result2 = Optional.ofNullable(user).orElseGet(() -> createNewUser());
assertEquals(user, result2);
```


这里有一点要注意，无论传入的值是否为`null`，`orElse`都会执行，但`orElseGet`只有在传入的值为`null`时才会执行，这也是两者大的区别，在执行相对耗时的任务时，注意不要用错，否则这个差异会对性能产生重大影响。

如果传入的值为`null`时还有抛出其他异常的需要，就可以使用`orElseThrow`，代码如下：

```Java
User user = null;

User result = Optional.ofNullable(user)
        .orElseThrow(() -> new IllegalArgumentException());
```

## map / flatMap 转换值

现在我们已经可以根据传入值是否为`null`来返回不同的值了，而且没有空指针异常，但像下面的代码，我们需要对值进行多层转换，这时我们就需要用到`map`方法


```Java
if(user != null) {
    String name = user.getName();
    if (name != null) {
        return name.toLowerCase();
    } else {
        return null;
    }
} else {
    return null;
}
```

上面的代码经过转换后，如下：

```
return Optional.ofNullable(user)
        .map(u -> u.getName())
        .map(name -> name.toLowerCase())
        .orElse(null);
```

是不是既简洁又很帅？`map`方法通过传入的lambda表达式对值进行处理，然后将返回的值包装在 Optional 中，所以`map`方法可以多次调用，真的很好用。


`map`方法是把结果自动封装成一个Optional，但是`flatmap`方法需要你自己去封装，这是两者的区别，`flatmap`方法相对来说比较灵活。


## filter 过滤

Optional提供过滤值功能，调用`filter`方法时传入过滤条件，返回测试结果为true的值。如果测试结果为false，会返回一个空的Optional。

```java
User user = new User(22, "walker");
Optional<User> result = Optional.ofNullable(user)
        .filter(u -> u.getName().contains("w") && u.getAge() > 20);

assertTrue(result.isPresent());
```

## Java SE 9:Optional类改进

在JDK9中，对Optional类进行增强，增加了如下几个方法：

- stream()
- ifPresentOrElse()
- or()

### stream

现在Optional可以直接转为stream 流来进行处理，这样我们就可以利用Stream对象强大丰富的API来实现我们的逻辑，示例代码如下：

```Java
User user = new User(22, "walker");
User user2 = new User(19, "walker2");
List<User> users = new ArrayList<>();
users.add(user);
users.add(user2);

List<String> names = Optional.ofNullable(users)
    .stream()
    .flatMap(x -> x.stream())
    .filter(u -> u.getName().contains("w") && u.getAge() > 19)
    .map(u -> u.getName())
    .collect(Collectors.toList());

names.stream().forEach(System.out::println);
```
### ifPresentOrElse()

`ifPresentOrElse()`方法需要两个参数：一个 Consumer 和一个 Runnable。如果对象包含值，会执行 Consumer 的动作，否则运行 Runnable。

```Java
User user = null;
Optional.ofNullable(user)
    .ifPresentOrElse(u -> System.out.print(u), () -> System.out.println("User not found"));
```

### or()

`or()` 方法与 `orElse()` 和 `orElseGet()` 类似，它们都在传入值为空的时候提供了替代情况。但`or()`的返回值是由 Supplier 参数产生的另一个 Optional 对象。示例代码如下：

```Java
User user = null;
User result = Optional.ofNullable(user)
    .or(() -> Optional.of(new User(23, "xcc"))).get();
assertEquals(23, result.getAge());
```

## 使用注意

1. 调用`get()`注意要用`isPresent()`方法进行检测，否则会抛出异常
2. 不要将Optional 类型用作属性或是方法参数，Optional 类型不可被序列化, 用作字段类型会出问题的
3. 尽量进行链式调用，这也是简化我们代码的利器。

参考：

- [Optional Doc](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Optional.html)
- [Optional in Java 8 cheat sheet](https://www.nurkiewicz.com/2013/08/optional-in-java-8-cheat-sheet.html)
- [理解、学习与使用 JAVA 中的 OPTIONAL](https://www.cnblogs.com/zhangboyu/p/7580262.html)
- [使用 Java8 Optional 的正确姿势](https://yanbin.blog/proper-ways-of-using-java8-optional/)