---
layout: post
title: "在程序运行时获取被调用的DLL的本地文件路径"
date: 2014-03-18 17:42:46 +0800
comments: true
categories: [C++]
tags: [C++, DLL]
keywords: DLL, GetModuleFileName, IMAGE_DOS_HEADER
description: 在程序运行时获取被调用的DLL文件路径
---

很多时候，DLL都是被别的进程所调用，所以在运行时，下面方法获取到的实际上是EXE所在的文件路径：

``` c++

	QCoreApplication::applicationFilePath();//Qt
```

但是我们实际上想要获得的是DLL本身的路径，因为运行的EXE与被调用的DLL不一定在同一个目录，比如，当把abc.dll注入到notepad.exe进程，很明显abc.dll是不在notepad所在的目录的。在dll代码中调用上述语句，返回的实际上是notepad的EXE路径。

那么，我们要获得abc.dll真实路径，有两个方法。

<!--more-->

####方法一：

在DLL的入口函数附近，声明以下变量，并定义函数：

``` c++

	EXTERN_C IMAGE_DOS_HEADER __ImageBase;	VOID CALLBACK abcAPCProc(ULONG_PTR dwParam)	{    	WCHAR path[MAX_PATH + 1] = {0};    	::GetModuleFileName((HINSTANCE)&__ImageBase, path, MAX_PATH);		//path就是当前dll的文件路径	}
```

然后，需要在导出函数里调用一下上面的函数：

``` c++

	extern "C" DWORD __declspec(dllexport) __stdcall showABC(void *)	{	    HANDLE hThread = NULL;	    DWORD dwRes = 0;	    hThread = ::OpenThread(THREAD_SET_CONTEXT,	        FALSE, getMainThreadId(0));	    DW_ASSERT(NULL != hThread);	    dwRes = ::QueueUserAPC(abcAPCProc, 	        hThread, 0);	    ::CloseHandle(hThread);	    hThread = NULL;	    return dwRes;	}
```

####方法二：

定义以下函数：

``` c++

	HMODULE GetCurrentModule()	{ // NB: XP+ solution!		HMODULE hModule = NULL;		GetModuleHandleEx(			GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,			(LPCTSTR)GetCurrentModule,			&hModule);			return hModule;	}
```

调用上面函数，获取当前局部，然后就可以使用`GetModuleFileName`方法获取DLL路径：

``` c++

	WCHAR path[MAX_PATH + 1] = {0};	HMODULE hm = GetCurrentModule();	::GetModuleFileName(hm, path, MAX_PATH);

```