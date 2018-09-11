# MongoDB

## Centos安装

首先更新系统

```
yum -y update
```

安装Mongodb

编辑Mongodb安装源


```
vim /etc/yum.repos.d/mongodb-org-3.6.repo
```

编辑内容如下：


```
[mongodb-org-3.6]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.6/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc
```

安装

```
yum install -y mongodb-org
```

修改mongodb配置文件


```
vim /etc/mongod.conf
```

开启认证并支持远程连接

```
net:
  port: 21111
  bindIp: 0.0.0.0

security:
  authorization: enabled
  javascriptEnabled: false
```
保存后重启系统


```
reboot
```

windows请参考：[MongoDb在windows下的安装与以auth方式启用服务](https://www.cnblogs.com/yjq-code/p/6880625.html)

## 运行

由于已经启动了认证模式，启动时会自动应用


```
service mongod start
```

在终端输入"mongo"，然后回车进入数据库

```
mongo
```

创建管理员用户


```
use admin

db.createUser( 
{ 
user: "admin", 
pwd: "admin123", 
roles: [ { role: "userAdminAnyDatabase", db: "admin" } ] 
} )
```
创建普通用户

```
use test
db.createUser({user:"test",pwd:"123456",roles:[{role:"readWrite",db:"test"}]})
```

测试登录

```
mongo -u test -p 123456 localhost:27017/test
```
