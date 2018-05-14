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
* [类加载器](#类加载器)
* [双亲委派模型](#双亲委派模型)

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

#### 类加载器
> 对于任意一个类，都需要由加载它的类加载器和这个类本身一同确立其在Java虚拟机中的唯一性，每一个类加载器，都拥有一个独立的类命名空间。

```vim
public class ClassLoaderTest {
    public static void main(String[] args) throws Exception {
        // 构造一个简单的类加载器
        ClassLoader myClassLoader = new ClassLoader() {
            @Override
            public Class<?> loadClass(String name) throws ClassNotFoundException {
                try {
                    String filename = name.substring(name.lastIndexOf(".") + 1) + ".class";
                    InputStream is = getClass().getResourceAsStream(filename);
                    if (is == null) {
                        return super.loadClass(name);
                    }
                    byte[] bytes = new byte[is.available()];
                    is.read(bytes);
                    return defineClass(name, bytes, 0, bytes.length);
                } catch (IOException e) {
                    throw new ClassNotFoundException(name);
                }
            }
        };
        // 使用自定义类加载器实例化类 "com.junhc.ClassLoaderTest" 对象
        Object o = myClassLoader.loadClass("com.junhc.ClassLoaderTest").newInstance();
        System.out.println(o.getClass());
        // 虚拟机中存在两个 ClassLoaderTest 类，一个是由系统应用程序类加载器加载的，另外一个由
        // 我们自定义的类加载的，虽然都来自同一个class文件，但依然是两个独立的类，做对象所属类型
        // 检查时结果为false
        System.out.println(o instanceof com.junhc.ClassLoaderTest);
    }
}

//class com.junhc.ClassLoaderTest
//false

```

#### 双亲委派模型
> ▣ 启动类加载器 (Bootstarp ClassLoader): 这个类将负责存放在 `<JAVA_HOME>\lib` 目录中的，或者被 `-Xbootclasspath` 参数所指定的路径中，并且虚拟机识别的类库加载到虚拟机内存中。启动类加载器无法被Java程序直接饮用，用户在编写自定义类加载器时，如果需要吧加载请求委派给引导类加载器，那么直接使用null代替即可。

> ▣ 扩展类加载器 (Extension ClassLoader): 这个加载器由 `sum.misc.Launcher$ExtClassLoader` 实现，它负责加载 `<JAVA_HOME>\lib\ext` 目录中的，或者被java.ext.dirs系统变量所指定的路径中的所有类库，开发者可以直接使用扩展类加载器。

> ▣ 应用程序类加载器 (Application ClassLoader): 这个类加载由 `sum.misc.Launcher$AppClassLoader` 实现。由于这个类加载器是 CLassLoader 中的 getSystemClassLoader() 方法的返回值，所以一般也称它为系统类加载器。它负责加载用户类路径 `classpath` 上所指定的类库，开发者可以直接使用这个类加载器，一般情况下这个就是程序中默认的类加载器。

> 除此之外，还有自定义的类加载器，它们之间的层次关系被称为类加载器的双亲委派模型。该模型要求除了顶层的启动类加载器外，其余的类加载器都应该有自己的父类加载器，而这种父子关系一般通过组合（Composition）关系来实现，而不是通过继承（Inheritance）。

> 双亲委派模型的工作过程: 如果一个类加载器收到了类加载的请求，它首先不会自己去尝试加载这个类，而是把这个请求委派给父类加载器去完成，每一个层次的类加载器都是如此，因此所有的加载请求最终都应该传送到的顶层的启动类加载器中，只有当父加载器反馈自己无法完成这个加载请求 (它的搜索范围中没有找到所需的类) 时，子加载器才会尝试自己去加载。  
使用双亲委派模型来组织类加载器之间的关系，有一个显而易见的好处就是Java类随着它的类加载器一起具备了一种带有优先级的层次关系。

```vim
protected Class<?> loadClass(String name, boolean resolve)
    throws ClassNotFoundException
{
    synchronized (getClassLoadingLock(name)) {
        // 首先，检查请求的类是否已经加载过了
        Class c = findLoadedClass(name);
        if (c == null) {
            long t0 = System.nanoTime();
            try {
                if (parent != null) {
                    c = parent.loadClass(name, false);
                } else {
                    c = findBootstrapClassOrNull(name);
                }
            } catch (ClassNotFoundException e) {
                // 如果父类加载器抛出 ClassNotFoundException
                // 说明父类加载器无法完成加载请求
            }

            if (c == null) {
                // 在父类加载器无法加载的时候
                // 再调用本身的 findClass 方法进行类加载
                long t1 = System.nanoTime();
                c = findClass(name);

                // this is the defining class loader; record the stats
                sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                sun.misc.PerfCounter.getFindClasses().increment();
            }
        }
        if (resolve) {
            resolveClass(c);
        }
        return c;
    }
}
```

