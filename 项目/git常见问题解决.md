# git常见问题总结（git忽略某一文件并不影响其他人+敏感信息上传到github后的解决办法）



[TOC]

## git忽略某一文件并不影响其他人（不加入.gitgnore）

### 场景

我们在自己的私有测试分支上调试项目逻辑，给文件做了一些特定的修改，但是文件不想被git提交，不想执行git status命令时出现在modified列表里；再比如，我们本地的数据库和测试环境的数据库配置是不一样的，或者你的密码不想被上传到仓库里，但是在项目开发中每次提交过程中忽略数据库配置文件。那么你这里就可以把不想提交的文件忽略。

当然关于git忽略文件的方式有很多，我这里使用的是git update-index --assume-unchanged命令。这个命令的好处是并不会影响到他人的开发。如果你用.gitgnore忽略，传到远程仓库后，别人拉下拉，改文件仍会被忽略。

### 忽略某一文件

```java
$ git update-index --assume-unchanged /path/to/file
```

命令中的file-path 就是需要忽略提交的文件的路径，只对文件有效。

### 如果忽略的文件多了，可以使用以下命令查看忽略列表

```java
git ls-files -v | grep '^h\ '
```

==这个命令我在idea的terminal终端下无法执行 但在git bash上是可以执行的 主要是因为grep这个命令的原因==

### 提取文件路径，方法如下

```java
git ls-files -v | grep '^h\ ' | awk '{print $2}'
```

### 取消忽略

```java
$ git update-index --no-assume-unchanged /path/to/file(文件相对路径)
```



### 命令介绍：

git-update-index  - 将工作树中的文件内容注册到索引。

修改索引或目录缓存。提到的每个文件都更新到索引中，并清除任何`unmerged`或`needs updating`状态。

`git update-index`处理文件的方式可以使用各种选项进行修改：

```shell
git update-index
	     [--add] [--remove | --force-remove] [--replace]
	     [--refresh] [-q] [--unmerged] [--ignore-missing]
	     [(--cacheinfo <mode>,<object>,<file>)…​]
	     [--chmod=(+|-)x]
	     [--[no-]assume-unchanged]
	     [--[no-]skip-worktree]
	     [--[no-]fsmonitor-valid]
	     [--ignore-submodules]
	     [--[no-]split-index]
	     [--[no-|test-|force-]untracked-cache]
	     [--[no-]fsmonitor]
	     [--really-refresh] [--unresolve] [--again | -g]
	     [--info-only] [--index-info]
	     [-z] [--stdin] [--index-version <n>]
	     [--verbose]
	     [--] [<file>…​]
```

**详细命令介绍可参考博客https://blog.csdn.net/Alen_xiaoxin/article/details/90647619**



## 敏感信息上传到github后的解决办法

![image-20210118140537577](https://gitee.com/lxsupercode/picture/raw/master/img/20210118140537.png)

**git工作流程**

（1）当我们对文件夹中的文件进行修改的时候，git 会自动帮我们把修改的内容加载到工作区

（2）当我们使用 git add 之后，修改的文件就会保存至暂存区

（3）当我们使用 git commit 之后，修改的文件会保存至版本库

（4）使用git push 之后，修改的文件会推送至远程仓库



这种情况适用于已经将git push到远程仓库后的解决办法

如果你还没有push ，没必要使用该方法，具体方法建议参考 [廖雪峰-Git教程-撤销修改](https://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000/001374831943254ee90db11b13d4ba9a73b9047f4fb968d000)



#### 一、依次执行命令 

==先提醒 一下命令建议在git bash上执行，之前在idea terminal终端下部分命令无法执行==

**1、删除git仓库中的所有该文件**

```git
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch E:\project\集体项目\smpe-admin\smpe-system\src\main\resources\config\application-dev.yml' --prune-empty --tag-name-filter cat -- --all
```

**file-name是指要删除文件的相对目录**

**使用这个命令必须将所有修改文件 commit  最好在git bash 上操作 用idea的终端不管用  **  

我运行这个命令大概执行了半分钟

![image-20210118110503386](https://gitee.com/lxsupercode/picture/raw/master/img/20210118110510.png)



![image-20210118110522749](https://gitee.com/lxsupercode/picture/raw/master/img/20210118110522.png)

看起来这部是把git仓库中所有的该文件给删除了 然后又重写了一遍

运行过后你会发现你要删除的那个文件已经不见了，git仓库中也找不到他的记录

**2、强制推送到远程分支**

```cmd
git push origin develop --force
```

develop是我得分支，大家可以选择自己要改变的分支

--force 作用是强制推送 

具体作用可以看阮一峰的博客http://www.ruanyifeng.com/blog/2014/06/git_remote.html

**3、删除git仓库中的文件**

```cmd
rm -rf .git/refs/original/
```

**4、应该是把你之前错误信息清空**

```cmd
git reflog expire --expire=now --all
```

关于git-reflog的用发总结可参考博客https://blog.csdn.net/chaiyu2002/article/details/81773041

**5、git 垃圾回收 进一步清空记录**

```cmd
git gc --prune=now

git gc --aggressive --prune=now
```

prune 过程相当于执行"git prune --expire"，他会删除所有过期的、不可达的且未被打包的松散对象。

具体可以参考博客https://blog.csdn.net/lihuanshuai/article/details/37345565

**----------------------------------完成--------------------------------------------**

完成之后你就会发现github上的所有该文件的记录都已经被清除了，本地更不会有该文件任何记录，即使你查找git版本库 。这时候你仅仅只需要再上传一遍没有敏感信息的该文件就可以了

