---
layout: post
title: "在C++中使用七牛C-SDK，给QINIU_ACCESS_KEY和QINIU_SECRET_KEY赋值失败的解决方法"
date: 2014-04-01 10:14
comments: true
categories: [C++]
tags: [c++, dll, qiniu]
keywords: C++, Qiniu, 七牛, uptoken
description: 在C++中使用七牛C-SDK，避免给QINIU_ACCESS_KEY和QINIU_SECRET_KEY赋值失败，自己生成uptoken的方法
---

七牛云存储为广大开发者提供了数据云存储的免费使用空间，对于个人开发来说完全足够了。并且提供了各种语言的SDK，方便开发。

在C++工程中使用C-SDK的时候，遇到了一个问题，下面语句在运行时，提示：`0x00401005 处未处理的异常: 0xC0000005: 写入位置 0x0040ab42 时发生访问冲突`

```cpp

extern "C"
{
#include "qiniu/conf.h"
#include "qiniu/rs.h"
#include "qiniu/io.h"
}

void Class::_initQiniu()
{
    QINIU_ACCESS_KEY = "my-akey";
    QINIU_SECRET_KEY = "my-sKey";
}
```
以上语句是官方文档给出的例子代码，但是我用了各种方法，都无法赋值成功，绝望……

在网上找有没有人遇到类似的问题的时候，看到了这篇问答：[七牛C-SDK中，QINIU_ACCESS_KEY和QINIU_SECRET_KEY应该怎么赋值？](http://segmentfault.com/q/1010000000450707)，虽然没有给出解决方案，但是至少可以知道，七牛官方提供的C-SDK由于没有在`qiniu.def`的导出变量后面加上`DATA`关键字，导致无法在别的C++工程中直接修改变量值。  
在回答中还看到，原来七牛还有一个[Cpp-SDK](https://github.com/qiniu/cpp-sdk/)，尝试下载，发现有28M，没有了继续使用的欲望。

那就继续折腾C-SDK吧。既然官方提供的C-SDK无法直接修改`QINIU_ACCESS_KEY` 和 `QINIU_SECRET_KEY`，在不重现编译DLL和Lib的情况下（Windows下编译不方便，还得配置各种cURL和OpenSSL的头文件路径），解决方法如下：  
**不直接给那两个变量赋值，而是自己参考源码写生成uptoken的方法。**
<!--more-->

```cpp
#include "cJSON.h"
#include "http.h"
//......
char* uptoken(const char* bucket)
{
	int expires = 3600; // 1小时;
	time_t deadline;
	char* authstr;
	char* token;

	cJSON* root = cJSON_CreateObject();

	cJSON_AddStringToObject(root, "scope", bucket);
	time(&deadline);
	deadline += expires;
	cJSON_AddNumberToObject(root, "deadline", deadline);

	authstr = cJSON_PrintUnformatted(root);
	cJSON_Delete(root);
        
	Qiniu_Auth mac;
	mac.accessKey = KYourQiniuAccessKey;//将两个Key赋值到mac
	mac.secretKey = KYourQiniuSecretKey;
	token = Qiniu_Mac_SignToken(&mac, authstr);//当mac不为空，七牛就不会访问QINIU_ACCESS_KEY和QINIU_SECRET_KEY
	Qiniu_Free(authstr);//这里会出现堆冲突=_=#

	return token;
}
```