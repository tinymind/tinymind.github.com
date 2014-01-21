---
layout: post
title: "用Octopress在Github搭建博客，并绑定独立域名"
date: 2013-11-27 01:45:36 +0800
comments: true
categories: [Octopress]
tags: [octopress, github]
keywords: octopress, github
description: 使用Octopress搭建个人博客，发布到Github Pages免费空间，并绑定独立域名的步骤
---


11月中旬在Godaddy购买了一个域名，一直没派上用场，想到经常在各个个人博客找到各种问题的解决方案，于是决定先成立一个博客，记录并分享一些浮生小记、程序问题、解决方案，顺便在互联网上表示，“来过”。

这是第一篇博文，记录一下使用Octopress搭建博客，发布到Github Pages免费空间，并绑定个人域名的步骤。


##概述

###什么是Github Pages

[Github Pages](http://pages.github.com/) Github提供的一个免费空间，拥有一个独立的二级域名，允许开发者提交静态网页文件，用于介绍自己，或者自己的开源项目，可以看作是个人或项目主页。每个Pages有300M的存储空间，于是很多人就当作个人博客来发布博文。特点：

* 轻量级，配置简单
* 无需自己提供空间
* 使用标记语言，如Markdown
* 可以绑定独立域名

###什么是Octopress

从[Octopress主页](http://octopress.org/)上的标语“A blogging framework for hackers”就可以看出，这是一个比较Geek的博客系统，提供了一套自动化的工具和模板，帮助用户简便地创建一个博客。

Octopress生成的博客可以很方便地部署到Github Pages上，网上已有很多教程介绍怎么利用Octopress在Github上搭建博客。不过，由于生成的博客都是静态文件，所以也可以部署到任何一个服务器上。随着Wordpress越来越臃肿庞大，相对而言更加方便快捷的Octopress则日渐流行。特点：

* 以Ruby为运行环境，使用简单的命令生成静态页面
* 默认使用Markdown语法
* 可离线编写博文，方便备份、预览
* 可从Wordpress迁移过来


##安装

<!--more-->

###安装Git

以Mac系统为例，安装Git的方法有很多，这里只说两种：

1. 下载[git-osx-installer](https://code.google.com/p/git-osx-installer/)安装包，使用Gui安装。
2. 使用Homebrew的包管理工具，命令行安装。

前者无需多说，后者的命令如下：

``` sh
	$ sudo brew install git
```

安装后，运行下面命令查看是否成功：

``` sh
	$ which git	
```

应该得到/usr/bin/git，说明已成功安装git。

###安装Rvm和Ruby

安装Rvm：

``` sh
	curl -L https://get.rvm.io | bash -s stable --ruby
```

安装Ruby1.9.3(或更新版本)：

``` sh
	rvm install ruby-2.0.0-p353  && rvm use ruby-2.0.0-p353
	rvm rubygems latest
```

[官方文档](http://octopress.org/docs/setup/rvm/)建议安装1.9.3版本，不过我安装的是2.0.0，一样可用。

###安装Octopress
按官方文档[http://octopress.org/docs/setup/](http://octopress.org/docs/setup/)操作即可，下面简述步骤，及可能会出现的问题。

利用终端，或Finder在本地建立一个用于存放Octopress的文件夹，并在终端切换到该目录，然后按以下步骤操作。

1)从Github将源码clong下来：

``` sh
	git clone git://github.com/imathis/octopress.git octopress
	cd octopress
```

2)安装依赖：

``` sh
	gem install bundler
	rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
	bundle install
```

这里可能会很慢，因为国内访问官方的ruby更新源速度奇慢……解决方法是，修改gem更新源地址。输入以下命令：

``` sh
	gem sources -a http://ruby.taobao.org/
	gem sources -r http://rubygems.org/
	gem sources -l
```

然后更改Octopress目录下的`Gemfile`文件，将`source "http://rubygems.org/"` 改为 `source "http://ruby.taobao.org/"`，保存，再运行`2)安装依赖`的命令就一气呵成了。

3)安装默认主题

``` sh
	rake install
```

4)测试。
这时已经安装成功了，下面两天命令可以生成本地静态页面并在4000端口启动预览：

``` sh
	rake generate
	rake preview
```

打开浏览器输入[http://localhost:4000](http://localhost:4000)就可以看到预览页面了。


##部署
下面介绍怎么将本地博客发布到Github Pages上。

###创建Github Pages
####注册github账号

首先我们得注册一个github账号，如果不打算绑定独立域名的话，这个账号就是你github pages的域名，如：yourname.github.io，所以要考虑好账号名。注册地址：[https://github.com/join](https://github.com/join)

####创建git repository

注册后，创建一个名为yourname.github.com的代码仓库，yourname是你的帐号名，不要省略后面的`.github.com`。

####设置博客使用的git repository的路径

``` sh
	 $ rake setup_github_pages
	Enter the read/write url for your repository(For example, 'git@github.com:your_username/your_username.github.io.git) or 'https://github.com/your_username/your_username.github.io')
	$ Repository url: 
```

这里会提示让你输入刚才创建的代码仓库地址，请输入：`git@github.com:yourname/yourname.github.com.git`

这个步骤，rake会做以下事情：

1. 修改.git/config中的origin为你输入的repos，并把原来的origin写到Octopress中。
2. 创建source分支并切换到该分支。
3. 在生成的_deploy目录下初始化git repos
	
####设置SSH key

1)终端输入：
	 ssh-keygen -t rsa -C "yourname@mail.com" #输入你的注册邮箱
	
2)按照提示输入两次短语：

	Generating public/private rsa key pair.
	Enter file in which to save the key (/Users/name/.ssh/id_rsa): 
	Enter passphrase (empty for no passphrase): 
	Enter same passphrase again: 
	
回车后，会看到：

	Your public key has been saved in /Users/name/.ssh/id_rsa.pub.
	
3)打开id_ras.pub文件，复制里面的内容，等一下会用到。

