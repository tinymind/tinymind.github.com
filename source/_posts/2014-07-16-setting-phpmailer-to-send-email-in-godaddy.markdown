---
layout: post
title: "在Godaddy上使用PHPMailer通过SMTP发送邮件的方法"
date: 2014-07-16 13:51:29 +0800
comments: true
categories: [PHP, Godaddy]
tags: [php, phpmailer, godaddy]
keywords: php, phpmailer, godaddy, smtp, email
description: 在Godaddy上使用PHPMailer通过SMTP发送邮件的方法
---

对于个人站点的“留言”、“评论”功能，除了把用户的发言保存到MySQL数据库中以外，管理员往往还希望在用户留言的同时发送一封邮件到指定邮箱，方便查看。

这个功能用PHP+MySQL实现很简单，PHP语言有一个mail()方法，只需配置好SMTP服务器、发件人的邮箱密码、收件人的邮箱，就可以自动发送邮件。

但是，mail()方法过于简洁，需要用户作很多其他配置，比如在php.ini里设置stmp服务器地址、端口等信息，同时使用也不太方便，比如没法便捷地使用抄送、添加附件等功能。

于是有了[PHPMailer](http://phpmailer.worxware.com)，简化了发送邮件的配置。

<!--more-->

使用PHPMailer发送邮件的代码如下：

``` php

	<?php
	require 'PHPMailerAutoload.php';
	
	$mail = new PHPMailer;
	
	$mail->isSMTP();
	$mail->Host = 'smtp1.example.com;smtp2.example.com';
	$mail->SMTPAuth = true;
	$mail->Username = 'user@example.com';
	$mail->Password = 'secret';
	
	$mail->From = 'from@example.com';
	$mail->FromName = 'Mailer';
	$mail->addAddress('joe@example.net', 'Joe User');
	$mail->WordWrap = 50;
	$mail->isHTML(true);
	$mail->Subject = 'Here is the subject';
	$mail->Body    = 'This is the HTML message body <b>in bold!</b>';
	if(!$mail->send()) {
	    echo 'Message could not be sent.';
	    echo 'Mailer Error: ' . $mail->ErrorInfo;
	} else {
	    echo 'Message has been sent';
	}

```

以上代码在本地服务器测试一切正常，但是上传到Godaddy空间后，发送邮件时会提示失败，因为Godaddy限制了用户利用第三方的SMTP服务器发送邮件。

解决方法有两个：

1. 使用Godaddy提供的免费邮箱转发
2. 使用Godaddy提供的公共SMTP转发

###方法1，使用Godaddy提供的邮箱账号

购买了Godaddy的空间之后，会给用户提供企业Email，后缀名是自己的域名，免费账号可以有100个。我们需要在上面创建一个Email账号。比如：user@test.com, helloworld。见[这里](http://support.godaddy.com/help/article/3552/managing-your-email-account-smtp-relays)。

完成后，查看相应账号的`Tools - Server Settings`，会列出该邮箱使用的smtp host和端口，host一般都是`smtpout.secureserver.net`，端口则有：`25, 80, 3535`。可以参考[Godaddy的帮助]()。

有了上述信息之后，调整PHPMailer配置如下：

``` php

	$mail->Host = 'smtpout.secureserver.net';
	$mail->Port = 80;
	$mail->SMTPAuth = true;
	$mail->Username = 'user@test';
	$mail->Password = 'helloworld';

```

这时候再发送，就不会提示`SMTP -> ERROR: Failed to connect to server: Connection refused (111)`之类的错误了。

###方法2，使用Godaddy提供的公共SMTP服务器

[这里](http://www.freehao123.com/godaddy-smtp/)提到了另一种免邮箱账号密码发送邮件的方法，就是利用Godaddy提供的公共SMTP服务器。

代码如下：

``` php

	$mail->Host = 'relay-hosting.secureserver.net';
	$mail->Port = 25;
	$mail->SMTPAuth = false;
	$mail->Username = '';	//blank
	$mail->Password = '';	//blank

```

(完)
