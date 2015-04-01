---
layout: post
title: "UITableView性能优化，提升列表滚动的流畅性"
date: 2015-04-01 12:13:46 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: ios, c, uitableview, 性能, 优化
description: UITableView是iOS开发中最常用也很实用并且最容易出现性能问题的的一个控件，本文列出了一些性能优化点，用于提高列表滚动的流畅性。
---

UITableView是iOS开发中最常用也很实用并且最容易出现性能问题的的一个控件，本文列出了一些性能优化点，用于提高列表滚动的流畅性。

<!--more-->

## 1. 重用
当TableView需要显示一个Cell时，会先从已创建的Cell中找一个可以重用的，然后展现到屏幕。一般情况下，可以被重用的Cell都滚到了屏幕区域外。如果慢慢地拖动TableView，就可以看到Cell不断地被重用（通过断点可以看到Cell的init或awakeFromNib没有被调用）。但是如果快速滚动，还是可能会看到Cell被创建。

### 1.1 已经在StoryBoard的TableView中定义Cell的ProtoType
则指定其ReuseIdentify，在delegate返回Cell的时候，调用：
``` c
     [tableView dequeueReusableCellWithIdentifier:kCellID];
```

### 1.2 Cell是从单独的xib加载
则需要先注册：
``` c
     [tableView registerNib:[UINib nibWithNibName:kCellID bundle:nil] forCellReuseIdentifier:kCellID];
```

### 1.3 Cell的ProtoType个数尽可能少，因为Cell的种类越多，TableView创建的Cell个数就越多，并且是成倍增长。

## 2. 缓存
缓存基本上可以解决大部分性能问题。TableView需要知道Cell的高度，才能对Cell进行布局；需要知道所有的Cell的高度，才能知道TableView本身的高度，所以，每次调用reloadData，都需要计算所有Cell的高度。我们要尽量减小高度计算的复杂度。

### 2.1 缓存Cell的高度
#### 2.1.1 高度固定、类型单一的Cell
在创建TableView的时候，直接设置其rowHeight属性。

#### 2.1.2 对于高度固定、类型多样的Cell
实现代理方法，根据Cell的类型返回不同的高度：
``` c
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
```

#### 2.1.3 对于高度不固定的Cell

![dynamic uitableviewcell](/images/2015/04/tableview_dynamic_cell.png)

由于需要动态计算高度，所以运算量必然会增大，但是还是存在优化的空间。常见的优化方式是，把cellHeight作为data的一个属性缓存起来，对于每一个data对应的每一个cell，就只需要计算一次高度。示例代码：
``` c
	@interface ContentInfo : NSObject
	
	@property(nonatomic, assign) DetailInfo *detail;
	@property(nonatomic, strong) CGFloat cellHeight;
	
	- (CGFloat)calcHeight;
	
	@end
	
	- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	    ContentInfo *info = _dataSource[index];
	    if (info.cellHeight <= 0.1) {
	        info.cellHeight = [info calcHeight];
	    }
	    return info.cellHeight;
	}
```

当然，这样的方式，还是把运算量放到了TableView的代理方法内，其实也可以在创建ContentInfo本身的时候，就调用它的calcHeight方法，在代理方法里就可以可以直接返回info.cellHeight了。但也要结合实际情况进行取舍，因为有时候，有了数据源，但不一定需要展示TableView，提前计算高度反而会浪费时间。

### 2.2 缓存Cell的资源
比如每一个Cell都需要用到的UIImage，UIFont，NSDateFormatter或者任何在绘制时需要的对象，推荐使用类层级的初始化方法中执行分配，并将其存储为静态变量。

## 3. 创建
### 3.1 去掉AutoLayout
如果发现通过StoryBoard+xib+AutoLayout创建Cell时性能满足不了需求，可以考虑去掉AutoLayout。
### 3.2 代码创建Cell
如果不用AutoLayout还是有问题，可以考虑通过代码创建Cell的Views。
### 3.3 自绘
如果使用代码创建还是解决不了问题，那就只能靠自绘了，重载Cell的drawRect方法即可。

## 4. 渲染
### 4.1 减少子View的个数和层级
子View的层级越深，渲染到屏幕上所需要的计算量就越大。

### 4.2 减少子View的透明图层
对于不透明的View，设置opaque为YES，这样在绘制该View时，就不需要考虑被View覆盖的其他内容。

### 4.3 避免CAlayer特效。
给Cell中View加阴影会引起性能问题，如下面代码会导致滚动时有明显的卡顿：
``` c
    view.layer.shadowColor = color.CGColor;
    view.layer.shadowOffset = offset;
    view.layer.shadowOpacity = 1;
    view.layer.shadowRadius = radius;
```

