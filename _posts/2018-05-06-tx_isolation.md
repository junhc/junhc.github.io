---
layout: post
title: "理解事务的4种隔离级别"
date: 2018-05-06 14:32:48
description: "理解事务的4种隔离级别"
categories:
- MySQL
permalink: /mysql/tx_isolation
---

### 目录
* [1. Read Uncommitted (读取未提交内容) ](#1-read-uncommitted-读取未提交内容)
* [2. Read Committed (读取提交内容) ](#2-read-committed-读取提交内容)
* [3. Repeatable Read (可重读) ](#3-repeatable-read-可重读)
* [4. Serializable (可串行化) ](#4-serializable-可串行化)

#### 1. Read Uncommitted (读取未提交内容)
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
|          1 | kk       |     -1 |  ---> '读取到事务B还没有提交的内容'
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

# 事务A, 依旧可以读取到事务B未提交的内容
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |      0 | ---> '脏读意味着, 所有事务都可以看到其他未提交事务的执行结果'
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+
```

#### 2. Read Committed (读取提交内容)
> 这是大多数据库系统的默认隔离级别（`但不是MySQL默认的`）。  
它满足了隔离的简单定义：一个事务只能看见已经提交事务所做的改变。  
这种隔离级别也支持所谓的`不可重复读（Nonrepeatable Read）`，因为同一事务的其他实例再该实例处理期间可能会有新的Commit，所以同一Select可能返回不同的结果。

```vim
# 修改隔离级别
mysql> set tx_isolation = 'READ-COMMITTED';
mysql> select @@tx_isolation;
+----------------+
| @@tx_isolation |
+----------------+
| READ-COMMITTED |
+----------------+

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
|          1 | kk       |      0 |  ---> '并没有读取到事务B未提交的内容'
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+

# 事务B, 如果执行提交呢?
mysql> commit;

# 事务A, 
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |     -1 | ---> '读取到事务B已提交的内容, '
|          6 | tanwd    |      0 |      '这也导致同一事务中, 执行完全相同的select语句读取到不一样的内容'
|          7 | yexk     |      0 |
+------------+----------+--------+
```

#### 3. Repeatable Read (可重读)
>`这是MySQL默认的事务隔离级别`，它确保同一事务的多个实例在并发读取数据时，会看到同样的数据行。  
不过理论上，这会导致另一个棘手的问题：`幻读（Phantom Read）`。  
简单的说，幻读指当用户读取某一范围的数据行时，另一个事务又在该范围内插入了新行，当用户再读取该范围的数据行时，会发现有新的“幻影”行。InnoDB和Falcon存储引擎，通过多版本并发控制机制解决了该问题。

```vim
# 修改隔离级别
mysql> set tx_isolation = 'REPEATABLE-READ';
mysql> select @@tx_isolation;
+-----------------+
| @@tx_isolation  |
+-----------------+
| REPEATABLE-READ |
+-----------------+

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

# 事务B, 也启动一个事务, 并执行更新语句, 并提交
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
mysql> commit;

# 事务A, 可以读取到事务B已经提交的内容吗?
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |      0 | ---> '并没有读取到事务B已提交的内容, 说明解决了不可重复读的问题'
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+
mysql> commit;
mysql> select account_id, username, status from account limit 3;
+------------+----------+--------+
| account_id | username | status |
+------------+----------+--------+
|          1 | kk       |     -1 | ---> '只有当事务A提交后, 才可以读取到事务B提交的内容'
|          6 | tanwd    |      0 |
|          7 | yexk     |      0 |
+------------+----------+--------+
```

###### 补充说明
> 可重复和提交读是矛盾的。  
在同一个事务里，如果保证了可重复读，就会读取不到其他事务的提交内容，违背了提交读。  
如果保证了提交读，就会导致前后两次读取到的内容不一样，违背了可重复读。  
`InnoDB`提供了这样的机制，在默认的可重复读的隔离级别里，可以使用加锁读取其他事务最新提交的内容。  
`InnoDB`可重复读并不保证避免幻读，需要加锁读来保证。而这个加锁读使用的机制就是`next-key locks`。

```vim
mysql> CREATE TABLE `tx` (
  `id` bigint(20) NOT NULL DEFAULT '0',
  `value` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# 事务A, 启动一个事务
mysql> start transaction;

# 事务B, 也启动一个事务, 并插入数据, 提交
mysql> start transaction;
mysql> insert into tx values (1, 'a');
mysql> commit;

# 事务A, 直接读
mysql> select * from tx;
Empty set (0.00 sec)

# 事务A, 加锁读
mysql> select * from tx lock in share mode;
+----+-------+
| id | value |
+----+-------+
|  1 | a     |
+----+-------+

mysql> select * from tx for update;
+----+-------+
| id | value |
+----+-------+
|  1 | a     |
+----+-------+
```

#### 4. Serializable (可串行化)
> 这是最高的隔离级别，它通过强制事务排序，使之不可能互相冲突，从而解决幻读问题。  
简言之，它是在每个读的数据行加共享锁。在这个级别，可能导致大量的超时现象和锁竞争。

```vim
# 修改隔离级别
mysql> set tx_isolation='SERIALIZABLE';
mysql> select @@tx_isolation;
+----------------+
| @@tx_isolation |
+----------------+
| SERIALIZABLE   |
+----------------+

# 事务A, 启动一个事务
mysql> start transaction;

# 事务B, 在事务A没有提交之前, 是不能更改数据的
mysql> start transaction;
mysql> update account set status = -1 where account_id = 1;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

#### 总结
> 四个级别逐渐增强，每个级别解决一个问题。事务级别越高，性能越差。
