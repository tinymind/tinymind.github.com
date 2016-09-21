---
layout: post
title: "iOS 10 ReplayKit Live 与 Broadcast UI/Upload Extension"
date: 2016-09-21 11:47:55 +0800
comments: true
categories: [iOS]
tags: [ios, replaykit]
keywords: iOS, ReplayKit, Live, Broadcast, Extension
description: iOS 10 的 ReplayKit 除了录制屏幕，还可以实时直播了，前提是手机里装了包含 Broadcast UI 和 Broadcast Upload 两个 Extension 的 App。
---

在 iOS 8 及以前，第三方 App 如果想要全局录屏，只能使用私有 API，详见[非越狱后台录屏](http://blog.lessfun.com/blog/2015/12/25/ios-record-screen-in-background/)。

升级到 iOS 9 后，官方新增了 ReplayKit，并且禁用了录屏的私有 API。ReplayKit 并不算是完美的录屏方案，如果想要把梦幻西游的游戏过程录制下来，需要梦幻西游这个应用本身添加 ReplayKit 的支持，然后再把录制的视频分享出去。对于不支持 ReplayKit 的游戏，怎么录制？答案是，没有办法。试想，又有多少个游戏会内置 ReplayKit 呢？

iOS 10 在 iOS 9 的 ReplayKit 保存录屏视频的基础上，增加了视频流实时直播功能（streaming live），官方介绍见 [Go Live with ReplayKit](http://devstreaming.apple.com/videos/wwdc/2016/601nsio90cd7ylwimk9/601/601_go_live_with_replaykit.pdf)。下面详细说说这个流程。

<!--more-->

## 1. ReplayKit Live 概述

从录制到直播，整体流程如下：

1. 被录制端需引入 ReplayKit，发起广播请求。
2. 广播端需要实现 Broadcast UI 和 Broadcast Upload 两个 [App Extension](https://developer.apple.com/library/content/documentation/General/Conceptual/ExtensibilityPG/index.html#//apple_ref/doc/uid/TP40014214-CH20-SW1)，以便出现在被录制端的 App 列表。
3. 被录制端选定广播端 App 后，开始直播。

其中，`被录制端`可以是任意一个 App，如梦幻西游，`广播端`是支持 ReplayKit Live 的直播平台，如虎牙直播。

![ReplayKit WorkFlow](/images/2016/09/replaykit_workflow.png)

## 2. 被录制端（游戏或应用）的实现

被录制端需要在原有功能的基础上，增加一个唤起广播的入口。代码：

``` objc
#import <ReplayKit/ReplayKit.h>

- (IBAction)onLiveButtonPressed:(id)sender {
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
        self.broadcastAVC = broadcastActivityViewController;
        self.broadcastAVC.delegate = self;
        [self presentViewController:self.broadcastAVC animated:YES completion:nil];
    }];
}


#pragma mark - RPBroadcastActivityViewControllerDelegate

- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error {
    
    [self.broadcastAVC dismissViewControllerAnimated:YES completion:nil];
    
    self.broadcastController = broadcastController;
    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
        if (!error) {
            self.liveButton.selected = YES;
        } else {
            NSLog(@"startBroadcastWithHandler error: %@", error);
        }
    }];
}

```

如下图的右上角就是开始广播的入口按钮。

![ReplayKit Demo Init](/images/2016/09/replaykit_demo_init.png)

如果手机内没有支持广播的 App，会弹框提示到 App Store 查找一个。

![ReplayKit Demo Choose](/images/2016/09/replaykit_demo_choose.png)

如果已经安装支持广播的 App，则会列出，点击后会打开广播端的 Broadcast UI。

![ReplayKit Demo List](/images/2016/09/replaykit_demo_list.png)

下面要说的就是怎么实现一个支持广播的 App。

## 3. 广播端（直播平台）的实现

很多直播 App 本身已经支持通过摄像头进行视频流上传、直播，新增对 ReplayKit Live 的支持，只需要创建两个扩展的 target，分别是 Broadcast UI Extension 和 Broadcast Upload Extension，在XCode 8 中内置了这两个模板。

### 3.1 Broadcast UI

Broadcast UI 负责广播前的一些初始化工作，比如，让用户填写直播平台的账号、密码、直播标题。从被录制端唤起广播请求并选定广播平台后，会显示 Broadcast UI 界面。

核心代码：

``` objc

#import <ReplayKit/ReplayKit.h>

@interface BroadcastViewController : UIViewController

@end

...

- (IBAction)onCancelButtonPressed:(id)sender {
    [self userDidCancelSetup];
}

- (IBAction)onOKButtonPressed:(id)sender {
    if (self.accountTextField.text.length == 0
        || self.passwordTextField.text.length == 0
        || self.channelIDTextField.text.length == 0) {
        return;
    }
    [self userDidFinishSetup];
}

#pragma mark - Private

// Called when the user has finished interacting with the view controller and a broadcast stream can start
- (void)userDidFinishSetup {
    
    NSLog(@"userDidFinishSetup");
    
    // Broadcast url that will be returned to the application
    NSURL *broadcastURL = [NSURL URLWithString:@"http://broadcastURL_example/stream1"];
    
    // Service specific broadcast data example which will be supplied to the process extension during broadcast
    NSDictionary *setupInfo = @{@"account" : self.accountTextField.text,
                                @"password" : self.passwordTextField.text,
                                @"channelID" : @(self.channelIDTextField.text.integerValue)};
    
    // Set broadcast settings
    RPBroadcastConfiguration *broadcastConfig = [[RPBroadcastConfiguration alloc] init];
    broadcastConfig.clipDuration = 5.0; // deliver movie clips every 5 seconds
    
    // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
    [self.extensionContext completeRequestWithBroadcastURL:broadcastURL broadcastConfiguration:broadcastConfig setupInfo:setupInfo];
}

- (void)userDidCancelSetup {
    // Tell ReplayKit that the extension was cancelled by the user
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"YourAppDomain" code:-1     userInfo:nil]];
}

```

效果：

![ReplayKit Demo List](/images/2016/09/replaykit_demo_broadcast_ui.png)

如果用户点击 `OK`，则会回调到第二部分中的`RPBroadcastActivityViewControllerDelegate`，开始直播会调用 Broadcast Upload 扩展。

### 3.2 Broadcast Upload

第二部分调用`startBroadcastWithHandler`，会跑到`Broadcast Upload`，本扩展的作用是接收并处理 Broadcast UI 传过来的用户信息，以及处理 RPBroadcastController 传过来的音视频流数据，如编码、上传。

核心代码：

``` objc

#import <ReplayKit/ReplayKit.h>

@interface SampleHandler : RPBroadcastSampleHandler

@end

...


//  To handle samples with a subclass of RPBroadcastSampleHandler set the following in the extension's Info.plist file:
//  - RPBroadcastProcessMode should be set to RPBroadcastProcessModeSampleBuffer
//  - NSExtensionPrincipalClass should be set to this class

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension will be supplied.
    NSLog(@"broadcastStartedWithSetupInfo: %@", setupInfo);
    [[ReplayKitUploader sharedObject] setupWithInfo:setupInfo];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    [[ReplayKitUploader sharedObject] handleSampleBuffer:sampleBuffer withType:sampleBufferType];
}

@end

```

### 3.3 注意事项

`ReplayKitUploader` 是自定义的一个类，使用了单例模式，负责广播服务的登录、编码、上传功能。使用单例，而不是直接在 SampleHandler 里面处理，是因为 SampleHandler 并不是 Broadcast Upload Extension 里的唯一一个实例，实际上，Upload Extension 会不断地创建很多个 SampleHandler 来处理 CMSampleBufferRef，而我们为了保存一些内部状态，必须使用一个固定的类实例来实现。

## 4. App 与 Extension 的代码共用

iOS 10 新增了很多种 Extension，包括本文提到的两种 Broadcast Extension。主 App 与 Extension 属于不同的两个进程，代码逻辑也是分离的，而实际情况中，主 App 与 Extension 往往会包含相同的逻辑，需要共用代码。

主 App 与 Extension 属于两个不同的 target，共用代码，有以下几种方式：

* 一份代码创建两个副本，分别加到 App 和 Extension 两个 target 中。这种方法简单粗暴而有效，只是，如果需要改动逻辑，则需要改两份代码，想象一下，假如这种改动很频繁，世界上又有几个程序员能受得了？
* 抽离公共代码，放到独立的 framework，然后两个 target 都依赖该 framework，这是标准而方便的做法。
* 使用 CocoaPods，只需要在 Podfile 中分别写两个 target 所依赖的 pod 即可，最简洁。

## 5. 结论

在 iOS 环境中，想要共享设备屏幕，无论是录播还是直播，都注定了没有直接方便的方案。ReplayKit Live 是目前最标准的做法，只是，使用 ReplayKit 有两个前提，应用本身支持 ReplayKit，直播平台支持 Broadcast Extension。这两个前提，后者比较容易实现，而前者，就需要靠各个应用开发商的自觉了。

