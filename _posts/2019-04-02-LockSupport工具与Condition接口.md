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

任意一个Java对象，都拥有一组监视器方法（定义在java.lang.Object上），主要包括wait()、wait(long timeout)、notify()以及notifyAll()方法，这些方法与synchronized同步关键字配合，可以实现等待/通知模式。Condition接口也提供了类似Object的监视器方法，与Lock配合可以实现等待/通知模式，但是这两者在使用方式以及功能特性上还是有差别的。

|对比项|Object Monitor Methods|Condition|
|:--:|:--|:--|
|前置条件|获取对象的锁|1.调用Lock.lock()获取  2.调用Lock.newCondition()获取Condition对象|
|调用方式|直接调用，如:object.wait()|直接调用，如:condition.await()|
|等待队列个数|一个|多个|
|当前线程释放锁并进入等待状态|支持|支持|
|当前线程释放锁并进入等待状态，在等待状态中不响应终端|不支持|支持|
|当前线程释放锁并进入超时等待状态|支持|支持|
|当前线程释放锁并进入等待状态到将来的某个时间|不支持|支持|
|唤醒等待队列中的一个线程|支持|支持|
|唤醒等待队列中的全部线程|支持|支持|

```vim
public class ConditionObject implements Condition, java.io.Serializable {
       private static final long serialVersionUID = 1173984872572414699L;
       /** First node of condition queue. */
       private transient Node firstWaiter;
       /** Last node of condition queue. */
       private transient Node lastWaiter;

       ...
}       
```
