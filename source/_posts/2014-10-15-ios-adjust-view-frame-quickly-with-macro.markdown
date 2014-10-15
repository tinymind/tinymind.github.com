---
layout: post
title: "iOS通过宏定义快速调整View的Frame"
date: 2014-10-15 18:45:03 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: iOS, Macro, UIView, Frame, Adjust
description: 在iOS开发中，使用宏定义快速调整View的Frame
---

在iOS开发中，经常需要在运行时动态修改View Frame，比如，theView的X坐标右移2个点，Y坐标下移2个点，常用的方法如下：

``` c

    CGRect newFrame = self.theView.frame;
    newFrame.origin.x += 2;
    newFrame.origin.y += 2;
    self.theView.frame = newFrame;

```

逻辑很简单，就是代码繁琐了点，设想一下，假如有5个以上的子View需要调整位置与大小……

<!--more-->

###解决方法

也很简单，就是封装为通用的宏，或者方法(有些人比较反感C语言样式的宏定义)。

``` c

    #define CGRectAdjust(r, x1, y1, w1, h1)    CGRectMake(r.origin.x + x1, r.origin.y + y1,  r.size.width + w1, r.size.height + h1)
    #define CGRectSetSize(r, w, h)    CGRectMake(r.origin.x, r.origin.y, w, h)
    #define CGRectSetOrigin(r, x, y)    CGRectMake(x, y, r.size.width, r.size.height)

    #define ViewAdjustFrame(view, x1, y1, w1, h1)   view.frame = CGRectAdjust(view.frame, x1, y1, w1, h1)
    #define ViewSetSize(view, w, h)   view.frame = CGRectSetSize(view.frame, w, h)
    #define ViewSetOrigin(view, x, y)   view.frame = CGRectSetOrigin(view.frame, x, y)

```

然后，就可以这样调整UIView的Frame了：

``` c

	//大小不变，位置往右下方移动2个点
    ViewAdjustFrame(theView, 2, 2, 0, 0);

```

