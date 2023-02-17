### ArrayList 与 LinkedList 区别?

1. 是否保证线程安全：都不保证
2. 底层数据结构：ArrayList是数组，LinkedList 是双向链表 （jdk1.6之前是循环链表，1.7之后取消了循环）
3. 插入和删除元素是否受元素位置的影响：
   - ArrayList 插入元素时追加到列表的末尾，复杂度是O(1)。但如果是在指定位置插入和删除元素时间复杂度是O(n - i).
   - LinkedList 采用链式储存，在头尾插入或删除元素不收位置影响但如果是在指定位置插入和删除元素时间复杂度是O(n - i)。
4. 是否支持快速随机访问：ArrayList可以，LinkedList不可以
5. 内存空间占用：ArrayList的空间浪费主要体现爱list列表结尾预留一定容量空间。而LinkedList的每一个元素都需要消耗比ArrayList更多的空间。



## ArrayList 扩容机制

数组类型是Object[]

初始化 三种方式：

1. 无惨构造函数，初始化复制是一个空数组，当真正对数组进行添加元素时，才真正分配容量。（JDK1.8）JDK1.6是直接创建容量为10
2. 参数为容量，传入容量
3. 参数为collection 元素传入collection元素列表

当容量不够时，调用grow() ，每次扩容都会变为原来的1.5倍左右（oldCapacity 为偶数就是1.5倍）。

当扩容量超过Integer.MAX_VALUE 则为Integer的最大值。



## HashMap 和 HashTable 的区别

1. 是否线程安全：HashTable 安全，内部基本经过synchronized

2. 效率：HashMap效率高

3. 对Null Key 和 Null value 的支持：HashMap都支持，HashTable两个都不支持

4. 初始容量大小和每次扩容容量大小的不同：

   - 没有初始值
     - HashTable 默认值是11，之后每次扩容变为原来的2n + 1。
     - HashMap默认值是16，每次扩容，容量变为原来的2倍。

   - 有初始值
     - HashTable 使用给定的大小
     - HashMap 扩充为2的幂次方大小。

5. 底层数据结构：
   - HashMap链表没有达到阈值（ 默认为8）时，为数组加链表，达到阈值，链表转换为红黑树（转换前先判断，如果数组长度小于64，选择进行数组扩容，而不是转换为红位数）
   - HashTable 就是数组加链表。



## HashSet 和 HashMap

HashSet底层是HashMap，HashSet使用成员对象来计算hashcode值，对于两个对象来说，hashcode值可能相同，所以需要调用equals方法来判断两个对象相等。

## HashMap 底层实现

1.8之前，HashMap是数组和链表结合在一起使用的链表散列。hashcode经过key的扰动函数处理过后得到hash值，然后通过(n - 1)& hash 判断当前元素放的位置，如果当前位置存在元素的话，判断元素与要存入的元素的hash值以及key是否相同，如果相同，直接覆盖，不相同就通过拉链法解决冲突。

扰动函数就指的HashMap的hash方法，使用扰动函数可以减少hash碰撞。



1.8之后，当链表长度大于阈值（默认为8）（转换前会先判断，如果数组长度小于64，会选择进行数组扩容，而不是转为红黑树）时，将链表转换为红黑树，减少搜索时间。

## HashMap的长度为什么是2的幂次方

为了让HashMap存取更高效，尽量减少碰撞，把数据分布均匀。Hash值的范围是-2^32 到 2^32 - 1，在计算对应数组存放的位置时需要对数组的长度进行取模运算，也就是  hash % length ，但是，**取余(%)操作中如果除数是 2 的幂次则等价于与其除数减一的与(&)操作（也就是说 hash%length==hash&(length-1)的前提是 length 是 2 的 n 次方；）** 采用二进制位操作& 相对于 % 能提高运算效率。



## HashMap 多线程操作导致死循环问题

并发下的 Rehash 会造成元素之间会形成一个循环链表。不过，jdk 1.8 后解决了这个问题，但是还是不建议在多线程下使用 HashMap,因为多线程下使用 HashMap 还是会存在其他问题比如数据丢失。



### ConcurrentHashMap

**JDK1.7 的 ConcurrentHashMap** ：

![Java7 ConcurrentHashMap 存储结构](https://guide-blog-images.oss-cn-shenzhen.aliyuncs.com/github/javaguide/java/collection/java7_concurrenthashmap.png)

`ConcurrentHashMap` 是由 `Segment` 数组结构和 `HashEntry` 数组结构组成。

`Segment` 数组中的每个元素包含一个 `HashEntry` 数组，每个 `HashEntry` 数组属于链表结构。

在 JDK1.7 的时候，`ConcurrentHashMap` 对整个桶数组进行了分割分段(`Segment`，分段锁)，每一把锁只锁容器其中一部分数据（下面有示意图），多线程访问容器里不同数据段的数据，就不会存在锁竞争，提高并发访问率。

首先将数据分为一段一段（这个“段”就是 `Segment`）的存储，然后给每一段数据配一把锁，当一个线程占用锁访问其中一个段数据时，其他段的数据也能被其他线程访问。

**`ConcurrentHashMap` 是由 `Segment` 数组结构和 `HashEntry` 数组结构组成**。

`Segment` 继承了 `ReentrantLock`,所以 `Segment` 是一种可重入锁，扮演锁的角色。`HashEntry` 用于存储键值对数据。

一个 `ConcurrentHashMap` 里包含一个 `Segment` 数组，`Segment` 的个数一旦**初始化就不能改变**。 `Segment` 数组的大小默认是 16，也就是说默认可以同时支持 16 个线程并发写。

`Segment` 的结构和 `HashMap` 类似，是一种数组和链表结构，一个 `Segment` 包含一个 `HashEntry` 数组，每个 `HashEntry` 是一个链表结构的元素，每个 `Segment` 守护着一个 `HashEntry` 数组里的元素，当对 `HashEntry` 数组的数据进行修改时，必须首先获得对应的 `Segment` 的锁。也就是说，对同一 `Segment` 的并发写入会被阻塞，不同 `Segment` 的写入是可以并发执行的。



![Java8 ConcurrentHashMap 存储结构](https://guide-blog-images.oss-cn-shenzhen.aliyuncs.com/github/javaguide/java/collection/java8_concurrenthashmap.png)

到了 JDK1.8 的时候，`ConcurrentHashMap` 已经摒弃了 `Segment` 的概念，而是直接用 `Node` 数组+链表+红黑树的数据结构来实现，并发控制使用 `synchronized` 和 CAS 来操作。（JDK1.6 以后 `synchronized` 锁做了很多优化） 整个看起来就像是优化过且线程安全的 `HashMap`，虽然在 JDK1.8 中还能看到 `Segment` 的数据结构，但是已经简化了属性，只是为了兼容旧版本；

`ConcurrentHashMap` 取消了 `Segment` 分段锁，采用 `Node + CAS + synchronized` 来保证并发安全。数据结构跟 `HashMap` 1.8 的结构类似，数组+链表/红黑二叉树。Java 8 在链表长度超过一定阈值（8）时将链表（寻址时间复杂度为 O(N)）转换为红黑树（寻址时间复杂度为 O(log(N))）。

Java 8 中，锁粒度更细，`synchronized` 只锁定当前链表或红黑二叉树的首节点，这样只要 hash 不冲突，就不会产生并发，就不会影响其他 Node 的读写，效率大幅提升。