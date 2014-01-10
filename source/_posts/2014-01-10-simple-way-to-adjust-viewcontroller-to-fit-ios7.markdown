---
layout: post
title: "通过简单的方法适应iOS7中的UIViewController，同时兼容iOS6"
date: 2014-01-10 15:07:24 +0800
comments: true
categories: [iOS]
tags: [ios]
---

###设置view从导航栏下方开始布局

在iOS6及以前的版本中，UIViewController的高度和位置都是从导航栏下方开始的。但是在iOS7中，UIViewController不再提供wantsFullScreenLayout属性，UIViewController创建后默认就是Full Screen的，因此如果带导航栏的应用界面中的部分控件会与导航栏重叠在一起。

我们的应用大都要兼容低于iOS7的版本，所以必须解决这种不兼容的现象。
思路是，还是按照iOS6的布局方式，因为被导航栏覆盖部分界面实在看不出有什么好处。所以，我们需要判断iOS版本，如果是iOS6，一切照旧，如果是iOS7，则设置view从导航栏下方开始布局。

简单的方法，在ViewDidLoad里面增加几句代码即可，如下：

<!--more-->

``` cpp

 #define SystemVersionLessThan(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
    
  - (void)viewDidLoad
  {
    [super viewDidLoad];
    
    if (!SystemVersionLessThan(@"7.0")) {
      self.edgesForExtendedLayout = UIRectEdgeNone;
      self.extendedLayoutIncludesOpaqueBars = NO;
    }
  }
```

这样设置之后，可以看到在iOS7中布局跟iOS显示一样了。

如果有很多个UIViewController，只需要新建一个UIViewController的子类，比如`MyUIViewController`，把上面代码放到MyUIViewController的`ViewDidLoad`中，然后修改所有的UIViewController为MyUIViewController即可。

###修改iOS7中UITableViewCell的分隔线

只是还有一个问题，如果添加了UITableView，会发现cell的分隔线短了一小部分，还需设置如下：

``` cpp
  self.tableView.separatorInset = UIEdgeInsetsZero;
```

修改后的效果如图：
iOS6：  
![ios_adjust_ios6](/images/2014/01/ios_adjust_ios6.png)

iOS7:  
![ios_adjust_ios6](/images/2014/01/ios_adjust_ios7.png)

iOS7表格分隔线：  
![ios_adjust_ios6](/images/2014/01/ios_adjust_ios7_tableviewcell.png)

搞定！

###去掉iOS6中导航栏的阴影

iOS6的UINavigationBar默认加了一层阴影，而iOS7中则默认没有，我们可以通过下面的代码去掉iOS6的导航栏阴影：

``` cpp
  if (!SystemVersionLessThan(@"6.0")) {
      [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
  }
```