---
layout: post
title: "Invalid binary, the binary is missing architectures[arm64] - iTunes Connect的Bug"
date: 2014-09-11 14:51:58 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: iOS, App, arm64, XCode
description: 让iOS开发者乱成一团的强制提交支持64位架构的App，原来只是苹果的iTunes Connect的Bug。
---

从昨天开始，网上iOS开发者哀鸿一片，因为提交App到AppStore的时候，都遇到了这样一个错误：

> 「Today I cannot submit the binary to App Store, with the error "Invalid binary, the binary is missing architectures[arm64]".」

国内开发者也遇到了同样的问题：  
[现在提交的新应用貌似必须支持arm64了](http://bbs.lbsyun.baidu.com/redirect.php?tid=12550&goto=lastpost)

[上传项目到APPstore，遇到的问题](http://www.cocoachina.com/ask/questions/show/119687)

公司内部这两天可能刚好不需要提交App，但是这是迟早的事，而项目中大部分引用的库都不支持arm64，未免开始紧张地修改工程编译选项，推动依赖库支持64位架构，沟通、协调、改错，乱成一团蚂蚁。

结果……苹果告诉我们，不好意思，让你们受惊了，这是我们的一个Bug！

<!--more-->

坑爹呢这是！  
![ios_tabbar_running](/images/2014/09/keng_die_ne.jpg)  

苹果开发者论坛里的员工TimT如是说：

> 「Yes, there was a fix recently applied to the server. Everyone should be able to submit 32-bit apps again.」

![ios_tabbar_running](/images/2014/09/invalid_arm64.png)   
[32. Re: Invalid binary, the binary is missing architectures[arm64]](https://devforums.apple.com/message/1039265#1039265)

居然Sorry也没一句！任你乱如蚂蚁，我自泰然自若。

好了，没啥事了，还不能洗洗睡，继续提交32位App去吧~  

