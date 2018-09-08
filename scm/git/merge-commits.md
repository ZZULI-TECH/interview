在我们做新功能的时候，我们可能需要自己新建一个分支，然后在这个分支上开发，由于功能复杂或者功能点很多，或者每改动一个重要的地方都要进行提交一次，这样自己在测试开发时方便回滚等操作，会产生多个临时的commit，这些临时commit其实才是一个功能点，在向团队开发分支合并代码的时候，我们为了避免太多的 commit 而造成版本控制的混乱，通常我们推荐将这些 commit 合并成一个。

<!-- more -->

**1. git log查看提交记录**

首先我们利用**git log**查看当前分支提交的历史，最近提交在最上面，如下：

```
commit 2d6454c942f3961ad351caf145bedf29c4d3743c

commit d059f47fd7ab863353cd98fb29c98ceb1fe97845

commit 951522a48081b8ab4a529fee706d94c8fe3b16c8

commit 1d85c5a75128b6127de90b9db367dc9d67bdd17a
```

**2. git rebase**

这里用到了**git rebase**命令，这个命令主要用于更新代码和合并commit。假设你本地和服务器目前是同步的，然后你本地做了几次commit，其他人向服务器推送了commit。如果你希望同步服务器的commit，但是本地的commit又不想push到服务器的时候(比如你开发完某个功能，可能需要5个commit)。先fetch，然后rebase服务器的代码。

这里想要合并 1~2的commit，有两种方式

1. 从HEAD开始往后合并两次提交


```
git rebase -i HEAD~2
```
2. 指定要合并的commit之前的版本号


```
git rebase -i 951522a
```

此时951522a这个commit不参与合并

**3. 选取要合并的提交**

当输入完以上两个命令会弹出一个文本文件，内容前几行如下：


```
pick d059f47 add test.txt
pick 2d6454c Update test.txt
```

此时将第二个pick改为squash或者s,之后保存并关闭文本编辑窗口即可。改完之后文本内容如下：


```
p d059f47 add test.txt
s 2d6454c Update test.txt
```

保存后会弹出一个新文件，前面是你刚才要合并的两条 commit message，然后将这两条commit message删除，然后重新设置新的message，保存退出，如下： 


```
# This is a combination of 2 commits.

# This is the commit message #2:

Add and update test.txt
```

最后就可以发现两条commit message 已经合并为一条了


```
commit 9fff5fa09e09836ff2c535486ced2a66f8e4c19a
Author: Juntao Han <499445428@qq.com>
Date:   Mon Mar 26 21:24:47 2018 +0800

    Add and update test.txt

commit 951522a48081b8ab4a529fee706d94c8fe3b16c8
Author: Juntao Han <499445428@qq.com>
Date:   Mon Mar 26 21:03:29 2018 +0800

    update  .gitignore

commit 1d85c5a75128b6127de90b9db367dc9d67bdd17a
Author: Juntao Han <499445428@qq.com>
Date:   Mon Mar 26 20:59:13 2018 +0800

    :octocat: Added .gitattributes & .gitignore files
```

接下来推送到git服务器就好了
