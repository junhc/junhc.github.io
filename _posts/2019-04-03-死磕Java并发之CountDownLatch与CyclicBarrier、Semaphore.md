---
layout: post
title: "死磕Java并发之CountDownLatch与CyclicBarrier、Semaphore"
date: 2019-04-03 14:32:48
description: "死磕Java并发之CountDownLatch与CyclicBarrier、Semaphore"
categories:
- 并发编程
permalink: 死磕Java并发之CountDownLatch与CyclicBarrier、Semaphore
---

##### 等待多线程完成的`CountDownLatch`
> CountDownLatch一般用于某个线程A等待若干个其他线程执行完任务之后，它才执行

```vim
public class CountDownLatchCase {

    public static void main(String[] args) {
        final CountDownLatch latch = new CountDownLatch(2);

        threadStart(latch);

        threadStart(latch);

        try {
            System.out.println("等待2个子线程执行完毕...");
            latch.await();
            System.out.println("2个子线程已经执行完毕");
            System.out.println("继续执行主线程");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    static void threadStart(final CountDownLatch latch) {
        new Thread() {
            @Override
            public void run() {
                try {
                    System.out.println("子线程" + Thread.currentThread().getName() + "正在执行");
                    Thread.sleep(3000);
                    System.out.println("子线程" + Thread.currentThread().getName() + "执行完毕");
                    latch.countDown();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }.start();
    }
}
```

##### 同步屏障`CyclicBarrier`
> CyclicBarrier一般用于一组线程互相等待至某个状态，然后这一组线程再同时执行

```vim
public class CyclicBarrierCase {

    public static void main(String[] args) {
        int N = 4;
        CyclicBarrier barrier = new CyclicBarrier(N, new Runnable() {
            @Override
            public void run() {
                System.out.println("当前线程" + Thread.currentThread().getName());
            }
        });

        for (int i = 0; i < N; i++) {
            new Writer(barrier).start();
        }

        try {
            Thread.sleep(25000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        System.out.println("CyclicBarrier重用");

        for (int i = 0; i < N; i++) {
            new Writer(barrier).start();
        }
    }

    static class Writer extends Thread {

        private CyclicBarrier cyclicBarrier;

        public Writer(CyclicBarrier cyclicBarrier) {
            this.cyclicBarrier = cyclicBarrier;
        }

        @Override
        public void run() {
            System.out.println("线程" + Thread.currentThread().getName() + "正在写入数据...");
            try {
                Thread.sleep(5000);      //以睡眠来模拟写入数据操作
                System.out.println("线程" + Thread.currentThread().getName() + "写入数据完毕，等待其他线程写入完毕");
                cyclicBarrier.await();
            } catch (InterruptedException e) {
                e.printStackTrace();
            } catch (BrokenBarrierException e) {
                e.printStackTrace();
            }
            System.out.println("所有线程写入完毕，继续处理其他任务...");
        }
    }
}
```

##### `CyclicBarrier`与`CountDownLatch`的区别
> CountDownLatch的计数器只能使用一次，而CyclicBarrier的计数器可以使用reset()方法重置。

##### 控制并发线程数的`Semaphore`(信号量)
> Semaphore是用来控制同时访问特定资源的线程数量，它通过协调各个线程，以保证合理的使用公共资源。

```vim
public class SemaphoreCase {

    public static void main(String[] args) {
        // 工人数
        int N = 8;
        // 机器数目
        Semaphore semaphore = new Semaphore(5);
        for (int i = 1; i <= N; i++) {
            new Worker(i, semaphore).start();
        }
    }

    static class Worker extends Thread {

        private int num;
        private Semaphore semaphore;

        public Worker(int num, Semaphore semaphore) {
            this.num = num;
            this.semaphore = semaphore;
        }

        @Override
        public void run() {
            try {
                semaphore.acquire();
                System.out.println("工人" + this.num + "占用一个机器在生产...");
                Thread.sleep(2000);
                System.out.println("工人" + this.num + "释放出机器");
                semaphore.release();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```

##### 线程间交换数据的`Exchanger`
