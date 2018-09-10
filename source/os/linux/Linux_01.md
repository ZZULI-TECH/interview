Linux-01
==========================================
1、Linux简介
----------------------
&ensp;&ensp;说起Linux,很容易让人联想到了UNIX。在很长时间，我甚至以为Linux是在UNIX开源时期的系统基础上改写的。但是之后又觉的Linux应该无法使用unix的代码的，毕竟UNIX是需要授权的。在之后的了解中，慢慢的解决了这个疑惑，Linux并不源于任何版本的UNIX操作系统，Linux只是一套成功模仿了UNIX的产品，他对UNIX的功能和界面进行了模仿，他是一款兼容于UNIX的独立的操作系统。<br/>
&ensp;&ensp;目前市场上的Linux发行版有两大类，一种是商业公司维护的发行版本，一种是社区组织维护的发行版本。商业公司维护的有Redhat系列、CentOS等，社区组织维护的有Debian、Ubuntu等。<br/>
&ensp;&ensp;CentOS是RHEL的社区克隆版本，所以CentOS和Redhat的操作方式大都是相同的，他们都采用基于RPM包的YUM包管理方式。Redhat系列和CentOS都是非常稳定的，适合于服务器使用。Fedora Core由Redhat桌面版发展而来，他的稳定性差强人意，所以更适合桌面应用。<br/>
&ensp;&ensp;Ubuntu是基于Debian加强而来的，他集合了Debian的优点和自己加强的优点。他们采用的是apt-get / dpkg包管理方式。总的来说，Ubuntu是一个非常适合做桌面操作系统的Linux发行版本。<br/>
&ensp;&ensp;(题外话，我曾经在Ubuntu上试着用yum装程序，最终白忙活了一大阵子。。。)

2、Linux的目录结构
-------------------------
&ensp;&ensp;linux不像windows那样将一个硬盘分区，linux目录结构是典型的树状结构，有一个主目录“/”，也叫根目录，你可以暂且认为所有的文件都在这个根目录里存放着。当你cd 到了“/”目录，就到了目录结构的顶点。

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/linux_dir_tree.png?raw=true)

根目录下的文件夹<br>

其中bin目录下放着许多可执行文件，一般都是存放着各种指令，像cat、mv等，boot目录存放着开机等设定的值，dev存放的都是设备文件，就像window下的资源管理器，etc存放的是系统的配置文件，像密码，path环境变量等。home是家目录，在linux中新建的其他用户都会在这里生成一个目录，之后这个用户登录都会进入到home里的相应目录。root目录就是系统管理员的家目录。至于其他的目录，使用者可以在用到的时候深入研究一下。



3、一些简单的Linux命令
-------------------------
&ensp;&ensp;很多初学者说啊，我没有Linux系统，我又不想学安装虚拟机，我也不想花钱买服务器，我拿什么来练习这些命令呢，好难啊。（就你事多。。。）<br/>
&ensp;&ensp;那么非常感谢git，git给了你在windows上敲击Linux命令的机会。你在你的windows主机上安装一个git客户端，能够给你提供一个git bash。git bash提供了仿真命令的环境，你在git bash里尽情的输入Linux命令吧。当然这些命令是基础命令，想既省钱又能使用全部的Linux命令，就去学习装系统吧！

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/biao_linux/git_bash.png?raw=true)
<center>git bash</center>

接下来我们就来一一看一下常用的Linux命令吧。
> # 磁盘管理
&ensp;&ensp;Linuxd的磁盘管理有很多命令，这里吧这些命令一一列出来，简单介绍一下。至于每一个命令的多种传参方式过多，这里不一一解释，使用者可以输入--help查看并使用。
<br>
```bash
cd命令是切换目录的命令，切换目录可以使用绝对路径和相对路径。和开发时使用的习惯一样，最前方带“/”的是绝对路径。不带的都是相对路径。.代表当前目录，..代表上级目录。
$ cd /home/biao         //切换到用户的家目录下
$ cd ~                  //切换到用户的家目录下
对于用户biao来说，上边的指令是相等的，~代表的就是家目录。
```
```bash
ls命令用于显示指定工作目录下之内容（列出目前工作目录所含之文件及子目录)。
$ ls                    //显示当前目录下的目录及文件 
```
```bash
pwd用于显示当前位置。
$ pwd                    //pwd用于显示当前位置
```
```bash
df用于显示文件系统的磁盘的使用情况。
$ df                     
```
```bash
du命令用于显示目录或文件的大小。
$ du -a或-all           //显示目录中个别文件的大小。
```
```bash
edquota命令用于编辑用户或群组的磁盘配额。
$ edquota [-ug] -t
```
```bash
mkdir命令用于建立子目录。
$ mkdir AAA               //在工作目录下，建立一个名为 AAA 的子目录 :
```
```bash
mount用于挂载Linux系统外的文件。
$ mount /dev/hda1 /mnt  //将 /dev/hda1 挂在 /mnt 之下。
```
```bash
tree命令用于以树状图列出目录的内容,这个功能一些Linux发行版没有，需要自己安装。
$ tree                  //以树状图列出当前目录结构
```
> # 文件管理
&ensp;&ensp;文件管理一般是对文件进行操作，在使用linux系统过程中，我们大多数时间都要对文件进行操作、管理。
```bash
cat命令用于连接文件并打印到标准输出设备上。
$ cat a.txt                 //打印a.txt的文件内容
```
```bash
more命令类似cat ，不过会以一页一页的形式显示，更方便使用者逐页阅读。
$ more a.txt                //按页打印a.txt的文件内容
```
```bash
less 与 more 类似，但使用 less 可以随意浏览文件，而 more 仅能向前移动，却不能向后移动，而且 less 在查看之前不会加载整个文件。
$ less a.txt 
```
```bash
touch 创建文件。
$ touch a.txt               //以a.txt为文件名创建文件 
```
```bash
mv命令用来为文件或目录改名、或将文件或目录移入其它位置。
$ mv a.txt b.txt            //以a.txt的文件改名为b.txt
$ mv info/ logs             //将info目录放入logs目录中。注意，如果logs目录不存在，则该命令将info改名为logs。
```
```bash
rm命令用于删除一个文件或者目录,删除文件可以直接使用rm命令，若删除目录则必须配合选项"-r"
$ rm  test.txt              //删除文件test.txt
$ rm  -r  test              //删除test目录
```
```bash
cp命令主要用于复制文件或目录。
$ cp –r test/ newtest       //将当前目录"test/"下的所有文件复制到新目录"newtest"下
```
```bash
cp命令主要用于复制文件或目录。
$ cp –r test/ newtest       //将当前目录"test/"下的所有文件复制到新目录"newtest"下
```
&ensp;&ensp;chmod用于更改文件权限，在linux的权限中，文件的权限分为三级：文件拥有者、群组、其他。<br/>
&ensp;&ensp;chmod拥有两种写法：<br/>
&ensp;&ensp;&ensp;&ensp;第一种是用u、g、o 表示要更改的用户（u：文件的拥有者，g：文件拥有者同一个群体，o：其他用户），rwx表示权限（r:读、w:写、x:执行），+、-表示添加或撤销权限。<br/>
&ensp;&ensp;&ensp;&ensp;第二种是用三个数字如（777），分别表示u、g、o三个用户的权限。其中数字的位置分别代表u、g、o用户，数字代表权限，r=4，w=2，x=1。4+2+1=7，所以7表示有所有权限，4+2=6，6表示读写权，4+1=5，5表示读，执行权。

