---
layout: post
title: "在一台电脑上使用两个Github账号"
date: 2014-06-11 01:30:09 +0800
comments: true
categories: [Github, Mac]
tags: [github, mac]
keywords: Github, ssh-key, Mac
description: 有时候我们需要在一台电脑上push到两个github的repo，但是默认情况github只适用一个账号。本文介绍了如何在一台电脑使用两个Github提交更改的方法。
---

有时候我们需要在一台电脑上push到两个github的repo，但是默认情况Github只适用一个账号。本文介绍了如何在一台电脑使用两个Github提交更改的方法。
<!--more-->

前提：你已经在使用github的A账号，其ssh-key保存在~/.ssh/id_rsa中。  
现在，需要做的是添加另一个ssh-key，按照以下步骤操作。

####1. 生成新的ssh-key

保存的时候，输入一个新的文件名，如：id_rsa_second

``` bash

    $ssh-keygen -t rsa -C "your_email@example.com"
    # Creates a new ssh key, using the provided email as a label
    # Generating public/private rsa key pair.
    # Enter file in which to save the key (/Users/you/.ssh/id_rsa_second): [Press enter]

```

####2. 添加到ssh-agent（每次重启之后都需要调用这句）

``` bash

    $ssh-add ~/.ssh/id_rsa_second

```

####3. 添加ssh key到github

见[配置ssh-key](https://help.github.com/articles/generating-ssh-keys)。

####4. 配置多个ssh-key

修改`~/.ssh/config`文件，如下：


``` bash

    #default github
    Host github.com
      HostName github.com
      IdentityFile ~/.ssh/id_rsa

    Host github_second
      HostName github.com
      IdentityFile ~/.ssh/id_rsa_second
    
```


####5. 使用别名pull/push代码

如：

``` bash

    git clone git@github_second:username/reponame

```

####6. 为每个账号对应的项目配置email/name

``` bash

    1.取消global
    git config --global --unset user.name
    git config --global --unset user.email

    2.设置每个项目repo的自己的user.email
    git config  user.email "xxxx@xx.com"
    git config  user.name "xxxx"

```  

这样，以后每次在相应的repo下提交更改，都会自动匹配相应的ssh-key了。
