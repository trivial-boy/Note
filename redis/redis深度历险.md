## redis 基本数据结构

共五种基本数据结构

- string （字符串）
- list （列表）
- hash（字典）
- set（集合）
- zset（有序列表）

### string（字符串）

string 是redis最简单的数据结构，它的内部表示就是一个 **字符数组**。

字符串结构使用非常广泛，一个常见的用途就是缓存用户信息。将用户信息结构体使用JSON序列化成字符串，然后将序列化后的字符串塞进Redis来缓存。

Redis 的字符串是动态字符串，是可以修改的字符串，内部结构的实现类似于java的ArrayList，采用预分配冗余空间的方式来减少内存的频繁分配。

如下图所示，内部为当前字符串分配的实际空间capacity 一般要高于实际字符串长度len。**当字符串长度小于1MB 时，扩容都是加倍现有的空间。如果字符串超过1MB，扩容一次只会多扩1MB的空间。字符串最大长度为512MB。**

### list（列表）

Redis 的 列表相当于java里面的LinkedList，注意它是链表而不是数组。这意味着list的插入和删除操作非常快，时间复杂度为O(1)，但是索引定位很慢，时间复杂度为O(n)。其数据结构如图所示，每个元素使用双向指针，串起来可以同时支持前向后向遍历。

