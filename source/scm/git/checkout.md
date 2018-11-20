# git 切换远程分支

`git clone`只能clone远程库的master分支，无法clone所有分支, 如果想要切换远程分支，操作如下：

1. `git clone <repository_url>`
2. cd `project_folder`
3. `git brance -a` 列出所有分支（包括远程分支）
4. `git checkout -b dev origin/dev`，作用是checkout远程的dev分支，在本地起名为dev分支，并切换到本地的dev分支
