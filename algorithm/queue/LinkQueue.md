# 链式队列

### 链式队列介绍
链式队列拥有队列的特性，只不过和顺序队列的区别是，顺序队列底层用的是数组存储元素，而链式队列用的是链表结构存储数据，也就是把一个元素和指向下个结点的指针封装成一个结点，这里称为Node，当队列为空，头指针与尾指针均指向头结点，只不过头结点为空结点，下面是链式队列的结构图

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/LinkQueue.png?raw=true)

一个结点抽象成Node类，代码如下：

```java
private class Node {
    private E data;
    private Node next;

    public Node(E data) {
        this.data = data;
    }
}
```
<!-- more -->

#### 初始

#### 成员变量

链式队列需要有个指向队首的指针，指向队尾的指针，这里把这两个均声明为Node类型，当然队列需要容量和统计队列内元素的个数，代码如下：

```java
private final AtomicInteger size = new AtomicInteger();
private final int capacity;
// 队列的头结点
private Node head;
// 队列的尾结点
private Node tail;

```

#### 构造函数

在构造函数中初始化队列，当队列为空时，头指针与尾指针均指向头结点，头结点不存储数据


```java
public LinkQueue() {
    this(Integer.MAX_VALUE);
}

public LinkQueue(int capacity) {
    if (capacity <= 0) throw new IllegalArgumentException();
    this.capacity = capacity;
    tail = head = new Node(null);
}

public LinkQueue(E element) {
    this(Integer.MAX_VALUE);
    // 初始Node，只有一个节点
    Node newNode = new Node(element);
    head.next = newNode;
    tail = newNode;
    size.incrementAndGet();
}
```

### 基本操作

#### 入队
链式队列也实现我们在顺序队列写好的接口，所以入队也有两种操作，抛异常和不抛异常，分别为**add(E e)**和**offer(E e)**，这里直接说offer方法，如果队列为空，让头结点指向新的节点，同时让为指针指向新节点，不为空直接正常入队即可，代码如下：

```
@Override
public boolean add(E e) {
    if (offer(e))
        return true;
    else
        throw new IllegalStateException("Queue full");
}

@Override
public boolean offer(E e) {
    if (e == null)
        throw new NullPointerException();
    if (size.get() == capacity)
        return false;
    Node newNode = new Node(e);
    if (head == null) {
        head.next = newNode;
        tail = newNode;
    } else {
        tail.next = newNode;
        tail = newNode;
    }

    size.incrementAndGet();
    return true;
}
```


#### 出队

出队也是比较简单的，直接移除队首结点即可，让头结点指向下一个结点，代码如下：


```java
@Override
public E poll() {
    if (!isEmpty()) {
        Node node = head.next;
        head.next = node.next;
        size.decrementAndGet();
        return node.data;
    }

    return null;
}
```

#### 清空队列

清空队列是让除了头结点的结点全部清除掉，解除关联，代码如下：

```java
@Override
public void clear() {
    head.next = null;
    tail = null;
    size.set(0);
}

```

### 源码地址

源码地址：<br/>
https://github.com/mstao/data-structures/blob/master/Queue/src/pers/mingshan/queue/LinkQueue.java