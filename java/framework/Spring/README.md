# Spring   
java 后台开发无论如何都是绕不过Spring的，其核心是IOC和AOP。spring是一个轻量级的应用开发平台。       
 
[TOC]  

## 【整体架构】      
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/spring.webp?raw=true "spring架构")      
## 【核心容器】     
spring-core、spring-beans、spring-context、spring-context-support和spring-expression共同组成spring的核心容器。  

*spring-core* 和 *spring-beans*提供框架的基础部分，包括IOC功能，BeanFactory是一个复杂的工厂模式的实现，将配置和特定的依赖从实际程序逻辑中解耦。  

context模块建立在core和beans模块的基础上，增加了对国际化的支持、事件广播、资源加载和创建上下文，ApplicationContext是context模块的重点。  

spring-context-support提供对常见第三个库的支持，集成到spring上下文中，比如缓存(ehcache,guava)、通信(javamail)、调度(commonj,quartz)、模板引擎等(freemarker,velocity)。  

spring-expression模块提供了一个强大的表达式语言用来在运行时查询和操作对象图，这种语言支持对属性值、属性参数、方法调用、数组内容存储、集合和索引、逻辑和算数操作及命名变量，并且通过名称从spring的控制反转容器中取回对象。    
     
          
## 【AOP和服务器工具】  
spring-aop模块提供面向切面编程实现，单独的spring-aspects模块提供了aspectj的集成和适用。  

spring-instrument提供一些类级的工具支持和ClassLoader级的实现，用于服务器。spring-instrument-tomcat针对tomcat的instrument实现。       
      

## 【消息组件】   
spring框架4包含了spring-messaging模块，从spring集成项目中抽象出来，比如Messge、MessageChannel、MessageHandler及其他用来提供基于消息的基础服务。    
     

## 【数据访问/集成】    

数据访问和集成层由JDBC、ORM、OXM、JMS和事务模块组成。

spring-jdbc模块提供了不需要编写冗长的JDBC代码和解析数据库厂商特有的错误代码的JDBC抽象出。

spring-tx模块提供可编程和声明式事务管理。

spring-orm模块提供了领先的对象关系映射API集成层，如JPA、Hibernate等。

spring-oxm模块提供抽象层用于支持Object/XML maping的实现，如JAXB、XStream等。

spring-jms模块包含生产和消费消息的功能，从Spring4.1开始提供集成spring-messaging模块。   
    

## 【web】    
     
Web层包含spring-web、spirng-webmvc、spring-websocket和spring-webmvc-portlet模块组成。

spring-web模块提供了基本的面向web开发的集成功能，例如多文件上传、使用servert listeners和web开发应用程序上下文初始化IOC容器。也包含HTTP客户端以及spring远程访问的支持的web相关部分。

spring-webmvc包含spring的model-view-controller和REST web services 实现的Web应用程序。

spring-webmvc-portlet模块提供了MVC模式的portlet实现，protlet与Servlet的最大区别是请求的处理分为action和render阶段，在一个请求中，action阶段只执行一次，但render阶段可能由于用户的浏览器操作而被执行多次。     
       

## 【测试】     

spring-test模块支持通过组合Junit或TestNG来进行单元测试和集成测试，提供了连续的加载ApplicationContext并且缓存这些上下文。      
      
## 参考：     
- [Spring技术内幕：设计理念和整体架构概述](https://mp.weixin.qq.com/s/2dCebIpVjE43xUpx-2YCTg)
