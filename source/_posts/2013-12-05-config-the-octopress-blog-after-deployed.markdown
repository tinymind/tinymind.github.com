---
layout: post
title: "Octopress博客发布后的基本配置、继续阅读、自动打开、代码高亮、插入图片、分类标签、修改样式"
date: 2013-12-05 02:41
comments: true
categories: [Octopress]
tags: [octopress]
---

##基本配置

修改_config.yml，格式为：`配置项: + 空格 + 参数`，空格不能少。

###标题、副标题、作者、侧边栏等

编辑`_config.yml`，修改`url: `、`title`、`sub_title`、`author`, `default_asides`的对应参数。

###修改日期格式

编辑`_config.yml`的`date_format`，格式定义见[这里](http://www.ruby-doc.org/core-1.9.2/Time.html#method-i-strftime)

如想显示为：`2013-12-02, Mon`，则改为：

    date_format: "%F, %a"

##继续阅读

如果正文太长，不希望在首页直接显示完整内容，可以在适当的位置加上一句`<!--more-->`，后面的内容就会被按钮`Read on→`所替代，点击继续阅读。

<!--more-->

##运行命令后自动打开文件、预览

修改`Rakefile`，运行指定命令后打开文件编辑，或者打开浏览器预览。见[博客：基于 Octopress－ 配置篇（Mac，Xcode 4.3.1，Ruby 1.9.3）](http://imwuyu.me/talk-about/configuring-octopress.html/)

###new_post后自动打开对应的markdown文件

在`Rakefile`中定义：

``` ruby
	editor = "vi"
```

然后在new_post命令后面添加：

``` ruby
  if #{editor}
    system "#{editor} #{filename}"
  end
```

###preview之后自动调用浏览器打开预览页面

在preview命令后面添加：

``` ruby
  system "sleep 2; open http://localhost:#{server_port}/"
```

##代码高亮

作为一个面向黑客的博客系统，如果不支持代码高亮就说不过去了。Octopress默认使用[pygment](http://pygments.org/)这个语法高亮插件。

Mac/Linux应该已经包含了该模块。

如果是Windows，需要安装Python，并且使用easy_install安装pygments模块。

1. 安装Python；
2. 安装[easy_install](https://pypi.python.org/pypi/setuptools)；
3. 添加%Python%\Scripts到环境变量，%Python%是Python的安装目录；
4. 安装pygements：`easy_install pygments`

在Markdown源文件里，插入代码有多种方法，这里只介绍简单的三种。

1.四个空格缩进

对于四个空格开头的语句，Markdown输出到html时会自动用`<pre>`和`<code>`标签包起来，当作代码块显示。需要注意的是，代码块前面必须要有一行空行。不过这样是不会有关键字高亮的，只是背景是代码高亮的背景而已。如下：

	std::string hi("Hello world!");

2.前后用三个反引号“```”包含

反引号设定代码高亮比较简单灵活，可以指定代码标题、语言、链接等等。格式如下：

    ``` [language] [title] [url] [link text]
     Hello world
    ```
高亮效果：

``` c++
    Hello world
```

3.codeblock代码块

这个效果与三个反引号的效果类似，只是写法不如反引号简便。格式如下：

    { % codeblock [title] [lang:language] [url] [link text] %}
    code snippet
    { % endcodeblock %}
    
高亮效果：

{% codeblock HelloWorld.js lang:javascript %}
    alert('Hello world!')
{% endcodeblock %}

Octopress还支持引用Github上的gist，见[官方文档](http://octopress.org/docs/blogging/code/)。

##插入图片

将图片放到`octopress/source/images/`下，然后在Markdown文件中直接引用即可。也可以直接引用网络上的图片。

为了方便管理，可以在images下对自己添加的图片建立目录区分，比如：`images/2013/12`。

语法与插入超链接类似：

    ![Alt text](/path/to/img.jpg)

    ![Alt text](/path/to/img.jpg "Optional title")
    
* 半角叹号
* 半角方括号，里面放图片的替代文字
* 半角圆括号，里面放图片的网址，后面可选地加上文字。

##添加分类

此节参考了这篇文章：[为octopress添加分类(category)列表](http://codemacro.com/2012/07/18/add-category-list-to-octopress/)

`rake new_post`生成的markdown文件中包含了`categories: `，在后面加上`[分类名]`就可以指定该文章的分类。下面说的是怎么使得分类能在博客侧边栏显示。

###添加category_list插件，保存下面的代码到`octopress/plugins/category_list_tag.rb`:

``` ruby category_list_tag.rb
module Jekyll
  class CategoryListTag < Liquid::Tag
    def render(context)
      html = ""
      categories = context.registers[:site].categories.keys
      categories.sort.each do |category|
        posts_in_category = context.registers[:site].categories[category].size
        category_dir = context.registers[:site].config['category_dir']
        category_url = File.join(category_dir, category.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase)
        html << "<li class='category'><a href='/#{category_url}/'>#{category} (#{posts_in_category})</a></li>\n"
      end
      html
    end
  end
end

Liquid::Template.register_tag('category_list', Jekyll::CategoryListTag)
```

###增加到侧边栏

保存以下代码到`source/_includes/custom/asides/category_list.html`

``` html category_list.html
<section>
  <h1>Categories</h1>
  <ul id="categories">
    { % category_list %}
  </ul>
</section>
```

###修改`_config.yml`的`default_asides`

``` xml
default_asides: [custom/asides/category_list.html]
```

##添加标签

见[为octopress添加tag Cloud](http://codemacro.com/2012/07/18/add-tag-to-octopress/)

##修改样式

见[Octopress主题样式修改](http://812lcl.github.io/blog/2013/10/27/octopresszhu-ti-yang-shi-xiu-gai/)

##让搜索引擎收录你的博客

有了自己的博客，当然希望博文的内容能被大家搜索到。但是刚开始，搜索引擎不一定抓取了你的博客，想要尽快让引擎收录，直接提交你的博客网址到各大搜索引擎即可。然后等待网络蜘蛛抓取吧，生效时间不定的。

* 百度：http://zhanzhang.baidu.com/sitesubmit/index
* 谷歌：https://www.google.com/webmasters/tools/submit-url?pli=1

##可能遇到的问题

* `rake preview`后看不到最新效果。解决方法：检查一下Markdown文件是不是有无法解析的语句。最容易发生的是，引用了代码片段，但是使用了pygement无法解析的语言；又或者代码片段内部含有代码高亮的关键字，如`{ %`。
* 侧边栏布局混乱，跑到博客底部。也是代码解析出错引起的，同上。定位出问题的代码很简单，用二分法剪切markdown文件，保存，查看预览，看看是不是还有问题，逐步缩小范围就可以看出是哪一句引起的了。
