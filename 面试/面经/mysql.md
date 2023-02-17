## MYSQL 如何保证ACID

### MySQL如何保证一致性

数据库通过原子性（A）、隔离性（I）、持久性（D）来保证一致性（C）。其中一致性是目的，原子性、隔离性、持久性是手段。因此数据库必须实现AID三大特性才有可能实现一致性。

### MySQL如何保证原子性

> 利用InnoDB的undo log
>  undo log（回滚日志）记录需要回滚的日志信息，是实现原子性的关键，当事务回滚时能够撤销所有已经成功执行的sql语句

例如

1. delete一条数据的时候，就会记录这条数据的曾经的信息，回滚的时候，insert这条旧数据
2. update一条数据的时候，就会记录之前的旧值，回滚的时候，根据旧值执行update操作
3. insert一条数据的时候，就会这条记录的主键，回滚的时候，根据主键执行delete操作

undo log记录了这些回滚需要的信息，当事务执行失败或调用了rollback，导致事务需要回滚，便可以利用undo log中的信息将数据回滚到修改之前的样子。

### MySQL如何保证持久性

> 利用Innodb的redo log

Mysql修改数据的大概流程是先把磁盘上的数据加载到内存中，在内存中对数据进行修改，再刷回磁盘上。如果此时突然宕机，内存中的数据就会丢失。
 **如何解决该问题**

最直观的想法，事务提交前直接把数据写入磁盘

**这么做有什么问题**

1. 浪费资源，只修改一个页面里的一个字节，就要将整个页面刷入磁盘（一个页面16kb，每次改动都需要将16kb的内容刷入磁盘）
2. 速度慢，每个事务里可能涉及到多个数据页的修改，而这些数据可能是不相邻的，属于随机操作IO

于是，决定采用redo log解决上面的问题。当做数据修改的时候，不仅在内存中操作，还会在redo log中记录这次操作。当事务提交的时候，会将redo log日志进行刷盘(redo log一部分在内存中，一部分在磁盘上)。当数据库宕机重启的时候，会将redo log中的内容恢复到数据库中，再根据undo log和binlog内容决定回滚数据还是提交数据。

> 采用redo log的优点

redo log进行刷盘的效率要远高于数据页刷盘，具体表现如下

- redo log体积小，只记录了哪一页修改的内容，因此体积小，刷盘快
- redo log是一直往末尾进行追加，属于顺序IO。效率显然比随机IO来的快

### MySQL 如何保证隔离性

> 利用锁和MVCC机制

MVCC(Multi Version Concurrency Control)即多版本并发控制，一个行记录数据有多个版本对快照数据，这些快照数据在undo log中。
 如果一个事务读取的行正在做DELELE或者UPDATE操作，读取操作不会等行上的锁释放，而是读取该行的快照版本。

在事务隔离级别为读已提交(Read Commited)时，一个事务能够读到另一个事务已经提交的数据，是不满足隔离性的。但是当事务隔离级别为可重复读(Repeateable Read)中，是满足隔离性的。

## MVCC 原理

### 版本链

InnoDB引擎的记录中都包含 **trx_id**和 **roll_pointer** 两个隐藏列。

trx_id ：一个事物对某条聚簇索引记录进行改动时，都会把该记录的事物id赋值给trx_id

roll_pointer: 每次对某条聚簇索引记录进行改动时，对会把旧的版本写入到undo日志中，roll_pointer是该记录的指针。

每对记录进行一次改动，都会记录一条undo日志（记录改动之前的旧值）。每条undo日志也都有一个roll_pointer属性（insert没有）。通过这个属性可以将这些undo日志串成一个链表。这个链表被称为版本链，版本链的头节点就是当前记录的最新值。另外，每个版本中还包含生成该版本时对应的事物id。我们通过它就可以实现多版本并发控制（mvcc）

### 四种隔离级别的实现

**READ UNCOMMITED :**  直接读取记录的最新版本



#### Read View

事务在对该条数据进行访问时，会生成ReadView，ReadView 记录了四个比较重要的内容

m_ids: 当前系统活跃的读写事务的事务id列表。

min_trx_id: 在生成ReadView 时，当前系统中活跃的读写事物·中最小的事务id

max_trx_id:在生成ReadView时，系统应该分配给下一个事务的事务id值。 

creator_trx_id:生成该ReadView的事物的事物id

有了这个ReadView之后，在访问的时候只需按下面的步骤来判断记录的某个版本是否可见即可。

