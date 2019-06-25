---
layout: post
title: "死磕Java并发之Synchronized"
date: 2019-03-01 10:41:08
description: "死磕Java并发之Synchronized"
categories:
- 并发编程
permalink: synchronized
---

##### Synchronized的实现原理与应用
> `synchronized`实现同步的基础：Java中的每一个对象都可以作为锁，具体表现为以下3中形式。

* 对于普通同步方法，锁是当前实例对象。
```vim
public class SynchronizedTest {

    Object lock = new Object();

    /**
     * 形式1
     */
    public synchronized void one() {
        perfectPrint("one");
    }

    /**
     * 形式2,作用域等同于形式1
     */
    public void two() {
        synchronized (lock) {
            perfectPrint("two");
        }
    }

    /**
     * 形式3，作用域等同于前面两种
     */
    public void three() {
        synchronized (this) {
            perfectPrint("three");
        }
    }

    public void perfectPrint(String s) {
        System.out.println(Thread.currentThread().getId() + ":" + s);
        try {
            Thread.sleep(3000L);
        } catch (InterruptedException e) {

        }
    }

    public static void main(String[] args) {
        final SynchronizedTest s1 = new SynchronizedTest();
        Thread t1 = new Thread(new Runnable() {
            @Override
            public void run() {
                s1.one();
            }
        });
        Thread t2 = new Thread(new Runnable() {
            @Override
            public void run() {
                s1.two();
            }
        });
        Thread t3 = new Thread(new Runnable() {
            @Override
            public void run() {
                s1.three();
            }
        });
        t1.start();
        t2.start();
        t3.start();
    }
}
```
* 对于静态同步方法，锁是当前类的Class对象。
```vim
public class SynchronizedTest {

    static Object lock = new Object();

    /**
     * 形式1
     */
    public synchronized static void one() {
        perfectPrint("one");
    }

    /**
     * 形式2,作用域等同于形式1
     */
    public void two() {
        synchronized (lock) {
            perfectPrint("two");
        }
    }

    /**
     * 形式3，作用域等同于前面两种
     */
    public void three() {
        synchronized (SynchronizedTest.class) {
            perfectPrint("three");
        }
    }

    public static void perfectPrint(String s) {
        System.out.println(Thread.currentThread().getId() + ":" + s);
        try {
            Thread.sleep(3000L);
        } catch (InterruptedException e) {

        }
    }

    public static void main(String[] args) {
        final SynchronizedTest s1 = new SynchronizedTest();
        final SynchronizedTest s2 = new SynchronizedTest();
        Thread t1 = new Thread(new Runnable() {
            @Override
            public void run() {
                SynchronizedTest.one();
            }
        });
        Thread t2 = new Thread(new Runnable() {
            @Override
            public void run() {
                s1.two();
            }
        });
        Thread t3 = new Thread(new Runnable() {
            @Override
            public void run() {
                s2.three();
            }
        });
        t3.start();
        t1.start();
        t2.start();
    }
}
```
* 对于同步方法块，锁是`synchronized`括号里配置的对象。

> 当一个线程试图访问同步代码块时，它首先必须得到锁，退出或抛出异常时必须释放锁。  
> JVM基于进入和退出Monitor对象来实现方法同步和代码块同步，但两者的实现细节不一样。  
> 代码块同步：  
> `monitorenter`指令是在编译后插入到同步代码块的开始位置，
> 而`monitoerexit`指令是插入到方法结束处和异常处，JVM要保证每个`monitorenter`必须有对应的`monitorexit`与只配对。  
> 任何一个对象都有一个`monitor`与之关联，当且一个`monitor`被持有后，它将处于锁定状态。  
> 线程执行到`monitorenter`指令时，将会尝试获取对象所对应的`monitor`的所有权，即尝试获取对象的锁。  
> 方法同步：  
> 线程执行识别方法结构中`flags`字段，是否有`ACC_SYNCHRONIZED`标记，尝试获取对象的锁。  

```vim
public synchronized void commonMethod();
   descriptor: ()V
   flags: ACC_PUBLIC, `ACC_SYNCHRONIZED`
   Code:
     stack=0, locals=1, args_size=1
        0: return
     LineNumberTable:
       line 17: 0
     LocalVariableTable:
       Start  Length  Slot  Name   Signature
           0       1     0  this   Lcom/junhc/provider/demo/SynchronizedTest;

 public static synchronized void staticMehtod();
   descriptor: ()V
   flags: ACC_PUBLIC, ACC_STATIC, `ACC_SYNCHRONIZED`
   Code:
     stack=0, locals=0, args_size=0
        0: return
     LineNumberTable:
       line 21: 0

 public static void main(java.lang.String[]);
   descriptor: ([Ljava/lang/String;)V
   flags: ACC_PUBLIC, ACC_STATIC
   Code:
     stack=2, locals=3, args_size=1
        0: ldc           #2                  // class com/junhc/provider/demo/SynchronizedTest
        2: dup
        3: astore_1
        4: `monitorenter`
        5: aload_1
        6: `monitorexit`
        7: goto          15
       10: astore_2
       11: aload_1
       12: `monitorexit`
       13: aload_2
       14: athrow
       15: return

}
```

##### Java对象头
> Java对象头里的`Mark Word`里默认存储对象的`HashCode`、`分代年龄`和`锁标记位`。

|锁状态|25bit|4bit|1bit是否偏向锁|2bit锁标志位|
|:--:|:--:|:--:|:--:|:--:|
|无锁状态|对象的HashCode|对象分代年龄|0|0|

##### 锁的升级与对比
> 锁一共有4中状态，级别从低到高依次是：无锁状态、偏向锁状态、轻量级锁状态和重量级锁状态，这几个  
> 状态会随着竞争情况逐级升级。**锁可以升级但不能降级**。  

###### 偏向锁
> 当一个线程访问同步块并获取锁时，会在对象头和栈帧中的锁记录里存储锁偏向的线程ID，以后该线程在进入
和退出同步块时不需要进行[CAS](/cas#cascompare-and-swap)操作来加锁和解锁，只需简单地测试一下  
对象头里`Mark Word`里是否存储这指向当前线程的偏向锁。  
如果测试成功，表示线程已经获得了锁。如果测试失败，则需要再测试一下`Mark Word`中偏向锁的标记是否设置成1，  
如果没有设置，则使用`CAS`竞争锁，如果设置了，则尝试使用`CAS`将对象头的偏向锁指向当前线程。  
> **偏向锁使用了一种等到竞争出现才释放锁的机制。**  
> 通过JVM参数关闭偏向锁：`-XX:UseBiasedLocking=false`，那么程序默认会进入轻量级锁状态。

![](/assets/img/Synchronized源码分析.png)

##### 参考资料
* [Synchronized的源码分析](https://mp.weixin.qq.com/s/moPPjs-A4ZAUxamMMTOeKQ)
* [Synchronized原理分析](https://mp.weixin.qq.com/s/jGETAozxhmmt8qkU5O93Pw)
