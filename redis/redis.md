# redis笔记

## 大纲

- Nosql数据模型
- redis安装
- 五种基本数据类型
- 三种特殊数据类型
  - geo
  - hyperloglog
  - bitmap
- Redis配置详解
- Redis持久化
  - RDB
  - AOF
- Redis事物操作 ACID
- Redis实现订阅发布(消息队列 )
- Redis主从复制
- Redis哨兵模式
- 缓存穿透及解决方案
- 缓存击穿及解决方案
- 缓存雪崩及解决方案
- 基础API之Jedis详解
- Springboot集成redis操作
- Redis实战分析

## Nosql概述

![image-20210321160055311](https://gitee.com/lxsupercode/picture/raw/master/img/20210321160055.png)

 

> 2 Mechached （缓存）+mysql+垂直拆分

![image-20210321162216639](https://gitee.com/lxsupercode/picture/raw/master/img/20210321162216.png)

> 3、分库分表+ 水平拆分+MySQL集群

![image-20210321163631696](https://gitee.com/lxsupercode/picture/raw/master/img/20210321163631.png)

>  4、如今最近的年代

2010--2020十年，世界发生翻天覆地的变化（定位，也是一种数据，音乐，热榜）

 Mysql等关系数据库就不够用了！数据量很多，变化很快~ ， 

Mysql有的使用它储存一些较大的文件，博客，图片！数据库表很大，效率就低了！

如果有一种数据库专门处理这种数据，MYSQL夜里就会变得很小。大数据的IO压力下，表几乎没法更大！

> 目前一个基本的互联网项目

![image-20210321164418106](https://gitee.com/lxsupercode/picture/raw/master/img/20210321164418.png)

> 为什么要用NOSQL！

用户的个人信息，社交网络，地理位置。用户自己产生的数据，用户日志等爆发式增长！

 这时我们就需要使用NoSQL数据库，NoSQL可恶意很好的处理以上情况

### 什么是NoSQL

> NoSQL

NoSQL = Not Only SQL(不仅仅是sql)

泛指非关系型数据库，随着web2.0互联网的诞生！传统的关系型数据库很难对付web2.0时代！尤其是超大规模的高并发的社区！暴露出很多难以克服的问题，NoSQL在当今大数据环境下发展的十分迅速，Redis是发展最快的，而且是我们当下必须掌握的一门技术

很多的数据类型用户的个人信息，社交网络，地理位置。这些数据类型的储存不需要一个固定的格式！不需要多余的操作就是可以很想扩展！

Map<String,Object> 使用键值对控制！



> NoSQL 特点

解耦！

1. 方便扩展（数据之间没有关系，很好扩展）

2. 大数据量高性能

3. 数据类型多样性（不需要事先设计数据库！随取随用！如果数据量十分大的表，很多人就无法设计了）

4. 传统RDBMS和NoSQL

   ```markdown
   传统的RDBMS
   - 结构化组织
   — SQL
   - 数据和关系都存在单独的表中
   - 严格的一致性
   - 基础的事务
   ```

   ```
   NOSQL
   - 不仅仅是数据
   - 没有固定的查询语言
   - 键值对存储，列存储，文档存储，图形数据库（社交关系）
   - 最终一致性
   - CAP定理 和 BASE (异地多活) 初级架构师！
   - 高性能，高可用，高可扩展
   -...
   ```



> 了解：3V+3高

大数据时代的3V：主要是描述问题的

1. 海量Volume

2. 多样Variety
3. 实时Velocity

大数据时代的3高：主要是对程序的要求

1. 高并发
2. 高可扩（随时水平拆分）
3. 高性能
