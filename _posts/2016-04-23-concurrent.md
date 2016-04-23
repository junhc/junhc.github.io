---
layout: post
title: "并发编程"
date: 2016-04-23 15:55:35
description: "并发编程"
categories:
- java
permalink: concurrent
---

### Segment数据结构  
```vim
static final class Segment<K,V> extands ReentrantLock implements Serializable {
    transient volatile int count; //Segment中元素的数量
    transient int modCount;//对table的大小造成影响的操作数量(如:put,reomve操作)
    transient int threshold;//阈值,Segment里面元素的数量超过这个值依旧就会对Segment进行扩容
    transient volatile HashEntry<K,V>[] table;//链表数据,数组中的每一个元素代表了一个链表的头部
    final float loadFactor;//负载因子,用于确定threshold
}
```

### HashEntry  
```vim
static final class HashEntry<K,V> {
    final K key;
    final int hash;
    volatile V value;//其他的几个变量都是final的,这样做是为了防止链表结构被破坏,出现ConcurrentModification的情况
    final HashEntry<K,V> next;
}
```

### ConcurrentHashMap  
```vim
public ConcurrentHashMap(int initialCapacity, //初始的容量
                         float loadFactor, //负载参数
                         int concurrencyLevel //内部Segment的数量,ConcurrentLevel一经指定,不可改变,后续如果ConcurrentHashMap
                         的元素数量增加导致ConcurrentHashMap需要扩容,不会增加Segment的数量,只会增加Segment中链表数组的容量.
                         这样的好处是扩容不需要对整个ConcurrentHashMap做rehash,而只需要对Segment里面的元素做一次rehash.
                        ) {
    if(!(localFactor > 0) || initialCapacity < 0 || concurrencyLevel <= 0)
      throw new IllegalArgumentException();
      
    if(concurrencyLevel > MAX_SEGMENTS)
      concurrencyLevel = MAX_SEGMENTS;
    
    int sshift = 0;
    int ssize = 0;
    while (ssize < concurrencyLevel) {
      ++sshift;
      ssize <<= 1;
    }
    segmentShift = 32 - sshift;
    segmentMask = ssize - 1;
    this.segments = Segment.newArray(ssize);
    
    if (initialCapacity > MAXIMUM_CAPACITY)
      initialCapacity = MAXIMUM_CAPACITY;
    int c = initialCapacity / ssize;
    if (c * ssize < initialCapacity)
       ++c;
    int cap = 1;
    while (cap < c)
      cap <<= 1;
    
    for (int i = 0; i < this.segments.length; ++i)
      this.segments[i] = new Segment<K,V>(cap, loadFactor);
}
```
