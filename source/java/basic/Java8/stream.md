# stream   
java 8 中的stream流是一个来自数据源的元素队列并支持聚合操作    
- 元素是特定类型的对象，形成一个队列。stream不会存储元素，只是按需计算    
- 的数据来源可以`集合`，`数组`，`I/O channel`,产生器`generator`等    
- 可以进行`聚合操作`，filter,map,reduce,find,match,sorted等   
- 具有 Pipelining 和 内部迭代    
    - `Pipelining`： 中间操作都会返回流对象本身。这样多个操作可以串联成一个管道，如同流式风格（fluent style）。这样做可以对操作进行优化，比如延迟执行（laziness）和短路（short-circuiting）   
    - `内部迭代`： 以前对集合遍历都是通过Iterator或者For-Each的方式, 显式的在集合外部进行迭代， 这叫做外部迭代。Stream提供了内部迭代的方式， 通过访问者模式(Visitor)实现   
    
## filter 过滤  

```Java
List<String> stringList = Arrays.asList("aa","zz","bb","","cd","kk","aa");

List<String> filtered = stringList.stream().filter(str -> !str.isEmpty()).collect(Collectors.toList());
```   

## forEach 遍历

```Java
filtered.stream().forEach(System.out::println);
```   

## map 映射每个元素到对应的结果 

```Java
List<String> maped1 = stringList.stream().map(str -> str+str).collect(Collectors.toList());
```    
## distinct 去重
```Java
List<String> maped2 = stringList.stream().map(str -> str+str).distinct().collect(Collectors.toList());  
```   
## limit 限流
```Java
 stringList.stream().limit(2).forEach(System.out::println);
```
## sort 排序
```Java
stringList.stream().sorted().forEach(System.out::println);
```    
## Collectors 规约操作(上边的toList和下边的joining)
```Java
String subString = stringList.stream().filter(str -> !str.isEmpty()).collect(Collectors.joining());
System.out.println(subString); // aazzbbcdkkaa
```
## summaryStatistics 统计     
getMax(),getMin(),getSum(),getAverage()等， 常用于int,double,long等基本类型  

```Java
List<Integer> numbers = Arrays.asList(3, 2, 2, 3, 7, 3, 5);

IntSummaryStatistics stats = numbers.stream().mapToInt((x) -> x).summaryStatistics();

System.out.println("列表中最大的数 : " + stats.getMax()); // 7
System.out.println("列表中最小的数 : " + stats.getMin()); // 2
System.out.println("所有数之和 : " + stats.getSum()); // 25
System.out.println("平均数 : " + stats.getAverage()); // 3.5714285714285716
```
