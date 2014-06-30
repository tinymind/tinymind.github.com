---
layout: post
title: "在Mac系统上简便地启用Http Server"
date: 2014-06-30 15:27:28 +0800
comments: true
categories: [Mac, Http]
tags: [mac, http]
keywords: mac, http, php, server
description: 在Mac系统上简便地启用Http Server，支持运行Php
---

在本地调试Html等简单网页的时候，经常需要启动一个Web服务器，但又不想或不方便安装Apache或者IIS之类的软件，那么可以使用简单的方法：在Python或Php命令行下启用Http Server。

由于在Mac系统下，Python和Php都是默认安装好的，所以不需要额外的软件支持。具体方法如下：

<!--more-->

####方法一：不支持Php

这一方法的前提是，Mac系统默认安装了Python，所以可以利用Python启用Http服务器。
步骤：
``` bash
    $cd /path/project/site
    $python -m SimpleHTTPServer 8080
````

然后，在浏览器打开http://localhost:8080/index.html即可。

####方法二：支持Php

注意，以上方法，仅适用于提供html等文件服务，不支持运行php脚本。
     
如果需要运行php，参考 StackOverFlow 和 官网。请先确保php版本是5.4之后。
步骤：
``` bash
    $cd /path/project/site
    $php -S localhost:8080
```

####停止Server

在终端按`Ctrl-C`即可停止。

####其他系统

由于Python和PHP都是跨平台的，在其他系统上，只需要安装好这两个运行环境，就可以使用同样的方法。

