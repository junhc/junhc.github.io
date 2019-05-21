---
layout: post
title: "虚拟机类加载机制"
date: 2019-04-04 14:32:48
description: "虚拟机类加载机制"
categories:
- JVM
permalink: classloader-topic
---

```vim
public class StaticTest {

    public static void main(String[] args) {
        // 类的准备阶段
        // 类的初始化阶段
        staticFunc();
    }

    static StaticTest st = new StaticTest();

    static {
        System.out.println("1");
    }

    {
        System.out.println("2");
    }

    StaticTest() {
        System.out.println("3");
        System.out.println("a=" + a + ",b=" + b);
    }

    public static void staticFunc() {
        System.out.println("4");
        //System.out.println("b=" + b);
    }

    int a = 100;
    static int b = 200;
}
//输出结果如下
2
3
a=100,b=0
1
4
```
