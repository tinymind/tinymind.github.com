---
layout: post
title: "非越狱 iOS 在后台截屏、录制屏幕的相关实现"
date: 2015-12-25 16:54:31 +0800
comments: true
categories: [iOS]
tags: [ios]
keywords: ios, screen, record, background, capture, non-jailbreak
description: 非越狱iOS系统在后台截屏、录制屏幕的几种方法，适用于iOS 7、iOS 8。iOS 9已经失效。
---

## 需求

先简单介绍一下标题的含义。也许你看到`iOS`、`截屏`，觉得这有什么好长篇大论的，小菜一碟而已。可能你忽略了`后台`这个关键词。

这里的关键就在于怎么在 App 切换到后台之后，仍然能够持续截取用户屏幕内容。解决了这点，剩下的就是把图片合成视频，有必要的话再加入声音。

另外，需要说明的是，实现后台截屏只能使用私有 API，而苹果是不允许这类 App 上架的，就算你用了一些技巧（比如动态加载私有 API 以绕过 App Store 的审核）而上架，假以时日苹果也会发现并且下架处理。[Display Recorder](http://stackoverflow.com/questions/11090184/how-does-the-ios-app-display-recorder-record-the-screen-without-using-private-ap) 就是这么做并且被下架的，所以现在它发到越狱市场了。

## 作用

在 iOS 上录制全局屏幕，保存成一个视频，这么一个小众需求到底有什么作用？虽然一般用户都不会用到，不过它还是有点用的：

* 录制 App 使用的视频教程（而不是图片+文字、图片+文字、图片+文字）；
* 如果 App 有个在某些用户机器上必现的 Bug，可以让他把操作记录下来，发给开发者（这样码农们就没办法再推脱：“在我这里是好的！肯定是你的打开方式不对！”）；
* 如果你是游戏大神，玩得一手好手游，还可以把你在游戏中的神操作保存下来供日后回味（或者分享出去让小白们膜拜）。

<!--more-->

## 实现

iOS 的系统封闭，API 变化无常，所以并没有一个可以全版本 iOS 系统通用的后台截屏方法。下面所列的方法都因系统版本而异，前提都是非越狱。

### 1. _UICreateScreenUIImage (< iOS 6)

[_UICreateScreenUIImage](http://iphonedevwiki.net/index.php/UIImage#UICreateScreenUIImage) 是 UIImage 的一个私有方法，在** iOS 6**以前可以用于后台调用截屏，方法如下：

``` objc
OBJC_EXTERN UIImage *_UICreateScreenUIImage(void);

- (void)takeScreenshot {
    UIImage *screenImage = _UICreateScreenUIImage();
    // ...
}
```

但是，在 iOS 6 以后，这个方法不允许在 App 切到后台的时候调用了，会在调试控制台输出不能调用的错误提示。

### 2. CARenderServerRenderDisplay (< iOS 7)

[RecordMyScreen](https://github.com/coolstar/RecordMyScreen) 用的就是这个方法，不过实测在 iOS 7以上，只能截到黑色的空白图片。网上说 RecordMyScreen 就是 Display Recorder 的开源版本。

其中涉及到后台截屏的代码如下：

``` objc
    IOSurfaceLock(_surface, 0, nil);
    // Take currently displayed image from the LCD
    CARenderServerRenderDisplay(0, CFSTR("LCD"), _surface, 0, 0);
    // Unlock the surface
    IOSurfaceUnlock(_surface, 0, 0);
    
    // Make a raw memory copy of the surface
    void *baseAddr = IOSurfaceGetBaseAddress(_surface);
    int totalBytes = _bytesPerRow * _height;
    NSMutableData *rawDataObj = [NSMutableData dataWithBytes:baseAddr length:totalBytes];
    // ...
```

但是，经过测试，在iOS 7和iOS 8上，这个方法没办法正确截屏，只能得到黑色的图片。而且，虽说 RecordMyScreen 是一个开源项目，但实际上它并不是一份完整可用的代码，开源到中途，作者发现有人在窃取他的项目源码，于是停止了开源。虽然如此，该项目中对于音视频的编码、合成部分的处理都是很值得参考的。

### 3. createScreenIOSurface(< iOS 7?)

[ScreenRecorder](https://github.com/kishikawakatsumi/ScreenRecorder) 用了这个方法，但是实际上这个项目没办法在后台运行。

``` objc

@interface UIWindow (ScreenRecorder)
+ (CFTypeRef)createScreenIOSurface;
@end

- (void)screenShot {
    CFTypeRef surface = [UIWindow createScreenIOSurface];
    backingData = surface;
                           
    NSDictionary *pixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    status = CVPixelBufferCreateWithIOSurface(NULL, surface, (__bridge CFDictionaryRef)(pixelBufferAttributes), &buffer);
    // ...
}
```

### 4. 终极方法 IOSurface (< iOS 9)

好吧，前面提到的几种方法在 iOS 7 以上版本都没啥卵用。现在说的这个方法是可以在 iOS 7 和 iOS 8 上使用的，只是 iOS 9 禁用了该方法。

与 RecordMyScreen 类似，还是基于 IOSurface 私有库，只是调用的方法不太一样：

``` objc
- (UIImage *)screenshot() {
    IOMobileFramebufferConnection connect;
    kern_return_t result;
CoreSurfaceBufferRef screenSurface = NULL;
    io_service_t framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleH1CLCD"));
if(!framebufferService)
        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleM2CLCD"));
if(!framebufferService)
        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleCLCD"));

result = IOMobileFramebufferOpen(framebufferService, mach_task_self(), 0, &connect);
result = IOMobileFramebufferGetLayerDefaultSurface(connect, 0, &screenSurface);

    uint32_t aseed;
    IOSurfaceLock((IOSurfaceRef)screenSurface, 0x00000001, &aseed);
    size_t width = IOSurfaceGetWidth((IOSurfaceRef)screenSurface);

    size_t height = IOSurfaceGetHeight((IOSurfaceRef)screenSurface);
    CFMutableDictionaryRef dict;
size_t pitch = width*4, size = width*height*4;

    int bPE=4;

    char pixelFormat[4] = {'A','R','G','B'};
    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(dict, kIOSurfaceIsGlobal, kCFBooleanTrue);
    CFDictionarySetValue(dict, kIOSurfaceBytesPerRow, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
    CFDictionarySetValue(dict, kIOSurfaceBytesPerElement, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bPE));
    CFDictionarySetValue(dict, kIOSurfaceWidth, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &width));
    CFDictionarySetValue(dict, kIOSurfaceHeight, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &height));
    CFDictionarySetValue(dict, kIOSurfacePixelFormat, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
    CFDictionarySetValue(dict, kIOSurfaceAllocSize, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &size));

    IOSurfaceRef destSurf = IOSurfaceCreate(dict);
    IOSurfaceAcceleratorRef outAcc;
    IOSurfaceAcceleratorCreate(NULL, 0, &outAcc);

    IOSurfaceAcceleratorTransferSurface(outAcc, (IOSurfaceRef)screenSurface, destSurf, dict, NULL);
    IOSurfaceUnlock((IOSurfaceRef)screenSurface, kIOSurfaceLockReadOnly, &aseed);
CFRelease(outAcc);

    CGDataProviderRef provider =  CGDataProviderCreateWithData(NULL,  IOSurfaceGetBaseAddress(destSurf), (width * height * 4), NULL);

    CGImageRef cgImage = CGImageCreate(width, height, 8,
8*4, IOSurfaceGetBytesPerRow(destSurf),
 CGColorSpaceCreateDeviceRGB(), kCGImageAlphaNoneSkipFirst |kCGBitmapByteOrder32Little, provider, NULL, YES, kCGRenderingIntentDefault);

    UIImage *image = [UIImage imageWithCGImage:cgImage];
    return image;
}
```

见：

* [IOMobileFramebufferGetLayerDefaultSurface does not work on ios7 retina](http://stackoverflow.com/questions/21870667/iomobileframebuffergetlayerdefaultsurface-does-not-work-on-ios7-retina)
* [IOMobileFramebufferGetLayerDefaultSurface not working on iOS 9](http://stackoverflow.com/questions/32239969/iomobileframebuffergetlayerdefaultsurface-not-working-on-ios-9)

## 合成

在 App 后台得到截图之后怎么处理成视频呢？其实在 RecordMyScreen 中有完整的代码可以参考，只是它里面截屏的方法需要替换为本文提到的`第四种`实现，不赘述。

## 注意

1. 需要修改 App 的 plist 文件，使其能在后台运行。
2. 需要打开设备的 Access Touch 功能，否则对于 OpenGL 实现的游戏 App，会黑屏。
3. iPad Retina 屏幕像素过大，处理起来很吃力，需要减小生成的图片大小。
