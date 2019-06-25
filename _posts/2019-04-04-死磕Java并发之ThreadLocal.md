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
    return t.threadLocals;
  }
}

public
class Thread implements Runnable {
  /* ThreadLocal values pertaining to this thread. This map is maintained
   * by the ThreadLocal class. */
  ThreadLocal.ThreadLocalMap threadLocals = null;  
  ...
}
```

##### 参考资料
* [ThreadLocal的使用及原理分析](https://mp.weixin.qq.com/s/bxIkMaCQ0PriZtSWT8wrXw)
* [手撕面试题ThreadLocal](https://mp.weixin.qq.com/s/SNLNJcap8qmJF9r4IuY8LA)
