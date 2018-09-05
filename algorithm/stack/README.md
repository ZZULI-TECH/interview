# 栈

### 栈介绍
栈是一种仅在表头进行插入和删除操作的线性表，并且属于后进先出（last-in，first-out，LIFO）原则，下面是栈的入栈和出栈的图示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/Stack.png?raw=true)

### 主要操作

栈主要有入栈和出栈操作，但要实现完整的栈操作，我们需要定义一些方法
- push 入栈，将元素压入栈顶
- pop 出栈，获取栈顶元素并将其从栈中删除
- peek 获取栈顶元素，但不删除
- empty 判断栈是否为空
- size 获取栈内元素的数量

下面来介绍一下实现这些方法的具体实现。

### 具体实现

栈内的元素是放在数组里面的，所以我们需要一些变量来存储和描述这些数据，定义如下：

```java
// 存放栈内元素的数组，默认大小为10
private Object[] elementData;
// 元素的数量
private int elementCount;
// 指定要增加的容量大小
private int capacityIncrement;
```

在构造方法中初始数组容量，代码如下：

```java
/**
 * 通过传入自定义的值来初始化数组
 * @param initialCapacity 数组容初始量
 * @param capacityIncrement 扩容增加的容量
 */
public Stack(int initialCapacity, int capacityIncrement) {
    super();
    if (initialCapacity < 0)
        throw new IllegalArgumentException("Illegal Capacity: "+
                                           initialCapacity);
    this.elementData = new Object[initialCapacity];
    this.capacityIncrement = capacityIncrement;
}

/**
 * 通过传入自定义的值来初始化数组
 * @param initialCapacity 数组初始容量
 */
public Stack(int initialCapacity) {
    this(initialCapacity, 0);
}

/**
 * 构造方法初始化数组容量
 */
public Stack() {
    this(10);
}
```

#### push

入栈操作需要将数据存到数组里面，如有数组有初始化大小，所以每次入栈操作需要检查数组的大小，大小不够需要进行扩容操作，代码如下：

```java
/**
 * 入栈
 * @param data
 * @return 入栈的数据
 */
public E push(E data) {
    addElement(data);
    return data;
}
```
这里调用了**addElement(data)**方法，我们来看看代码：

```java
/**
 * 向栈顶添加元素
 * @param obj
 */
private void addElement(E obj) {
    ensureCapacity(elementCount + 1);
    elementData[elementCount++] = obj;
}
```
在**addElement(data)**方法中调用ensureCapacity来检测数组的大小，扩容操作也是在这个方法中进行的，下面是方法的代码：

```java
/**
 * 确保栈容量，扩容
 * @param minCapacity 
 */
private void ensureCapacity(int minCapacity) {
    int oldCapacity = elementData.length;
    // 判断是否需要扩容
    if (oldCapacity < minCapacity) {
        // 指定要扩大多少，否则就扩容2倍
        int newCapacity = oldCapacity + (this.capacityIncrement > 0 
                ? this.capacityIncrement : oldCapacity);
        // 将原数组的容量拷贝到扩容后的数组
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
}
```
在这个方法中，首先判断当前的数组的大小够不够用，如果不够用，那么会根据传入的自定义扩容大小**capacityIncrement**来进行扩容操作，如果**capacityIncrement**小于0，那么容量就扩大2倍。最后将原来数组的数据拷贝到新数组中。

#### pop

出栈是将栈顶的元素移除并返回，下面是代码：

```java
/**
 * 出栈，移除栈顶的元素
 * @return 被移除的元素
 */
public E pop() {
    E obj = peek();
    if (size() > 0) {
        // 移除栈顶元素
        elementData[elementCount - 1] = null;
        elementCount--;
    }
    return obj;
}
```
在pop方法中，我们实则是调用了**peek**方法来获取栈顶元素，然后将栈顶元素移除下面来看**peek**的代码。

#### peek

peek方法是获取栈顶的元素，代码比较简单

```java
/**
 * 获取栈顶的元素，但不移除
 * @return 栈顶的元素
 */
@SuppressWarnings("unchecked")
public E peek() {
    int len = size();

    if (len == 0)
        throw new EmptyStackException();
    E obj = (E) elementData[elementCount - 1];
    return obj;
}
```

#### search

通过传入的元素来获取该元素第一次出现的位置，如果找不到返回-1，下面是代码：

```java
/**
 * 返回对象在堆栈中的位置，以 0 为基数。
 * @param element
 * @return 元素第一次出现的位置，找不到返回-1
 */
public int search(Object element) {
    int z = elementCount - 1;
    if (element == null) {
        for (int i = z; i > 0; i--) {
            if (elementData[i] == null) {
                return i;
            }
        }
    } else {
        for (int i = z; i > 0; i--) {
            if (element.equals(elementData[i])) {
                return i;
            }
        }
    }
    return -1;
}

```
由于栈可以存储null，所以需对null进行处理。

### 完整代码
完整代码：<br/>
https://github.com/mstao/data-structures/blob/master/Stack/src/pers/mingshan/stack/Stack.java