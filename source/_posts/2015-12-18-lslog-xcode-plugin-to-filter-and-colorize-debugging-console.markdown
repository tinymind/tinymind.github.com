---
layout: post
title: "使用LSLog XCode插件来过滤Log及修改Log的文本颜色"
date: 2015-12-18 18:34:16 +0800
comments: true
categories: [XCode, Plugin]
tags: [xcode, plugin]
keywords: XCode, Plugin, Log, Filter, Colorize, 过滤, 配色
description: LSLog XCode插件可以过滤XCode调试控制台输出的Log，支持正则表达式，可自定义前缀字符串以区分不同等级的Log，并修改对应的文字颜色。
---

![LSLog-XCode](https://github.com/tinymind/LSLog-XCode/raw/master/LSLog-XCode.gif)  

<!--more-->

## 1. 功能

LSLog-XCode 是一款 XCode 插件，用于过滤 XCode 调试控制台输出的 Log，支持正则表达式，可自定义前缀字符串以区分不同等级的Log，并修改对应的文字颜色。

LSLog-XCode 内置支持 [XCodeColors](https://github.com/robbiehanson/XcodeColors) 插件。如果你没有安装 XCodeColors，LSLog-XCode 会采用类似 XCodeColors 的语法，高亮显示调试器打印的 Log。

### 1.1 默认配置

不同 Log 等级对应的前缀字符串及默认文字颜色：

* Error: `<ERROR>`, RGB(214, 57, 30)
* Warn: `<WARNING>`, RGB(204, 121, 32)
* Info: `<INFO>`, RGB(32, 32, 32)
* Verbose: `<VERBOSE>`, RGB(0, 0, 255)

## 2. 安装

* 通过 [Alcatraz](https://github.com/alcatraz/Alcatraz) 安装。(即将上线...)
* 下载工程文件 [LSLog-XCode](https://github.com/tinymind/LSLog-XCode)，编译运行，然后**重启XCode**。

## 3. 卸载

LSLog-XCode.xcplugin 被保存在 `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`，如果要卸载，只需删除这个文件：`~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/LSLog-XCode.xcplugin`。

## 4. 感谢

* [MCLog](https://github.com/yuhua-chen/MCLog)
* [XCodeColors](https://github.com/robbiehanson/XcodeColors)