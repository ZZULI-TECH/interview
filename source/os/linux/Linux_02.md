Linux-02
==========================================
1、Linux程序安装
----------------------
&ensp;&ensp;linux程序安装有三种，包管理安装方式、解压程序包配置环境变量方式和自己编译并安装方式。这三种安装方式的难易程度依次递增。
现在我们通过包管理方式安装JDK，如果使用远程yum仓库，安装的会是openjdk。所以我们需要先下载sunjdk的rpm包。然后通过yum方式本地安装
```bash
$ wget --no-check-certificate --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" "http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.rpm"
$ yum install jdk-8u181-linux-x64.rpm
```

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/yum_install_jdk.png?raw=true)

<center>yun 安装jdk</center>

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/java_install_success.png?raw=true)

<center>jdk安装成功</center>

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/find_javapath.png?raw=true)

<center>查找出yum安装jdk的真正路径</center>

&ensp;&ensp;在通过包管理的方式安装成功之后，我们试一试自己解压并配置环境变量的方式安装jdk。首先要卸载yum安装的jdk。卸载完之后下载jdk的Linux版本的后缀为.tar.gz的压缩文件，并解压。解压.tar.gz的方式上一节已经说过。<br/>

```bash
$ tar -xzvf jdk1.8.0_181.tar.gz
```

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/un_gz.png?raw=true)

&ensp;&ensp;从上图可以看出java已经可以使用，但是我们使用的时候还要指定java的路径。这样过于麻烦，为了便于使用，我们会配置环境变量，配置环境变量我们会在下一节介绍。<br/>
&ensp;&ensp;对比包管理安装和解压缩安装，通常情况下包管理安装，用户是不需要自己配置环境变量的，对于大多数应用程序，包管理安装用户也不需要自己下载东西，所以包管理是一种快速便捷的方式。在使用包管理的安装方式时要注意，首先建议更换一下源，linux系统默认的源在国外，安装程序会慢，并且容易安装失败。其次，Redhat系列的程序，包管理使用yum方式，而Debian系列使用的apt方式。两类系统包管理方式不能互通，使用时需注意。
&ensp;&ensp;至于第三种编译安装的方式，复杂的主要是要将编译环境的库准备齐全，编译过程中除了耗费时间倒也不麻烦，读者如果感兴趣可以自主学习。

2、Linux环境变量配置
-------------------------
&ensp;&ensp;环境变量就是系统操作执行时配置好的参数，我们经常需要修改的就是path路径。在windows环境下和Linux环境下都有path，这个path到底是干什么的。其实，我们输入的指令都是一个可执行程序，当我们输入指令时，操作系统会通过path去我们设置好的几个路径中找出这个指令对应的程序。就比如我们刚刚解压的jdk压缩包，在path指定的路径中没有java命令的情况下，我们如果没有使用./java，系统是找不到java指令的。如果我们在环境变量里将path配置好了java，以后输入java的命令都不需要再指定路径了。<br/>
&ensp;&ensp;linux配置的环境变量分用户级和系统级。系统级的是 /etc/profile 这个文件，系统下的所有用户的环境变量都先加载这个配置文件配置的环境变量。用户级的是用户家目录下的~/.bash_profile,或 ~/.bash_login, 或 ~/.profile（其实我说了是家目录，就不用带~/了，但是我怕新手找不到位置），bash会按顺序读取上边三个文件，只要一个文件有就不会读下一个文件了。这三个配置文件是这样写的:


![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/bash_profile.png?raw=true)

&ensp;&ensp;从上边这一段代码其实可以看出~/.bash_profile先加载了~/.bashrc文件，我一直修改用户的环境变量就是修改~/.bashrc这个文件，当然这只是个人习惯。接下来配置环境变量，为jdk添加path。我这里使用的vi编辑器，读者可以自学vim编辑器，这里不对vim进行过多解释<br>

```bash
$ vi ~/.bashrc
在最下方添加三句话
export JAVA_HOME=/root/jdk1.8.0_181
export CLASSPATH=.:$JAVA_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$PATH
$ source ~/.bashrc                                 //重新加载一下配置文件
```

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/bashrc.png?raw=true)

<center>bashrc文件</center>

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/path_ok.png?raw=true)

<center>path已配置完成</center>

3、shell脚本简单解释
-------------------------
&ensp;&ensp;linux的shell脚本可是大名鼎鼎，shell脚本在很多时候可是帮了运维和开发的大忙。windows下边的bat文件和linux的shell文件是类似的，不多在大多时候windows的命令行不如linux的好用，因此他的批处理文件的强大性还是比不上shell的。
&ensp;&ensp;shell文件一般是*.sh的命名格式，他是一个批处理文件。其实shell就是按顺序存储了你想要执行的命令行，但是他比你单纯的输入命令行多出了if、else等逻辑控制，使你可以随心所欲排放你要执行的命令。shell中可以存储变量、传递参数等，功能强大。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/shell_hello.png?raw=true)

<center>shell文件一般长这样</center>

&ensp;&ensp;这里只是简单介绍一下shell，有时间的话，建议读者自己深入学习一下。

小结
---------------------------
&ensp;&ensp;Linux的东西还是很多，我暂时没有时间应该也没有能力详细的写一本书Linux学习的书，我的这么点东西只能教你初步用linux部署自己的程序，部署一个简单的自己的测试环境。深入学习的话，还要靠自己去努力啦。
