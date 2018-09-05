# 单链表

### 单链表描述
单链表又为单向链表，由数据域(Data)和结点域(Node)组成，数据域代表该结点所存储的元素，结点域指向下一个节点，单链表的图示如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/SingleLinkedList.png?raw=true)

### 单链表结构
我们先定义一下单链表一个结点的结构，一个Node类：


```java
private class Node {
    E item;
    Node next;

    public Node(E e) {
        this.item = e;
    }
}
```
<!-- more -->

从Node类我们可以看出，item代表结点存储的元素，next指向链表的下一个节点。谈到链表，肯定少不了链表的基本操作，比如添加结点，删除结点，获取给定索引的节点啦，所以我们先写一个链表接口LinkedList，代码如下：


```java
package pers.mingshan.linkedlist;

/**
 * 链表接口
 * @author mingshan
 *
 * @param <E>
 */
public interface LinkedList<E> {

    /**
     * 根据索引获取节点的值
     * @param index 传入的索引值， 从1开始
     * @return 节点的值
     */
    E get(int index);

    /**
     * 设置某个结点的的值
     * @param index 传入的索引值， 从1开始
     * @param data 要插入的元素
     * @return 旧的节点的值
     */
    E set(int index, E data);

    /**
     * 根据index添加结点
     * @param index 传入的索引值， 从1开始
     * @param data 要插入的元素
     * @return 插入是否成功
     */
    void add(int index, E data);

    /**
     * 添加结点
     * @param data
     * @return 插入是否成功
     */
    boolean add(E data);

    /**
     * 根据index移除结点
     * @param index 传入的索引值， 从1开始
     * @return 移除成功返回该索引处的旧值
     */
    E remove(int index);

    /**
     * 根据data移除结点
     * @param data
     * @return 是否移除成功
     */
    boolean removeAll(E data);

    /**
     * 清空链表
     */
    void clear();

    /**
     * 是否包含data结点
     * @param data
     * @return 包含返回{@code true}, 不包含返回 {@code false}
     */
    boolean contains(E data);

    
    /**
     * 获取链表长度
     * @return 链表长度
     */
    int length();

    /**
     * 判断链表是否为空
     * @return 链表为空返回{@code true}, 不为空返回 {@code false}
     */
    boolean isEmpty();

    /**
     * 链表反转
     */
    void reverse();
}

```

这么多方法，先实现哪个呢？由于我们做了很多的增删改查，那么就从增加新结点开始吧(￣▽￣)／

### add方法
我们首先实现***add(E data)***，代码如下：

```java
@Override
public boolean add(E data) {
    if (data == null)
        throw new NullPointerException();
    if (head == null) {
        Node newNode = new Node(data);
        head = newNode;
        size++;
        return true;
    }

    Node temp = head;
    // 从头结点向后遍历，获取链表最后一个节点
    while (temp.next != null) {
        // temp 始终指向下一个节点
        temp = temp.next;
    }

    // 根据当前元素构造新节点
    Node newNode = new Node(data);
    // 将最后一节点的next指向新节点
    temp.next = newNode;
    // 计数加一
    size++;
    return true;
}

```
在**add(E data)**方法中，首先进行判空操作，然后检查头结点是否为空，如果头结点为空那么就把该新结点作为头结点；如果头结点不为空，那么就需要从头结点开始遍历单链表，直到找到尾节点，并将原来的尾节点的next指向新添加的结点，链表的元素数量加一。

然后实现**add(int index, E data)**，代码如下：

```java
/**
 * 根据索引插入元素
 * @param e 要插入的元素
 * @param index 传入的索引值， 从1开始
 */
@Override
public void add(int index, E data) {
    if (data == null)
        throw new NullPointerException();
    checkPositionIndex(index);

    int count = 1;
    Node temp = head;
    // 从头结点向后遍历
    while (temp.next != null) {
        // 1       2 
        // temp  temp.next
        // 假设现在index为2 那么原先在2位置上的节点需要向后移动一个
        // 1           2              3
        // temp    temp.next(e)     temp.next.next
        // 判断是否到了传入的索引

        // 如果索引为1，那么将当前节点置为头结点
        if (index == 1) {
            Node newNode = new Node(data);
            head = newNode;
            head.next = temp;
            size++;
        }
        // 判断是否到了传入的索引
        if (++count == index) {
            // 构造新节点
            Node newNode = new Node(data);
            // 将当前的位置的节点设置为新节点
            newNode.next = temp.next;
            temp.next = newNode;
            size++;
        }
        // temp 始终指向下一个节点
        temp = temp.next;
    }
}
```
**add(int index, E data)**这个方法是根据传入的索引值向链表插入元素。首选需要进行判空操作，然后检测传入的索引值是否合法，代码如下：

