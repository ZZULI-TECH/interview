# awk命令

awk就是把文件逐行的读入，以空格为默认分隔符将每行切片，切开的部分再进行各种分析处理。 
awk有3个不同的版本：awk、nawk和gawk，未做特殊说明，一般指gawk，这个是AWK的GNU版本

**基本语法：**

```
awk [options] '{pattern + action}' {filenames}
```


**常用例子**

查看TCP网络连接情况

```
netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'
```

参考：

- [awk基础](http://www.zsythink.net/archives/1336)