```bash
$ chmod ug+w,o-w file1.txt file2.txt  //将文件 file1.txt 与 file2.txt 设为该文件拥有者，与其所属同一个群体者可写入，但其他以外的人则不可写入
$ chmod 777 file           //给所有用户读写执行权
```
```bash
which命令可以查找环境变量$PSTH设置的目录中的文件。
$ which bash               //查找bash指令的绝对路径
```
```bash
find命令用来在指定目录下查找文件。
$ find . -name "*.c"       //将当前目录及其子目录下后缀为.c的文件查找出来
$ find . -ctime -20        //将当前目录及其子目录下20天内更新过的文件查找出来
```
```bash
whereis命令用于查找文件
$ whereis bash             //查看指令bash的位置
```
```bash
wc命令用于计算字数。
$ wc testfile.txt          //可以查看文件testfile.txt的行数，单词数以及字节数。
```
```bash
sh命令用于执行sh文件
$ sh test.sh               //执行sh文件
$ ./test.sh                //可执行文件可以直接这样执行          
```
> # 系统管理
&ensp;&ensp;系统管理命令多是用于操作用户、线程、权限等。系统管理的命令也经常要使用到。
```bash
adduser与useradd在centOS上是相同的指令。在Ubuntu上，useradd不会在/home目录创建用户名相同的目录，而adduser会。
$ adduser -r  biao         //创建一个系统用户biao
$ adduser -g root  biao    //创建一个用户biao，并制定其用户组为root
$ userdel -r biao          //删除用户biao，及其目录和子目录
$ id                       //显示用户ID及群组ID
$ passwd biao              //修改用户biao的密码
```
```bash
$ su - biao                //变更账户为biao并切换至biao的家目录
$ sudo  command            //临时提升权限运行命令，只有在/etc/sudoers有的用户才能临时提升权限。
$ who                      //显示当前登录系统的用户
```
```bash
ps显示当前进程的状态。
$ ps -A                    //列出所有的进程
$ top                      //实时显示进程信息
$ kill 12345               //关掉pid为123456的线程
$ kill -KILL 12345         //强制关掉pid为123456的线程
```
```bash
$ sleep 5m                 //休眠5分钟（很少有人用sleep ，单核服务器直接停了5分钟。。。）
```
> # 备份压缩
&ensp;&ensp;在CentOS中，默认安装了tar和gzip。tar可以解压后缀为*.tar[.gz/b2/z]的文件，gzip可解压后缀为*.gz的文件。linux系统中大多数为这两种压缩包，基本够用，若你有更高的需求可以装其他压缩软件。
```bash
在tar跟的参数中，第一个字母代表执行什么（-c: 建立压缩档案-x：解压-t：查看内容-r：向压缩归档文件末尾追加文件-u：更新原压缩包中的文件）,中间的v表示要显示解压过程，可以去掉v不显示。
$ tar -xvf file.tar //解压 tar包
$ tar -xzvf file.tar.gz //解压tar.gz
$ tar -xjvf file.tar.bz2   //解压 tar.bz2
$ tar -xZvf file.tar.Z   //解压tar.Z
```
小结
---------------------------
&ensp;&ensp;你看了这么多东西将会发现，并不能操作linux系统。因为没有使用场景，你根本就没有去练习这些命令的愿望，其实在真实的开发中这些命令也就那几个常用的命令一直用，其他的都不怎么用。在下一个文档我会配置环境变量，书写一些shell批处理脚本等安装程序等一系列开发中会用到东西。但是想看后边的你还是老老实实把这部分看完，毕竟千里之行始于足下，九层之台，始于垒土。这是基础，这些内容不看你可能会一头雾水。
