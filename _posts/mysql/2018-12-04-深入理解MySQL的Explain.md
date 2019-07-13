---
layout: post
title: "深入理解MySQL的Explain"
date: 2018-12-04 16:44:35
description: "深入理解MySQL的Explain"
categories:
- MySQL
permalink: /mysql/explain
---

> `explain`关键字可以模拟优化器执行SQL语句，从而知道MySQL是如何处理你的SQL语句的。分析你的查询语句或是结构的性能瓶颈。在select语句之前增加`explain`关键字，MySQL会在查询上设置一个标记，执行查询时，会返回执行计划的信息，而不是执行这条SQL(如果from中包含子查询，仍会执行该子查询，将结果放入临时表中)

##### 建表
```vim
DROP TABLE IF EXISTS `actor`;
CREATE TABLE `actor` (
 `id` int(11) NOT NULL,
 `name` varchar(45) DEFAULT NULL,
 `update_time` datetime DEFAULT NULL,
 PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `actor` (`id`, `name`, `update_time`) VALUES (1,'a','2017-12-22 15:27:18');
INSERT INTO `actor` (`id`, `name`, `update_time`) VALUES (2,'b','2017-12-22 15:27:18');
INSERT INTO `actor` (`id`, `name`, `update_time`) VALUES (3,'c','2017-12-22 15:27:18');

DROP TABLE IF EXISTS `film`;
CREATE TABLE `film` (
 `id` int(11) NOT NULL AUTO_INCREMENT,
 `name` varchar(10) DEFAULT NULL,
 PRIMARY KEY (`id`),
 KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `film` (`id`, `name`) VALUES (3,'film0');
INSERT INTO `film` (`id`, `name`) VALUES (1,'film1');
INSERT INTO `film` (`id`, `name`) VALUES (2,'film2');

DROP TABLE IF EXISTS `film_actor`;
CREATE TABLE `film_actor` (
 `id` int(11) NOT NULL,
 `film_id` int(11) NOT NULL,
 `actor_id` int(11) NOT NULL,
 `remark` varchar(255) DEFAULT NULL,
 PRIMARY KEY (`id`),
 KEY `idx_film_actor_id` (`film_id`,`actor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `film_actor` (`id`, `film_id`, `actor_id`) VALUES (1,1,1);
