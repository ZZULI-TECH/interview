# 双向链表

### 双向链表描述

双向链表也叫双链表，它的每个数据结点都有两个指针，分别指向前驱结点和后继节点，同时有一个数据域来保存数据，双向链表的图示如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/DoubleLinkedList.png?raw=true)

从图片可以看出，双链表的头结点的前驱结点和尾结点的后继结点为空，这一点要注意，对双链表的操作要检查这两种情况。

### 双向链表结构

每个数据结点都有两个指针，分别指向前驱结点和后继节点，同时有一个数据域来保存数据，我们先来定义一个数据结点的结构：

```java
/**
 * 内部Node，用于存储链表的结点
 * @author mingshan
 *
 */
private class Node {
    // 存储节点的值
    E item;
    // 指向节点的前驱结点
    Node next;
    // 指向节点的后继结点
    Node prev;

    Node(Node prev, E element, Node next) {
        this.item = element;
        this.next = next;
        this.prev = prev;
    }
}

```

从Node类我们可以看出，item代表结点存储的元素，next指向链表的后继结点，prev指向前驱结点，由于我们在写单链表时定义了**LinkedList**接口，所以我们直接实现这个接口好了。

下面是对双向链表的功能的具体分析。

### add方法

我们现在定义三个成员变量：**size**， **first**，**last**，用来表示链表结点的个数以及指向链表头结点和尾节点，代码与解释如下：

```java
// 链表结点数量
private int size = 0;

// 指向头结点
private Node first;

// 指向尾结点
private Node last;
```
#### add(E data)
首先我们来实现**add(E data)**方法，代码如下：

```java
@Override
public boolean add(E data) {
    if (data == null)
        throw new NullPointerException();
    // 将当前结点作为尾结点
    linkLast(data);
    return true;
}
```
在这个方法中我们调用了linkLast(data)这个方法来将当前节点作为尾结点，代码如下：

```java
/**
 * 将当前结点作为尾结点
 * @param e
 */
private void linkLast(E data) {
    final Node l = last;
    final Node newNode = new Node(l, data, null);
    last = newNode;
    if (l == null) {
        first = newNode;
    } else {
        // 原来的尾结点指向新结点
        l.next = newNode;
    }
    size++;
}
```
在linkLast方法中，先获取尾结点，再构造新节点，让last指向新节点，然后开始判断原来的尾节点是否为空，为空代表链表为空，让first指向新结点即可；如果不为空，那么原来的尾结点的next指向新结点。

#### add(int index, E data)

我们再来**add(int index, E data)**这个方法怎么实现，代码如下：

```java
@Override
public void add(int index, E data) {
    if (data == null)
        throw new NullPointerException();
    checkPositionIndex(index);

    // 判断在该索引的结点是不是尾结点
    if (size == index) {
        // 将当前结点作为尾结点
        linkLast(data);
    } else {
        // 将结点插入到指定位置index(原来的结点之前)
        linkBefore(index, data);
    }
}
```
这个方法的作用是向索引位置index处添加结点，这个时候我们就需要检测index是否有效，**checkPositionIndex(index)**相关的方法如下：


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
    return index >= 0 && index <= size;
}

```

如果index符合以上要求，那么就要判断在该索引位置的结点是不是尾结点，如果是，直接调用**linkLast(data)** 将当前节点作为尾结点；如果不是，将结点插入到指定位置index(原来的结点之前)，此时调用**linkBefore(index, data)**方法，代码如下：

```java
/**
 * 将结点插入到指定位置index(原来的结点之前)
 * @param index
 * @param data
 */
private void linkBefore(int index, E data) {
    Node curr = node(index);
    Node pred = curr.prev;
    Node newNode = new Node(pred, data, curr);
    curr.prev = newNode;
    
    if (pred == null) {
        first = newNode;
    } else {
        pred.next = newNode;
    }
    size++;
}
```
在该方法中，我们需要获取在该索引位置的节点**curr**，**curr**的前驱结点**pred**，以及构造新节点**newNode**，同时还要将**curr**的前驱结点指向新节点，然后判断**pred**是否为空，如果**pred**为空，说明**curr**为头结点，那么此时就让新节点作为头结点；如果不为空，说明此时属于一般情况，在链表的中间的某个位置插入元素，那么就让**prev**的后继结点指向新节点就行了。

### remove方法

#### remove(int index)

根据索引位置来删除元素，代码如下：

```java
@Override
public E remove(int index) {
    checkElementIndex(index);

    // 获取在该索引位置上的结点
    Node c = node(index);
    E element = c.item;
    Node prev = c.prev;
    Node next = c.next;

    // 代表头结点
    if (prev == null) {
        // 将下一个结点置为头结点
        first = next;
        // 将下一个结点的前驱结点置为null
        next.prev = null;
        // 将原来头结点的后继结点置为null
        c.next = null;
    } else if (next == null) {
        // 移除尾结点
        last = prev;
        // 前一个结点的后继结点置为null
        prev.next = null;
        // 将原来尾结点的前驱结点置为null
        c.prev = null;
    } else {
        // 属于一般情况
        // 将前一个结点的后继结点置为原结点的后继结点
        prev.next = next;
        // 将后一个结点的前驱结点置为原结点的前驱结点
        next.prev = prev;
        // 切断当前删除的结点的前驱和后继结点
        c.prev = null;
        c.next = null;
    }

    c.item = null;
    size--;
    return element;
}
```

在该方法中，还是要先检测索引是否合法，这里是**checkElementIndex(index)**方法，代码如下：


```java
/**
 * 检测元素位置是否合法
 * @param index
 */
