---
layout: post
title: "理解事务的4种隔离级别"
date: 2018-05-06 14:32:48
description: "理解事务的4种隔离级别"
categories:
- MySQL
permalink: /mysql/tx-isolation
---

### 目录
* [Read Uncommitted (读取未提交内容) ](#read-uncommitted-读取未提交内容)
* [Read Committed (读取提交内容) ](#read-committed-读取提交内容)
* [Repeatable Read (可重读) ](#repeatable-read-可重读)
* [Serializable (可串行化) ](#serializable-可串行化)

#### Read Uncommitted (读取未提交内容)
> 在该隔离级别，所有事务都可以看到其他未提交事务的执行结果。  
本隔离级别很少用于实际应用，因为它的性能也不比其他级别好多少。  
读取未提交的数据，也被称之为脏读（Dirty Read）。

```vim

```

#### Read Committed (读取提交内容)
#### Repeatable Read (可重读)
#### Serializable (可串行化)