INSERT INTO `film_actor` (`id`, `film_id`, `actor_id`) VALUES (2,1,2);
INSERT INTO `film_actor` (`id`, `film_id`, `actor_id`) VALUES (3,2,1);
```

```vim
mysql> explain select (select id from actor limit 1) from film;
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
|  1 | PRIMARY     | film  | NULL       | index | NULL          | idx_name | 33      | NULL |    3 |   100.00 | Using index |
|  2 | SUBQUERY    | actor | NULL       | index | NULL          | PRIMARY  | 4       | NULL |    3 |   100.00 | Using index |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
```

##### `id`列
> `id列`的编号是select的序列号，表示查询中执行select子句或操作表的顺序，并且id的顺序是按照select执行的顺序增长的。  
> `id列的值越大，执行优先级越高，id相同则从上往下执行，id值如果为NULL，表示是一个结果集，不需要执行。`

##### `select_type`列
> `select_type列`表示对应行的查询类型是简单查询还是复杂查询，如果是复杂的查询，又分为简单子查询、派生表（from语句中的子查询）、union查询  

- `simple`
  > 表示不需要union操作或者不包含子查询的简单select查询。有连接查询时，外层的查询为simple，且只有一个  

  ```vim
  mysql> explain select * from film where id = 1;
  +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
  | id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref   | rows | filtered | Extra |
  +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
  |  1 | SIMPLE      | film  | NULL       | const | PRIMARY       | PRIMARY | 4       | const |    1 |   100.00 | NULL  |
  +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
  ```
- `primary`  
  > 一个需要union操作或者含有子查询的select，位于最外层的单位查询的select_type即为primary。且只有一个  
- `subquery`  
  > 包含在select中的子查询（不在from子句中）  

  ```vim
  mysql> explain select (select id from actor limit 1) from film;
  +----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
  | id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra       |
  +----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
  |  1 | PRIMARY     | film  | NULL       | index | NULL          | idx_name | 33      | NULL |    2 |   100.00 | Using index |
  |  2 | SUBQUERY    | actor | NULL       | index | NULL          | PRIMARY  | 4       | NULL |    3 |   100.00 | Using index |
  +----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
  ```
- `dependent subquery`
  > 与dependent union类似，表示这个subquery的查询要受到外部表查询的影响
- `derived`
  > from字句中出现的子查询，也叫做派生表，其他数据库中可能叫做内联视图或嵌套select  

  ```vim
  mysql> explain select id from (select id from film group by id) as t;
  +----+-------------+------------+------------+-------+------------------+---------+---------+------+------+----------+-------------+
  | id | select_type | table      | partitions | type  | possible_keys    | key     | key_len | ref  | rows | filtered | Extra       |
  +----+-------------+------------+------------+-------+------------------+---------+---------+------+------+----------+-------------+
  |  1 | PRIMARY     | <derived2> | NULL       | ALL   | NULL             | NULL    | NULL    | NULL |    2 |   100.00 | NULL        |
  |  2 | DERIVED     | film       | NULL       | index | PRIMARY,idx_name | PRIMARY | 4       | NULL |    2 |   100.00 | Using index |
  +----+-------------+------------+------------+-------+------------------+---------+---------+------+------+----------+-------------+
  ```
- `union`
  > union连接的两个select查询，第一个查询是dervied派生表，除了第一个表外，第二个以后的表select_type都是union  

  ```vim
  mysql> explain select id from actor union select id from actor;
  +----+--------------+------------+------------+-------+---------------+---------+---------+------+------+----------+-----------------+
  | id | select_type  | table      | partitions | type  | possible_keys | key     | key_len | ref  | rows | filtered | Extra           |
  +----+--------------+------------+------------+-------+---------------+---------+---------+------+------+----------+-----------------+
  |  1 | PRIMARY      | actor      | NULL       | index | NULL          | PRIMARY | 4       | NULL |    3 |   100.00 | Using index     |
  |  2 | UNION        | actor      | NULL       | index | NULL          | PRIMARY | 4       | NULL |    3 |   100.00 | Using index     |
  | NULL | UNION RESULT | <union1,2> | NULL       | ALL   | NULL          | NULL    | NULL    | NULL | NULL |     NULL | Using temporary |
  +----+--------------+------------+------------+-------+---------------+---------+---------+------+------+----------+-----------------+
  ```
- `dependent union`
  > 与union一样，出现在union 或union all语句中，但是这个查询要受到外部查询的影响    
- `union result`
  > 包含union的结果集，在union和union all语句中，因为它不需要参与查询，所以id字段为null

##### `table`列
> 显示的查询表名，如果查询使用了别名，那么这里显示的是别名  
> 如果不涉及对数据表的操作，那么显示为null  
> 如果显示为尖括号括起来的<derived N>就表示这个是临时表，后边的N就是执行计划中的id，表示结果来自于这个查询产生  
> 如果是尖括号括起来的<union M,N>，与<derived N>类似，也是一个临时表，表示这个结果来自于union查询的id为M,N的结果集

##### `type`列
> 查询效率最优到最差分别为：`system > const > eq_ref > ref > range > index > ALL`

- `system`、`const`
> mysql能对查询的某部分进行优化并将其转化成一个常量（可以看show warnings 的结果）。用于 primary key 或 unique key 的所有列与常数比较时，所以表最多有一个匹配行，读取1次，速度比较快。system是const的特例，表里只有一条元组匹配时为system。

```vim
mysql> explain select * from (select * from film where id = 1) tmp;
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
| id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref   | rows | filtered | Extra |
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | film  | NULL       | const | PRIMARY       | PRIMARY | 4       | const |    1 |   100.00 | NULL  |
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
```

- `eq_ref`
>  `primary key（主键索引）`或 `unique key（唯一索引）`的所有部分被连接使用 ，最多只会返回一条符合条件的记录。这可能是在 const 之外最好的联接类型了。

```vim
mysql> explain select * from film_actor left join film on film_actor.film_id = film.id;
+----+-------------+------------+------------+--------+---------------+---------+---------+----------------------------+------+----------+-------+
| id | select_type | table      | partitions | type   | possible_keys | key     | key_len | ref                        | rows | filtered | Extra |
+----+-------------+------------+------------+--------+---------------+---------+---------+----------------------------+------+----------+-------+
|  1 | SIMPLE      | film_actor | NULL       | ALL    | NULL          | NULL    | NULL    | NULL                       |    2 |   100.00 | NULL  |
|  1 | SIMPLE      | film       | NULL       | eq_ref | PRIMARY       | PRIMARY | 4       | alibaba.film_actor.film_id |    1 |   100.00 | NULL  |
+----+-------------+------------+------------+--------+---------------+---------+---------+----------------------------+------+----------+-------+
```

- `ref`
> 相比`eq_ref`，不使用唯一索引，而是使用普通索引或者唯一性索引的部分前缀，索引要和某个值相比较，可能会找到多个符合条件的行。

```vim
mysql> explain select * from film where name = "film1";
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref   | rows | filtered | Extra       |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | film  | NULL       | ref  | idx_name      | idx_name | 33      | const |    1 |   100.00 | Using index |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
```

> 关联表查询，idx_film_actor_id是film_id和actor_id的联合索引。这里使用到了film_actor的左边前缀film_id部分。

```vim
mysql>  explain select film_id from film left join film_actor on film.id = film_actor.film_id;
+----+-------------+------------+------------+-------+-------------------+-------------------+---------+-----------------+------+----------+-------------+
| id | select_type | table      | partitions | type  | possible_keys     | key               | key_len | ref             | rows | filtered | Extra       |
+----+-------------+------------+------------+-------+-------------------+-------------------+---------+-----------------+------+----------+-------------+
|  1 | SIMPLE      | film       | NULL       | index | NULL              | idx_name          | 33      | NULL            |    2 |   100.00 | Using index |
|  1 | SIMPLE      | film_actor | NULL       | ref   | idx_film_actor_id | idx_film_actor_id | 4       | alibaba.film.id |    2 |   100.00 | Using index |
+----+-------------+------------+------------+-------+-------------------+-------------------+---------+-----------------+------+----------+-------------+
```

- `range`
> 范围扫描通常出现在 in(), between ,> ,<, >= 等操作中。使用一个索引来检索给定范围的行。

```vim
mysql> explain select * from actor where id > 1;
+----+-------------+-------+------------+-------+---------------+---------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+-------+---------------+---------+---------+------+------+----------+-------------+
|  1 | SIMPLE      | actor | NULL       | range | PRIMARY       | PRIMARY | 4       | NULL |    2 |   100.00 | Using where |
+----+-------------+-------+------------+-------+---------------+---------+---------+------+------+----------+-------------+
```
- `index`
> 扫描全表索引，这通常比ALL快一些。（index是从索引中读取的，而all是从硬盘中读取）

```vim
mysql> explain select * from film;
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
|  1 | SIMPLE      | film  | NULL       | index | NULL          | idx_name | 33      | NULL |    2 |   100.00 | Using index |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
```
- `ALL`
> 全表扫描

> 使用 `show warnings;` 查看MySQL给出的优化建议

```vim
mysql> show warnings;
+-------+------+----------------------------------------------------------------------------------------------------------------------------------+
| Level | Code | Message |
+-------+------+----------------------------------------------------------------------------------------------------------------------------------+
| Note  | 1003 | /* select#1 */ select `alibaba`.`film_actor`.`id` AS `id`,`alibaba`.`film_actor`.`film_id` AS `film_id`,`alibaba`.`film_actor`.`actor_id` AS `actor_id`,`alibaba`.`film_actor`.`remark` AS `remark`,`alibaba`.`film`.`id` AS `id`,`alibaba`.`film`.`name` AS `name` from `alibaba`.`film_actor` left join `alibaba`.`film` on((`alibaba`.`film`.`id` = `alibaba`.`film_actor`.`film_id`)) where 1 |
+-------+------+----------------------------------------------------------------------------------------------------------------------------------+
```

##### `possible_keys`列
> 这一列显示查询可能使用哪些索引来查找。explain 时可能出现 possible_keys 有列，而 key 显示 NULL 的情况，这种情况是因为表中数据不多，mysql认为索引对此查询帮助不大，选择了全表查询。  
> 如果该列是NULL，则没有相关的索引。在这种情况下，可以通过检查 where 子句看是否可以创造一个适当的索引来提高查询性能，然后用 explain 查看效果。

##### `keys`列
> 这一列显示mysql实际采用哪个索引来优化对该表的访问。 如果没有使用索引，则该列是 NULL。如果想强制mysql使用或忽视possible_keys列中的索引，在查询中使用 force index、ignore index。

##### `key_len`列
> 这一列显示了mysql在索引里使用的字节数，通过这个值可以算出具体使用了索引中的哪些列。  
> 举例说明：film_actor的联合索引 idx_film_actor_id 由 film_id 和 actor_id 两个int列组成，并且每个int是4字节。通过结果中的key_len=4可推断出查询使用了第一个列：film_id列来执行索引查找。

```vim
mysql> explain select * from film_actor where film_id = 2;
+----+-------------+------------+------------+------+-------------------+-------------------+---------+-------+------+----------+-------+
| id | select_type | table      | partitions | type | possible_keys     | key               | key_len | ref   | rows | filtered | Extra |
+----+-------------+------------+------------+------+-------------------+-------------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | film_actor | NULL       | ref  | idx_film_actor_id | idx_film_actor_id | 4       | const |    1 |   100.00 | NULL  |
+----+-------------+------------+------------+------+-------------------+-------------------+---------+-------+------+----------+-------+
```

```vim
key_len计算规则如下：
字符串：
  char(n)：参考栗子①
  varchar(n)：参考栗子②