4)登录github，在右上角用户名旁找到“设置”图标，点击进入设置页面进入`SSH Public Keys`，

5)点击右边的`Add another public key`

6)在Title输入名称，在Key粘贴刚才自己复制的公钥，点击`Add key`即可。

7)输入以下命令测试ssh：

``` sh
	ssh -T git@github.com
```

将会看到下面输出：

he authenticity of host 'github.com (192.30.252.128)' can't be established.
RSA key fingerprint is 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48.
Are you sure you want to continue connecting (yes/no)?

输入yes，回车，就会看到：

Hi yourname! You've successfully authenticated, but GitHub does not provide shell access.

8)设置个人信息

	$ git config --global user.name "yourname"
	$ git config --global user.email "yourname@mail.com"

创建好yourname.github.io项目之后，提交一个index.html文件，然后push到Github的master分支。第一次页面生效需要大概10分钟左右。生效之后，访问yourname.github.io就可以看到你上传的页面了。

###配置Octopress

####标题与副标题
打开_config.yml，按照注释，修改主页的配置。

如果需要每次更改后都重新生成，添加一行：

	auto: true
	
可以参考唐巧的博文《[象写程序一样写博客：搭建基于github的博客](http://blog.devtang.com/blog/2012/02/10/setup-blog-based-on-github/)》,删除Twitter相关的配置和会拖慢访问速度的Google字体。

####修改主题
比如，想要使用[darkstripes](https://github.com/amelandri/darkstripes)主题，切换到Octopress目录，使用如下命令：

``` sh
	$ git clone git://github.com/amelandri/darkstripes.git .themes/darkstripes
	$ rake install['darkstripes']
	$ rake generate
```

##撰写并发布博文

1)创建第一篇博文

这时候我们的部署已经完成，可以创建自己的第一篇博文了：

``` sh
	$ rake new_post["My first blog"]
```

这会在source/_posts下创建一个以时间和标题为名称的markdown文件，这就是创建的第一篇博文。

2)编辑文章

也就是修改source/_posts下的.markdown文件。可以使用自己喜欢的编辑器，比如Vim，或者Mou，和Sublime text2之类。

