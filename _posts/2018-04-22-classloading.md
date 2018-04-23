---
layout: post
title: "虚拟机类加载机制"
date: 2018-04-21 14:32:48
description: "虚拟机类加载机制"
categories:
- jvm
permalink: classloading
---

### 目录
* [加载](#加载)
* [验证](#验证)
* [准备](#验证)
* [解析](#验证)
* [初始化](#初始化)
* [使用](#使用)
* [卸载](#卸载)

> 类从被加载到虚拟机内存中开始，到卸载出内存为止，它的整个生命周期包括：加载、验证、准备、解析、初始化、使用和卸载7个阶段，
其中验证、准备、解析3个部分称为连接。

#### 加载
1. 通过一个类的全限定名来获取定义此类的二进制字节流  
2. 将这个字节流所代表的静态存储结构转换为方法去的运行时数据结构  
3. 在内存中生成一个代表这个类的 java.lang.Class 对象，作为方法区这个类的各种数据的访问入口

#### 初始化
1. 遇到new、getstatic、putstatic或invokestatic这4条字节码指令时，如果类没有经过初始化，则需要先触发其初始化。最常见的Java代码场景是：使用new关键字实例化对象的时候、读取或设置一个类的静态字段（被final修饰、已在编译期把结果放入常量池的静态字段除外）的时候，以及调用一个类的静态方法的时候。  
2. 使用java.lang.reflect包的方法对类进行反射调用的时候。  
3. 当初始化一个类的时候，如果发现其父类还没有进行过初始化，则需要先触发其父类的初始化。  
4. 当虚拟机启动时，用户需要制定一个执行的主类（包含main()方法的那个类），虚拟机会先初始化这个主。
5. 当使用JDK1.7的动态语言支持时，如果一个java.lang.invoke.MethodHandle实例最后的解析结果REF_getStatic、REF_putStatic、REF_invokeStatic的方法句柄，并且这个方法句柄所对应的类没有进行过初始化。

```vim
public class SuperClass {

    static {
        System.out.println("SuperClass init!");
    }

    public static int value = 123;
}

public class SubClass extends SuperClass {

    static {
        System.out.println("SubClass init!");
    }
}

public class NotInitialization {

    public static void main(String[] args) {
        // 被动引用的例子之一
        // 对于静态字段，只有直接定义这个字段的类才会被初始化。
        System.out.println(SubClass.value);
        // SuperClass init!
        // 123

        // 被动引用的例子之二
        // 通过数组定义来引用类，不会触发此类的初始化
        SuperClass[] sca = new SuperClass[10];

        // 被动引用的例子之三
        // 常量在编译阶段会存入调用类的常量池，本质上并没有直接引用到定义常量的类，因此不会触发此类的初始化
        System.out.println(SuperClass.HELLO_WORLD);
        
        // 一个接口在初始化时，并不要求其父接口全部都完成初始化，只有在真正使用到父接口的时候（如引用接口中定义的常量）才会初始化。
    }
}
```
