---
layout: post
title: "死磕Java并发之ThreadLocal"
date: 2019-03-01 10:41:08
description: "死磕Java并发之ThreadLocal"
categories:
- 并发编程
permalink: threadlocal
---

![](/assets/img/ThreadLocal的使用及原理分析.png)

```vim
public class ThreadLocal<T> {

  private final int threadLocalHashCode = nextHashCode();
  private static AtomicInteger nextHashCode = new AtomicInteger();
  private static final int HASH_INCREMENT = 0x61c88647;
  private static int nextHashCode() {
    return nextHashCode.getAndAdd(HASH_INCREMENT);
  }

  public T get() {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    return setInitialValue();
  }

  private T setInitialValue() {
    T value = initialValue();
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
    return value;
  }

  public void set(T value) {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
  }

  ThreadLocalMap getMap(Thread t) {
    // 实际上就是访问Thread类中的ThreadLocalMap这个成员变量
    // 每一个线程都有自己单独的ThreadLocalMap实例，而对应这个线程的所有本地变量都会保存到这个map内
    return t.threadLocals;
  }

  void createMap(Thread t, T firstValue) {
    t.threadLocals = new ThreadLocalMap(this, firstValue);
  }
  ...
}
```

```vim
public
class Thread implements Runnable {
  /* ThreadLocal values pertaining to this thread. This map is maintained
   * by the ThreadLocal class. */
  ThreadLocal.ThreadLocalMap threadLocals = null;  
  ...
}
```

```vim
static class ThreadLocalMap {
  // 使用弱引用的对象，不会阻止它所指向的对象被垃圾回收器回收
  static class Entry extends WeakReference<ThreadLocal<?>> {
    /** The value associated with this ThreadLocal. */
    Object value;
    Entry(ThreadLocal<?> k, Object v) {
        super(k);

        value = v;
    }
  }

  ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
    //构造一个Entry数组，并设置初始大小
    table = new Entry[INITIAL_CAPACITY];
    //计算Entry数据下标
    int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
    //将`firstValue`存入到指定的table下标中
    table[i] = new Entry(firstKey, firstValue);
    //设置节点长度为1
    size = 1;
    //设置扩容的阈值
    setThreshold(INITIAL_CAPACITY);
  }

  private void set(ThreadLocal<?> key, Object value) {
    Entry[] tab = table;
    int len = tab.length;
    // 根据哈希码和数组长度求元素放置的位置，即数组下标
    int i = key.threadLocalHashCode & (len-1);
    // 从i开始往后一直遍历到数组最后一个Entry(线性探索)
    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        ThreadLocal<?> k = e.get();
        // 如果key相等，覆盖value
        if (k == key) {
            e.value = value;
            return;
        }
        // 如果key为null，用新key、value覆盖，同时清理历史key=null的陈旧数据
        if (k == null) {
            replaceStaleEntry(key, value, i);
            return;
        }
    }

    tab[i] = new Entry(key, value);
    int sz = ++size;
    // 如果超过阀值，就需要扩容了
    if (!cleanSomeSlots(i, sz) && sz >= threshold)
        rehash();
  }
  ...
}
```

##### 魔数0x61c88647

> 魔数0x61c88647的选取和斐波那契散列有关，0x61c88647对应的十进制为1640531527。  
> 而斐波那契散列`(f(n) = f(n-1) + f(n-2) (n>1))`的乘数可以用 `(long)((1L<<31)*(Math.sqrt(5)-1))`  
> 如果把这个值给转为带符号的int，则会得到1640531527。  

```vim
private static final int HASH_INCREMENT = 0x61c88647;

private static void magicHash(int size) {
  int hashCode = 0;
  for (int i = 0; i < size; i++) {
      hashCode = i * HASH_INCREMENT + HASH_INCREMENT;
      // 我们用0x61c88647作为魔数累加为每个ThreadLocal分配各自的ID也就是threadLocalHashCode再与2的幂取模，得到的结果分布很均匀
      System.out.printf((hashCode & (size - 1)) + " ");
  }
  System.out.println();
}

public static void main(String[] args) {
  magicHash(16);
  magicHash(32);
  // 7 14 5 12 3 10 1 8 15 6 13 4 11 2 9 0
  // 7 14 21 28 3 10 17 24 31 6 13 20 27 2 9 16 23 30 5 12 19 26 1 8 15 22 29 4 11 18 25 0
}
```

##### ThreadLocal的内存泄漏
> ThreadLocalMap中Entry的key使用的是ThreadLocal的弱引用，  
> 如果一个ThreadLocal没有外部强引用，当系统执行GC时，这个ThreadLocal势必会被回收，  
> 这样一来，ThreadLocalMap中就会出现一个key为null的Entry，  
> 而这个key=null的Entry是无法访问的，当这个线程一直没有结束的话，那么就会存在一条强引用链

##### 参考资料
* [ThreadLocal的使用及原理分析](https://mp.weixin.qq.com/s/bxIkMaCQ0PriZtSWT8wrXw)
* [手撕面试题ThreadLocal](https://mp.weixin.qq.com/s/SNLNJcap8qmJF9r4IuY8LA)
