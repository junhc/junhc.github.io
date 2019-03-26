---
layout: post
title: "Java中的阻塞队列"
date: 2019-03-16 23:45:50
description: "Java中的阻塞队列"
categories:
- Java
- 并发编程
permalink: blocking-queue
---

##### 什么是阻塞队列
> 阻塞队列(`BlockingQueue`)是一个支持两个附加操作的队列。  
> 1) 支持阻塞的插入方法：意思是当队列满时，队列会阻塞插入元素的线程，直到队列不满。    
> 2) 支持阻塞的移除方法：意思是当队列为空时，获取元素的线程会等待队列变为非空。  

##### ArrayBlockingQueue
> `ArrayBlockingQueue`是一个用数组实现的有界阻塞队列。此队列按照先进先出(`FIFO`)的原则对元素进行排序。

##### LinkedBlockingQueue
> `LinkedBlockingQueue`是一个用链表实现的有界阻塞队列。此队列的默认和最大长度为`Integer.MAX_VALUE`。  
此队列按照先进先出(`FIFO`)的原则对元素进行排序。

##### PriorityBlockingQueue
> `PriorityBlockingQueue`是一个支持优先级的无界阻塞队列。默认情况下元素采取自然顺序升序排列。  
也可以自定义类实现`compareTo()`方法来指定元素排序规则，或者初始化`PriorityBlockingQueue`时，  
指定构造参数`Comparator`来对元素进行排序。需要注意的是不能保证同优先级元素的排序。

##### DelayQueue
> `DelayQueue`是一个支持延时获取元素的无界阻塞队列。队列使用`PriorityQueue`来实现。  
队列中的元素必须实现`Delayed`接口，在创建元素时可以指定多久才能从队列中获取当前元素。  
只用延迟期满时才能从队列中提取元素。  
> `DelayQueue`非常有用，可以将`DelayQueue`运用以下应用场景。  
> 1) 缓存系统的设计：可以用`DelayQueue`保存缓存元素的有效期，使用一个线程循环查询`DelayQueue`，  
一旦能从`DelayQueue`中获取元素时，表示缓存有效期到了。  
> 2) 定时任务调度：使用`DelayQueue`保存当天将会执行的任务和执行时间，一旦从`DelayQueue`中获取到任务就开始执行，  
比如`TimerQueue`就是使用`DelayQueue`实现的。

##### SynchronousQueue
> `SynchronousQueue`是一个不存储元素的阻塞队列。每一个put操作必须等待一个take操作，否则不能继续添加元素。  
它支持公平访问队列。默认情况下线程采用非公平性策略访问队列。

##### LinkedTransferQueue
> `LinkedTransferQueue`是一个由链表结构组成的无界阻塞TransferQueue队列。

##### LinkedBlockingDeque
> `LinkedBlockingDeque`是一个由链表结构组成的双向阻塞队列。