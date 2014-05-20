---
layout: post
title: "将已存在的Octopress博客部署到一台新机器(OSX)"
date: 2014-05-20 18:45:00 +0800
comments: true
categories: [Octopress]
tags: [octopress, github, recreate]
keywords: recreate octopress
description: 在新的Mac系统上部署已有的Octopress博客
---

###适用情形
已经通过另一台电脑基于octopress搭建了一个博客，现在换到一台新电脑，或者想在两台电脑同时更新博客。本文针对的是Mac电脑，OSX系统。


###步骤简述
与新搭建一个octopress博客的过程大同小异，都是需要安装Git、安装Ruby、安装Octopress，只是从git中clone已有数据的地方有所不同。

###具体方法

####安装Homebrew，用于安装应用。
     
    $ ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)”。
    
有可能提示需要安装CLT(Command Line Tools) "xcode-select —install"。

####安装Git，用于Octopress上传。
如果还没有安装Git，使用命令安装：`$ brew install git`  
安装好之后，[配置ssh-key](https://help.github.com/articles/generating-ssh-keys)。

####安装Ruby，以便使用Octopress。

Mac系统默认会安装ruby，但是它设定了权限，导致用户无法修改ruby的文件内容，所以我们需要单独在用户目录下安装一个ruby。见[installing-gem-or-updating-rubygems-fails-with-permissions-error](http://stackoverflow.com/questions/14607193/installing-gem-or-updating-rubygems-fails-with-permissions-error)。

如果使用默认的ruby，在后面的步骤有可能会出现以下错误：

#####没有权限：

``` bash

$ gem install bundler
Fetching: bundler-1.6.2.gem (100%)
ERROR:  While executing gem ... (Gem::FilePermissionError)
    You don't have write permissions for the /Library/Ruby/Gems/2.0.0 directory.
    
```
     
#####即使加了sudo，成功执行这一步，后面也会出错：

``` bash

$ bundle install
Fetching source index from http://ruby.taobao.org/

Errno::EACCES: Permission denied - /Library/Ruby/Gems/2.0.0/build_info/rake-0.9.6.info
An error occurred while installing rake (0.9.6), and Bundler cannot continue.
Make sure that `gem install rake -v '0.9.6'` succeeds before bundling.

```

#####所以，还是老老实实安装一个Ruby吧：

``` bash

	# 1. 安装Rvm：
    $ curl -L https://get.rvm.io | bash -s stable —ruby
    # 2. 安装Ruby：
    $ rvm install ruby-2.0.0-p353  && rvm use ruby-2.0.0-p353
    $ rvm rubygems latest

```

####安装Octopress
     
见：http://blog.zerosharp.com/clone-your-octopress-to-blog-from-two-places/

在本地目录为已有的博客创建一个目录，如：Blog。命令行下切换到该目录，执行以下命令：

``` bash

     # 将source分支迁出到本地Blog/octopress_blog
     $ git clone -b source git@github.com:username/username.github.com.git octopress_blog
     # clone _deploy目录
     $ cd octopress_blog
     $ git clone git@github.com:username/username.github.com.git _deploy

```
然后运行rake进行配置：

``` bash

     $ gem install bundler
     $ rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
     $ bundle install
     $ rake setup_github_pages

```

会要求输入你的repos路径，输入即可。然后就可以在新机器上写博客了。

####在两台机器上同步Octopress内容

#####在一台机器提交新的更改：

``` bash

     $ rake generate
     $ git add .
     $ git commit -am "Some comment here."
     $ git push origin source  # update the remote source branch
     $ rake deploy             # update the remote master branch

```

#####从另一台机器同步更新：

``` bash

     $ cd octopress_blog
     $ git pull origin source  # update the local source branch
     $ cd ./_deploy
     $ git pull origin master  # update the local master branch

```
