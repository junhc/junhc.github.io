---
layout: post
title: "设计模式之单例模式"
date: 2019-03-07 01:02:45
description: "设计模式之单例模式"
categories:
- java
- 设计模式
permalink: singleton
---

##### 基于`volatile`的解决方案

```vim
public class SafeDoubleCheckedLocking {

  private volatile static Instance instance;

  public static Instance getInstance() {
    if(instance == null) {
      synchronized(SafeDoubleCheckedLocking.class) {
        if(instance == null) {
          // 1.分配对象的内存空间
          // 2.初始化对象
          // 3.设置 instance 指向刚分配的内存地址
          // 如果 instance 不使用 volatile 修饰，那么2，3指令重排
          // 多线程并发情况下，线程将会访问到一个还未初始化的对象
          instance = new Instance();
        }
      }
    }
  }

}
```

##### 基于类初始化的解决方案
> JVM在类的初始化阶段(即在Class被加载后，且被线程使用之前)，会执行类的初始化。  
> 在执行类的初始化期间，JVM会去获取一个锁。  

```vim
public class InstanceFactory {

  private static class InstanceHolder {
    public static Instance instance = new Instance();
  }

  public static Instance getInstance() {
    return InstanceHolder.instance; // 这里将导致 InstanceHolder 类被初始化
  }

}
```
> **Java语言规范，在首次发生下列任意一种情况时，一个类或接口类型T将被立即初始化。**  
> 1) T是一个类，且一个T类型的实例被创建  
> 2) T是一个类，且T中声明的一个静态方法被调用  
> 3) T中声明的一个静态字段被赋值  
> 4) T中声明的一个静态字段被使用，且这个字段不是一个常量字段  
> 5) T是一个顶级类，且一个断言语句嵌套在T内被执行  
