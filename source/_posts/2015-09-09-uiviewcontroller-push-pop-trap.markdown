---
layout: post
title: "UIViewController Push & Pop 的那些坑"
date: 2015-09-09 18:37:32 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: iOS, UIViewController, Push, Pop, 卡死, 崩溃
description: iOS开发中，UIViewController是最常用的一个类，在Push和Pop的过程中也会经常出现一些UI卡死、App闪退的问题，本文总结了开发中遇到的一些坑。
---

iOS开发中，UIViewController是最常用的一个类，在Push和Pop的过程中也会经常出现一些UI卡死、App闪退的问题，本文总结了开发中遇到的一些坑。

大部分视图控制器切换导致的问题，根本原因都是使用了动画，因为执行动画需要时间，在动画未完成的时候又进行另一个切换动画，容易产生异常，假如在 Push 和 Pop 的过程不使用动画，世界会清静很多。所以本文只讨论使用了动画的视图切换。也就是使用一下方式的 Push 和 Pop：

``` objc
    [self.navigationController pushViewController:controller animated:YES];
    [self.navigationController popViewControllerAnimated:NO];
```
<!--more-->

## 1. 连续 Push

连续两次 Push 不同的 ViewController 是没问题的，比如这样：

``` objc
- (void)onPush: {
    [self.navigationController pushViewController:vc1 animated:YES];
    [self.navigationController pushViewController:vc2 animated:YES];
}
```

但是，如果不小心连续 Push 了同一个 ViewController，并且 animated 为 YES，则会 Crash：`Pushing the same view controller instance more than once is not supported`。

这种情况很有可能发生，特别是界面上触发切换的入口不止一处，并且各个入口的点击没有互斥的话，用两根手指同时点击屏幕就会同时触发两个入口的切换了。多点触碰导致的同时 Push，基本上是防不胜防，当界面元素很复杂的时候，特别容易出现这个问题，而指望从用户交互的角度上避免这个问题是不可能的，测试美眉以暴力测试、胡乱点击而著称，防得了用户防不住测试。

所以我们需要从根本上解决这个问题：当一个 Push 动画还没完成的时候，不允许再 Push 别的 ViewController。这样处理是没有问题的，因为连续带动画地 Push 多个 ViewController 肯定不是开发和产品的意愿，就算有这种需求，也可以通过禁用动画的方式来解决。

### 1.1 解决方案

继承 UINavigationController 并重载 pushViewController 方法。

1. 如果是动画 Push，并且属性 `isSwitching == YES`，则忽略这次 Push。
2. 否则，设置 `isSwitching = YES` 再继续切换。
3. 等到动画切换完毕，需要再把 `isSwitching ` 改为 NO。

``` objc

@interface MYNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (assign, nonatomic) BOOL isSwitching;

@end


@implementation MYNavigationController

// 重载 push 方法
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (animated) {
        if (self.isSwitching) {
            return; // 1. 如果是动画，并且正在切换，直接忽略
        }
       self.isSwitching = YES; // 2. 否则修改状态
    }
    
    [super pushViewController:viewController animated:animated];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isSwitching = NO; // 3. 还原状态
}

```

## 2. 连续 Pop

连续 Pop ，可能会导致两种情况。

### 2.1 self 被释放

例如，下面的代码，执行到第二句的时候，self 已经被释放了。

``` objc
    [self.navigationController popViewControllerAnimated:YES]; // self 被 release
    [self.navigationController popViewControllerAnimated:YES]; // 继续访问 self 导致异常
```

### 2.2 界面异常、崩溃

假如你避开了上面那种调用，换成了这样：

``` objc
    [[AppDelegate sharedObject].navigationController popViewControllerAnimated:YES]; 
    [[AppDelegate sharedObject].navigationController popViewControllerAnimated:YES]; 
```

由于访问的是全局的 AppDelegate，自然避免了调用者被释放的问题，但是，连续两次动画 Pop，在iOS 7.X 系统会导致界面混乱、卡死、莫名其妙的崩溃（iOS 8 貌似不存在类似的问题）。比如，下面这个崩溃的堆栈：

