---
layout: post
title: "iOS中检测UIScrollView滚动动画是否结束"
date: 2013-12-06 00:34
comments: true
categories: [iOS]
tags: [ios]
---

在iOS中使用UITableView的时候，有时候需要检测UITableView的滚动动画是否结束，但是很遗憾，iOS没有直接提供这样的API。
先看一下现有的几个方法是怎样的：

``` cpp
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
```
这个方法表示手指离开了scrollview，第二个参数用于判断滚动速度是否慢慢下降。


``` cpp
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;      // called when scroll view grinds to a halt
```
这个方法看上去挺像我们要找的：停止减速。但是，从注释看，“嘎然而止”的时候才会被调用，很明显，我们要的是“自然停止”时被调的方法。


``` cpp
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView; // called when setContentOffset scrollRectVisible:animated: finishes. not called if not animating
```
这个是指scrollview停止滚动动画，嗯，这下是我们想要的了吧！


抱歉，不是！！！
试验一下就会发现，无论怎么滚动怎么停止，这个方法都不会被调！处分用代码的方式调用了`setContentOffset scrollRectVisible:animated: finishes`，但是，我们手指触发试图滚动是不会调该方法的……

一堆似是而非的方法绕得头晕啊……

###解决方法

<!--more-->

我们自己主动去调`scrollViewDidEndScrollingAnimation`。

原理：在`- (void)scrollViewDidScroll:(UIScrollView *)scrollView`内，创建一个异步调用，等待0.1秒后调`scrollViewDidEndScrollingAnimation`。由于`scrollViewDidScroll`会不断被调用，再次触发时取消上一次的异步请求。等到不再滚动时，最后一次的请求不会被取消，最终会跑到`scrollViewDidScroll`，然后，添加想要在滚动停止时调用的代码即可。

代码如下：

``` cpp
-(void)scrollViewDidScroll:(UIScrollView *)sender 
{   
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.1]; 
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //这里添加你的逻辑，比如，触发上拉加载更多
}
```

