---
layout: post
title: "更可靠和高精度的 iOS 定时器"
date: 2016-08-05 18:23:26 +0800
comments: true
categories: [iOS]
tags: [ios, objectivec]
keywords: iOS, NSTimer, Accuracy, Precision, CADisplayLink 
description: NSTimer 并不是一个可靠的定时器，精度也不高。本文对 iOS 中的各种定时器类型作一个对比和总结，探讨如何创建可靠的、高精度的 iOS 定时器。具体应该使用什么定时器，需要视情况而定。
---

定时器一般用于延迟一段时间执行特定的代码，必要的话按照指定的频率重复执行。iOS 中延时执行有多种方式，常用的有：

- NSTimer
- NSObject 的 `(void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay;`
- CADisplayLink
- GCD 的 `dispatch_after`
- GCD 的 `dispatch_source_t`

每种方法创建的定时器，其可靠性与最小精度都有不同。`可靠性`指是否严格按照设定的时间间隔按时执行，`最小精度`指支持的最小时间间隔是多少。

<!--more-->

## 1. NSRunLoop

谈到定时器，首先需要了解的一个概念是 [NSRunLoop](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSRunLoop_Class/)。NSRunLoop 是消息处理的一种机制，类似于 Windows 中的[消息循环](http://winprog.org/tutorial/message_loop.html)，有个更通用的叫法是 [Event Loop](https://en.wikipedia.org/wiki/Event_loop)。

其原理很简单，启动一个循环，无限地重复`接受消息->等待消息->处理消息`这个过程，直到退出。伪代码如下：

``` c
void loop() {
    do {
        void *msg = getMessage();
        processMessage(msg);
    } while (msg != quit);
}
```

每个线程内部都会有一个 RunLoop，启动 RunLoop 之后，就能够让线程在没有消息时休眠，在有消息时被唤醒并处理消息，避免资源长期被占用。

在 iOS 中，NSThead 和 NSRunLoop 是一一对应的，但创建线程的时候不会默认创建 NSRunLoop，实际上也不允许自己创建 NSRunLoop，在线程内第一次调用`[NSRunLoop currentRunLoop]`的时候才会自动创建。

### 1.1 NSRunLoop 处理的输入源(input sources)：

- 鼠标、键盘事件。
- NSPort 对象。
- NSConnection 对象。

NSRunLoop 也处理 NSTimer 事件，但 NSTimer 并不属于输入源的一种。

### 1.2 苹果使用 NSRunLoop 实现的功能：

- 硬件操作，如触摸、按键、摇晃等。
- 手势操作。
- 界面刷新，如更新了 UI 的 frame，或手动调 setNeedsLayout/setNeedsDisplay。
- 定时器。包括 NSTimer、CADisplayLink、PerformSelecter、GCD。
- 网络请求。

[深入了解 RunLoop](http://blog.ibireme.com/2015/05/18/runloop/)有更深入完整的介绍。

## 2. NSTimer

最常用，能满足对间隔要求不严格、对精确度不敏感的需求。

### 2.1 使用方法

``` objc

- (void)startNSTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval target:self selector:@selector(onNSTimerTimeout:) userInfo:nil repeats:YES];
}

- (void)onNSTimerTimeout:(id)sender {
    NSLog(@"onNSTimerTimeout");
}

```

### 2.2 可靠性

不可靠，其所在的 RunLoop 会定时检测是否可以触发 NSTimer 的事件，但由于 iOS 有多个 RunLoop 的运行模式，如果被切到另一个 run loop，NSTimer 就不会被触发。每个 RunLoop 的循环间隔也无法保证，当某个任务耗时比较久，RunLoop 的下一个消息处理就只能顺延，导致 NSTimer 的时间已经到达，但 Runloop 却无法及时触发 NSTimer，导致该时间点的回调被错过。

苹果官方文档：

> A timer is not a real-time mechanism; it fires only when one of the run loop modes to which the timer has been added is running and able to check if the timer’s firing time has passed. 
> If a timer’s firing time occurs during a long callout or while the run loop is in a mode that is not monitoring the timer, the timer does not fire until the next time the run loop checks the timer. 

### 2.3 最小精度

理论上最小精度为 0.1 毫秒。不过由于受 Runloop 的影响，会有 50 ~ 100 毫秒的误差，所以，实际精度可以认为是 0.1 秒。

苹果官方文档：

> Because of the various input sources a typical run loop manages, the effective resolution of the time interval for a timer is limited to on the order of 50-100 milliseconds. 

### 2.4 实测结果

间隔 0.1 秒，调用12次。其中倒数第二次调用前会执行一个比较耗时的运算任务。

代码：

``` objc
- (void)startNSTimer {
    [self setupConfig];
    
    [self runNSTimerIfNeeded];
    
    NSLog(@"NSTimer start with interval: %.3f ms, start time: %@, total count: %d", self.timeInterval * 1000, [self timeStringWithTime:self.startTime], (int)self.maxCount);
}

- (void)runNSTimerIfNeeded {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval
                                     target:self
                                   selector:@selector(onNSTimerTimeout:)
                                   userInfo:nil
                                    repeats:NO];
    
    self.startTime = [NSDate date];
}

- (void)onNSTimerTimeout:(NSTimer *)sender {
    NSLog(@"%d, %@", ++ self.curCount, [self diffTimeStringFromStart]);
    
    [self.timer invalidate];
    self.timer = nil;
    
    if (self.curCount < self.maxCount) {
        [self runNSTimerIfNeeded];
        [self runBusyTaskIfNeeded];
    }
}
```

结果：

``` sh
2016-08-29 11:32:40.302 TimerDemo[37258:10736148] NSTimer start with interval: 100.000 ms, start time: 1472441560302.602 ms, total count: 12
2016-08-29 11:32:40.403 TimerDemo[37258:10736148] 1, interval: 101.045 ms, discrepancy: 1.045 ms
2016-08-29 11:32:40.505 TimerDemo[37258:10736148] 2, interval: 100.890 ms, discrepancy: 0.890 ms
2016-08-29 11:32:40.606 TimerDemo[37258:10736148] 3, interval: 101.087 ms, discrepancy: 1.087 ms
2016-08-29 11:32:40.707 TimerDemo[37258:10736148] 4, interval: 101.038 ms, discrepancy: 1.038 ms
2016-08-29 11:32:40.809 TimerDemo[37258:10736148] 5, interval: 101.061 ms, discrepancy: 1.061 ms
2016-08-29 11:32:40.910 TimerDemo[37258:10736148] 6, interval: 101.069 ms, discrepancy: 1.069 ms
2016-08-29 11:32:41.012 TimerDemo[37258:10736148] 7, interval: 101.031 ms, discrepancy: 1.031 ms
2016-08-29 11:32:41.113 TimerDemo[37258:10736148] 8, interval: 101.035 ms, discrepancy: 1.035 ms
2016-08-29 11:32:41.214 TimerDemo[37258:10736148] 9, interval: 100.890 ms, discrepancy: 0.890 ms
2016-08-29 11:32:41.315 TimerDemo[37258:10736148] 10, interval: 101.042 ms, discrepancy: 1.042 ms
2016-08-29 11:32:41.315 TimerDemo[37258:10736148] start busy task
2016-08-29 11:32:41.970 TimerDemo[37258:10736148] finish busy task
2016-08-29 11:32:41.970 TimerDemo[37258:10736148] 11, interval: 654.319 ms, discrepancy: 554.319 ms
2016-08-29 11:32:42.071 TimerDemo[37258:10736148] 12, interval: 100.906 ms, discrepancy: 0.906 ms
```

可以看到偏差在 1 ~ 2 毫秒左右。在第 10 次之后执行了一个较耗时的任务，导致第 11 次比预期延迟了 0.5 秒执行。后面的回调仍然按照预设的延时执行。

## 3. performSelector:withObject:afterDelay:

这是 NSObject 对 NSTimer 封装后提供的一个比较简单的延时方法，内部用的也是 NSTimer，所以，同上。

## 4. CADisplayLink

CADisplayLink 也可以用作定时器，其调用间隔与屏幕刷新频率一致，也就是每秒 60 帧，间隔 16.67 ms。与 NSTimer 类似，如果在两次屏幕刷新之间执行了一个比较耗时的任务，其中的某一帧就会被跳过，造成 UI 卡顿。

### 4.1 使用方法

``` objc

- (void)runCADisplayLinkTimer {
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onCADisplayLinkTimeout)];
    displayLink.frameInterval = 0.0167; // S
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink = displayLink;
}

- (void)onCADisplayLinkTimeout {
    NSLog(@"onCADisplayLinkTimeout");
}
```

### 4.2 可靠性

如果执行的任务很耗时，也会导致回调被错过，所以并不十分可靠。但是，假如调用者能够确保任务能够在最小时间间隔内执行完成，CADisplayLink 就比较可靠，因为屏幕的刷新频率是固定的。

### 4.3 最小精度

受限于每秒 60 帧的屏幕刷新频率，注定 CADisplayLink 的最小精度为 16.67 毫秒。误差在 1 毫秒左右。

另外需要注意的是，虽然 CADisplayLink 有一个属性 `frameInterval` 是用于设置定时器的调用间隔，但是这个属性会在第一次回调之后才生效，对于第一次回调，总是会以 1/60 的间隔来执行的。这样会导致的结果是，比如你设置了每 1 秒执行一次某个方法，但是第一次执行的时候，却是在 16.7 毫秒之后，远远小于预设值。

### 4.4 实测结果

间隔 0.1 秒，调用12次。其中倒数第二次调用前会执行一个比较耗时的运算任务。

代码：

``` objc
- (void)startCADisplayLinkTimer {
    [self setupConfig];

    [self runCADisplayLinkTimer];
    
    NSLog(@"CADisplayLink start with interval: %.3f ms, start time: %@, total count: %d", self.timeInterval * 1000, [self timeStringWithTime:self.startTime], (int)self.maxCount);
}

- (void)runCADisplayLinkTimer {
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onCADisplayLinkTimeout)];
    NSInteger frameInterval = floor(self.timeInterval * 1000 / (1000 / 60.0));
    displayLink.frameInterval = frameInterval;
    
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink = displayLink;
    
    self.startTime = [NSDate date];
}

- (void)onCADisplayLinkTimeout {
    NSLog(@"%d, %@", ++ self.curCount, [self diffTimeStringFromStart]);
    
    if (self.curCount < self.maxCount) {
        self.startTime = [NSDate date];
        [self runBusyTaskIfNeeded];
    } else {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}
```

结果：

``` sh
2016-08-29 11:33:47.835 TimerDemo[37258:10736148] CADisplayLink start with interval: 100.000 ms, start time: 1472441627835.872 ms, total count: 12
2016-08-29 11:33:47.845 TimerDemo[37258:10736148] 1, interval: 10.061 ms, discrepancy: -89.939 ms
2016-08-29 11:33:47.946 TimerDemo[37258:10736148] 2, interval: 99.829 ms, discrepancy: -0.171 ms
2016-08-29 11:33:48.046 TimerDemo[37258:10736148] 3, interval: 99.573 ms, discrepancy: -0.427 ms
2016-08-29 11:33:48.145 TimerDemo[37258:10736148] 4, interval: 99.427 ms, discrepancy: -0.573 ms
2016-08-29 11:33:48.246 TimerDemo[37258:10736148] 5, interval: 99.801 ms, discrepancy: -0.199 ms
2016-08-29 11:33:48.346 TimerDemo[37258:10736148] 6, interval: 99.754 ms, discrepancy: -0.246 ms
2016-08-29 11:33:48.446 TimerDemo[37258:10736148] 7, interval: 99.791 ms, discrepancy: -0.209 ms
2016-08-29 11:33:48.546 TimerDemo[37258:10736148] 8, interval: 99.836 ms, discrepancy: -0.164 ms
2016-08-29 11:33:48.646 TimerDemo[37258:10736148] 9, interval: 99.840 ms, discrepancy: -0.160 ms
2016-08-29 11:33:48.746 TimerDemo[37258:10736148] 10, interval: 99.811 ms, discrepancy: -0.189 ms
2016-08-29 11:33:48.746 TimerDemo[37258:10736148] start busy task
2016-08-29 11:33:49.399 TimerDemo[37258:10736148] finish busy task
2016-08-29 11:33:49.400 TimerDemo[37258:10736148] 11, interval: 653.891 ms, discrepancy: 553.891 ms
2016-08-29 11:33:49.412 TimerDemo[37258:10736148] 12, interval: 12.566 ms, discrepancy: -87.434 ms
```

除了第一次回调，间隔误差比较大之外，别的回调误差在 0.1 ~ 0.5 毫秒之间，精度比 NSTimer 要高。第 11 次回调，受耗时任务影响，延时了 0.5 秒。值得注意的是，第 12 次，延时再次与第一次回调一样，变成了 1/60 秒左右。

换言之，CADisplayLink 在第一次回调以及在耗时任务之后的回调，精度不可控。

## 5. GCD `dispatch_after`

dispatch_after 用起来十分简单，代码紧凑易读，而且可以很轻松地在别的线程分配延时任务，所以使用范围很广泛。

### 5.1 使用方法

``` objc
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //handle timeout
    });
```

### 5.2 可靠性

> Any fire of the timer may be delayed by the system in order to improve power consumption and system performance. The upper limit to the allowable delay may be configured with the 'leeway' argument, the lower limit is under the control of the system.

### 5.3 最小精度

延时参数的单位是纳秒。如果有延时，则无法保证。

### 5.4 实测结果

间隔 0.1 秒，调用12次。其中倒数第二次调用前会执行一个比较耗时的运算任务。

代码：

``` objc
- (void)startDispatchAfterTimer {
    [self setupConfig];
    
    [self runDispatchAfterTimerIfNeeded];
    
    NSLog(@"DispatchAfterTimer start with interval: %.3f ms, start time: %@, total count: %d", self.timeInterval * 1000, [self timeStringWithTime:self.startTime], (int)self.maxCount);
}

- (void)runDispatchAfterTimerIfNeeded {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self onDispatchAfterTimeout];
    });
    
    self.startTime = [NSDate date];
}

- (void)onDispatchAfterTimeout {
    NSLog(@"%d, %@", ++ self.curCount, [self diffTimeStringFromStart]);
    if (self.curCount < self.maxCount) {
        [self runDispatchAfterTimerIfNeeded];
        [self runBusyTaskIfNeeded];
    }
}
```

结果：

``` sh
2016-08-29 11:34:09.652 TimerDemo[37258:10736148] DispatchAfterTimer start with interval: 100.000 ms, start time: 1472441649652.825 ms, total count: 12
2016-08-29 11:34:09.756 TimerDemo[37258:10736148] 1, interval: 103.876 ms, discrepancy: 3.876 ms
2016-08-29 11:34:09.866 TimerDemo[37258:10736148] 2, interval: 109.686 ms, discrepancy: 9.686 ms
2016-08-29 11:34:09.976 TimerDemo[37258:10736148] 3, interval: 109.772 ms, discrepancy: 9.772 ms
2016-08-29 11:34:10.085 TimerDemo[37258:10736148] 4, interval: 108.764 ms, discrepancy: 8.764 ms
2016-08-29 11:34:10.195 TimerDemo[37258:10736148] 5, interval: 109.057 ms, discrepancy: 9.057 ms
2016-08-29 11:34:10.299 TimerDemo[37258:10736148] 6, interval: 104.544 ms, discrepancy: 4.544 ms
2016-08-29 11:34:10.408 TimerDemo[37258:10736148] 7, interval: 108.753 ms, discrepancy: 8.753 ms
2016-08-29 11:34:10.516 TimerDemo[37258:10736148] 8, interval: 107.597 ms, discrepancy: 7.597 ms
2016-08-29 11:34:10.626 TimerDemo[37258:10736148] 9, interval: 109.933 ms, discrepancy: 9.933 ms
2016-08-29 11:34:10.736 TimerDemo[37258:10736148] 10, interval: 109.791 ms, discrepancy: 9.791 ms
2016-08-29 11:34:10.736 TimerDemo[37258:10736148] start busy task
2016-08-29 11:34:11.394 TimerDemo[37258:10736148] finish busy task
2016-08-29 11:34:11.394 TimerDemo[37258:10736148] 11, interval: 657.669 ms, discrepancy: 557.669 ms
2016-08-29 11:34:11.496 TimerDemo[37258:10736148] 12, interval: 102.005 ms, discrepancy: 2.005 ms
```

平均误差 9 毫秒。

## 6. GCD `dispatch_source_t`

经测试，dispatch_source_t 的最小精度和可靠性都与 diapatch_after 差不多。

### 6.1 实测结果

间隔 0.1 秒，调用12次。其中倒数第二次调用前会执行一个比较耗时的运算任务。

代码：

``` objc
- (void)startDispatchSourceTimer {
    [self setupConfig];
    
    [self runDispatchSourceTimerIfNeeded];
    
    NSLog(@"DispatchSourceTimer start with interval: %.3f ms, start time: %@, total count: %d", self.timeInterval * 1000, [self timeStringWithTime:self.startTime], (int)self.maxCount);
}

- (void)runDispatchSourceTimerIfNeeded {
    self.sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, 0);
    dispatch_source_set_timer(self.sourceTimer, start, (int64_t)(self.timeInterval * NSEC_PER_SEC), 0);
    
    dispatch_source_set_event_handler(self.sourceTimer, ^{
        [self onDispatchSourceTimeout];
    });
    
    dispatch_resume(self.sourceTimer);
    
    self.startTime = [NSDate date];
}

- (void)onDispatchSourceTimeout {
    NSLog(@"%d, %@", ++ self.curCount, [self diffTimeStringFromStart]);
    
    dispatch_cancel(self.sourceTimer);
    self.timer = nil;
    
    if (self.curCount < self.maxCount) {
        [self runDispatchAfterTimerIfNeeded];
        [self runBusyTaskIfNeeded];
    }
}
```

结果：

``` sh
2016-08-29 11:34:24.088 TimerDemo[37258:10736148] DispatchSourceTimer start with interval: 100.000 ms, start time: 1472441664088.390 ms, total count: 12
2016-08-29 11:34:24.089 TimerDemo[37258:10736148] 1, interval: 1.429 ms, discrepancy: -98.571 ms
2016-08-29 11:34:24.196 TimerDemo[37258:10736148] 2, interval: 106.696 ms, discrepancy: 6.696 ms
2016-08-29 11:34:24.306 TimerDemo[37258:10736148] 3, interval: 109.500 ms, discrepancy: 9.500 ms
2016-08-29 11:34:24.416 TimerDemo[37258:10736148] 4, interval: 109.999 ms, discrepancy: 9.999 ms
2016-08-29 11:34:24.526 TimerDemo[37258:10736148] 5, interval: 109.744 ms, discrepancy: 9.744 ms
2016-08-29 11:34:24.636 TimerDemo[37258:10736148] 6, interval: 109.691 ms, discrepancy: 9.691 ms
2016-08-29 11:34:24.746 TimerDemo[37258:10736148] 7, interval: 109.767 ms, discrepancy: 9.767 ms
2016-08-29 11:34:24.856 TimerDemo[37258:10736148] 8, interval: 109.799 ms, discrepancy: 9.799 ms
2016-08-29 11:34:24.966 TimerDemo[37258:10736148] 9, interval: 109.820 ms, discrepancy: 9.820 ms
2016-08-29 11:34:25.076 TimerDemo[37258:10736148] 10, interval: 109.804 ms, discrepancy: 9.804 ms
2016-08-29 11:34:25.076 TimerDemo[37258:10736148] start busy task
2016-08-29 11:34:25.734 TimerDemo[37258:10736148] finish busy task
2016-08-29 11:34:25.734 TimerDemo[37258:10736148] 11, interval: 657.591 ms, discrepancy: 557.591 ms
2016-08-29 11:34:25.835 TimerDemo[37258:10736148] 12, interval: 101.295 ms, discrepancy: 1.295 ms
```

从结果看，与 `diapatch_after` 区别不大。

## 7. 更高精度的定时器

上述的各种定时器，都受限于苹果为了保护电池和提高性能采用的策略，导致无法实时地执行回调。如果你的确需要使用更高精度的定时器，官方也提供了方法，见 
[High Precision Timers in iOS / OS X](https://developer.apple.com/library/ios/technotes/tn2169/_index.html)

前面所述的定时器，使用方法各有不同，但其核心代码实际上是一样的。
> There are many API's in iOS and OS X that allow waiting for a specified period of time. They may be Objective C or C, and they take different kinds of arguments, but they all end up using the same code inside the kernel.

而有别于普通定时器的[高精度定时器](https://developer.apple.com/library/ios/technotes/tn2169/_index.html#//apple_ref/doc/uid/DTS40013172-CH1-TNTAG5000)，则是基于高优先级的线程调度类创建的定时器，在没有多线程冲突的情况下，这类定时器的请求会被优先处理。

### 7.1 实现方法

- 把定时器所在的线程，移到高优先级的线程调度类。
- 使用更精确的计时器API，换言之，你想要 10 秒后执行，就绝对在 10 秒后执行，绝不提前，也不延迟。

### 7.2 如何使用

- [How do I get put into the real time scheduling class?](https://developer.apple.com/library/ios/technotes/tn2169/_index.html#//apple_ref/doc/uid/DTS40013172-CH1-TNTAG6000)
- [Which timing API(s) should I use?](https://developer.apple.com/library/ios/technotes/tn2169/_index.html#//apple_ref/doc/uid/DTS40013172-CH1-TNTAG8000)

提高调度优先级：

``` cpp
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <pthread.h>
 
void move_pthread_to_realtime_scheduling_class(pthread_t pthread) {
    mach_timebase_info_data_t timebase_info;
    mach_timebase_info(&timebase_info);
 
    const uint64_t NANOS_PER_MSEC = 1000000ULL;
    double clock2abs = ((double)timebase_info.denom / (double)timebase_info.numer) * NANOS_PER_MSEC;
 
    thread_time_constraint_policy_data_t policy;
    policy.period      = 0;
    policy.computation = (uint32_t)(5 * clock2abs); // 5 ms of work
    policy.constraint  = (uint32_t)(10 * clock2abs);
    policy.preemptible = FALSE;
 
    int kr = thread_policy_set(pthread_mach_thread_np(pthread_self()),
                   THREAD_TIME_CONSTRAINT_POLICY,
                   (thread_policy_t)&policy,
                   THREAD_TIME_CONSTRAINT_POLICY_COUNT);
    if (kr != KERN_SUCCESS) {
        mach_error("thread_policy_set:", kr);
        exit(1);
    }
}
```

精确延时：

``` cpp
#include <mach/mach.h>
#include <mach/mach_time.h>
 
static const uint64_t NANOS_PER_USEC = 1000ULL;
static const uint64_t NANOS_PER_MILLISEC = 1000ULL * NANOS_PER_USEC;
static const uint64_t NANOS_PER_SEC = 1000ULL * NANOS_PER_MILLISEC;
 
static mach_timebase_info_data_t timebase_info;
 
static uint64_t abs_to_nanos(uint64_t abs) {
    return abs * timebase_info.numer  / timebase_info.denom;
}
 
static uint64_t nanos_to_abs(uint64_t nanos) {
    return nanos * timebase_info.denom / timebase_info.numer;
}
 
void example_mach_wait_until(int argc, const char * argv[]) {
    mach_timebase_info(&timebase_info);
    uint64_t time_to_wait = nanos_to_abs(10ULL * NANOS_PER_SEC);
    uint64_t now = mach_absolute_time();
    mach_wait_until(now + time_to_wait);
}
```

### 7.3 最小精度

小于 0.5 毫秒。[这里](http://atastypixel.com/blog/wp-content/uploads/2011/09/TPPreciseTimer.zip)有一份实现的代码以及与普通定时器的对比。

## 8. 参考

- [深入了解 RunLoop](http://blog.ibireme.com/2015/05/18/runloop/)
- [High Precision Timers in iOS / OS X](https://developer.apple.com/library/ios/technotes/tn2169/_index.html)
- [Experiments with precise timing in iOS](http://atastypixel.com/blog/experiments-with-precise-timing-in-ios/)