数值类型：
  tinyint：1字节
  smallint：2字节
  int：4字节
  bigint：8字节　　
时间类型：
  date：3字节
  timestamp：4字节
  datetime：8字节

举个栗子
  ① char(10)固定字段且允许NULL：10*(Character Set：utf8=3,gbk=2,latin1=1)+1(NULL)
    char(10)固定字段且不允许NULL：10*(Character Set：utf8=3,gbk=2,latin1=1)
  ② varchr(10)变长字段且允许NULL：10*(Character Set：utf8=3,gbk=2,latin1=1)+1(NULL)+2(变长字段)
    varchr(10)变长字段且不允许NULL：10*(Character Set：utf8=3,gbk=2,latin1=1)+2(变长字段)
```

> **如果字段允许为 NULL，需要1字节记录是否为 NULL 索引最大长度是`768`字节，当字符串过长时，mysql会做一个类似左前缀索引的处理，将前半部分的字符提取出来做索引。**

##### `ref`列
> 这一列显示了在key列记录的索引中，表查找值所用到的列或常量，常见的有：const（常量），字段名

##### `rows`列
> 这一列是mysql估计要读取并检测的行数，注意这个不是结果集里的行数

##### `Extra`列
> 1）、Using index： 查询的列被索引覆盖，并且where筛选条件是索引的前导列，是性能高的表现。一般是使用了覆盖索引(索引包含了所有查询的字段)。对于innodb来说，如果是辅助索引性能会有不少提高  
> 2）、Using where： 查询的列未被索引覆盖，where筛选条件非索引的前导列  

```vim
mysql> explain select * from actor where name = 'a';
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------------+
|  1 | SIMPLE      | actor | NULL       | ALL  | NULL          | NULL | NULL    | NULL |    2 |    50.00 | Using where |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------------+
```

> 3）、Using where Using index： 查询的列被索引覆盖，并且where筛选条件是索引列之一但是不是索引的前导列，意味着无法直接通过索引查找来查询到符合条件的数据  

```vim
mysql> explain select film_id from film_actor where actor_id = 1;
+----+-------------+------------+------------+-------+---------------+-------------------+---------+------+------+----------+--------------------------+
| id | select_type | table      | partitions | type  | possible_keys | key               | key_len | ref  | rows | filtered | Extra                    |
+----+-------------+------------+------------+-------+---------------+-------------------+---------+------+------+----------+--------------------------+
|  1 | SIMPLE      | film_actor | NULL       | index | NULL          | idx_film_actor_id | 8       | NULL |    2 |    50.00 | Using where; Using index |
+----+-------------+------------+------------+-------+---------------+-------------------+---------+------+------+----------+--------------------------+
```

> 4）、NULL： 查询的列未被索引覆盖，并且where筛选条件是索引的前导列，意味着用到了索引，但是部分字段未被索引覆盖，必须通过“回表”来实现，不是纯粹地用到了索引，也不是完全没用到索引

```vim
mysql> explain select * from film_actor where film_id = 1;
+----+-------------+------------+------------+------+-------------------+-------------------+---------+-------+------+----------+-------+
| id | select_type | table      | partitions | type | possible_keys     | key               | key_len | ref   | rows | filtered | Extra |
+----+-------------+------------+------------+------+-------------------+-------------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | film_actor | NULL       | ref  | idx_film_actor_id | idx_film_actor_id | 4       | const |    2 |   100.00 | NULL  |
+----+-------------+------------+------------+------+-------------------+-------------------+---------+-------+------+----------+-------+
```

> 5）、Using index condition： 与Using where类似，查询的列不完全被索引覆盖，where条件中是一个前导列的范围

```vim
mysql> explain select * from film_actor where film_id > 1;
+----+-------------+------------+------------+-------+-------------------+-------------------+---------+------+------+----------+-----------------------+
| id | select_type | table      | partitions | type  | possible_keys     | key               | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+------------+------------+-------+-------------------+-------------------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | film_actor | NULL       | range | idx_film_actor_id | idx_film_actor_id | 4       | NULL |    1 |   100.00 | Using index condition |
+----+-------------+------------+------------+-------+-------------------+-------------------+---------+------+------+----------+-----------------------+
```

> 6）、Using temporary： mysql需要创建一张临时表来处理查询。出现这种情况一般是要进行优化的，首先是想到用索引来优化

```vim
mysql> explain select distinct name from actor;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-----------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra           |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-----------------+
|  1 | SIMPLE      | actor | NULL       | ALL  | NULL          | NULL | NULL    | NULL |    2 |   100.00 | Using temporary |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-----------------+
```

> 7）、Using filesort：**mysql会对结果使用一个外部索引排序，而不是按索引次序从表里读取行。此时mysql会根据联接类型浏览所有符合条件的记录，并保存排序关键字和行指针，然后排序关键字并按顺序检索行信息。这种情况下一般也是要考虑使用索引来优化的**

```vim
mysql> explain select * from actor order by name;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra          |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
|  1 | SIMPLE      | actor | NULL       | ALL  | NULL          | NULL | NULL    | NULL |    2 |   100.00 | Using filesort |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
```