private void checkElementIndex(int index) {
    if (!isElementIndex(index))
        throw new IndexOutOfBoundsException("查找元素位置不合法");
}

private boolean isElementIndex(int index) {
    return index >= 0 && index < size;
}
```
检测通过后就要获取在该索引处的结点信息，包括结点的数据，前驱节点和后继节点，此时有三种情况需要考虑：

- 如果**prev**为空，代表该结点为头结点，那么就将下一个结点置为头结点，然后将下一个结点的前驱结点置为null，最后将原来头结点的后继结点置为null。说白了就是讲头结点移除，同时解除头结点与后面一个节点的关系。
- 如果**next**为空，代表该结点为尾节点，那么就将尾节点的前驱节点作为尾节点，前一个结点的后继结点置为null，将原来尾结点的前驱结点置为null。
- 如果既不是头结点，又不是尾节点，那么就属于一般情况了，此时将前一个结点的后继结点置为原结点的后继结点，将后一个结点的前驱结点置为原结点的前驱结点，最后切断当前删除的结点的前驱和后继结点。

以上代码可以简化，具体可以参考JDK源码中**java.util.LinkedList**中的**unlink**方法，简化后的代码如下：

```java
// 代表头结点
if (prev == null) {
    first = next;
} else {
    prev.next = next;
    c.prev = null;
}

if (next == null) {
    last = prev;
} else {
    next.prev = prev;
    c.next = null;
}
```
老铁们看懂了吗(￣▽￣)／，其实和我上面的代码效果是一样的，只是把一般情况合并了，也很好理解。

### set方法

set方法将索引位置的结点的值替换成新的值，代码如下：

```java
@Override
public E set(int index, E data) {
    if (data == null)
        throw new NullPointerException();
    checkPositionIndex(index);

    // 获取原来在该索引位置上的结点
    Node oldNode = node(index);
    // 获取原来结点的值
    E oldValue = oldNode.item;
    // 更新值
    oldNode.item = data;
    return oldValue;
}
```
此时获取当前索引位置的结点用到了**node(index)**方法，代码如下：

```java
/**
 * 根据索引获取结点
 * @param index
 * @return
 */
private Node node(int index) {
    // 如果当前索引值小于当前链表长度的一半，那么从头结点开始遍历
    if (index < size / 2) {
        Node temp = first;
        for (int i = 0; i < index; i++) {
            temp = temp.next;
        }

        return temp;
    } else {
        // 如果当前索引值大于当前链表长度的一半，那么从尾结点反向遍历
        Node temp = last;
        for (int i = size - 1; i > index; i--) {
            temp = temp.prev;
        }

        return temp;
    }
}
```
在**node**方法中，我们进行了折半查找，这样效率会高些吧，哈哈，简单就不说了。

### get方法

获取传入索引的结点的值，也需要遍历双链表，就不说了，代码如下：

```java
@Override
public E get(int index) {
    checkElementIndex(index);
    // 获取其索引的结点
    Node node = node(index);
    return node.item;
}

```

### 反转双链表

反转双链表，这里我采用是遍历双链表，逐个链接点进行反转。原理是：使用p和q两个指针配合工作，使得两个节点间的指向反向，同时用r记录剩下的链表。
图示如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/DoubleLinkedList-reverse.png?raw=true)

具体代码和步骤参考如下代码：
```java
@Override
public void reverse() {
    if (first != null) {
        // 代表指向当前进行反转的下一个结点
        Node r;
        // p 代表进行结点指向反转的结点前一个结点
        Node p = first;
        // q 代表进行结点指向反转的当前结点
        Node q = first.next;

        // 首先将head指向的下一个结点置为null
        // 因为进行链表反转时头结点变成了尾结点，指向的下一个结点必然是null
        first.next = null;
        // 进行循环操作，p, q指向向前移动
        while (q != null) {
            // 将当前正在反转的结点的下一个结点指向r
            r = q.next;
            // 将当前结点的下一个结点指向其前一个结点(由指向后一个结点改为指向前一个结点)
            q.next = p;
            // 将当前结点的prev改为指向下一个结点
            p.prev = q;
            // p和q都向链表后面移一位
            // 原来的q变成了p
            p = q;
            // 原来的r变成了q
            q = r;
        }
        // 将最后一个结点的prev指向为null
        p.prev = null;
        // 将原来的头结点置为尾结点
        last = first;
        // 将最后一个结点置为头结点
        first = p;
    }
}
```

### 完整代码
完整代码：<br/>
https://github.com/mstao/data-structures/blob/master/LinkedList/src/pers/mingshan/linkedlist/DoubleLinkedList.java