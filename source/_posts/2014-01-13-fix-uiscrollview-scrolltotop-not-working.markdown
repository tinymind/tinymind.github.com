---
layout: post
title: "修复iOS中UIScrollView的scrollToTop设置后不生效的问题"
date: 2014-01-13 15:15:04 +0800
comments: true
categories: [iOS]
tags: [ios]
---

iOS中的`UIScrollView`有一个属性`scrollToTop`，设置为`YES`之后，点击设备的状态栏(StatusBar)即可将滚动试图的内容滚动到最顶端，在滚动列表很长的时候，这个特性十分有用。

今日在使用这一属性的时候，发现部分情况下，一切正常；但是也有时候，点击状态栏，滚动条没反应！检查了代码，确定已经设置`scrollToTop = YES`，但是总是会有不起作用的情况。

于是到万能的StackOverflow寻求答案，不失所望，找到了类似的问题：[scroll UITableView to top when tapping top of the screen](http://stackoverflow.com/questions/8951357/scroll-uitableview-to-top-when-tapping-top-of-the-screen)

答案也解释得很清楚了，如下：
<!--more-->

如果同一个UIViewController中包含了多个UIScrollView，那么只能有一个ScrollView被设置为scrollToTop = YES; 另外的都要设置为NO，否则就会被系统忽略。
比较坑爹的是，该属性默认为YES，在`UIScrollView.h`中可以看到声明如下：

``` cpp
  @property(nonatomic) BOOL  scrollsToTop;  // default is YES.
```

所以我们需要显示设置其他的`scrollView.scrollToTop = NO`。  
