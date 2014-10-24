---
layout: post
title: "Xcode 6.1 iPhone Simulator 8.1 Keyboard Issue：键盘无法显示，设置inputAccessoryView崩溃"
date: 2014-10-24 14:42:51 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: ios, xcode, simulator, keyboard, crash
description: 如果升级到XCode 6.1，使用iPhone Simulator 8.1之后，发现原来在iOS 7.1上一切正常的键盘，突然就没法显示，或者会导致崩溃，可以试试本文的解决方法。
---

随着iPhone 6 & Plus的发布，苹果也陆续更新了XCode和开发模拟器，目前最新的Xcode版本是6.1，内置的Simulator的iOS版本是8.1。也许你兴致冲冲迫不及待地一下子升级到了最新版的开发环境，那么可能会遇到一些键盘上的问题：无法弹出键盘，或者弹出键盘后会莫名其妙地崩溃。

当然，不能怪你，你的项目在iOS7.1上是运行地好好的。只能怪苹果没有推出一个完美无Bug的开发工具。

<!--more-->

##1. 在XCode 6，iOS 8.1模拟器无法弹出键盘

解决方法很简单，在Simulator的系统菜单中，取消勾选：

`Hardware` -> `Keyboard` -> `Connect Hardware Keyboard`。

取消选中之后，键盘可以正常弹出，但是，无法使用硬件的键盘输入了，自己慢慢用鼠标点击模拟器里的键盘吧……

##2. 弹出键盘后会莫名其妙地崩溃

也许你键盘能正常显示了，但是一显示就崩溃，在堆栈中有这样的字样：

``` m

	*** First throw call stack:
	(
	    0   CoreFoundation                      0x02101df6 __exceptionPreprocess + 182
	    1   libobjc.A.dylib                     0x01d8ba97 objc_exception_throw + 44
	    2   CoreFoundation                      0x02101d1d +[NSException raise:format:] + 141
	    3   UIKit                               0x008cff9c -[UIViewController _addChildViewController:performHierarchyCheck:notifyWillMove:] + 210
	    4   UIKit                               0x00f4b44d -[UIInputWindowController changeToInputViewSet:] + 576
	    5   UIKit                               0x00f4c1be __43-[UIInputWindowController setInputViewSet:]_block_invoke + 103
	    6   UIKit                               0x007f73bf +[UIView(Animation) performWithoutAnimation:] + 82
	    7   UIKit                               0x00f4bf9c -[UIInputWindowController setInputViewSet:] + 374
	    8   UIKit                               0x00ce9101 __64-[UIPeripheralHost(UIKitInternal) setInputViews:animationStyle:]_block_invoke1459 + 43
	    9   UIKit                               0x00f473af -[UIInputWindowController performOperations:withAnimationStyle:] + 56
	    
	......
	}
```

以上崩溃也只在XCode 6，iOS 8出现，在iOS 7一切正常。

原因可能是你设置了`UITextField`或`UITextView`的`inputView`或`inputAccessoryView`为customView，比如这样：

``` m

	//在Xib或Storyboard中创建了一个自定义View
	@property (strong, nonatomic) IBOutlet UIView *switchKeyboardBar;
	
	...
	
	- (void)viewDidLoad
	{
	    [super viewDidLoad];
	    
	    self.textView.inputAccessoryView = self.switchKeyboardBar;
	}

```

上述代码在iOS 8中是必定Crash的，因为`UITextView.inputAccessoryView`不能是其他View的子View。而上面的`switchKeyboardBar`先被添加到了当前`UIViewController`的`View`中，再被设置到`inputAccessoryView`，就会导致崩溃。

###2.1 解决方法

不从Xib创建自定义View，而是在代码中手动创建，并且不添加到别的View中。

如下：

``` m

	//注意这里没有 IBOutlet
	@property (strong, nonatomic) UIView *switchKeyboardBar;
	
	- (UIView *)switchKeyboardBar
	{
	    if (!_switchKeyboardBar) {
	        _switchKeyboardBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 40)];
	        
	        //add other subviews
	        ...
	    }
	    return _switchKeyboardBar;
	}
	
	- (void)viewDidLoad
	{
	    [super viewDidLoad];
	    
	    self.textView.inputAccessoryView = self.switchKeyboardBar;
	}

```

