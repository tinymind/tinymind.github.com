---
layout: post
title: "SmartSVN一直是Local Refreshing状态，却无法Update/Commit/Check Out"
date: 2014-10-17 11:00:22 +0800
comments: true
categories: [SVN]
tags: [SmartSVN, SVN, MacOS]
keywords: SmartSVN, SVN, MacOS, SSLv3
description: Mac系统下，SmartSVN 7.5.5一直是Local Refreshing状态，却无法Update/Commit/Check Out的解决方法
---

![smart svn](http://www.wandisco.com/sites/all/themes/wandisco/assets/i/prod-detail/screens/smartsvn.png)

<!--more-->

###Mac下最好的SVN客户端

在Windows下，最好用的SVN客户端是TortoiseSVN，但是没有跨平台版本。在Mac OS X，也有好几个SVN客户端，比如：Versions，CornerStone，SmartSVN，其中，最好用的是SmartSVN。

SmartSVN有两个版本，专业版和基础版。专业版可以免费试用30天，如果不注册，自动切换为基础版。最重要的是，基础版已经涵盖了大部分的功能特性，实乃业界良心。


###SmartSVN 7.5.5的问题

话说我一直以来在Mac系统都用着SmartSVN 7.5.5版，顺心顺手，直到昨晚，update的时候一直是`Local Refreshing`状态，数据也是有出没进，如下图：

![smart svn slow local refresh](/images/2014/10/lessfun_smart_svn_keep_local_refreshing.jpg)

`Out`的数据一直在增加，如果放任不管，甚至可以达到几百M。于是我意识到出问题了，但是用命令行的svn来操作却一切正常。怀疑是SmartSVN的`Log Cache`太大，于是删除了`Log Cache`文件，位置在`~/Library/Preferences/SmartSVN`下，问题依旧。


###解决Keep Local Refreshing的方法

无奈，只好使出重装大法。下载、安装了SmartSVN 8.6版本后，直接弹出了下面的提示：

![smart svn slow local refresh](/images/2014/10/lessfun_smart_svn_update_tips.jpg)

实在是后知后觉啊，既然你那么Smart，就不能在出问题的时候直接弹提示吗？非得等到人家摸索并安装了最新版后才弹这个。

好消息是，安装8.6版本后，问题解决。

###更新：

SmartSVN更新不了，问题不在于客户端本身，而是svn server端禁用了SSLv3引起的，为了避免这个问题： https://poodle.io/

至于为什么更新为SmartSVN 8.6之后，问题解决，是因为8.6版本内置的是svn1.8，在SSLv3无法连接的时候，可能自动切换为tlsv模式。

