---
layout: post
title: "App适配iOS8遇到的兼容问题：键盘方向与StatusBar方向不一致，阻止锁屏失效，OpenGL崩溃"
date: 2014-09-24 13:59:29 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: iOS8, orientation, idleTimerDisabled, OpenGL, 适配
description: App适配iOS8遇到的兼容问题：键盘弹出方向与StatusBar方向不一致，阻止锁屏失效，OpenGL崩溃
---

{% img left /images/2014/09/lessfun_ios8_adapt.png 'ios8 adapt' 'ios8 adapt' %}
苹果正式发布iOS8系统，到现在安装覆盖率已达48%，而iOS7的安装率是49%。所以，各位开发者又有得忙了，把所有的App都升级并适配到iOS8系统可不是一件轻松的事。

下面罗列一下我在适配iOS8过程中遇到的兼容问题——而同样的代码在iOS6/7是完全没问题的。  

<!--more-->

##1. 键盘弹出方向与StatusBar方向不一致

在App中，第一个ViewController是只支持竖屏方向(Portrait)的，切换到第二个页面，默认也是Portrait，但用户可以点击按钮切换为横屏(Landscape)。

所以，我把App-Info.plist只选中了`Portrait`一项，并且在`Root ViewController`重载了以下方法：

``` c
	
	- (BOOL)shouldAutorotate
	{
	    return NO;
	}
	
	- (NSUInteger)supportedInterfaceOrientations
	{
	    return UIInterfaceOrientationMaskPortrait;
	}
	
	- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
	{
	    return UIInterfaceOrientationPortrait;
	}

```

然后在需要切换到横屏的时候，调用以下代码：

``` c

- (void)onFullScreenButtonTouchUpInside:(id)sender
{
    [self adjustViewFrameToFullScreen];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
}

```

由于在iOS6、7中，键盘方向是跟随状态栏方向的，所以一切表现正常，横屏下，无论设备方向怎样，键盘都是横着弹出。

但是，在iOS8中，键盘却随着设备方向弹出了。换言之，<strong>即使Interface Orientation为Landscape，但Device Orientation为Portrait，键盘就会以Portrait的方向弹出</strong>。  
如下图：

{% img center /images/2014/09/lessfun_ios8_adapt_keyboard.png 'ios8 adapt keyboard' 'ios8 adapt keyboard' %}

###1.1 解决方法

我想要的是键盘不管设备方向，只关注状态栏方向，也就是StatusBarOrientation。由于iOS8新出不久，在网上没找到解决方案。后来我一同事发现手动更改设备方向可以解决这一问题：

``` c


- (void)onFullScreenButtonTouchUpInside:(id)sender
{
    [self adjustViewFrameToFullScreen];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
    //改设备方向
    if (IsIOS8) {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft] forKey:@"orientation"];
    }
}

```

##2. 禁用屏幕自动锁定失效

本来，防止屏幕锁定只需一句代码：

``` c

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

```

但是，在iOS8中，偶尔会失效。测试人员发现了这个问题是在弹出键盘点击发送后必现，而原因不明。因为键盘出现与隐藏，理论上不应该影响这个`idleTimerDisabled`的属性。暂且认为是iOS8的Bug吧。

###2.1 解决方法

在键盘收起的时候，重设`IdleTimerDisabled`。

``` c

	- (void)onKeyboardDidHide:(NSNotification *)notification
	{
	    if (IsIOS8) {
	        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	    }
	}

```

##3. OpenGL ES渲染时崩溃

在iOS中使用OpenGL ES渲染，切换到后台时需要停止渲染，否则会引起崩溃。见这里：[How to fix OpenGL ES application crashes when moving to the background](https://developer.apple.com/library/ios/qa/qa1766/_index.html)

但是在iOS8中，即使不是切换到后台，而是通过`NavigationController`切换到另一个ViewController再切回来，也会引起崩溃，崩溃点在：

``` c

	[EAGLContext presentRenderbuffer:GL_RENDERBUFFER];

```

猜测可能是，在iOS 8中，如果OpenGL的视图如果切换到不可见的ViewController，也需要停止绘制，否则也会引起在后台渲染OpenGL类似的崩溃。

###3.1 解决方法

在ViewWillDisapper的时候停止渲染。

``` c

	- (void)viewWillDisappear:(BOOL)animated
	{
	    [super viewWillDisappear:animated];
	    
	    if (_videoView && IsIOS8) {
	        [_videoView pauseVideo];
	    }
	}
	
	- (void)viewWillAppear:(BOOL)animated
	{
	    [super viewWillAppear:animated];
	    
	    if (_videoView && IsIOS8) {
	        [_videoView resumeVideo];
	    }
	}

```

iOS的兼容真是个蛋疼的问题。

