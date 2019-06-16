---
layout: post
title: "删除hosts配置中localhost引发的 Unable to import maven project: See logs for details 错误"
date: 2015-08-21 16:40:12
description: ""
categories:
- 其他
permalink: error-hosts-no-localhost
---
##### 缘起
> 有一次清理hosts文件, 觉得`localhost`相关的配置没什么用, 就给删除了.
> 结果在idea中导入maven项目时, 一直提示: Unable to import maven project: See logs for details 错误.

```vim
# 系统配置, 请勿乱删
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
```

##### 解决过程
- 在idea的Help菜单下, 点击Show Log in Finder, 打开日志发现如下错误  

```vim
Caused by: java.rmi.RemoteException: Cannot start maven service; nested exception is:
	java.rmi.ConnectIOException: Exception creating connection to: localhost; nested exception is:
	java.net.SocketException: Permission denied (connect failed)
  ...
Caused by: java.rmi.ConnectIOException: Exception creating connection to: localhost; nested exception is:
	java.net.SocketException: Permission denied (connect failed)
  ...
Caused by: java.net.SocketException: Permission denied (connect failed)
  ...
```
- 连不上localhost, 第一反应就是想起自己删除掉了, 于是又给加回去了, 然后问题解决了.
