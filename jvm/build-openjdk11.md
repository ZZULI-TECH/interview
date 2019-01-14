最近在看JVM相关的知识，涉及的知识十分繁杂且不好掌握，需要很多时间来慢慢学习。编译JDK的源码对我们了解JDK来说是第一步，为我们以后DEBUG源码打下基础，并且在Linux下编译JDK相对来说比较容易，让我们编译一个我们自己jdk11吧！(编译之前最好浏览一遍官方的[building指南](http://hg.openjdk.java.net/jdk/jdk11/file/1ddf9a99e4ad/doc/building.html))

## 利用Docker下载openjdk11

安装docker

```
sudo apt install docker.io
```

创建`/usr/local/work/openjdksrc`文件夹

下载openjdk11源码

```
sudo docker run --rm -it -v /usr/local/work/openjdksrc:/output bolingcavalry/openjdksrc11:0.0.1
```

然后进行解压即可。

或者自己到openjdk的网站下载:[地址](http://hg.openjdk.java.net/jdk/jdk11)，不过下载速度较慢，容易出现下载的文件不完整的情况。

## 安装openjdk10作为boot jdk

编译jdk需要一个boot jdk，一般为要编译的jdk的上一个版本，所以我们先在Ubuntu安装openjdk10。

首先到[openjdk10](http://jdk.java.net/java-se-ri/10)下载linux的压缩包，然后将其放入Ubuntu的目录`/usr/lib/jvm`，然后解压压缩包：

```
sudo tar -zxvf jdk-10_linux-x64_bin_ri.tar.gz
```

现在`/usr/lib/jvm`目录下有个jdk-10目录，接下来配置环境变量，利用vim打开`/etc/profile`文件

```
sudo vim /etc/profile
```

然后在该文件中添加如下配置

```
export JAVA_HOME=/usr/lib/jvm/jdk-10
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
```

最后刷新配置

```
source /etc/profile
```

## 配置编译环境

编译的时候会用到boot JDK的jre目录下的lib库，我们这里只有JDK没有jre，因此需要创建一个jre目录，再把jdk的lib文件夹复制到这个目录下，执行以下命令：


```
mkdir /usr/lib/jvm/jdk-10/jre && cp -r /usr/lib/jvm/jdk-10/lib /usr/lib/jvm/jdk-10/jre/
```

将`/usr/local/work/openjdksrc/jdk11`文件夹权限改为root用户


```
chown -R root jdk11 && chgrp -R root jdk11
```

安装编译必要软件


```
apt-get install -y autoconf zip libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev libcups2-dev libfontconfig1-dev libasound2-dev
```

以上软件安装完毕后，进入`/usr/local/work/openjdksrc/jdk11`源码包，进行编译确认：

```
bash configure --with-num-cores=4 --with-memory-size=8192 --disable-warnings-as-errors
```
以上命令中`–with-num-cores=4`表示四核CPU参与编译，`–with-memory-size=8192`表示8G内存参与编译，请您根据自己电脑的实际配置来调整。

如果检测通过，最后会有以下输出，代表可以进行正式编译了！

```
====================================================
The existing configuration has been successfully updated in
/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release
using configure arguments '--with-num-cores=4 --with-memory-size=8192 --disable-warnings-as-errors'.

Configuration summary:
* Debug level:    release
* HS debug level: product
* JVM variants:   server
* JVM features:   server: 'aot cds cmsgc compiler1 compiler2 epsilongc g1gc graal jfr jni-check jvmci jvmti management nmt parallelgc serialgc services vm-structs' 
* OpenJDK target: OS: linux, CPU architecture: x86, address length: 64
* Version string: 11-internal+0-adhoc.root.jdk11 (11-internal)

Tools summary:
* Boot JDK:       openjdk version "10" 2018-03-20 OpenJDK Runtime Environment 18.3 (build 10+44) OpenJDK 64-Bit Server VM 18.3 (build 10+44, mixed mode)  (at /usr/lib/jvm/jdk-10)
* Toolchain:      gcc (GNU Compiler Collection)
* C Compiler:     Version 7.3.0 (at /usr/bin/gcc)
* C++ Compiler:   Version 7.3.0 (at /usr/bin/g++)

Build performance summary:
* Cores to use:   4
* Memory limit:   8192 MB

WARNING: The result of this configuration has overridden an older
configuration. You *should* run 'make clean' to make sure you get a
proper build. Failure to do so might result in strange build problems.
```

## 编译与结果

接着执行`make`命令进行编译

```
make
```

然后。。。是漫长的等待，我用的是Ubuntu18虚拟机进行编译的。

注意如果在`bash  configure` 的时候如果没有加入`--disable-warnings-as-errors`参数，编译过程出现警告信息会终止编译，下面是官方的描述：

```
By default, the JDK has a strict approach where warnings from the compiler is considered errors which fail the build. For very new or very old compiler versions, this can trigger new classes of warnings, which thus fails the build.
Run configure with --disable-warnings-as-errors to turn of this behavior. (The warnings will still show, but not make the build fail.)
```

然后出现如下相关的错误：

```
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/TimeZone_md.c: In function ‘findZoneinfoFile’:
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/TimeZone_md.c:150:5: error: ‘readdir64_r’ is deprecated [-Werror=deprecated-declarations]
     while (readdir64_r(dirp, entry, &dp) == 0 && dp != NULL) {
     ^~~~~
In file included from /usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/TimeZone_md.c:36:0:
/usr/include/dirent.h:201:12: note: declared here
 extern int readdir64_r (DIR *__restrict __dirp,
            ^~~~~~~~~~~
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/UnixFileSystem_md.c: In function ‘Java_java_io_UnixFileSystem_list’:
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/UnixFileSystem_md.c:342:5: error: ‘readdir64_r’ is deprecated [-Werror=deprecated-declarations]
     while ((readdir64_r(dir, ptr, &result) == 0)  && (result != NULL)) {
     ^~~~~
In file included from /usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/UnixFileSystem_md.c:43:0:
/usr/include/dirent.h:201:12: note: declared here
 extern int readdir64_r (DIR *__restrict __dirp,
            ^~~~~~~~~~~
cc1: all warnings being treated as errors
CoreLibraries.gmk:128: recipe for target '/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/support/native/java.base/libjava/TimeZone_md.o' failed
make[3]: *** [/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/support/native/java.base/libjava/TimeZone_md.o] Error 1
make[3]: *** Waiting for unfinished jobs....
cc1: all warnings being treated as errors
CoreLibraries.gmk:128: recipe for target '/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/support/native/java.base/libjava/UnixFileSystem_md.o' failed
make[3]: *** [/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/support/native/java.base/libjava/UnixFileSystem_md.o] Error 1
make/Main.gmk:215: recipe for target 'java.base-libs' failed
make[2]: *** [java.base-libs] Error 2

ERROR: Build failed for target 'default (exploded-image)' in configuration 'linux-x86_64-normal-server-release' (exit code 2) 

=== Output from failing command(s) repeated here ===
* For target support_native_java.base_libjava_TimeZone_md.o:
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/TimeZone_md.c: In function ‘findZoneinfoFile’:
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/TimeZone_md.c:150:5: error: ‘readdir64_r’ is deprecated [-Werror=deprecated-declarations]
     while (readdir64_r(dirp, entry, &dp) == 0 && dp != NULL) {
     ^~~~~
In file included from /usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/TimeZone_md.c:36:0:
/usr/include/dirent.h:201:12: note: declared here
 extern int readdir64_r (DIR *__restrict __dirp,
            ^~~~~~~~~~~
cc1: all warnings being treated as errors
* For target support_native_java.base_libjava_UnixFileSystem_md.o:
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/UnixFileSystem_md.c: In function ‘Java_java_io_UnixFileSystem_list’:
/usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/UnixFileSystem_md.c:342:5: error: ‘readdir64_r’ is deprecated [-Werror=deprecated-declarations]
     while ((readdir64_r(dir, ptr, &result) == 0)  && (result != NULL)) {
     ^~~~~
In file included from /usr/local/work/openjdksrc/jdk11/src/java.base/unix/native/libjava/UnixFileSystem_md.c:43:0:
/usr/include/dirent.h:201:12: note: declared here
 extern int readdir64_r (DIR *__restrict __dirp,
            ^~~~~~~~~~~
cc1: all warnings being treated as errors

* All command lines available in /usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/make-support/failure-logs.
=== End of repeated output ===

=== Make failed targets repeated here ===
CoreLibraries.gmk:128: recipe for target '/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/support/native/java.base/libjava/TimeZone_md.o' failed
CoreLibraries.gmk:128: recipe for target '/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/support/native/java.base/libjava/UnixFileSystem_md.o' failed
make/Main.gmk:215: recipe for target 'java.base-libs' failed
=== End of repeated output ===

Hint: Try searching the build log for the name of the first failed target.
Hint: See doc/building.html#troubleshooting for assistance.

/usr/local/work/openjdksrc/jdk11/make/Init.gmk:300: recipe for target 'main' failed
make[1]: *** [main] Error 2
/usr/local/work/openjdksrc/jdk11/make/Init.gmk:186: recipe for target 'default' failed
make: *** [default] Error 2
```

所以在碰到因为警告而导致编译终止时，加上`--disable-warnings-as-errors`参数忽略警告，直至编译完成。


当编译完成时，会输出如下信息，说明编译已经完成了：


```
Creating support/modules_cmds/jdk.rmic/rmic from 1 file(s)
Creating support/modules_cmds/jdk.scripting.nashorn.shell/jjs from 1 file(s)
Creating support/modules_libs/jdk.sctp/libsctp.so from 3 file(s)
Creating support/modules_libs/jdk.security.auth/libjaas.so from 1 file(s)
Compiling 4 files for BUILD_JIGSAW_TOOLS
Stopping sjavac server
Finished building target 'default (exploded-image)' in configuration 'linux-x86_64-normal-server-release'
```

我们此时可以到`/jdk11/build/linux-x86_64-normal-server-release`目下查看我们编译的jdk，利用vim打开`build.log`，可以看到详细的编译耗时等信息。


```
Creating support/modules_cmds/jdk.scripting.nashorn.shell/jjs from 1 file(s)
Creating support/modules_libs/jdk.sctp/libsctp.so from 3 file(s)
Creating support/modules_libs/jdk.security.auth/libjaas.so from 1 file(s)
Compiling 4 files for BUILD_JIGSAW_TOOLS
----- Build times -------
Start 2019-01-10 07:00:07
End   2019-01-10 07:18:31

00:18:24 TOTAL
-------------------------
Finished building target 'default (exploded-image)' in configuration 'linux-x86_64-normal-server-release'

```

在`/jdk11/build/linux-x86_64-normal-server-release`该目录下有一个`jdk`目录，这里面就是最新构建的OpenJDK，进入里面的bin目录，再执行命令`./java -version`，可以看到我们构建的jdk11了

```
root@ubuntu:/usr/local/work/openjdksrc/jdk11/build/linux-x86_64-normal-server-release/jdk/bin# ./java -version
openjdk version "11-internal" 2018-09-25
OpenJDK Runtime Environment (build 11-internal+0-adhoc.root.jdk11)
```

终于编译成功，花费两晚上，中间遇到了几个错误，折腾了点时间。完美，撒花花(〃’▽’〃)

## References：

- [Ubuntu环境编辑OpenJDK11源码](https://blog.csdn.net/boling_cavalry/article/details/83303317)
- [openjdk](http://hg.openjdk.java.net/jdk/jdk11)
- [building.md](http://hg.openjdk.java.net/jdk/jdk11/file/1ddf9a99e4ad/doc/building.md)
- [JVM-Ubuntu18.04.1下编译OpenJDK8](http://www.cnblogs.com/iou123lg/p/9696039.html)