3)预览和发布
输入以下命令，访问[访问 http://localhost:4000](http://localhost:4000)查看预览。

``` sh
	$ rake preview
```

觉得没有问题之后，发布：

``` sh
	$ rake gen_deploy
```

这个命令会生成页面到_deploy并提交代码到repos，如果一切顺利，十分钟左右就可以在http://yourname.github.com 或http://yourname.github.io 访问你的博客主页了。

4)保存更改，提交source

``` sh
	$ git add .
	$ git commit -m "Source code of my blog"
	$ git push origin source
```

5)总结一下写博客的流程：

* rake new_post["Title"]，生成博文模板，修改生成的Markdown文件。
* rake generate，生成静态文件
* rake preview，在本机4000端口生成预览
* rake deploy，发布


##绑定域名

要想让username.github.io能通过你自己的域名来访问，需要在项目的根目录下新建一个名为CNAME的文件，文件内容形如：yourdomain.com
你也可以绑定在二级域名上：blog.yourdomain.com

``` sh
	$ echo 'blog.yourdomain.com' >> source/CNAME
```

然后在你的DNS服务商，添加相应的CNAME指向yourname.github.com。
如果你使用形如yourdomain.com这样的一级域名的话，需要在DNS处设置A记录到207.97.227.245（地址可以在[这里](https://help.github.com/articles/my-custom-domain-isn-t-working)查看），而不是在DNS处设置为CNAME的形式。设置成功后，等待生效即可。

详见：[http://octopress.org/docs/deploying/github/#custom_domains](http://octopress.org/docs/deploying/github/#custom_domains)


##第三方插件

###添加多说评论插件

首先我们需要有一个多说网的short_name，在后面的配置中需要用到。于是我们就得先注册一个多说网的账号。

####注册多说short_name

这里顺便吐槽一下多说网的交互。它不提供注册功能，只能绑定微博、豆瓣等现有账号，好吧，我绑定了微博，然后登录，发现坑爹了!

[官方文档](http://dev.duoshuo.com/threads/4ff28d95552860f21f000010)说`修改您的多说二级域名：（在多说后台设置中找到）`，但是我在设置页面转了一圈，根本没找到可以设置或者创建short_name的地方！！！找遍了各个可以点击的链接，硬是没发现什么后台管理、域名设置的地方。

无奈之下，用了万能的Google，然后找到了[这个博客](http://blog.puhao.me/%E5%90%90%E6%A7%BD/%E4%BD%BF%E7%94%A8%E5%A4%9A%E8%AF%B4/)，他也在吐槽不断地点击后，才找到了设置页面：[获取多说通用代码](http://duoshuo.com/create-site/)，按照要求设置即可，复制它生成的通用代码。

####添加多说模块到Octopress模板

1)在`source/_inludes/post/`下创建duoshuo.html:
粘贴生成的通用代码：

``` html
	<!-- Duoshuo Comment BEGIN -->
	<div class="ds-thread"></div>
	<script type="text/javascript">
	var duoshuoQuery = {short_name:"your_short_name"};
	(function() {
		var ds = document.createElement('script');
		ds.type = 'text/javascript';ds.async = true;
		ds.src = 'http://static.duoshuo.com/embed.js';
		ds.charset = 'UTF-8';
		(document.getElementsByTagName('head')[0] 
		|| document.getElementsByTagName('body')[0]).appendChild(ds);
	})();
	</script>
	<!-- Duoshuo Comment END -->
```
	
2)在`source/_layouts/post.html`，在disqus代码下方添加：

{% codeblock lang:html %}
    { % if site.duoshuo_short_name and site.duoshuo_comments == true and page.comments == true %}
	<section>
	<h1>Comments</h1>
    <div id="comments" aria-live="polite">{ % include post/duoshuo.html %}</div>
    </section>
    { % endif %}
{% endcodeblock %}

3)修改`source/_includes/article.html`文件，在disqus代码下方添加：

``` html
	{ % if site.duoshuo_short_name and page.comments != false and post.comments != false and site.duoshuo_comments == true %}| <a href="{ % if index % }{{ root_url }}{{ post.url }}{ % endif %}#comments">Comments</a>
	{ % endif %}
```

4)在`_config.yml`中添加：
	
	# duoshuo comments
	duoshuo_comments: true
	duoshuo_short_name: yourname
	
