# lambda

lambda 的通用格式(参数类型可以不用声明):
```
(Type a, Type b, ……) -> {
    statment1;          //代码1
    statment2;          //代码2
    ……
    return statmentN;
}
```    
当只有一个参数时：    
```
a -> {
    ……
}
```    
当只有一行代码时：     
```
(Type a, Type b, ……) -> expression;
```    
## 函数式编程   
`@FunctionalInterface`注解声明函数式接口，该接口中只能有一个抽象方法，    
例如：     
```
@FunctionalInterface
public static interface Converter<F, T> {
    T converter(F from);
}
```
可以使用lambda表达式实现函数式接口，在java8之前内部实现接口都是用匿名类的，    
例如：
```
Converter<String, Integer> integerConverter1 = from -> Integer.valueOf(from);
```    
上边的lambda表达式可以简写为：
```
// method reference
Converter<String, Integer> integerConverter2 = Integer::valueOf;
```   
这就是方法引用，其写法为：
```
Class or instance :: method
```      
lambda 表达式的局部变量可以不用声明为 final，但是必须不可被后面的代码修改（即隐性的具有 final 的语义）      
```
int num = 1;  
Converter<Integer, String> s = (param) -> System.out.println(String.valueOf(param + num));
s.convert(2);
num = 5;  
//报错信息：Local variable num defined in an enclosing scope must be final or effectively final
```

在 Lambda 表达式当中不允许声明一个与局部变量同名的参数或者局部变量     
```
String first = "";  
Comparator<String> comparator = (first, second) -> Integer.compare(first.length(), second.length());  //编译会出错 
```