---
layout: post
title: "XCode无法正确import预编译文件.pch里的头文件"
date: 2014-09-18 11:13:56 +0800
comments: true
categories: [XCode, iOS]
tags: [xcode, ios]
keywords: xcode, objective-c, ios, macro, prefix.pch
description: 有时候用XCode打开Obj-C工程会遇到一些符号已经定义但是就是无法被识别的问题，比如在Prefix.pch预编译头文件中import的文件没有被全部加载。
---

{% img center /images/2014/09/lessfun_xcode_reload_pch_1.png 'lessfun_xcode_reload_pch_1' 'lessfun_xcode_reload_pch_1' %}

<!--more-->

如图。我在`xx-Prefix.pch`预编译文件中添加了`#import "YYMacro.h"`，其中定义了一些公共常用的宏和常量。这样就不需要在每个源文件中再import一次，节省代码并且可以提高便以速度。

大部分情况下，一切工作正常。但是，偶尔，XCode会出现一些Bug，导致无法完全加载pch里的头文件，而代码里用到的在Macro.h中定义的常量，全部被标识为未定义：

{% img center /images/2014/09/lessfun_xcode_reload_pch_2.png 'lessfun_xcode_reload_pch_2' 'lessfun_xcode_reload_pch_2' %}

虽然不影响编译运行，但是却让代码可读性变得很差，无法正常自动补全。试过了以下方法：

* 重启XCode
* Product - Clean
* Build - Run

无果。  
摸索并搜索之后，找到了[解决方法](http://stackoverflow.com/questions/11840622/xcode-4-4-does-not-get-all-the-pch-file-headers-imports)。

###解决方法

####1. 打开DerivedData目录

打开`Window`-`Organizer`，点击`右箭头`：

{% img center /images/2014/09/lessfun_xcode_reload_pch_3.png 'lessfun_xcode_reload_pch_3' 'lessfun_xcode_reload_pch_3' %}

####2. 定位到Index - PrecompiledHeaders

{% img center /images/2014/09/lessfun_xcode_reload_pch_4.png 'lessfun_xcode_reload_pch_4' 'lessfun_xcode_reload_pch_4' %}

####3. 删掉相关的预编译头文件目录

由于XCode打开的可能是Workspace，包含了多个工程，而大部分工程的pch工作正常，所以我们不需要删除整个`PrecompiledHeaders`，只需要删除无法正常工作的工程的相关目录，就是以工程名为前缀的那几个。

####4. 重新编译

现在，一切又正常了。

{% img center /images/2014/09/lessfun_xcode_reload_pch_5.png 'lessfun_xcode_reload_pch_5' 'lessfun_xcode_reload_pch_5' %}

###结论

与XCode相关的Bug，比如变量无法正确被加载，头文件没有被import，修改了xib文件但是在模拟器中不起作用，等等，都可以通过删除`DerivedData`的中间文件解决。  

