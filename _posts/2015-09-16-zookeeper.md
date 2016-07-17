---
layout: post
title: "ZooKeeper"
date: 2015-09-16 18:56:17
description: "ZooKeeper"
categories:
- zookeeper
permalink: zookeeper
---

#### Maven依赖写法
```xml
<dependency>
    <groupId>org.apache.zookeeper</groupId>
    <artifactId>zookeeper</artifactId>
    <version>3.4.6</version>
</dependency>

<dependency>
    <groupId>com.101tec</groupId>
    <artifactId>zkclient</artifactId>
    <version>0.1.0</version>
</dependency>
```

#### 客户端脚本

```vim
#启动客户端
sh zkCli.sh
#指定ZooKeeper服务器地址
sh zkCli.sh -server ip:port

#创建
create [-s] [-e] path data acl
#其中，-s或-e分别指定节点特性：顺序或临时节点。缺省情况下，创建的是持久节点。
#最后一个参数是acl，它是用来进行权限控制的，缺省情况下，不做任何权限控制。

#读取
ls path [watch]

get path [watch]

#更新
set path data [version]

#删除
delete path [version]
```

#### 相关资料
* [ZkClient源码](https://github.com/sgroschupf/zkclient)


