---
layout: post
title: "使用Swift语言在iOS客户端生成七牛的上传Token"
date: 2015-12-29 14:14:01 +0800
comments: true
categories: [Swift, iOS]
tags: [swift, ios, qiniu]
keywords: Swift, iOS, 七牛, SDK, Token
description: 七牛SDK官方不推荐由客户端生成Token，所以在SDK的源码以及Demo中都没有提供生成上传Token的接口与示例。但是有时候的确需要在客户端生成Token，因为个人用户哪里有那么多服务器啊……本文提供了Swift语言版本在iOS客户端生成七牛上传Token的示例代码。
---

七牛SDK官方不推荐由客户端生成Token，所以在SDK的源码以及Demo中都没有提供生成上传Token的接口与示例。但是有时候的确需要在客户端生成Token，因为个人用户哪里有那么多服务器啊……本文提供了Swift语言版本在iOS客户端生成七牛上传Token的示例代码。

<!--more-->

## Token 的生成算法

详见 [官方说明](http://developer.qiniu.com/docs/v6/api/reference/security/upload-token.html)。概述如下：

1. 构造[上传策略](http://developer.qiniu.com/docs/v6/api/reference/security/put-policy.html)，转为 JSON 字符串，进行 [URL安全的Base64编码](http://developer.qiniu.com/docs/v6/api/overview/appendix.html#urlsafe-base64)，得到 `encodedPutPolicy `。
2. 使用 `SecretKey` 对上一步生成的 `encodedPutPolicy ` 计算 [HMAC-SHA1](http://en.wikipedia.org/wiki/Hash-based_message_authentication_code) 签名，进行URL安全的Base64编码，得到 `encodedSign`。
3. 将 `AccessKey`、`encodedSign` 和 `encodedPutPolicy` 用`:`连接起来，得到Token

## Swift 示例代码

### 修改 Podfile 文件添加七牛依赖库

``` bash
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

inhibit_all_warnings!

pod 'JSONKit-NoWarning', '1.2'
pod 'AFNetworking', '2.5.0'
pod 'Qiniu', '~> 7.0'
```

### 在 .swift 文件上方，引入库，定义钥匙串

``` objc
import Qiniu
import JSONKit_NoWarning

let kQiniuBucket = "qiniubucket"
let kQiniuAccessKey = "xxxxxxxxxxxxxxxxxxxxxx--xxxxxxxxxxxxxxxx"
let kQiniuSecretKey = "xxxxxxxxxxxxxxxxxxxxxx--xxxxxxxxxxxxxxxx"
```

### 定义辅助方法

``` objc
    func hmacsha1WithString(str: String, secretKey: String) -> NSData {
    
        let cKey  = secretKey.cStringUsingEncoding(NSASCIIStringEncoding)
        let cData = str.cStringUsingEncoding(NSASCIIStringEncoding)
        
        var result = [CUnsignedChar](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData: NSData = NSData(bytes: result, length: (Int(CC_SHA1_DIGEST_LENGTH)))
        return hmacData
    }
```

其中，`CCHmac ` 使用的是 Objective C 的 `#import <CommonCrypto/CommonCrypto.h>`，在 Swift 中用需要自己添加桥接头文件。

### 定义生成 Token 方法

``` objc
    func createQiniuToken(fileName: String) -> String {
        
        let oneHourLater = NSDate().timeIntervalSince1970 + 3600
        // 上传策略中，只有scope和deadline是必填的
        let scope = fileName.isEmpty ? kQiniuBucket : kQiniuBucket + ":" + fileName;
        let putPolicy: NSDictionary = ["scope": scope, "deadline": NSNumber(unsignedLongLong: UInt64(oneHourLater))]
        let encodedPutPolicy = QNUrlSafeBase64.encodeString(putPolicy.JSONString())
        let sign = self.hmacsha1WithString(encodedPutPolicy, secretKey: kQiniuSecretKey)
        let encodedSign = QNUrlSafeBase64.encodeData(sign)
        
        return kQiniuAccessKey + ":" + encodedSign + ":" + encodedPutPolicy
    }
```

### 上传示例

``` objc
    func uploadWithName(fileName: String, content: String) {
        let dict: NSDictionary = ["content": content]
        // 如果覆盖已有的文件，则指定文件名。否则如果同名文件已存在，会上传失败
        let token = self.qiniuToken(self.replaceIfExists ? fileName : "")
        
        var uploader: QNUploadManager = QNUploadManager()
        uploader.putData(dict.JSONData(), key: fileName, token: token, complete: { (info: QNResponseInfo!, key: String!, resp: [NSObject : AnyObject]!) -> Void in
                if info.ok {
                    NSLog("Success")
                } else {
                    NSLog("Error: " + info.error.description)
                }
            }, option: nil)
    }
```


