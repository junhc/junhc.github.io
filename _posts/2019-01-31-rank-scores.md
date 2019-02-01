---
layout: post
title: "LeetCode数据库之分数排名"
date: 2019-01-21 15:30:03
description: "LeetCode数据库之分数排名"
categories:
- MySQL
permalink: rank-scores
---

编写一个 SQL 查询来实现分数排名。如果两个分数相同，则两个分数排名（Rank）相同。请注意，平分后的下一个名次应该是下一个连续的整数值。换句话说，名次之间不应该有“间隔”。

```
+----+-------+
| Id | Score |
+----+-------+
| 1  | 3.50  |
| 2  | 3.65  |
| 3  | 4.00  |
| 4  | 3.85  |
| 5  | 4.00  |
| 6  | 3.65  |
+----+-------+
```
例如，根据上述给定的 Scores 表，你的查询应该返回（按分数从高到低排列）：

```
+-------+------+
| Score | Rank |
+-------+------+
| 4.00  | 1    |
| 4.00  | 1    |
| 3.85  | 2    |
| 3.65  | 3    |
| 3.65  | 3    |
| 3.50  | 4    |
+-------+------+
```
#### 准备数据
```
DROP TABLE IF EXISTS `scores`;
CREATE TABLE `scores` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `score` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

INSERT INTO `scores` VALUES (1, 3.5);
INSERT INTO `scores` VALUES (2, 3.65);
INSERT INTO `scores` VALUES (3, 4);
INSERT INTO `scores` VALUES (4, 3.85);
INSERT INTO `scores` VALUES (5, 4);
INSERT INTO `scores` VALUES (6, 3.65);
```

#### 不管分数是否相同，依次排名（1，2，3，4，5，6）
```
SELECT
	score,
	@rank := @rank + 1 AS rank
FROM
	( SELECT * FROM scores ORDER BY score DESC ) obj,
	(
SELECT
	@rank := 0
	) r;
```

#### 分数相同，并列排名（1，1，2，3，3，4）
```
SELECT
	score,
CASE

	WHEN @score = obj.score THEN
	cast( @rank AS SIGNED )
	WHEN @score := obj.score THEN
	@rank := @rank + 1
	WHEN @score = 0 THEN
	@rank := @rank + 1
	END AS rank
FROM
	( SELECT * FROM scores ORDER BY score DESC ) obj,
	(
	SELECT
		@rank := 0,
	@score := NULL
) r;
```

#### 并列排名，另类解法
```
SELECT
	score,
	(
SELECT
	count( DISTINCT score )
FROM
	scores
WHERE
	score >= obj.score
	) AS Rank
FROM
	scores obj
ORDER BY
	score DESC;
```

#### 分数相同，并列排名，同时并列的排名也占一位，依次排名（1，1，3，4，4，5）
```
SELECT
	score,
	@rank := @rank + 1 AS ephemeral_rank,
	@increment :=
CASE

	WHEN @score = obj.score THEN
	cast( @increment AS SIGNED )
	WHEN @score := obj.score THEN
	@rank
	WHEN @score = 0 THEN
	@rank
	END AS rank
FROM
	( SELECT score FROM scores ORDER BY score DESC ) obj,
	(
	SELECT
		@rank := 0,
		@score := NULL,
	@increment := 0
) r;
```
