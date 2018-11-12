# 循环队列

## ArrayQueue假溢出

我们在利用数组实现队列的时候，发现数组队列会出现假溢出问题，即队列还没有满，但不能再往队列中放入元素了，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/ArrayQueue_false_overflow.png?raw=true)

在数据进行出队的时候，每一个元素出队，指向队列头元素的head就会向后移动，导致head之前的元素被“遗忘”了，无法再次利用，出队的代码如下：

```Java
@Override
public E poll() {
    if (!isEmpty()) {
        E value = (E) elements[head];
        // 移除头部元素
        elements[head] = null;
        head++;
        return value;
    }

    return null;
}

```

当然，我们可以对数组队列进行一些优化。在插入元素的时候，我们检查一下tail是否已经指向了队尾，如果指向了队尾并且head不等于0的情况下，说明发生了假溢出，需要进行元素迁移工作，将head和tail之间的元素整体移动到 0 到 `tail - head ` 的位置，这样就可以避免假溢出问题了（还是上面的图），实现代码如下：


```Java
/**
 * 由于数组队列存在假溢出问题，所谓要进行数据搬运
 */
@Override
public boolean add(E e) {
    Objects.requireNonNull(e);

    if (tail == capacity) {
        if (head == 0) {
            // 证明队列是满的
            throw new IllegalStateException("Queue full");
        }
        // 如果head 不等于0，证明head之前的空间是空着的，所以需要进行数据搬运
        for (int i = head; i < tail; i++) {
            elements[i - head] = elements[i];
        }
        // 搬运完更新head 和 tail
        head = 0;
        tail -= head; // tail = tail - head
    }

    // 正常操作
    elements[tail++] = e;
    return true;
}

```


## 循环队列

上面我们知道了假溢出问题，并且找到了解决方式，但在添加元素的时候可能会出现数据移动工作，并不是十分优雅，有没有一种比较好的方式去处理这个问题呢？既不出现假溢出问题，又不移动数据，还...（想的太多），答案是有的。仔细想想如果我们将数组队列收尾相连会出现什么情况，哈哈，根本不用管假溢出问题了，添加元素的时候直接往后移动tail（tail 加 1）就完事了，是不是很酷？大致结构如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/CircularQueue.png?raw=true)


### 空和满队列判断

看完描述和图示，我们可能会有疑问，head 和 tail的位置一直是不固定的，那么该如何判断队列是否满的呢？

当**循环队列为空**时，很明显head 和 tail 是相等的，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/CircularQueue_empty.png?raw=true)

那么如何判断队列是否满了呢？ 由于我们用head与tail相等来判断队列为空的情况，所以队列满时，必须有一个空位来由我们的tail指向，如下图所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/CircularQueue_full.png?raw=true)

上图只是一种情况，总结来说，队头指针head在队尾指针tail的下一位置时，队满。由于是环形结构，所以需要进行求余运算，例如`（5 + 1） % 8 = 3`，总结规律下来，就是 

```
(head + 1） % capacity = tail
```

由于这种机制的存在，当队列满时，总有一个位置是被浪费掉的。

**构造函数和成员变量**

循环队列默认把元素存到数组里，所以这里用数组来保存队列里的元素，在构造函数中初始化容量和数组，代码如下：

```Java
// 队列内部数组默认容量
private static final int DEFAULT_CAPACITY = 8;

// 队列内部数组的容量
private int capacity;

// 保存元素的数组
private Object[] elements;

// 指向队列头部
private int head;

// 指向队列尾部
private int tail;

/**
 * 默认构造函数初始化
 */
public CircularQueue() {
    capacity =  DEFAULT_CAPACITY;
    elements = new Object[capacity];
}

/**
 * 指定队列内部数组容量进行初始化
 * @param capacity 指定容量
 */
public CircularQueue(int capacity) {
    this.capacity = capacity;
    elements = new Object[capacity];
}


```

下面就不废话了，直接看实现吧，通过上面的分析，代码没什么难度了。嘻嘻^_^

**入队**

```
@Override
public boolean add(E e) {
    Objects.requireNonNull(e);
    // 判断队列是否满了
    if ((tail + 1) % capacity == head) {
        throw new IllegalStateException("Queue full");
    }

    elements[tail] = e;
    tail = (tail + 1) % capacity;
    return true;
}
```

**出队**

```
@Override
public E poll() {
    // 如果 head == tail, 队列就为null
    if (isEmpty()) {
        return null;
    }

    E value = (E) elements[head];
    head = (head + 1) % capacity;
    return value;
}
```

**打印**


```
/**
 * 打印
 */
public String toString() {
    if (isEmpty()) {
        return "[]";
    } else {
        StringBuilder sb = new StringBuilder("[");
        for (int i = head; i != tail; i = (i + 1) % capacity) {
          sb.append(elements[i].toString() + ", ");
        }
        int len = sb.length();  
        return sb.delete(len - 2, len).append("]").toString();
    }
}
```


源代码在[这里](https://github.com/mstao/data-structures/blob/master/Queue/src/pers/mingshan/queue/CircularQueue.java)
