---
layout: post
title: "让Octopress博客侧边栏的多说评论显示文章标题"
date: 2014-09-14 16:02:58 +0800
comments: true
categories: [Octopress]
tags: [octopress]
keywords: Octopress, 多说, 评论, 标题
description: Octopress博客侧边栏的多说最近评论不显示文章标题的解决方法，需要自己传标题参数。
---

基于Octopress的博客搭建，在[用Octopress在Github搭建博客，并绑定独立域名](/blog/2013/11/27/create-blog-in-github-page-using-octopress-and-binding-domain/)里已经介绍过了，并且介绍了在侧边栏集成多说评论的方法。

但是，有一处陷阱，一直坑了我好久，那就是，多说的最近评论里，被评论的文章标题与链接大多数时候是空的，但是偶尔又能正常显示，如图：  
![多说最近评论](/images/2014/09/recent_comment_title.png)

<!--more-->

一直以来，我都以为这是多说的Bug，默默期待着它有朝一日会自动修复。安静地等待了大半年之后……这个Bug依然深深地存在我的博客里。虽然用户评论不多，但是偶尔难得有一条新评论，但是我却不知道评论的是哪一篇文章，得从头到尾慢慢遍历所有文章才能找出来，这种感觉实在是太不好受了！！！

我忍不住了，那么明显的Bug，多说不可能会那么久都不修复，一定是我的配置出了问题！于是，我检查了三遍`_config.yml`的内容：

``` bash

duoshuo_asides_title: 1 #显示评论的文章标题

```

配置是没问题的啊！！！  
估计靠个人力量是解决不了这个问题的了，于是我用上了万能的谷歌，在[蝶姐的博客](http://yrzhll.com/blog/2012/12/12/comment/)中找到了原因与解决方法。

###问题原因

多说默认没有传递文章标题，需要用户手动传递。

###解决方法

修改`source/_includes/post/duoshuo.html`：

将：
``` html

	<div class="ds-thread"></div>

```

改为：

``` html

	<div class="ds-thread" data-title="{ { page.title } }"></div>

```

`rake genrate`重新生成一下，Done。  

