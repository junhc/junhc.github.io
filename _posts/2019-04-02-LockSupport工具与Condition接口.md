---
layout: post
title: "LockSupport工具与Condition接口"
date: 2019-04-02 00:00:00
description: "LockSupport工具与Condition接口"
categories:
- java
permalink: /locksupport_and_condition
---


##### LockSupport工具

|方法名称|描述|
|:--:|:--|
|void park()|阻塞当前线程，如果调用uppark方法或者当前线程被中断，才能从park方法返回|
|void parkNanos(long nanos)|阻塞当前线程，最长不超过nanos纳秒，返回条件在park的基础上增加了超时返回|
|void parkUntil(long deadline)|阻塞当前线程，知道deadline时间|
|void unpark(Thread thread)|唤醒处于阻塞状态的线程thread|

##### Condition接口
