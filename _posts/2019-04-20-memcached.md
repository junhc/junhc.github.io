---
layout: post
title: "Memcached"
date: 2019-04-20 13:08:17
description: "Memcached"
categories:
- Memcached
permalink: memcached
---

##### `Memcached`的特征

- 协议简单
- 基于`libevent`的事件处理
  > `libevent`是个程序库，它将Linux的epoll、BSD类操作系统的kqueue等事件处理功能封装成统一的接口。  
  > 即使对服务器的连接数增加，也能发挥O(1)的性能。

- 内置内存存储方法
  > 由于数据仅存在内存中，因此重启memcached、重启操作系统会导致全部数据丢失。  
  > 内容容量达到指定值之后，就基于LRU算法自动删除不使用的缓存。

- memcached不互相通信的分布式
  > 服务器端没有分布式的功能，各个memcached不会互相共享信息。  
  > 怎样进行分布式完全取决于客户端的实现。

##### `Memcached`的安装

```vim
#
sudo yum install libevent libevent-devel

# 下载
wget http://memcached.org/latest
tar -zxvf memcached-1.x.x.tar.gz
cd memcached-1.x.x
./configure && make && make test && sudo make install

# 启动
# -p 使用的 TCP 端口。默认为 11211
# -M 禁止LRU机制
# -m 最大内存大小。默认为 64M
# -vv 用 very vrebose 模式启动，调试信息和错误输出到控制台
# -d 作为 daemon 在后台启动
/usr/local/bin/memcached -p 11211 -m 64m -d
```  

##### `Memcached`的内存存储

- Slab Allocation机制：整理内存以便重复使用
  > 按照预先规定的大小，将分配的内存分割成特定长度的块，并把尺寸相同的块分成组（chunk的结合），
  > 分配到的内存不会释放，而是重复利用。  

  ```vim
  Slab Allocation 的主要术语
  Page
      分配给 Slab 的内存空间，默认是 1MB。分配给 Slab 之后根据 slab 的大小切分成 chunk。
  Chunk
     用于缓存记录的内存空间。
  Slab Class
     特定大小的 chunk 的组。
  ```
- Slab Allocation的缺点
  > 由于分配的特定长度的内存，因此无法有效利用分配的内存。  
  > 如：将100字节的数据缓存到128字节的chunk中，剩余28字节就浪费了。

- 使用 Growth Factor 进行调优
  > memcached 在启动时指定 Growth Factor 因子(通过-f 选项)，就可以在某种程度上控制 slab 之间的
  > 差异。默认值为 1.25。但是，在该选项出现之前，这个因子曾经固定为 2，称为“powers of 2”策略。

```vim
memcached -f 2 -vv

...
slab class   1: chunk size        96 perslab   10922
slab class   2: chunk size       192 perslab    5461
slab class   3: chunk size       384 perslab    2730
slab class   4: chunk size       768 perslab    1365
slab class   5: chunk size      1536 perslab     682
slab class   6: chunk size      3072 perslab     341
slab class   7: chunk size      6144 perslab     170
slab class   8: chunk size     12288 perslab      85
slab class   9: chunk size     24576 perslab      42
slab class  10: chunk size     49152 perslab      21
slab class  11: chunk size     98304 perslab      10
slab class  12: chunk size    196608 perslab       5
slab class  13: chunk size    524288 perslab       2
...

```  

##### 查看slabs的使用状况

下载 [memcached-tool](/downloads/memcached/memcached-tool.zip) 工具

```vim
Usage: memcached-tool <host[:port]> [mode]

       memcached-tool 10.0.0.5:11211 display    # shows slabs
       memcached-tool 10.0.0.5:11211            # same.  (default is display)
       memcached-tool 10.0.0.5:11211 stats      # shows general stats
       memcached-tool 10.0.0.5:11211 move 7 9   # takes 1MB slab from class #7
                                                # to class #9.

# slab class编号
# Item_Size Chunk大小
# Max_age LRU内最旧的记录的生存时间
# 1MB_pages 分配给Slab的页数
# Count Slab 内的记录数
# Full? Slab 内是否含有空闲 chunk

$ perl memcached-tool localhost:11211 display
  #  Item_Size   Max_age  1MB_pages Count   Full?     

```

##### `Memcached`在数据删除方面有效利用资源

- Lazy Expiration
  > memcached内部不会监视记录是否过期，而是在get时查看记录的时间戳，检查记录是否过期。  
  > 因此，memcached不会在过期监视上耗费CPU时间。

- LRU 从缓存中有效删除数据的原理
  > memcached会优先使用已超时的记录的空间，但即使如此，也会发生追加新纪录时空间不足的情况，  
  > 此时就要删除“最近最少使用”的记录的机制。  

##### `Memcached`的键长度最大为 250 字节

##### `Memcached`的分布式算法

- 根据余数计算分散
  > 根据服务器台数的余数进行分散，求得键的整数哈希值，再除以服务器台数，根据余数来选择服务器

- 缺点
  > 余数计算的方法简单，数据的分散性也相当优秀，但当添加或移除服务器时，缓存重组的代价相当巨大。

- 一致性Hash算法
  > 首先求出 memcached 服务器(节点)的哈希值，并将其配置到 0~2^32 的圆(continuum)上。  
  > 然后用同样的方法求出存储数据的键的哈希值，并映射到圆上。  
  > 然后从数据映射到的位置开始顺时针查找，将数据保存到找到的第一个服务器上。  
  > 如果超过 2^32 仍然找不到 服务器，就会保存到第一台 memcached 服务器上。  
  > 当添加或移除服务器时，只有在 continuum 上增加服务器的地点逆时针方向的第一台服务器上的键会受到影响。  
