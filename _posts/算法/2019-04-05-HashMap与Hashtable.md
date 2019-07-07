---
layout: post
title: "HashMap与Hashtable"
date: 2018-03-25 16:44:35
description: "HashMap与Hashtable"
categories:
- Java
permalink: /java/hashmap_and_hashtable
---

##### 1. 线程安全
Hashtable 是线程安全的，HashMap 不是线程安全的。  

为什么说 HashTable 是线程安全的？  

来看下 Hashtable 的源码，Hashtable 所有的元素操作都是 synchronized 修饰的，而 HashMap 并没有。  

```vim
...
public synchronized V put(K key, V value);
public synchronized V get(Object key);
...
```

##### 2. 性能优劣
既然 Hashtable 是线程安全的，每个方法都要阻塞其他线程，所以 Hashtable 性能较差，HashMap 性能较好，使用更广。  

如果要线程安全又要保证性能，建议使用 JUC 包下的 ConcurrentHashMap。  

##### 3. NULL
Hashtable 是不允许键或值为 null 的，HashMap 的键值则都可以为 null。  

那么问题来了，为什么 Hashtable 是不允许 KEY 和 VALUE 为 null, 而 HashMap 则可以？  

Hashtable put 方法逻辑：  
```vim
public synchronized V put(K key, V value) {
   // Make sure the value is not null
   if (value == null) {
       throw new NullPointerException();
   }

   // Makes sure the key is not already in the hashtable.
   Entry<?,?> tab[] = table;
   int hash = key.hashCode();

   ...
}  
```

HashMap hash 方法逻辑：
```vim
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```
可以看出 Hashtable key 为 null 会直接抛出空指针异常，value 为 null 手动抛出空指针异常，而 HashMap 的逻辑对 null 作了特殊处理。

##### 4. 实现方式
Hashtable 的继承源码：
```vim
public class Hashtable<K,V>
    extends Dictionary<K,V>
    implements Map<K,V>, Cloneable, java.io.Serializable
```

HashMap 的继承源码：
```vim
public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable
```

可以看出两者继承的类不一样，Hashtable 继承了 Dictionary类，而 HashMap 继承的是 AbstractMap 类。  

##### 5. 容量扩容
HashMap 的初始容量为：16，Hashtable 初始容量为：11，两者的负载因子默认都是：0.75。  
当现有容量大于总容量 * 负载因子时，HashMap 扩容规则为当前容量翻倍，Hashtable 扩容规则为当前容量翻倍 + 1。  

##### 6. 迭代器
HashMap 中的 Iterator 迭代器是 fail-fast 的，而 Hashtable 的 Enumerator 不是 fail-fast 的。  

所以，当其他线程改变了HashMap 的结构，如：增加、删除元素，将会抛出 ConcurrentModificationException 异常，而 Hashtable 则不会。  
```vim
public static void main(String[] args) {
    Map<String, String> hashtable = new Hashtable<>();
    hashtable.put("t1", "1");
    hashtable.put("t2", "2");
    hashtable.put("t3", "3");

    Enumeration<Map.Entry<String, String>> iterator1 = (Enumeration<Map.Entry<String, String>>) hashtable.entrySet().iterator();
    hashtable.remove(iterator1.nextElement().getKey());
    while (iterator1.hasMoreElements()) {
        System.out.println(iterator1.nextElement());
    }

    Map<String, String> hashMap = new HashMap<>();
    hashMap.put("h1", "1");
    hashMap.put("h2", "2");
    hashMap.put("h3", "3");

    Iterator<Map.Entry<String, String>> iterator2 = hashMap.entrySet().iterator();
    hashMap.remove(iterator2.next().getKey());
    while (iterator2.hasNext()) {
        System.out.println(iterator2.next());
    }
}
```

输出信息：  

```vim
t2=2
t1=1
Exception in thread "main" java.util.ConcurrentModificationException
	at java.util.HashMap$HashIterator.nextEntry(HashMap.java:922)
	at java.util.HashMap$EntryIterator.next(HashMap.java:962)
	at java.util.HashMap$EntryIterator.next(HashMap.java:960)
	at com.junhc.provider.demo.T.main(T.java:41)
```
