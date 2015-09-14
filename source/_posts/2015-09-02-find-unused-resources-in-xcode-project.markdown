---
layout: post
title: "查找XCode工程中没被使用的图片资源"
date: 2015-09-02 13:27:29 +0800
comments: true
categories: [App, Mac]
tags: [app, mac]
keywords: Unused, XCode, Project, Resources, 未使用, 资源, 图片
description: LSUnusedResources 是一款查找 XCode 工程中未被使用的图片资源的 Mac 小工具，简单快速。有助于减少 App 的安装包大小，优化项目工程。
---


![LSMessageHUD Example1](https://github.com/tinymind/LSUnusedResources/raw/master/LSUnusedResourcesExample.gif)  

## 1. 需求的引入

一个项目开发得越久，添加的功能模块也就越多，相应地，也会慢慢引入大量图片等资源。但是，在移除一些不再使用的模块的时候，开发者往往会把该模块所对应的图片资源一起删除，因为源码和资源是分离的。长久以来，项目中就会存在大量没被使用的资源文件。

在某个时机，也就是需求完成得差不多，Bug 增加得不够多，Crash 上涨得不够快的时候，码农们终于有了一点闲暇时间，打算清理一下资源文件，减少 App 安装包的大小。这是一件体力活，方法无非是，一个一个地复制资源文件名，然后在 XCode 中全局查找该字符串，如果结果为 0，那么这个资源很可能就没有被使用。为什么说很可能？因为在代码中，有可能通过字符串拼接的方式使用了这个资源，而这种情况是没办法通过字符串匹配查找出来的。

道理我们都懂，但是，操作起来也实在是太繁琐了，码农们不可能会乐意这样干的。于是，我们需要这么一款工具：能够迅速找出工程中所有没被使用的资源文件。

<!--more-->

## 2. 已有的方案

果不其然，在我打算写这么一个工具的时候，在网上已经有了两种方案。

### 2.1 方案1：[万能的脚本](http://stackoverflow.com/a/6113449/3737409)

``` sh
#!/bin/sh
PROJ=`find . -name '*.xib' -o -name '*.[mh]'`

for png in `find . -name '*.png'`
do
    name=`basename $png`
    if ! grep -qhs "$name" "$PROJ"; then
        echo "$png is not referenced"
    fi
done
```

**缺点**：不够智能，不够通用，速度太慢，结果不正确。

### 2.2 方案2：[脚本界面化](http://jeffhodnett.github.io/Unused/)

[Unused](http://jeffhodnett.github.io/Unused/) 对脚本的调用做了封装，通过界面可以配置一定的信息，然后比较清晰的输入结果。

**缺点**：实际上，Unused 的内部还是调用了方案 1 的脚本，所以方案 1 的缺点也就是方案 2 的缺点。

## 3. LSUnusedResources 做的改进

### 3.1 提高匹配速度

LSUnusedResources 很大程度上受 Unused 的影响，比如界面、交互，以及部分代码。但是，本工具在核心代码上做了优化，使其在搜索的速度、结果的正确上都有了很大的提高。

核心步骤，简述如下：

* 查找：选定的目录下的所有资源文件。这一步与上述方案1区别不大，都是调用 `find` 命令查找指定后缀名的文件。
* 匹配：与上述方案不同，我不是对每个资源文件名都做一次全文搜索匹配，因为加入项目的资源太多，这里会导致性能快速下降。而我只是针对源码、Xib、Storyboard 和 plist 等文件，先全文搜索其中可能是引用了资源的字符串，然后用资源名和字符串做匹配。

### 3.2 优化匹配结果

Unused 会把大量实际上有使用的资源，当做未使用的资源输出。LSUnusedResources 则不会出现这样的问题，并且使得结果更加优化。

举例说明：  
你在工程中添加了下面资源:

```
    icon_tag_0.png
    icon_tag_1.png
    icon_tag_2.png
    icon_tag_3.png
```

然后用字符串拼接的方式在代码中引用:

``` objc
    NSInteger index = random() % 4;
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"icon_tag_%d", index]];
```

`icon_tag_x.png` 是不应该被当做未使用的资源的，只是以一种比较隐晦的方式间接引用了，所以不应该出现在结果列表中。

## 4. 使用方法

1. 点击 `Browse..` 选择一个文件夹；
2. 点击 `Search` 开始搜索；
3. 等待片刻即可看到结果。

## 5. 下载安装

* 下载: [LSUnusedResources.app.zip](https://github.com/tinymind/LSUnusedResources/raw/master/Release/LSUnusedResources.app.zip)
* 或者使用 XCode 编译运行[项目代码](https://github.com/tinymind/LSUnusedResources/)。

