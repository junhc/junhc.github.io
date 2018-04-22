---
layout: post
title: "虚拟机类加载机制"
date: 2018-04-21 14:32:48
description: "虚拟机类加载机制"
categories:
- jvm
permalink: classloading
---

> 类从被加载到虚拟机内存中开始，到卸载出内存为止，它的整个生命周期包括：加载、验证、准备、解析、初始化、使用和卸载7个阶段，
其中验证、准备、解析3个部分称为连接。

#### 初始化
1. 遇到new、getstatic、putstatic或invokestatic这4条字节码指令时，如果类没有经过初始化，则需要先触发其初始化。最常见的Java代码场景是：使用new关键字实例化对象的时候、读取或设置一个类的静态字段（被final修饰、已在编译期把结果放入常量池的静态字段除外）的时候，以及调用一个类的静态方法的时候。  
2. 使用java.lang.reflect包的方法对类进行反射调用的时候。  
3. 当初始化一个类的时候，如果发现其父类还没有进行过初始化，则需要先触发其父类的初始化。  
4. 当虚拟机启动时，用户需要制定一个执行的主类（包含main()方法的那个类），虚拟机会先初始化这个主。
5. 当使用JDK1.7的动态语言支持时，如果一个java.lang.invoke.MethodHandle实例最后的解析结果REF_getStatic、REF_putStatic、REF_invokeStatic的方法句柄，并且这个方法句柄所对应的类没有进行过初始化。
