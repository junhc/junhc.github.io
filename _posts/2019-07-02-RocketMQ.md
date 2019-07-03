---
layout: post
title: "RocketMQ"
date: 2019-07-02 07:27:57
description: "RocketMQ"
categories:
- 消息队列
permalink: RocketMQ
---

##### 概念专业术语

* Producer
  > 消息生产者，负责产生消息，一般由业务系统负责产生消息。

* Consumer
  > 消息消费者，负责消费消息，一般是后台系统负责异步消费。

* Push Consumer
  > Consumer 的一种，应用通常向 Consumer 对象注册一个 Listener 接口，一旦收到消息，Consumer 对象立刻回调 Listener 接口方法。

* Pull Consumer
  > Consumer 的一种，应用通常主动调用 Consumer 的拉消息方法从 Broker 拉消息，主动权由应用控制。

* Producer Group
  > 一类 Producer 的集合名称，这类 Producer 通常发送一类消息，且发送逻辑一致。

* Consumer Group
  > 一类 Consumer 的集合名称，这类 Consumer 通常消费一类消息，且消费逻辑一致。

* Broker
  > 消息中转角色，负责存储消息，转发消息，一般也称为 Server。在 JMS 规范中称为 Provider。

##### 架构

![](/assets/img/RocketMQ架构图.jpg)  

* Producer
  > 生产者支持分布式部署。分布式生产者通过多种负载均衡模式向 Broker 集群发送消息。发送过程支持快速失败并具有低延迟。

* NameServer
  > 它提供轻量级服务发现和路由，每个 Name Server 记录完整的路由信息，提供相应的读写服务，支持快速存储扩展。  
  > 主要包括两个功能：  
  > 代理管理， NameServer 接受来自 Broker 集群的注册，并提供检测代理是否存在的心跳机制。  
  > 路由管理，每个 NameServer 将保存有关代理群集的全部路由信息以及客户端查询的队列信息。  

*   
