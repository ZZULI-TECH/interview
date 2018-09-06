# grep 命令

grep (Global Regular Expression Print)是一种强大的文本搜索工具，它能使用正则表达式搜索文本，并把匹配的行打印出来。

基本语法：

```
grep "match_pattern" f1 f2 f3...
```

标记匹配颜色 --color=auto 选项

```
grep "match_pattern" file_name --color=auto
```

输出匹配内容到一个文件

```
grep "match_pattern" file_name > a.txt
```

统计文件或者文本中包含匹配字符串的行数 -c 选项
```
grep -c "text" file_name
```

输出包含匹配字符串的行数 -n 选项

```
grep "text" -n file_name
或
cat file_name | grep "text" -n
```

**grep 打印前后几行**

显示file文件里匹配foo字串那行以及上下5行

```
grep -C 5 foo file
```

显示foo及前5行

```
grep -B 5 foo file 
```

显示foo及后5行

```
grep -A 5 foo file 
```

**grep 使用正则表达式**

基本用法

```
grep -E pattern f1 f2 f3...

或者

egrep pattern f1 f2 f3
```

搜索一个或者多个连续的no的行。

```
grep -E '(no)+' testfile
```