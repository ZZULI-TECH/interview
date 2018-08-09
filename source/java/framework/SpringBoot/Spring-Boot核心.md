---
title: Spring Boot核心
date: 2018-08-06 16:17:24
tags: [spring,Spring Boot]  
categories: 
- 微服务   
- Spring Boot
---
<!-- more -->    
[参考](https://lyfzhixing.github.io/2018/08/06/Spring-Boot%E6%A0%B8%E5%BF%83/)       
## - 基本配置  
### - 启动入口   
Spring Boot通常有一个入口类，*Application.java，运行该类中的main方法即可启动项目。   
在入口类可以使用@SpringBootApplication注解进行配置，也可以使用@Configuration、@EnableAutoConfiguration和@ComponentScan组合进行注解配置。    
@EnableAutoConfiguration让Spring Boot根据类路径中的jar包依赖为当前项目进行自动配置  
使用@SpringBootApplication注解exclude参数可以关闭特定的自动配置  
   
### - 配置文件   
在src/main/resources目录下或根路径/config下，使用一个全局配置文件application.properties或Application.yml。   
举个小栗子： （修改Tomcat的默认端口8080为8090，并将默认的访问路径"/"修改为"/helloboot"）     

```
Application.properties:   
server.port=8090   
server.context-path=/helloboot   
   
application.yml:    
server:   
    port: 8090   
    context-path: /helloboot 
```   
  
### - Starter pom    
官方提供spring-boot-starter : Spring Boot 核心starter，包含自动配置、日志、yaml配置文件的支持  
和spring-boot-starter-*等starter   
    
### - xml配置   
虽然Spring Boot提倡零配置，但在实际项目中，还是会有一些特殊的需求需要使用xml配置，可以通过Spring的@ImportResource来加载配置。      

```
@ImportResource({"classpath:some-context.xml","classpath:another-context.xml"})
```   
## - Spring Boot配置属性的加载顺序   
1. 在命令行中传入的参数；   
2. SPRING——APPLICATION——JSON中的属性。SPRING——APPLICATION——JSON是以JSON格式配置在系统环境变量中的内容；    
3. java:comp/env中的JNDI配置；    
4. Java的系统属性，可以通过System.getProperties()获得的内容；    
5. 操作系统的环境变量；       
6. 通过random.*配置的随机属性；    
7. 位于当前应用jar包之外，针对不同{profile}环境的配置文件内容，例如application-{profile}.properties或是YAML定义的配置文件；     
8. 位于当前应用jar包之内，针对不同{profile}环境的配置文件内容，例如application-{profile}.properties或是YAML定义的配置文件；     
9. 位于当前应用jar包之外的application.properties和YAML配置内容；    
10. 位于当前应用jar包之外的application.properties和YAML配置内容；         
11. 在@Configuration注解修改的类中，通过@PropertySource注解定义的属性；    
12. 应用默认属性，使用SpringApplication.setDefaultProperties定义的内容     
## spring boot中的监控与管理    
actuator模块