这时候应该就成功添加多说模块了。

####首页侧边栏显示最新评论

1)在`_config.yml`中插入如下代码

	duoshuo_asides_num: 10      # 侧边栏评论显示条目数
	duoshuo_asides_avatars: 0   # 侧边栏评论是否显示头像
	duoshuo_asides_time: 1      # 侧边栏评论是否显示时间
	duoshuo_asides_title: 1     # 侧边栏评论是否显示标题
	duoshuo_asides_admin: 0     # 侧边栏评论是否显示作者评论
	duoshuo_asides_length: 20   # 侧边栏评论截取的长度

2)再创建`source/_includes/custom/asides/recent_comments.html`:

``` html
	<section>
	<h1>最近评论</h1>
	<ul class="ds-recent-comments" data-num-items="{{ site.duoshuo_asides_num }}" data-show-avatars="{{ site.duoshuo_asides_avatars }}" data-show-time="{{ site.duoshuo_asides_time }}" data-show-title="{{ site.duoshuo_asides_title }}" data-show-admin="{{ site.duoshuo_asides_admin }}" data-excerpt-length="{{ site.duoshuo_asides_length }}">
	</ul>
	<!--多说js加载开始，一个页面只需要加载一次 -->
	<script type="text/javascript">
	var duoshuoQuery = {short_name:"your_duoshuo_name"};
	(function() {
	var ds = document.createElement('script');
	ds.type = 'text/javascript';
	ds.async = true;ds.src = 'http://static.duoshuo.com/embed.js';
	ds.charset = 'UTF-8';
	(document.getElementsByTagName('head')[0] || document.getElementsByTagName('body') [0]).appendChild(ds);
	})();
	</script>
	<!--多说js加载结束，一个页面只需要加载一次 -->
	</section>
```

3)打开`_config.yml`将custom/asides/recent_comments.html添加到`default_asides`:

    [custom/asides/recent_comments.html]

####给网站添加访问分析 Google Analytics

1)到[Google Analytics](https://www.google.com/analytics)注册GA账户，登记网站名字、地址，获得自己的Track ID，格式如：US-1234XXXX-X

**注册GA的网址应与你在`_config.yml`中url的设置一致。**

2)修改`_config.xml`，将ID写到`google_analytics_tracking_id:`后。

3)`rake deploy`。然后就可以到Google Analytics看报告了。

####添加About Me到侧边栏

1)修改`source/_includes/custom/asides`里面的`about.html`，内容如下：

``` html
    <section>
    <h1>About Me</h1>
    <p>Your Introduce</p>
    </section>
```

2)修改`_config.yml`，在`default_asides`加入`custom/asides/about.html`

##参考

1. Mac下的Markdown文件编辑器: [Mou](http://mouapp.com)
2. 唐巧的博客: [象写程序一样写博客：搭建基于github的博客](http://blog.devtang.com/blog/2012/02/10/setup-blog-based-on-github/)
3. 觅珠人: [第一篇博文：用Octopress搭建博客系统](http://tchen.me/posts/2012-12-16-first-blog.html)
4. 破船之家: [你好！github页面](http://beyondvincent.com/blog/2013/07/27/107-hello-page-of-github/)
5. opoo.org: [Octopress 博客系统 —— a Blogging Framework for Hackers](http://opoo.org/octopress/)
6. Ocotpress: [Octopress Documentation](http://octopress.org/docs/)
7. Havee's Space: [为 Octopress 添加多说评论系统](http://havee.me/internet/2013-02/add-duoshuo-commemt-system-into-octopress.html)
8. colors4.us: [Octopress博客从零开始 III](http://colors4.us/blog/2012/01/08/octopressbo-ke-cong-ling-kai-shi-iii/)

(全文完)
