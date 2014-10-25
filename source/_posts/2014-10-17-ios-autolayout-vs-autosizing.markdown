---
layout: post
title: "iOS AutoLayout与AutoSizing：自动布局，想说爱你真的好难"
date: 2014-10-17 14:31:20 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: iOS, AutoLayout, AutoSizing
description: iOS AutoLayout与AutoSizing的对比：自动布局，想要说声爱你真的好难
---

在iPhone Retina发布之前，还没有AutoLayout，因为屏幕只有一种尺寸。  
当iPhone Retina发布之后，我没有用上AutoLayout，因为屏幕尺寸是用点来表示，布局写起来没什么不同。  
当iPhone 5发布之后，屏幕尺寸终于加长了，但是由于有AutoSizing，所以我还是可以不用AutoLayout。  
现在，iPhone 6和6 Plus发布了，屏幕又大了，我不得不开始考虑是否要使用AutoLayout。

<!--more-->

##1. Autolayout 与 Autosizing的区别

虽然自iOS6之后，苹果推荐我们使用Autolayout布局，并且在Xib和Storyboard中默认帮我们打开了这个选项，但是在开发过程中，我们偏向于使用`Autosizing`，并且手动取消掉`Autolayout`，原因在于，Autolayout太繁琐复杂，而Autosizing简单并且能满足大部分的需求。

###Autosizing适用的情况

当父视图被拉伸的时候，子视图能够适配父视图的新大小。其原理是，子视图有一个masks，用于指定与父视图上下左右边缘的距离，以及自身宽高的关系。

比如，指定子视图的右边缘紧跟着父视图的右边缘，那么父视图变大之后，子视图还是贴在父视图的右边。

这在大部分简单布局情况下非常有效。

###Autosizing的不足

使用Autosizing，有一个前提，就是子视图的Frame是固定的，至少宽高是固定的，或者跟随着父视图的Frame变化。但是，如果希望多个子视图与父视图的边距固定，大小自动调整，Autosizing就爱莫能助了。

原因在于：**Autosizing无法智能计算多个子View各自的Frame**。

比如，我们希望在竖屏下布局是这样：

![autosizing portrait](http://cdn4.raywenderlich.com/wp-content/uploads/2013/09/StrutsProblem-portrait-design-423x500.png)

并且在横屏下布局是这样：

![autosizing landscape](http://cdn4.raywenderlich.com/wp-content/uploads/2013/09/StrutsProblem-landscape-looks-good-480x289.png)

除了手写代码调整Frame，单独用Autosizing是无法做到的。这时候就需要借助强大的Autolayout了。

###Autolayout的优点

Autolayout使用约束来决定每个View的坐标、大小，约束可以针对SuperView，也可以针对其他任意一个SubView。

使用自动布局，你可以表达出视图与视图之间的关系，而不是明确地指定每个视图的Frame。通过约束，视图会自动计算它们应该呆在哪个位置，只要约束足够多，它们也能自动计算自己的大小。

只要指定了约束，无论屏幕大小怎么变化，它们都能自适应，这就是Autolayout的优点：妈妈再也不用担心你手写布局代码啦！也不用担心你为了适配各种屏幕大小而加班了。

###Autolayout的缺点

Autolayout唯一的缺点就在于：过于复杂，较难上手。

###使用Autolayout，还是Autosizing？

取决于项目需求。如果Autosizing完全能满足开发需求，那么就没必要使用复杂的Autolayout。但是，如果你已经被适配各种屏幕大小折腾得不成人形了，那么就要早日投入到Autolayout的怀抱了。

##Autolayout的使用

首先要改变自己对布局的思考方式。你应该忘掉Frame，需要考虑的是subView A与subView B的上下左右的关系，以及与superView的关系。

###借助XCode

在Xcode5之后，苹果已经尽力让开发者能更方便地使用Autolayout了。  
通过`Xcode`->`Editor`->`Pin/Align`菜单为视图添加约束即可。

在XCode中除了通过菜单，还可以通过可视化的方式添加约束：

![autolayout add constraint](http://cdn4.raywenderlich.com/wp-content/uploads/2013/09/Pin-green-view.png)

如果你添加的约束不足以表达某个View的位置大小，XCode还会以黄色的辅助线发出警告，十分好用。

###手写约束Constraint

XCode虽然强大，但是有时候我们也许希望借助代码来写Constraint。

加入你希望一个子view跟随父view的大小，但是与边距有10个点的距离：

``` m

UIView *superview = self;

UIView *view1 = [[UIView alloc] init];
view1.translatesAutoresizingMaskIntoConstraints = NO;
view1.backgroundColor = [UIColor greenColor];
[superview addSubview:view1];

UIEdgeInsets padding = UIEdgeInsetsMake(10, 10, 10, 10);

[superview addConstraints:@[

    //view1 constraints
    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:padding.top],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeLeft
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                  constant:padding.left],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:-padding.bottom],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeRight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeRight
                                multiplier:1
                                  constant:-padding.right],

 ]];

```

每个约束都是这样的长长一串代码，设想一下需要添加6个约束的话……

幸好有了这个开源库：[Masonry](https://github.com/Masonry/Masonry)。

使用这个库，代码添加约束就可以简介如下：

``` m

[view1 mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(superview).with.insets(padding);
}];

```

###更新约束

比如，我们自己实现了一个图文混排的TextView，添加到Xib时我们还不知道其高度，需要在代码中计算，那么就需要在代码里更新约束，如：

``` m

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *richTextHeightConstraint;
    
...
    
- (void)relayout
{
    self.richTextHeightConstraint.constant = self.richTextView.frame.size.height;

    [self needsUpdateConstraints];
}

```

##关键还是实践

多说无益，贵在实践。只要有意识地去使用了一次，自然就会了。

###参考链接

* [Beginning Auto Layout Tutorial in iOS 7: Part 1](http://www.raywenderlich.com/50317/beginning-auto-layout-tutorial-in-ios-7-part-1)
* [Beginning Auto Layout Tutorial in iOS 7: Part 2](http://www.raywenderlich.com/50319/beginning-auto-layout-tutorial-in-ios-7-part-2)
* [开始iOS 7中自动布局教程 一](http://www.cocoachina.com/industry/20131203/7462.html)
* [开始iOS 7中自动布局教程 二](http://www.cnblogs.com/zer0Black/p/3977288.html)
* [从此爱上iOS Autolayout](http://segmentfault.com/blog/ilikewhite/1190000000646452)
