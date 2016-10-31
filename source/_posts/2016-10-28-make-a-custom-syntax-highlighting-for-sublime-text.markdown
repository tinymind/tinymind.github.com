---
layout: post
title: "为 Sublime Text 自定义 Log 语法高亮"
date: 2016-10-28 15:53:44 +0800
comments: true
categories: [SublimeText]
tags: [sublime]
keywords: Sublime, Text, Syntax, Highlighting
description: 平时一直用 Sublime Text 搭配过滤插件来查看崩溃或者用户上报的 Log 日志文件，加载流畅，过滤方便，堪称码农必备神器。问题只有一个，如果能自动高亮 Log 等级，如 Warning、Error、Crash 信息以及一些自定义的关键词就完美了。
---

近日，代码写得越来越少，大部分时间都用来查 Bug 了，而查 Bug 的大部分时间里，是在看崩溃报告和用户日志。

有过看 Log 经历的人都知道，Log 到看时方恨少，对着十多兆的日志文件，满屏幕的文本信息，却找不到自己想要的那个关键点的记录，这是极其让人崩溃的。于是，看代码和写代码的时候都会下意识地在关键路径都打上 Log，宁可错打一千，不可放过一条。几次下来， Log 文件越来越大，看 Log 越来越累……如果逼不得已非得要大海捞针，那就让捞针这个过程更方便一些吧，这时候，关键字过滤以及高亮的需求随之而来。

软件界的神器之所以能成为神器，除了其本身功能突出之外，很大部分原因是它支持各种定制，能方便地添加插件或扩展，比如 Vim，Alfred，Chrome，等等。Sublime Text 也毫不例外地支持插件和自定义。本文要说的就是如何为 Log 文本文件添加自定义的语法高亮。

<!--more-->

## 1. 创建自定义语法高亮文件

### 1.1 安装 Package Control

[Package Control](https://packagecontrol.io/installation) 是 Sublime Text 的插件管理器，其本身也是一个插件，通过 Package Control 能很方便地查找、安装、卸载插件。

### 1.2 安装 PackageDev 插件

[PackageDev](https://github.com/SublimeText/PackageDev) 是一款快速创建 Sublime Text 的语法定义、片段等扩展文件的插件。

### 1.3 创建语法文件

安装 PackageDev 后，通过`Tools | Packages | Package Development | New Syntax Definition` 菜单，创建一个新的语法文件。

这时候，会自动新建一个空模板：

``` yaml
# [PackageDev] target_format: plist, ext: tmLanguage
---
name: Syntax Name
scopeName: source.syntax_name
fileTypes: []
uuid: 516bc7ff-03be-4474-a398-b83e20204594

patterns:
- 
...
```

### 1.4 定义语法高亮规则

包括设置语法名、后缀名、需要匹配的关键字、使用什么语法高亮关键字，等等。如下所示：

``` yaml
# [PackageDev] target_format: plist, ext: tmLanguage
---
name: MyLog
scopeName: text.mylog
fileTypes: [mylog]
uuid: 516bc7ff-03be-4474-a398-b83e20204594

patterns:
- comment: Keyword
  name: keyword.other.mylog
  match: \b(INFO|Info|WARN|Warn|ERROR|Error)\b

- comment: Number
  name: constant.numeric.mylog
  match: \b((\d*)|(0x[0-9a-zA-Z]*))\b
  
- comment: Funtion
  name: support.function.mylog
  match: ([-+])(\[.*?\])

- comment: Crash Error
  name: string.regexp.log
  match: (\b(CRASH|Crash|crash|WARNING|Warning|warning|FAIL|Fail|fail)\b.*)
...
```

点击保存，在 `Packages/User/` 目录下创建一个 `MyLog` 文件夹，文件名改为 `MyLog.YAML-tmLanguage`，保存到 `MyLog` 文件中。

语法的定义可以参考[官方文档](http://docs.sublimetext.info/en/latest/reference/syntaxdefs.html)。

匹配的关键字的 `name` 的定义，见[这里](https://manual.macromates.com/en/language_grammars#naming_conventions)。

### 1.5 保存为 tmLanguage 文件

上面的 YAML 文件提高了可读性，但为了让 Sublime Text 能识别，还需要转换为 tmLanguage 文件。

编辑完并保存 YAML 后，点击 `Tools | Build System | Convert to` ，或者按 `Ctrl(CMD) + B` 把 YAML 文件转为 `tmLanguage`，这时应该会自动保存到 Sublime Text 的配置文件夹中 `Packages/User/MyLog/MyLog.tmLanguage`：

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>fileTypes</key>
	<array>
		<string>mylog</string>
	</array>
	<key>name</key>
	<string>MyLog</string>
	<key>patterns</key>
	<array>
		<dict>
			<key>comment</key>
			<string>Keyword</string>
			<key>match</key>
			<string>\b(INFO|Info|WARN|Warn|ERROR|Error)\b</string>
			<key>name</key>
			<string>keyword.other.mylog</string>
		</dict>
		<dict>
			<key>comment</key>
			<string>Number</string>
			<key>match</key>
			<string>\b((\d*)|(0x[0-9a-zA-Z]*))\b</string>
			<key>name</key>
			<string>constant.numeric.mylog</string>
		</dict>
		<dict>
			<key>comment</key>
			<string>Funtion</string>
			<key>match</key>
			<string>([-+])(\[.*?\])</string>
			<key>name</key>
			<string>support.function.mylog</string>
		</dict>
		<dict>
			<key>comment</key>
			<string>Crash Error</string>
			<key>match</key>
			<string>(\b(CRASH|Crash|crash|WARNING|Warning|warning|FAIL|Fail|fail)\b.*)</string>
			<key>name</key>
			<string>string.regexp.log</string>
		</dict>
	</array>
	<key>scopeName</key>
	<string>text.mylog</string>
	<key>uuid</key>
	<string>516bc7ff-03be-4474-a398-b83e20204594</string>
</dict>
</plist>

```

此后，使用 Sublime Text 打开一个后缀名 `.mylog` 的文件，或者打开 `Plain Text` 类型的文件然后设置 `Syntax` 为 `MyLog` 类型，就可以看到高亮的效果了。如图：

![sublime text custom syntax highlighting](/images/2016/10/sublime_text_custom_syntax_highlighting.gif)

## 2. 配合其他插件，效果更佳

### 2.1 Filter Lines

[Filter Lines](https://packagecontrol.io/packages/Filter%20Lines) 插件能方便地过滤特定字符串到一个新的 Tab 中，支持全字匹配、正则匹配。相对于全文搜索而已，把匹配结果输出到一个全新的文件中，能更有助于查看关键信息。

### 2.2 Log Hihhlight

[Log Highlight](https://packagecontrol.io/packages/Log%20Highlight) 是专门处理 Log 高亮的插件，原理与自定义语法高亮不同。这个插件也可以自定义语法高亮，同时可定制性与功能也更强大，比如支持跳转、为警告或错误添加书签，等等，有兴趣可以使用一下。

