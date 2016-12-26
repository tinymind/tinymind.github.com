---
layout: post
title: "iOS App 本地化的自动翻译脚本"
date: 2016-12-26 18:00:03 +0800
comments: true
categories: [Python]
tags: [ios, python]
keywords: iOS, App, strings, translate, multi-language
description: 利用百度翻译 API，把 iOS App 的语言文件 xx.strings 翻译成多国语言。
---

写 App 的激情与动力，往往在于核心功能的实现，至于那些 UI 细节的微调、多国家的语言文件，岂是尔等大牛需要做的事？

但是，一款出色的产品，往往不只有出色的核心功能，它的产品细节、用户体验也是趋于完善近乎完美的。大牛的你，虽然不想干这些脏活累活，然而，牛在江湖身不由己，你有三个选择：

1. 咬咬牙，自己上。
2. 招个临时工 or 实习生，让他干。
3. 写个脚本，自动完成。

现在要说的 App 本地化，就是一个典型的又粗又脏又累的活：

1. 没有任何技术含量。
2. 需要大量重复劳动。
3. 每个 App 都需要做一遍。

身为一名程序员，看到上述三个烦死人的特征，除了累觉不爱之外，还有没有别的什么想法呢？

<!--more-->

利用脚本自动完成啊！脚本天生就是干这些事的。

脚本已经写好了：[AppStringsTranslator](https://github.com/tinymind/AppStringsTranslator)

### 原理

1. 扫描 App 的 `xx.strings` 文件，遍历每一行。
2. 如果该行格式为 `"xx" = "xxx";`，则把等号左右的`key` 和 `value`提取出来，保存到 `keys` 和 `values` 两个数组中。
3. 如果该行不是 key/value 格式，则把整行加到 `keys`，而往 `values` 里加一个空字符串。
4. 利用百度翻译的 API，翻译 `values` 里的每个元素。
5. 把 `keys` 和翻译结果按照同样的格式写入到新的 `xx_toLang.strings` 文件。

第 3 步的目的是，保留原来的语言文件里的注释和空行。

### 用法

1. 修改 `AppStringsTranslator.py`，填上你自己的百度 `AppKey/SecretKey`，见[这里](http://api.fanyi.baidu.com/api/trans/product/desktop?req=developer)。
2. 在终端执行脚本，eg: `python AppStringsTranslator.py`。
3. 输入语言文件名称，eg: `Localizable.strings`。
4. 输入源文件的语言简写，eg: `zh`。
5. 输入需要翻译成的语言列表，以空格区分。eg: `en cht jp kor`。
6. 等待完成。

``` bash
>> LSiMac:AppStringsTranslator $ python AppStringsTranslator.py
>> Enter a fileName: Localizable.strings
>> Supports languages:
['auto', 'zh', 'en', 'yue', 'wyw', 'jp', 'kor', 'fra', 'spa', 'th', 'ara', 'ru', 'pt', 'de', 'it', 'el', 'nl', 'pl', 'bul', 'est', 'dan', 'fin', 'cs', 'rom', 'slo', 'swe', 'hu', 'cht', 'vie']
>> Enter from language: zh
>> Enter to language list, split by space: cht en jp kor
>> Start
Translating cht to fileName: Localizable_cht.strings
Finished translating to cht
Translating en to fileName: Localizable_en.strings
Finished translating to en
Translating jp to fileName: Localizable_jp.strings
Finished translating to jp
Translating kor to fileName: Localizable_kor.strings
Finished translating to kor
All done!

```

### 支持的语言

``` bash
语言简写               名称
auto                自动检测(可以作为源语言，但不能是目标语言)
zh                  中文
en                  英语
yue                 粤语
wyw                 文言文
jp                  日语
kor                 韩语
fra                 法语
spa                 西班牙语
th                  泰语
ara                 阿拉伯语
ru                  俄语
pt                  葡萄牙语
de                  德语
it                  意大利语
el                  希腊语
nl                  荷兰语
pl                  波兰语
bul                 保加利亚语
est                 爱沙尼亚语
dan                 丹麦语
fin                 芬兰语
cs                  捷克语
rom                 罗马尼亚语
slo                 斯洛文尼亚语
swe                 瑞典语
hu                  匈牙利语
cht                 繁体中文
vie                 越南语
```

### 无法脚本化的情况

有时候，我们会在语言文件里添加一些特殊的字符，比如 `%@ %d %lld` 之类的格式化占位符，这些字符是不需要被翻译的。但是利用脚本，是没有办法智能识别哪些字符需要保留，以及保留到哪里的，这种情况还是需要开发者自己去处理。

### 参考和说明

1. [百度翻译 API](http://api.fanyi.baidu.com/api/trans/product/apidoc)
2. 百度翻译不是完全免费的，不过每个月有一定的免费调用次数，还是完全可以满足 App 开发这种小数据量的。
3. 可以修改脚本，改变翻译后的文件存放方式。