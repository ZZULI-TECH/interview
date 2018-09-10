# List   
List的继承关系和简易类图如下：
   
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/Collection/List.png?raw=true)

## 对比Vector、ArrayList、LinkedList有何区别？

这三者都实现了List接口，也就是所谓有序集合，它们有很多相似的地方，比如元素都是可以重复的，都是按照索引位置进行元素的查找、修改和删除操作的，但由于具体设计细节和性能方面的差异，它们应用场景也有很大差异。

**Vector**是JDK早期基于synchronized实现的线程安全的动态数组，在官方文档中，如果没有线程安全的需求，不建议使用Vector，而是使用ArrayList替代，毕竟同步是需要性能开销的。Vector底层使用数组来存储数据，可以根据需要自动扩容，默认容量为10，当数组已满时，会创建新的数组，并拷贝原有数组数据。

**ArrayList**底层也是基于数组实现的动态数组，它不是线程安全的，所以在单线程环境，性能会好很多。它的初始容量也是10，可以根据需要自动扩容，只不过和Vector有区别，Vector 在扩容时会提高 1 倍，而 ArrayList则是增加50%。

**LinkedList**，从名字就可以看出它底层是利用链表来存储数据，而且是双向链表，所以不需要自动扩容，它也不是线程安全的。

所以总结如下：

**1 底层实现方式**

ArrayList和Vector内部用数组来实现；LinkedList内部采用双向链表实现。

**2 读写机制**

ArrayList在执行插入元素是超过当前数组初始容量时，数组需要扩容，扩容过程需要调用底层System.arraycopy()方法进行大量的数组复制操作；在删除元素时并不会减少数组的容量（如果需要缩小数组容量，可以调用trimToSize()方法）；在查找元素时要遍历数组，对于非null的元素采取equals的方式寻找。

LinkedList在插入元素时，须创建一个新的Entry对象，并更新相应元素的前后元素的引用；在查找元素时，需遍历链表；在删除元素时，要遍历链表，找到要删除的元素，然后从链表上将此元素删除即可。

Vector与ArrayList仅在插入元素时容量扩充机制不一致。对于Vector，默认创建一个大小为10的Object数组，并将capacityIncrement设置为0；当插入元素数组大小不够时，如果capacityIncrement大于0，则将Object数组的大小扩大为现有size+capacityIncrement；如果capacityIncrement<=0,则将Object数组的大小扩大为现有大小的2倍。

**3 读写效率**

ArrayList对元素的增加和删除都会引起数组的内存分配空间动态发生变化。因此，对其进行插入和删除速度较慢，但检索速度很快。

LinkedList由于基于链表方式存放数据，增加和删除元素的速度较快，但是检索速度较慢。

**4 线程安全性**

ArrayList、LinkedList为非线程安全；Vector是基于synchronized实现的线程安全的ArrayList。

需要注意的是：单线程应尽量使用ArrayList，Vector因为同步会有性能损耗；即使在多线程环境下，我们可以利用Collections这个类中为我们提供的synchronizedList(List list)方法返回一个线程安全的同步列表对象。

```Java
public static <T> List<T> synchronizedList(List<T> list) 

```

**适用场景：**

Vector 和 ArrayList 作为动态数组，其内部元素是以数组形式存储的，所以十分适合随机访问，但对于除尾部删除、插入操作，需要移动其他元素，效率会差些。

LinkedList由于底层是双向链表，啥双向链表的特性我们比较清楚，进行节点插入、删除却要高效得多，但是随机访问性能则要比动态数组低。

参考：
- 杨晓峰，对比Vector、ArrayList、LinkedList有何区别？
- JDK10源码和文档