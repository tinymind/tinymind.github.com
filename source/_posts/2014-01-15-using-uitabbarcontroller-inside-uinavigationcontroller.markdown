---
layout: post
title: "在UINavigationController中使用UITabBarControllier，处理报错"
date: 2014-01-15 12:12:51 +0800
comments: true
categories: [iOS]
tags: [ios]
---

写iOS应用时，经常需要将UITabBarController嵌入到一个根UINavigationController中，如果处理不好，我们会遇到这样的错误：

    Two-stage rotation animation is deprecated. This application should use the smoother single-stage animation.
   
网上找了一下，StackOverFlow的[这个答案](http://stackoverflow.com/a/6637554)说，不应该将UITabBarControllier嵌入到UINavigationController中作为rootViewController，但是，我们的确想要这样做，所以只好寻找其它办法。不过，至少我们可以确定的是，问题出在rootViewController同时包含UITabBarControllier和UINavigationController。

几经尝试，最后发现，在设置为`window.rootViewController`之前，先指定`tabBarController.selectedIndex = 0`，问题解决。

可以得出，出现上述错误，是因为XCode不知道你需要push哪个子viewController，在加载navigationController的时候，不知道要载入哪一个controller，于是无脑的将tabBarController的viewControllers都动画载入了。

完整代码如下：

<!--more-->

``` cpp
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UINavigationController *navVC = [storyBoard instantiateInitialViewController];
    //MainViewController是UITabBarController的子类
    MainViewController *rootVC = (MainViewController *)navVC.visibleViewController;
    rootVC.delegate = self;
    rootVC.selectedIndex = 0;   //需要这样设置
    
    self.window.rootViewController = navVC;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}
```

StoryBoard：

![ios_tabbar_storyboard](/images/2014/01/ios_tabbar_storyboard.png)

运行效果：

![ios_tabbar_running](/images/2014/01/ios_tabbar_running.png)  