- 如果被访问版本的trx_id属性值与ReadView中的creator_trx_id值相同，意味着当前事物在访问它自己修改过的记录，所以该版本可以被当前事物访问。
- 如果被访问版本的trx_id属性值小于ReadView中的min_trx_id值，表明生成该版本的事物在当前事物生成ReadView前已经提交，所以该版本可以被当前事物访问。
- 如果被访问版本的trx_id属性值大于或等于ReadView中的max_trx_id值，表明生成该版本的事务在当前事务生成ReadView后才开启，所以该版本不可以被当前事务访问
- 如果被访问版本的trx_id属性值在ReadView的min_trx_id和max_trx_id之间，则需要判断trx_id属性值是否在m_ids列表中，如果在，说明创建ReadView时生成该版本的事物还是活跃的，该版本不可以访问；如果不在，说明创建ReadView时生成该版本的事物已经被提交，可以被访问。

如果某个版本的数据对当前事物不可见，那就顺着版本链找到下一个版本的数据，并继续执行上面的步骤来判断记录的可见性；依次类推，直到版本链中的最后一个版本。如果记录的最后一个版本也不可见，意味着该条记录对当前事务完全不可见，查询结果就不包含该记录。

#### Read COMMITED - 每次读取数据前都生成一个ReadView



#### REPEATABLE READ- 在第一次读取数据时生成一个ReadView

对于使用REPEATABLE READ 隔离级别的事物来说，只会在第一次执行查询语句时生成一个ReadView，之后的查询就不会重复生成ReadView。

### 二级索引如何实现版本控制

可以分为两步

步骤一：二级索引页面的Page Header部分有一个名为PAGE_MAX_TRX_ID的属性，其记录着修改该二级索引页面的最大事务id。当SELECT语句访问某个二级索引记录时，首先会看对应的ReadView的min_trx_id是否小于该页面的PAGE_MAX_TRX_ID。如果是，说明所有的记录对该READVIEW可见；否则就执行步骤二。

步骤二：利用二级索引记录中的主键值进行回表操作，得到对应的聚簇索引记录后再按照前面的方式找到对该ReadView可见的第一个版本，然后判断该版本对应的二级索引列的值是否与利用该二级索引查询时的值相同。如果是，就把这条记录发给客户端，否则就跳过该记录。

## InnoDB 索引分类



## MYSQL 中常见的日志

### mysql常见的日志有哪些？

mysql 中常见的日志类型主要有下面几种：

- 错误日志（error log）: 对mysql的启动、运行、关闭过程进行记录。
- 二进制日志（binary log）： 记录更改数据库数据的sql语句
- 一般查询日志（general query log）：已建立连接的客户端发给MYSQL服务器的所有SQL记录，因为SQL的量比较大，默认是不开启的，也不建议开启
- 慢查询日志（slow query log）：执行时间超过long_query_time 秒钟的查询，解决SQL慢查询问题的时候会遇到。
- 事物日志（redo 和 undo log）：redo log 是重做日志，undo log是回滚日志
- 中继日志：relay log 是复制过程中产生的日志，很多方面跟binary log差不多。不过，relay log 针对的是主从复制中的从库。

- DDL 日志：DDL语句执行的元数据操作。
- 

### 慢查询日志

慢查询日志记录了执行时间超过 long_query_time（默认是 10s）的所有查询，在我们解决 SQL 慢查询（SQL 执行时间过长）问题的时候经常会用到。

慢查询日志默认是关闭的，我们可以通过下面的命令将其开启：

```
SET GLOBAL slow_query_log=ON
```

`long_query_time` 参数定义了一个查询消耗多长时间才可以被定义为慢查询，默认是 10s，通过 `SHOW VARIABLES LIKE '%long_query_time%'`命令即可查看：

在实际项目中，慢查询日志可能会比较大，直接分析的话不太方便，我们可以借助 MySQL 官方的慢查询分析调优工具 [mysqldumpslow](https://dev.mysql.com/doc/refman/5.7/en/mysqldumpslow.html)。

### Binlog 主要记录了什么

MySQL binlog(binary log 即二进制日志文件) 主要记录了 MySQL 数据库中数据的所有变化(数据库执行的所有 DDL 和 DML 语句)。

binlog 有一个比较常见的常见就是主从复制，MYSQL主从复制依赖于binlog。另外，常见的一些同步MYSQL数据到其他数据源的工具（比如 canal）的底层一般也是依赖 binlog 。

binlog 通过追加的方式进行写入，大小没有限制。并且，我们可以通过max_binlog_size参数设置每个 binlog 文件的最大容量，当文件大小达到给定值之后，会生成新的 binlog 文件来保存日志，不会出现前面写的日志被覆盖的情况。

 
