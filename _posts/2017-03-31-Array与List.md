---
layout: post
title: "Array与List"
date: 2017-03-31 00:00:00
description: "Array与List"
categories:
- java
permalink: /java/array_and_list
---

##### 目录
* [1. 关于ArrayList常见问题](#1-关于arraylist常见问题)
  * [1.1 ArrayList的扩容机制](#1-1-ArrayList的扩容机制)
  * [1.2. ArrayList是实现了基于动态数组的数据结构，因为地址连续，一旦数据存储好了，查询操作效率会比较高，但插入和删除操作时，要移动数据效率比较低](#1-2-ArrayList是实现了基于动态数组的数据结构，因为地址连续，一旦数据存储好了，查询操作效率会比较高，但插入和删除操作时，要移动数据效率比较低)
  * [1.3. 当传递ArrayList到某个方法中，或者某个方法返回ArrayList，什么时候要考虑安全隐患？如果修复呢？](#1-3-当传递ArrayList到某个方法中，或者某个方法返回ArrayList，什么时候要考虑安全隐患？如果修复呢？)
  * [1.4. 如何复制一个ArrayList到另一个ArrayList中去？](#1-4-如何复制一个ArrayList到另一个ArrayList中去？)
  * [1.5. 理解fail-fast原理](#1-5-理解fail-fast原理)
  * [1.6. 使用CopyOnWriteArrayList解决fail-fast问题](#1-6-使用CopyOnWriteArrayList解决fail-fast问题)
* [2. LinkedList](#2-linkedlist)
  * [2.1. LinkedList基于链表的数据结构，地址是任意，所以在开辟内存空间的时候不需要等一个连续的地址，对于插入和删除操作效率会比较高，但查询操作时，要移动指针效率比较低](#2-1-LinkedList基于链表的数据结构，地址是任意，所以在开辟内存空间的时候不需要等一个连续的地址，对于插入和删除操作效率会比较高，但查询操作时，要移动指针效率比较低)
* [小知识](#小知识)


##### 1. 关于ArrayList常见问题   
###### 1.1. ArrayList的扩容机制  

```vim
public class ArrayList<E> extends AbstractList<E>
        implements List<E>, RandomAccess, Cloneable, java.io.Serializable
{
    // 默认容纳大小
    private static final int DEFAULT_CAPACITY = 10;
    private static final Object[] EMPTY_ELEMENTDATA = {};
    private transient Object[] elementData;
    private int size;

    ...
    // 继承自AbstractList, 记录size变化的次数
    protected transient int	modCount;
    ...

    public ArrayList(int initialCapacity) {
        super();
        if (initialCapacity < 0)
          throw new IllegalArgumentException("Illegal Capacity: " + initialCapacity);
        this.elementData = new Object[initialCapacity];
    }

    // 当使用无参构造方法初始化ArrayList对象时，会在首次调用add方法时，生成一个长度为10的Object类型数组。
    public ArrayList() {
        super();
        this.elementData = EMPTY_ELEMENTDATA;
    }

    public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        elementData[size++] = e;
        return true;
    }

    private void ensureCapacityInternal(int minCapacity) {
        if (elementData == EMPTY_ELEMENTDATA) {
            minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
        }

        ensureExplicitCapacity(minCapacity);
    }

    private void ensureExplicitCapacity(int minCapacity) {
        modCount++;

        // overflow-conscious code
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }

    private void grow(int minCapacity) {
        // overflow-conscious code
        int oldCapacity = elementData.length;
        int newCapacity = oldCapacity + (oldCapacity >> 1);
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // minCapacity is usually close to size, so this is a win:
        elementData = Arrays.copyOf(elementData, newCapacity);
    }

    public E remove(int index) {
        rangeCheck(index);

        modCount++;
        E oldValue = elementData(index);

        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work

        return oldValue;
    }

    public boolean remove(Object o) {
        if (o == null) {
            for (int index = 0; index < size; index++)
                if (elementData[index] == null) {
                    fastRemove(index);
                    return true;
                }
        } else {
            for (int index = 0; index < size; index++)
                if (o.equals(elementData[index])) {
                    fastRemove(index);
                    return true;
                }
        }
        return false;
    }

    private void fastRemove(int index) {
        modCount++;
        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work
    }
}
```
###### 1.2. ArrayList是实现了基于动态数组的数据结构，因为地址连续，一旦数据存储好了，查询操作效率会比较高，但插入和删除操作时，要移动数据效率比较低
###### 1.3. 当传递ArrayList到某个方法中，或者某个方法返回ArrayList，什么时候要考虑安全隐患？如果修复呢？
> 如果Array在没有被复制的情况下直接被分配给成员变量，就会发生当原始的数组被改变时，传递到这个方法中的数组也会改变。

```vim
public void set(String[] array) {
  this.array = array;
}

// 修复安全隐患
public void set(String[] array) {
  if (array == null) {
    this.array = new Stringp[0];
  } else {
    this.array = Arrays.copayOf(array, array.length);
  }
}  
```

###### 1.4. 如何复制一个ArrayList到另一个ArrayList中去？
```vim
// 1. 使用`clone()`方法
ArrayList newArray = oldArray.clone();
// 2. 使用ArrayList构造方法
ArrayList newArray = new ArrayList(oldArray);
// 3. 使用Collections.copy()方法
List<String> src = new ArrayList<>();
src.add("1");
src.add("1");
src.add("1");
// 初始化一个`size = 3`的空数组，否则会报错
List<String> dest = new ArrayList<>(Arrays.asList(new String[src.size()]));
Collections.copy(dest, src);
```
###### 1.5. 理解fail-fast原理
```vim
public abstract class AbstractList<E> extends AbstractCollection<E> implements List<E> {
  ...
  //
  protected transient int modCount = 0;
  private class Itr implements Iterator<E> {

    int cursor = 0;

    int lastRet = -1;

    // 修改数的记录值
    // 每次新建Itr()对象时，都会保存新建该对象时对应的modCount
    // 以后每次遍历List中的元素时，都会比较expectedModCount与modCount是否相等
    // 若不相等，则抛出ConcurrentModificationException异常，产生fail-fast事件
    int expectedModCount = modCount;

    public boolean hasNext() {
        return cursor != size();
    }

    public E next() {
        // 获取下一个元素之前，都会判断“新建Itr对象时保存的modCount”和“当前的modeCount”是否相等
        checkForComodification();
        try {
            int i = cursor;
            E next = get(i);
            lastRet = i;
            cursor = i + 1;
            return next;
        } catch (IndexOutOfBoundsException e) {
            checkForComodification();
            throw new NoSuchElementException();
        }
    }

    public void remove() {
        if (lastRet < 0)
            throw new IllegalStateException();
        checkForComodification();

        try {
            AbstractList.this.remove(lastRet);
            if (lastRet < cursor)
                cursor--;
            lastRet = -1;
            expectedModCount = modCount;
        } catch (IndexOutOfBoundsException e) {
            throw new ConcurrentModificationException();
        }
    }

    final void checkForComodification() {
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
    }
  }
}  
```

###### 1.6. 使用CopyOnWriteArrayList解决fail-fast问题

##### 2. LinkedList  
###### 2.1. LinkedList基于链表的数据结构，地址是任意，所以在开辟内存空间的时候不需要等一个连续的地址，对于插入和删除操作效率会比较高，但查询操作时，要移动指针效率比较低
```vim
public class LinkedList<E>
    extends AbstractSequentialList<E>
    implements List<E>, Deque<E>, Cloneable, java.io.Serializable
{
    transient int size = 0;
    // Pointer to first node.
    transient Node<E> first;
    // Pointer to last node.
    transient Node<E> last;

    private static class Node<E> {
        E item;
        Node<E> next;
        Node<E> prev;

        Node(Node<E> prev, E element, Node<E> next) {
            this.item = element;
            this.next = next;
            this.prev = prev;
        }
    }

    /**
     * Links e as first element.
     */
    private void linkFirst(E e) {
        final Node<E> f = first;
        final Node<E> newNode = new Node<>(null, e, f);
        first = newNode;
        if (f == null)
            last = newNode;
        else
            f.prev = newNode;
        size++;
        modCount++;
    }

    /**
     * Links e as last element.
     */
    void linkLast(E e) {
        final Node<E> l = last;
        final Node<E> newNode = new Node<>(l, e, null);
        last = newNode;
        if (l == null)
            first = newNode;
        else
            l.next = newNode;
        size++;
        modCount++;
    }

    /**
     * Returns the element at the specified position in this list.
     *
     * @param index index of the element to return
     * @return the element at the specified position in this list
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    public E get(int index) {
        checkElementIndex(index);
        return node(index).item;
    }

    /**
     * Returns the (non-null) Node at the specified element index.
     */
    Node<E> node(int index) {
        // assert isElementIndex(index);

        if (index < (size >> 1)) {
            Node<E> x = first;
            for (int i = 0; i < index; i++)
                x = x.next;
            return x;
        } else {
            Node<E> x = last;
            for (int i = size - 1; i > index; i--)
                x = x.prev;
            return x;
        }
    }

    public E remove(int index) {
        checkElementIndex(index);
        return unlink(node(index));
    }

     /**
     * Unlinks non-null node x.
     */
    E unlink(Node<E> x) {
        // assert x != null;
        final E element = x.item;
        final Node<E> next = x.next;
        final Node<E> prev = x.prev;

        if (prev == null) {
            first = next;
        } else {
            prev.next = next;
            x.prev = null;
        }

        if (next == null) {
            last = prev;
        } else {
            next.prev = prev;
            x.next = null;
        }

        x.item = null;
        size--;
        modCount++;
        return element;
    }    
}
```

##### 小知识
```vim
public final class System {
   /**
   * 源数组中位置在 srcPos 到 srcPos+length-1 之间的元素被复制到目标数组中的 destPos 到 destPos+length-1 位置.
   * @param      src      源数组.
   * @param      srcPos   源数组中的起始位置, 若 srcPos+length 大于 src.length，则抛出 IndexOutOfBoundsException 异常
   * @param      dest     目标数组.
   * @param      destPos  目标数组中的起始位置, 若 destPos+length 大于 dest.length，则抛出 IndexOutOfBoundsException 异常
   * @param      length   要复制的数组元素的数量.
   */
   public static void arraycopy(Object src, int srcPos, Object dest, int destPos, int length){}
}
```
