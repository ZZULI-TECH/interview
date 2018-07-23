# Spring AOP     
*AOP*要实现的是在我们原来写的代码基础上，进行一定的包装，如在方法执行前、方法返回后、方法抛出异常后等地方进行一定的拦截处理或者叫增强处理。       
     
AOP的实现并不是因为Java提供了什么神奇的[钩子](https://baike.baidu.com/item/%E9%92%A9%E5%AD%90%E5%87%BD%E6%95%B0),可以把方法的生命周期告诉我们，而是我们要实现一个代理，实际运行的实例其实就是代理类的实例。    
    
Spring AOP基于动态代理实现。默认地，如果使用接口，使用JDK提供的动态代理实现，如果没有接口，使用cglib实现。

**JDK动态代理**

- JDK动态代理： 通过反射类Proxy以及InvocationHandler回调接口实现的   

- JDK动态代理缺点： JDK中所要进行动态代理的类必须要实现一个接口，也就是说只能对该类所实现接口中定义的方法进行代理，这在实际编程中具有一定的局限性，而且使用反射的效率也并不是很高。   

**CGLIB**

- CGLIB原理：动态生成一个要代理类的子类，子类重写要代理的类的所有不是final的方法。在子类中采用方法拦截的技术拦截所有父类方法的调用，顺势织入横切逻辑。它比使用java反射的JDK动态代理要快。     
- CGLIB底层：使用字节码处理框架ASM，来转换字节码并生成新的类。不鼓励直接使用ASM，因为它要求你必须对JVM内部结构包括class文件的格式和指令集都很熟悉。  

- CGLIB优点：它为没有实现接口的类提供代理，为JDK的动态代理提供了很好的补充。通常可以使用Java的动态代理创建代理，但当要代理的类没有实现接口或者为了更好的性能，CGLIB是一个好的选择。        
- CGLIB缺点：对于final方法，无法进行代理      
   
[AspectJ 是一个 AOP 编程的完全解决方案](https://www.javadoop.com/post/aspectj)，可以在Spring中使用，但Spring中的@AspectJ注解和AspectJ并无关系。    
     
- Spring AOP 在开发中的实际应用有：   
   - 日志：对特定的操作输出日志来记录。   
   - 安全：在执行操作之前进行操作检查。      
   - 事务：在方法开始之前开始事务，结束之后提交或回滚事务。   
   - 性能统计：统计每个方法的执行时间。      
   - ……       

这些非功能性需求，是多个业务模块都需要的，是跨越模块的，使用OOP设计如下图：      
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/springAOP01.png?raw=true)   
这样设计会使日志，安全，事务，性能和统计相关的代码与真正的业务代码混在一块，降低可读性和可维护性。      
应该使用AOP思想，面向切面(Aspect)编程。把日志/安全/事务这样的代码和业务代码完全隔离开来，因为他们的关注点和业务代码的关注点完全不同，他们之间应该是正交的，他们之间的关系应该是这样的：       

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/SpringAOP02.png?raw=true)    

参考：   
- [Spring AOP 使用介绍，从前世到今生](https://www.javadoop.com/post/spring-aop-intro?hmsr=toutiao.io&utm_medium=toutiao.io&utm_source=toutiao.io)    
- [Spring本质系列(2)-AOP](https://mp.weixin.qq.com/s/Hiug-ed9gUPg8IA3PW-msA)
