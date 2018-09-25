# Map  
Map的继承关系和简易类图如下：
    
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/Collection/Map.png?raw=true)

## HashMap

HashMap是Map基于散列表的实现(它取代了Hashtable)。插入和查询“键值对”的开销是固定的。可以通过构造器设置*容量*和*负载因子*，以调整容器的特性。

## LinkedHashMap

LinkedHashMap类似于HashMap，但是迭代遍历它时，取得“键值对”的顺序是其插入次序，或者是最近最少使用(LRU)的次序。只比HashMap慢一点；而在迭代访问时反而更快，因为它使用链表维护内部次序。

## TreeMap

TreeMap是基于红黑树的实现。查看“键”或“键值对”时，它们会被排序(次序由Comparable或Comparator决定)。TreeMap的特点在于，所得到的结果是经过排序的。TreeMap是唯一带有subMap()方法的Map,它可以返回一个子树。

## WeakHashMap

WeakHashMap是一种*弱键*(weak key)映射，允许释放映射所指向的对象；这是为解决某类特殊问题而设计的。如果映射之外没有引用指向某个“键”，则此“键”可以被垃圾收集器回收。


