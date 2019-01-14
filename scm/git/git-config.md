# git config     
git在使用时，一般需要配置用户名和邮箱用来标识用户。在配置时有两种配置方式，全局配置和针对单个项目的配置。   
## 全局配置    
使用`git config --gloable ××××`命令进行全局配置，全局配置之后，从所有本机git仓库提交的内容标识都以全局配置为准，其具体命令如下：    
```
# 进行全局设置
git config --global user.name ""
git config --global user.email "×××××@×××.com"

# 取消全局设置
git config --global --unset user.name ""
git config --global --unset user.email "×××××@×××.com"
```   

## 局部配置    
当本机有多个git账号，例如既要使用公司的gitlab , 又要使用github , 这时全局配置就不能满足需求了，需要针对具体的项目，在项目目录下进行配置
```
git config user.name ""  
git config user.email "××××@×××.com"

git config --unset user.name ""
git config --unset user.email "×××××@×××.com" 
```    
## 查看git配置    
```
git config --list
```