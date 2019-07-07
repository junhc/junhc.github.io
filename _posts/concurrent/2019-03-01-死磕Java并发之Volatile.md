---
layout: post
title: "死磕Java并发之Volatile"
date: 2019-03-01 10:41:08
description: "死磕Java并发之Volatile"
categories:
- 并发编程
permalink: volatile
---

##### 1. volatile定义与实现原理
> `volatile`关键字提示线程每次从共享内存中读取变量，而不是从私有内存中读取，这样就保证了同步数据的‘可见性’。
> 但`volatile`关键字最致命的缺点是不支持原子性。   
> 如果使用恰当的话，它比`synchronized`的使用和执行成本更低，因为它不会引起线程上下文的切换和调度。  
> **Java编程语言允许线程访问共享变量，为了确保共享变量能被准确和一致地更新，线程应该确保通过排他锁单独获取这个变量。**  

###### 1.1. volatile是如何保证可见性的呢？
> 有`volatile`变量修饰的共享变量进行写操作的时候会多出`lock addl $0x0,(%rsp);`汇编代码，  
> `lock`前缀的指令在多核处理器下会引发两件事情。  
> 1) 将当前处理器缓存行的数据写回到系统内存。  
> 2) 这个写回内存的操作会使得其他CPU里缓存了该内存地址的数据无效。  

##### 2. volatile变量自增运算测试
```vim
public class VolatileTest {

    private static volatile int race = 0;

    public static void increase() {
        race++;
    }

    public static void main(String[] args) {
        Thread[] threads = new Thread[20];
        for (int i = 0; i < 20; i++) {
            threads[i] = new Thread(new Runnable() {
                @Override
                public void run() {
                    for (int j = 0; j < 10000; j++) {
                        increase();
                    }
                }
            });
            threads[i].start();
        }

        while (Thread.activeCount() > 1) {
            Thread.yield();
        }

        System.out.println(race);
    }
}
```
> 每次运行程序，输出结果都不一样，都是一个小于200000的数字，这是为什么呢？  
> 使用`javap`反编译代码  

```vim
...
public static void increase();
   Code:
      0: getstatic     #2                  // Field race:I
      3: iconst_1
      4: iadd
      5: putstatic     #2                  // Field race:I
      8: return
```
> 从字节码层面上很容易就分析出并发失败的原因了  
> 当`getstatic`指令吧`race`的值渠道操作栈顶时，`volatile`关键字保证了`race`的值在此时是正确的。  
> 但是在执行`iconst_1`、`iadd`指令的时候，其他线程可能已经把`race`的值加大了，而在操作栈顶的值就变成了过期的数据  
> 所以`putstatic`指令执行后就可能把较小的值同步回主内存之中。

##### 3. 指令重排
> `volatile`规则：`volatile`变量的写，先发生于读，这保证了`volatile`变量的可见性
