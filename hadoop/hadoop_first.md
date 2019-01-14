
Hadoop 主要是运行在Linux平台，所以安装和测试都在Linux上，这里以Ubuntu Linux系统为例来安装和配置Linux。

## 配置Hadoop用户组

**创建Hadoop用户组：**

```
$ sudo addgroup hadoop
```

**创建Hadoop用户：**

```
$ sudo adduser -ingroup hadoop hadoop
```

回车后会提示输入密码，这是新建Hadoop的密码，输入两次密码敲回车即可。如下图所示：

```
mingshan@ubuntu:/usr$ sudo adduser -ingroup hadoop hadoop
Adding user `hadoop' ...
Adding new user `hadoop' (1001) with group `hadoop' ...
Creating home directory `/home/hadoop' ...
Copying files from `/etc/skel' ...
Enter new UNIX password: 
Retype new UNIX password: 
passwd: password updated successfully
Changing the user information for hadoop
Enter the new value, or press ENTER for the default
	Full Name []: 
	Room Number []: 
	Work Phone []: 
	Home Phone []: 
	Other []: 
Is the information correct? [Y/n] y

```
**为Hadoop用户添加权限：**

```
$ sudo vim /etc/sudoers
```
然后在

`root　　　　ALL=(ALL:ALL) ALL`

后添加：

`hadoop　　 ALL=(ALL:ALL) ALL`

如下所示：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/sudoers.png?raw=true)

**切换hadoop用户**

```
su - hadoop
```

## 配置SSH

Linux 系统需要安装ssh和rsync，命令如下：


```
$ sudo apt-get install ssh 
$ sudo apt-get install rsync
```

检测sshd运行状态

```
systemctl status sshd
```

## 镜像下载

首先选择国内的镜像速度较快

```
$ wget http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-3.1.1/hadoop-3.1.1.tar.gz
```

解压

```
$ sudo tar -zxvf hadoop-3.1.1.tar.gz
```

将hadoop移动到 /usr/local/hadoop目录下：

```
$ sudo mv hadoop-3.1.1 /usr/local/hadoop
```

给hadoop用户授予`/usr/local/hadoop`文件夹权限：
```
$ sudo chown -R hadoop:hadoop /usr/local/hadoop
```

## 运行hadoop

**Hadoop部署模式**

Hadoop部署模式有：本地模式、伪分布模式、完全分布式模式、HA完全分布式模式。

下面是各模式的区别：

模式名称       | 	各个模块占用的JVM进程数	 |  各个模块运行在几个机器数上
---|---|---
本地模式       |	1个	| 1个
伪分布式模式   |	N个	| 1个
完全分布式模式 |	N个	| N个
HA完全分布式   |	N个	| N个


### 本地模式部署

我们来测试本地部署模式，用在带的例子（比如WordCount）进行测试

首先在`/usr/local/hadoop/hadoop-3.1.1` 文件夹下创建`input`文件夹

```
$ mkdir input
```

拷贝 README.txt 到 input 文件夹

```
$ cp README.txt input
```

运行测试例子，命令如下：

```
$ bin/hadoop jar share/hadoop/mapreduce/sources/hadoop-mapreduce-examples-3.1.1-sources.jar org.apache.hadoop.examples.WordCount input output
```

运行后会在屏幕上输出一大堆东西，最终如下：

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/hadoop/hadoop-example1-result.png?raw=true)


OK, 安装测试完毕，撒花✿✿ヽ(°▽°)ノ✿


参考：

- [Hadoop快速入门](http://hadoop.apache.org/docs/r1.0.4/cn/quickstart.html)
- [在Ubuntu系统上一步步搭建Hadoop（单机模式）](https://www.cnblogs.com/maybe2030/p/4591195.html)
- [史上最详细的Hadoop环境搭建](https://blog.csdn.net/hliq5399/article/details/78193113)