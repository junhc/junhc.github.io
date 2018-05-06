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
# 修改隔离级别
mysql> set tx_isolation = 'READ-UNCOMMITTED';

mysql> select @@tx_isolation;
+------------------+
| @@tx_isolation   |
+------------------+
| READ-UNCOMMITTED |
+------------------+

# 事务A, 启动一个事务
mysql> start transaction;
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |      0 |
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+

# 事务B, 也启动一个事务, 并执行更新语句, 但不提交
mysql> start transaction;
mysql> update account set status = -1 where account_id = 1;
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |     -1 |
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+

# 事务A, 那么这个时候事务A能看到事务B更新的数据吗?
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |     -1 |  ---> 读到了事务B还没有提交的内容
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+

# 事务B, 回滚, 但不提交
mysql> rollback;
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |      0 |
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+

# 事务A, 依旧可以读到事务B未提交的内容
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |      0 | ---> 脏读意味着, 所有事务都可以看到其他未提交事务的执行结果
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+
```

#### Read Committed (读取提交内容)
#### Repeatable Read (可重读)
#### Serializable (可串行化)