```
{"bundleID":"com.enterprise.kiwi","app_name":"kiwi","bug_type":"109","name":"kiwi","os_version":"iPhone OS 7.1.1 (11D201)","version":"1190 (3.1.0)"}
Incident Identifier: FE85E864-393C-417D-9EA0-B4324BEEDA2F
CrashReporter Key:   a54805586b9487c324ff5f42f4ac93dabbe9f23e
Hardware Model:      iPhone6,1
Process:             kiwi [1074]
Path:                /var/mobile/Applications/D81CE836-3F88-481C-AA5A-21DA530234E0/kiwi.app/kiwi
Identifier:          com.yy.enterprise.kiwi
Version:             1190 (3.1.0)
Code Type:           ARM-64 (Native)
Parent Process:      launchd [1]

Date/Time:           2015-09-08 15:44:57.327 +0800
OS Version:          iOS 7.1.1 (11D201)
Report Version:      104

Exception Type:  EXC_CRASH (SIGSEGV)
Exception Codes: 0x0000000000000000, 0x0000000000000000
Triggered by Thread:  1

Thread 0:
0   libobjc.A.dylib               	0x00000001993781dc objc_msgSend + 28
1   UIKit                         	0x000000018feacf14 -[UIResponder(Internal) _canBecomeFirstResponder] + 20
2   UIKit                         	0x000000018feacba0 -[UIResponder becomeFirstResponder] + 240
3   UIKit                         	0x000000018feacfa0 -[UIView(Hierarchy) becomeFirstResponder] + 120
4   UIKit                         	0x000000018ff320f8 -[UITextField becomeFirstResponder] + 64
5   UIKit                         	0x000000018ffe4800 -[UITextInteractionAssistant(UITextInteractionAssistant_Internal) setFirstResponderIfNecessary] + 208
6   UIKit                         	0x000000018ffe3f84 -[UITextInteractionAssistant(UITextInteractionAssistant_Internal) oneFingerTap:] + 1792
7   UIKit                         	0x000000018ffcac60 _UIGestureRecognizerSendActions + 212
8   UIKit                         	0x000000018fe5929c -[UIGestureRecognizer _updateGestureWithEvent:buttonEvent:] + 376
9   UIKit                         	0x000000019025803c ___UIGestureRecognizerUpdate_block_invoke + 56
10  UIKit                         	0x000000018fe1a258 _UIGestureRecognizerRemoveObjectsFromArrayAndApplyBlocks + 284
11  UIKit                         	0x000000018fe18b34 _UIGestureRecognizerUpdate + 208
12  UIKit                         	0x000000018fe57b1c -[UIWindow _sendGesturesForEvent:] + 1008
13  UIKit                         	0x000000018fe5722c -[UIWindow sendEvent:] + 824
14  UIKit                         	0x000000018fe28b64 -[UIApplication sendEvent:] + 252
15  UIKit                         	0x000000018fe26c54 _UIApplicationHandleEventQueue + 8496
16  CoreFoundation                	0x000000018ce1f640 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 20
17  CoreFoundation                	0x000000018ce1e99c __CFRunLoopDoSources0 + 252
18  CoreFoundation                	0x000000018ce1cc34 __CFRunLoopRun + 628
19  CoreFoundation                	0x000000018cd5dc1c CFRunLoopRunSpecific + 448
20  GraphicsServices              	0x0000000192a45c08 GSEventRunModal + 164
21  UIKit                         	0x000000018fe8efd8 UIApplicationMain + 1152
22  kiwi                          	0x000000010026a2b8 main (main.mm:26)
23  libdyld.dylib                 	0x000000019995ba9c start + 0

Thread 1 Crashed:
0   libsystem_kernel.dylib        	0x0000000199a3daa8 kevent64 + 8
1   libdispatch.dylib             	0x0000000199941998 _dispatch_mgr_thread + 48
```

从崩溃记录完全看不出原因，十分坑爹。

### 2.3 解决方案

* 方案一：第一次 Pop 不使用动画。
* 方案二：统一管理 Pop 的调用，如果当前正在 Pop，则下一次 Pop 先入栈；等到 Pop 执行完再执行下一次 Pop。

## 3. Push 的过程中立即 Pop

Push 的过程中调用 Pop，会导致界面卡死，表现为：不响应任何点击、手势操作，但是不会崩溃。这也是在 iOS7 中出现的问题，iOS 8 之后不存在。

### 3.1 解决方案

同 1.1，重载 Pop 方法：

1. Pop 的时候先判断是否在切换中；
2. 如果正在切换，则 Pop 的命令先保存到队列；
3. 切换动画执行完毕，判断是否需要处理 Pop 的队列。

``` objc

#pragma mark - UINavigationController

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!self.isSwitching) {
        return [super popToViewController:viewController animated:animated];
    } else {
        [self enqueuePopViewController:viewController animate:animated];
        return nil;
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    if (!self.isSwitching) {
        return [super popViewControllerAnimated:animated];
    } else {
        [self enqueuePopViewController:nil animate:animated];
        return nil;
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isSwitching = NO;
    
    // 显示完毕之后判断是否需要Pop
    if (self.popVCAnimateQueue.count) {
        PopVCInfo *info = [self.popVCAnimateQueue firstObject];
        [self.popVCAnimateQueue removeObjectAtIndex:0];
        if (info.controller) {
            [self.navigationController popToViewController:info.controller animated:info.animate];
        } else {
            [self.navigationController popViewControllerAnimated:info.animate];
        }
    }
}

```

## 4. Push 的过程中手势滑动返回

手势滑动返回本质上调用的还是 Pop，所以，同上。

不过，还可以更根本地禁止用户进行这样的操作，也就是在切换过程中禁止滑动返回手势。


``` objc

#pragma mark - UINavigationController

// Hijack the push method to disable the gesture
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.interactivePopGestureRecognizer.enabled = NO;
    
    [super pushViewController:viewController animated:animated];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isSwitching = NO;
    
    self.interactivePopGestureRecognizer.enabled = YES;
    
    // 显示完毕之后判断是否需要Pop
    if (self.popVCAnimateQueue.count) {
        PopVCInfo *info = [self.popVCAnimateQueue firstObject];
        [self.popVCAnimateQueue removeObjectAtIndex:0];
        if (info.controller) {
            [self.navigationController popToViewController:info.controller animated:info.animate];
        } else {
            [self.navigationController popViewControllerAnimated:info.animate];
        }
    }
}

```

