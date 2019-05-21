---
layout: post
title: "String与StringBuilder与StringBuffer"
date: 2017-03-31 00:00:00
description: "String与StringBuilder与StringBuffer"
categories:
- Java
permalink: /java/string_stringbuilder_stringbuffer
---

##### 目录
* [1. 深究字符串String类](#1-深究字符串string类)
* [2. StringBuilder](#2-StringBuilder)
* [3. StringBuffer](#3-StringBuffer)

##### 1. 深究字符串String类  
###### 1.1 重载运算符 “+” 与 StringBuilder 的冤缘
```vim
public class T {
    public static void main(String[] args) {
       String a = "-";
       String b = "123" + a + "456" + a + 789;
       System.out.println(b);
    }
}

// 使用JDK自带javap命令生成字节码 javap -c T.class

public class T {
  public T();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return

  public static void main(java.lang.String[]);
    Code:
       0: ldc           #2                  // String -
       2: astore_1
       3: new           #3                  // class java/lang/StringBuilder -- 编译器自动引用java.lang.StringBuilder类, 并实例化了一个StringBuilder对象
       6: dup
       7: invokespecial #4                  // Method java/lang/StringBuilder."<init>":()V
      10: ldc           #5                  // String 123 -- 每个运算符 "+" 调用一次 append 方法
      12: invokevirtual #6                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      15: aload_1
      16: invokevirtual #6                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      19: ldc           #7                  // String 456
      21: invokevirtual #6                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      24: aload_1
      25: invokevirtual #6                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      28: sipush        789
      31: invokevirtual #8                  // Method java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
      34: invokevirtual #9                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String; -- 最后调用 toString 方法, 返回String
      37: astore_2
      38: getstatic     #10                 // Field java/lang/System.out:Ljava/io/PrintStream;
      41: aload_2
      42: invokevirtual #11                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
      45: return
}

// 再看看循环使用运算符 "+"  

public class T {
    public static void main(String[] args) {
       String a = "";
       for(int i=0; i<10; i++) {
          a += i;
       }
       System.out.println(a);
    }
}

public class T {
  public T();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return

  public static void main(java.lang.String[]);
    Code:
       0: ldc           #2                  // String
       2: astore_1
       3: iconst_0
       4: istore_2
       5: iload_2 -- 循环开始..
       6: bipush        10
       8: if_icmpge     36
      11: new           #3                  // class java/lang/StringBuilder -- 每次循环都会实例化一个StringBuilder对象
      14: dup
      15: invokespecial #4                  // Method java/lang/StringBuilder."<init>":()V
      18: aload_1
      19: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      22: iload_2
      23: invokevirtual #6                  // Method java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
      26: invokevirtual #7                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
      29: astore_1
      30: iinc          2, 1
      33: goto          5  -- 跳转到第5行..
      36: getstatic     #8                  // Field java/lang/System.out:Ljava/io/PrintStream;
      39: aload_1
      40: invokevirtual #9                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
      43: return
}
```
###### 1.2. String不可变性
```vim
//String   
public final class String  
{  
  /** The value is used for character storage. */
  private final char value[];

  /** Cache the hash code for the string */
  private int hash; // Default to 0

  public String(String original) {  
    // 把原字符串original切分成字符数组并赋给value[];  
    this.value = original.value;
    this.hash = original.hash;
  }

  public String(char value[]) {
    this.value = Arrays.copyOf(value, value.length);
  }  

  public char[] toCharArray() {
   // Cannot use Arrays.copyOf because of class initialization order issues
   char result[] = new char[value.length];
   System.arraycopy(value, 0, result, 0, value.length);
   return result;
 }
}
```
> 如上代码所示，可以观察到以下设计细节  
> 1. String类被final修饰，不可继承  
> 2. String内部所有成员变量都设为私有  
> 3. 不存在value的setter方法  
> 4. value设为final  
> 5. 当传入可变数组value[]时，使用Arrays.copayOf复制给内部变量
> 6. 获取value时，不是直接返回对象引用，而是返回对象的拷贝

###### 1.3. String不可变性的优缺点
> 优点  
> 1. 字符串常量池，避免每次都重新创建相同的对象、节省存储空间。    
> 2. 线程安全，同一个字符串对象可以背多个线程共享。  
> 3. 类加载器使用到字符串，不可变性提供了安全性，以便正确的类被加载。  
> 4. 支持hash隐射和缓存，字符串的hashcode在它创建的时候就被缓存了，不需要重新计算，这使得字符串很适合作为Map中的键。    
>
> 缺点  
> 1. 如果对String对象的值进行改变，那么会创建大量的String对象

###### 1.4. String对象是否真的不可变
> 虽然String对象将value设置为final，并且还通过各种机制保证其成员变量的不可变，但是可以通过反射机制的手段改变其值。

```vim
//创建字符串"Hello World"， 并赋给引用s
String s = "Hello World";
System.out.println("s = " + s); //Hello World

//获取String类中的value字段
Field valueFieldOfString = String.class.getDeclaredField("value");
//改变value属性的访问权限
valueFieldOfString.setAccessible(true);

//获取s对象上的value属性的值
char[] value = (char[]) valueFieldOfString.get(s);
//改变value所引用的数组中的第5个字符
value[5] = '_';
System.out.println("s = " + s);  //Hello_World
```

##### 2. StringBuffer与StringBuilder的线程安全性问题
> StringBuffer和StringBuilder可以算是双胞胎了，这两者的方法没有很大区别。但在线程安全性方面，StringBuffer允许多线程进行字符操作。这是因为在源代码中StringBuffer的很多方法都被关键字`synchronized`修饰了，而StringBuilder没有。

##### 3. String和StringBuffer的效率问题
```vim
// 测试代码位置1  
long beginTime = System.currentTimeMillis();
for (int i = 0; i < 10000; i++) {
    // 测试代码位置2  
}
long endTime = System.currentTimeMillis();
System.out.println(endTime - beginTime);  
```

###### 3.1. String常量与String变量的"+"操作比较
> 测试①  
> 测试代码位置1 String str = "";  
> 测试代码位置2 str = "Hello" + "World";  
> 耗时: 0ms  

> 测试②  
> 测试代码位置1 String str = "", s1 = "Hello", s2 = "World";  
> 测试代码位置2 str = s1 + s2;  
> 耗时: 15ms  

> 原因：  
> 测试①的"Hello" + "World"在编译阶段就已经连接起来，形成了一个字符串常量"HelloWorld"，并指向堆中的拘留字符串对象。  
> 运行时只需要将"HelloWorld"指向的拘留字符串对象地址取出1W次，存放在局部变量str中。这确实不需要什么时间。  
> 测试②中局部变量s1和s2存放的是两个不同的拘留字符串对象的地址。然后会通过下面三个步骤完成“+连接”：  
1、StringBuilder temp=new StringBuilder(s1)，  
2、temp.append(s2);  
3、str=temp.toString();  
> 我们发现，虽然在中间的时候也用到了append()方法，但是在开始和结束的时候分别创建了StringBuilder和String对象。  
> 可想而知：调用1W次，是不是就创建了1W次这两种对象呢？不划算。

###### 3.2. String对象的"累+"连接操作与StringBuffer对象的append()累和连接操作比较
> 测试①  
> 测试代码位置1 String str = "Hello", s = "";  
> 测试代码位置2 s = s + str;  
> 耗时: 1371ms  

> 测试②  
> 测试代码位置1 String str = "Hello"; StringBuilder s = new StringBuffer();  
> 测试代码位置2 s.append(str);  
> 耗时: 0ms  

>原因：  
> 测试① 中的s=s+str，JVM会利用首先创建一个StringBuilder，并利用append方法完成s和str所指向的字符串对象值的合并操作，  
> 接着调用StringBuilder的toString()方法在堆中创建一个新的String对象，其值为刚才字符串的合并结果。而局部变量s指向了新创建的String对象。  
> 因为String对象中的value[]是不能改变的，每一次合并后字符串值都需要创建一个新的String对象来存放。  
> 循环1W次自然需要创建1W个String对象和1W个StringBuilder对象，效率低就可想而知了。  
> 测试②中s.append(str);只需要将自己的value[]数组不停的扩大来存放str即可。循环过程中无需在堆中创建任何新的对象。效率高就不足为奇了。  