![image-20220917095940332](https://img.trivial.top/img/image-20220917095940332.png)

#### 右边进左边出 （队列）

![image-20220917102530960](https://img.trivial.top/img/image-20220917102530960.png)

#### 右边进右边出（栈）

```shell
> rpush books python java golang
(integer) 3
> rpop books 
"golang"
> rpop books
"java"
> rpop books
"python"
> rpop books
(nil)
```

#### 慢操作

- lindex 相当于 java 链表的 get(int index) 方法，它需要对链表进行遍历，性能随着参数index增大而变差。

- ltrim 的两个参数 start_index 和 end_index 定义了一个区间，在这个区间内的值，ltrim 要保留，区间之外的则砍掉，可以通过ltrim来实现一个定长的链表。

index 可以为负数，index = -1  表示倒数第一个元素，同理 index = -2 表示倒数第二个元素。

```shell
> rpush books python java golang 
(integer) 3 
> lindex books 1    # O(n) 慎用
”java"
> lrange books 0 -1 # 获取所有元素， 
1) ”python” 
2) ”java" 
3) ”golang” 
> ltrim books 1 -1  # O(n)慎用
OK 
> lrange books 0 -1 
1) ”java” 
2) ”golang” 
> ltrim books 1 0  # 这其实是清空了整个列表 因为区间范围长度为负
OK 
> llen books 
(integer) 0
```

#### 快速列表

如果再深入一点，你会发现Redis底层储存的不是一个简单的linkedlist，而是称之为“快速列表” 的一个结构

首先在列表元素较少的情况下，会使用一块连续的内存存储，这个结构是ziplist，即压缩列表。它将所有的元素彼此紧挨着一起储存，分配的是一块连续的内存。当数据量比较多的时候才会改成 quicklist。因为普通的链表需要的附加指针空间太大，会浪费空间，还会加重内存的碎片化。比如普通链表存的知识int类型的数据，结构上还需要两个额外的指针prev和next。所以Redis将链表和ziplist结合起来组成了quicklist，也就是将多个ziplist使用双向指针串起来使用。

![image-20220917104632903](https://img.trivial.top/img/image-20220917104632903.png)

### hash （字典）

Redis的字典相当于 java语言里面的HashMap，它是无序字典，内部存储了很多键值对。实现结构上与java的HashMap 也是一样的，都是 “数组+链表” 二维结构。如图，第一维hash的数组位置碰撞时，就会将碰撞的元素使用链表串接起来。

![image-20220917105326605](https://img.trivial.top/img/image-20220917105326605.png)

​	不同的是，Redis 的字典的值只能是字符串，另外它们rehash 的方式不一样，因为java的 HashMap在字典很大时，rehash是个耗时的操作，需要一次性全部rehash。Redis未来追求高性能，不能堵塞服务，所以采用了**渐进式rehash策略。**

​	渐进式rehash 会在rehash的同时，保留新旧两个hash结构，查询时会同时查询两个hash结构，然后再后续的定时任务以及hash操作指令中，循序渐进地将旧hash的内容一点点地迁移到新的hash结构中。当搬迁完成，就会使用新的hash结构取而代之

![image-20220917105911302](https://img.trivial.top/img/image-20220917105911302.png)



hash结构也可以用来存储用户信息，与字符串需要一次性全部序列化整个对象不同，hash可以对用户结构中的每个字段单独存储。这样当我们需要获取用户信息时可以进行部分获取。而以真个字符串形式去保存用户信息的话，就只能一次性全部读取，这样就会浪费网络流量。

hash 也有缺点，hash结构的存储消耗要高于单个字符串，到底使用hahs还是字符串，需要根据实际情况权衡。

```shell
> hset books java "think in java"
(integer) 1
> hset books golang "concurrency in go"
(integer) 1
> hgetall books
1) "java"
2) "think in java"
3) "golang"
4) "concurrency in go"
5) "python"
6) "python cookbook"
> hlen books
(integer) 3
> hget books java
"think in java"
> hset books golang "learning go programming" 
(integer) 0
> hget books golang
"learning go programming"
> hmset books java "effective java" python "learning python" # 批量set
golang "modern golang programming"
OK
```

同字符串一样，hash结构中的单个子key也可以计数，它对应的指令是hincrby，和incr 的使用方法基本一致

```
> hset user-laoqian age 29
(integer) 1
> hincrby user-laoqian age 1
(integer) 30
```

### set (集合)

Redis 的集合相当于java语言里面的 HashSet，它内部的键值对是无序的、唯一的。它的内部实现相当于一个特殊的字典，字典所有的value都是一个值NULL。

当集合最终最后一个元素被移出之后，数据结构被自动删除，内存被回收。

set结构可以用来存储在某种活动中中奖的用户ID，因为有去重功能，可以保证同一个用户不会中奖两次。

```shell
> sadd books python
(integer) 1
> sadd books python # 重复
(integer) 0
> sadd books java golang
(integer) 2
> smembers books # 注意顺序，和插入的并不一致，因为 set 是无序的
1) "java"
2) "python"
3) "golang"
> sismember books java 
(integer) 1
> sismember books rust
(integer) 0
> scard books  # 获取长度 相当于 count()
(integer) 3
> spop books   # 弹出一个
"java"
```

### **zset（有序列表）**

zset 可能是Redis 提供的最有特色的数据结构。它类似于java的SortedSet 和 HashMap 的结合体，一方面它是一个set，保证了内部value的唯一性，另一方面它可以给每一个value赋予一个score，代表这个value的排序权重。它的内部实现用的是一种叫作“跳跃列表” 的数据结构。

zset 中最后一个value 被移出后，数据结构被自动删除，内存被回收。

zset 可以用来存储粉丝列表，value是粉丝的用户ID，score是关注事件。我们可以对粉丝列表按关注事件进行排序。

zset 还可以用来存储学生的成绩，value值是学生的ID，score是他的考试成绩。我们对成绩按分数进行排序就可以得到他的名次。

```shell
> zadd books 9.0 "think in java"
(integer) 1
> zadd books 8.9 "java concurrency"
(integer) 1
> zadd books 8.6 "java cookbook"
(integer) 1
> zrange books 0 -1
1) "java cookbook"
2) "java concurrency"
3) ”think in java”
> zreverange books 0 -1  # 按score 逆序列出，参数区间为排名范围
1) “think in java”
2) "java concurrency"
3) "java cookbook"
> zcard books # 相当于 count()
(integer) 3
> zscore books "java concurrency" # 获取指定 value 的score
”8.9000000000000004”  # 内部score 使用 double 类型进行存储，所以存在小数点精度问题
> zrank books "java concurrency" # 排名
(integer) 1
> zrangebyscore books 0 8.91   # 根据分支区间遍历 zset
1） "java cookbook"
2) "java concurrency"
> zrangebyscore books -inf 8.91 withscores # 根据分值区间 (-∞，8.91] 遍历zset，同时返回分值，inf 代表 infinite，无穷大的意思。
1) "java cookbook"
2) "8.599999999999999996"
3) "java concurrency"
4) "8.900000000000000004"
> zrem books "java concurrency"
(integer) 1
> zrange books 0 -1
1) "java cookbook"
2) "think in java"
```

#### 跳跃列表

zset 内部的排序功能是通过 “跳跃列表“ 数据结构来实现的。



## 布隆过滤器 

布隆过滤器可以理解为一个不精确的set结构。当布隆过滤器说某个值存在时，这个值可能不存在；当它说某个值不存在时，那就肯定不存在。

布隆过滤器两个基本指令：bf.add 和 bf.exists。 bf.add 添加元素，bf.exists 查询元素是否存在。

bf.add 只能一次添加一个元素，如果想要一次添加多个，就需要用到bf.madd 指令。

判断多个元素是否存在 bf.mexists。

### **布隆过滤器基本用法**

```
127.0.0.1:6379> bf.add codehole userl 
(integer) 1 
127.0.0.1:6379> bf.add codehole user2 
(integer) 1 
127.0.0.1:6379> bf.add codehole user3 
(integer) 1 
127.0.0.1:6379> bf.exists codehole userl 
(integer) 1 
127.0.0.1:6379> bf.exists codehole user2 
(integer) 1 
127.0.0.1:6379> bf.exists codehole user3 
(integer) 1 
127.0.0.1:6379> bf.exists codehole user4 
(integer) 0 
127.0.0.1:6379> bf.madd codehole user4 user5 user6 
1) (integer) 1 
2) (integer) 1 
3) (integer) 1 
127.0.0.1:6379> bf.mexists codehole user4 user5 user6 user7 
1) (integer) 1 
2) (integer) 1 
3) (integer) 1 
4) (integer) 0
```



Java 客户端 Jedis -2.x 没有提供指令扩展机制，所以你无法直接使用 Jedis 来访问Redis Module 供的 bf.xxx 指令。 RedisLabs 供了一个单独的包 JReBloom 但是

它是基于 Jedis-3.0 ，而 Jedis-3 这个包目前（截至 2018 月）还没有进入 relea se阶段 没有进入 maven 中央仓库，需要在 Github 上下载 想使用的话很不方便。

如果你怕麻烦，还可以使用 lettuce ，它是另一个 Redis 的客户端，相比 Jedis 而言，它很早就支持了指令扩展。

```java
public class BloomTest {
    public static void main(Stirng[] args) {
        Client client = new Client();
       	client.delete("codehole");
        for(int i = 0; i < 100000; i++) {
            client.add("codehole","user"+i);
            boolean ret = client.exists("codehole","user"+(i+1));
            if (!ret) {
                System.out.println(i);
                break;
            }
        }
        client.close();
    }
}
```

redis 其实还提供了自定义参数的布隆过滤器，需要我们在add 之前使用 bf.reserve 指令显式创建。如果对应的 key 已经存在， bf.reserve会报错。bf.reserv 有三个参数，分别是 key、error_rate （错误率）和 initial_size。

error_ rate 越低 需要的空间越大。

initial_size 表示预计放入的元素数量，当实际数量超出这个数值时，误判率会上升，所以需要提前设置一个较大的数值避免超出导致误判率升高。

如果不使用 bf.reserve ，默认的 error_rate 是 0.01 ，默认的 initial_size是100。

java 代码对应 bf.reserve 指令

```java
client.createFilter(”codehole”,50000,0.001);
client.add("codehole","user"+i);
```

### 注意事项

- 布隆过滤器的initial_size 设置的过大，会浪费存储空间，设置的过小，就会影响准确率。使用之前要尽可能地精确估计元素数量，还需要加上一定的冗余空间以避免时间元素可能高处估计很多。

- 布隆过滤器的 error_rate 越小，需要的存储空间就越大，对于不需要过于精确的场合， error_rate 设置稍大一点也无伤大雅。

### 布隆过滤器的原理

每个布隆过滤器对应到Redis 的数据结构里面就是一个大型的位数组和几个不一样的无偏hash函数，f、g、h就是这样的hash函数。所谓无偏就是能够把元素的hash值算的比较均匀，让元素被hash映射到位数组的位置比较随机。 

## 漏斗限流

