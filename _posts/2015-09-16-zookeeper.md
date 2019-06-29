---
layout: post
title: "ZooKeeper"
date: 2015-09-16 18:56:17
description: "ZooKeeper"
categories:
- Zookeeper
permalink: zookeeper
---

##### Maven依赖写法
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

##### 客户端脚本

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

![](/assets/img/znode.png)

* data: ZNode存储的数据信息
* ACL: 记录ZNode的访问权限
* Stat: 记录ZNode的元数据，如事务ID、版本号、时间戳、大小等
* child: 当前ZNode的子节点

> `每个节点的数据最大不能超过1MB`

##### 参考资料
* [ZkClient源码](https://github.com/sgroschupf/zkclient)