```java
/**
 * 检测索引位置是否合法
 * @param index
 */
private void checkPositionIndex(int index) {
    if (!isPositionIndex(index))
        throw new IllegalArgumentException("参数不合法");
}

private boolean isPositionIndex(int index) {
    return index >= 1 && index <= size;
}
```
检测完之后，需要判断传入的索引值的位置上的节点是否为头结点，如果是，将新结点设置为头结点，并将新结点的next指向原来的头结点。然后进行链表遍历，直到索引位置，在该位置之前插入新结点即可，具体参考代码注释。

### remove方法

现在我们根据索引值删除结点，代码如下：
```java
/**
 * 根据索引删除元素
 * @param index 传入的索引值， 从1开始
 */
@Override
public E remove(int index) {
    checkPositionIndex(index);

    int count = 1;
    Node temp = head;
    // 从头结点向后遍历
    while (temp.next != null) {
        if (index == 1) {
            head = head.next;
            return head.item;
        }

        if (++count == index) {
            E oldValue = temp.next.item;
            temp.next = temp.next.next;
            return oldValue;
        }
        // temp 始终指向下一个节点
        temp = temp.next;
    }

    return null;
}
```
这个删除操作也比较简单，也需要遍历单链表，直到索引位置结点，然后将结点的前驱节点的next指向索引节点的下一个节点即可。

### set方法

set方法将索引的结点的值设置为传入的值，也需要遍历单链表，套路都一样。代码如下：
```java
@Override
public E set(int index, E data) {
    if (data == null)
        throw new NullPointerException();
    checkPositionIndex(index);

    int count = 1;
    Node temp = head;
    while (temp != null) {
        if (count++ == index) {
            E oldValue = temp.item;
            temp.item = data;
            return oldValue;
        }
        temp = temp.next;
    }

    return null;
}
```
### get方法

获取传入索引的结点的值，也需要遍历单链表，就不说了，代码如下：
```java
@Override
public E get(int index) {
    checkPositionIndex(index);
    int count = 1;
    Node temp = head;
    while (temp != null) {
        if (count++ == index) {
            return temp.item;
        }
        temp = temp.next;
    }

    return null;
}
```
### 反转单链表

反转单链表，这里我采用是遍历单链表，逐个链接点进行反转。原理是：使用p和q两个指针配合工作，使得两个节点间的指向反向，同时用r记录剩下的链表。流程如下图：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/SingleLinkedList-reverse.png?raw=true)


具体代码和步骤参考如下代码：
```java
/**
 * 链表反转
 * 遍历单链表，逐个链接点进行反转。
 * 原理：
 * 使用p和q两个指针配合工作，使得两个节点间的指向反向，同时用r记录剩下的链表。
 * 
 */
@Override
public void reverse() {
    if (head != null) {
        // 代表指向当前进行反转的下一个节点
        Node r;
        // p 代表进行节点指向反转的节点前一个节点
        Node p = head;
        // q 代表进行节点指向反转的当前节点
        Node q = head.next;

        // 首先将head指向的下一个节点置为null
        // 因为进行链表反转时头结点变成了尾节点，指向的下一个节点必然是null
        head.next = null;
        // 进行循环操作，p, q指向向前移动
        while (q != null) {
            // 将当前正在反转的节点的下一个节点指向r
            r = q.next;
            // 将当前节点的下一个节点指向其前一个节点(由指向后一个节点改为指向前一个节点)
            q.next = p;
            // p和q都向链表后面移一位
            // 原来的q变成了p
            p = q;
            // 原来的r变成了q
            q = r;
        }

        head = p;
    }
}
```

### 完整代码
完整代码链接：<br/>
https://github.com/mstao/data-structures/blob/master/LinkedList/src/pers/mingshan/linkedlist/SingleLinkedList.java

### 参考
http://blog.csdn.net/feliciafay/article/details/6841115