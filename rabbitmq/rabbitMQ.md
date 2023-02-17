# 消息队列之RabbitMQ

## 消息队列介绍

@[toc](目录)

### 什么叫消息队列

- 消息队列，一般我们会简称它为MQ(Message Queue)翻译过来就是消息队列

- 消息（Message）是指在应用间传送的数据，Queue队列是一种先进先出的数据结构。

![img](https://pic1.zhimg.com/80/v2-607a5661776bdf018ed26cdfca23cf11_1440w.jpg?source=1940ef5c)

- 消息队列可以看成一个存放数据的容器，我们将传输的数据存放在队列当中。

- 消息发布者只管把数据发布到 MQ 中而不用管谁来取，消息使用者只管从 MQ 中取数据而不管是谁发布的。

### 为什么使用消息队列

我们通过模拟一些场景来告诉大家，消息队列有什么好处

[参考知乎java3y ](https://www.zhihu.com/question/54152397?sort=created)

#### 1. 解耦

现在我有一个系统A，系统A里面有一个UserId的属性， 系统A的一个方法是发送消息。

![img](https://pic2.zhimg.com/80/v2-e43cace21f924b41f03b2982632f489d_1440w.jpg?source=1940ef5c)



然后，系统A需要调用系统·B和系统C的接口去获取一些信息

![img](https://pic2.zhimg.com/80/v2-e43cace21f924b41f03b2982632f489d_1440w.jpg?source=1940ef5c)

然后，现在有系统B和系统C都需要这个`findUser()`去做相关的操作

![img](https://pic4.zhimg.com/80/v2-f8a27d712f1f95027490e5d2da4b3179_1440w.jpg?source=1940ef5c)

写成伪代码可能是这样的：

```java
public class SystemA {

    // 系统B和系统C的依赖
    SystemB systemB = new SystemB();
    SystemC systemC = new SystemC();

    // 系统A独有的数据userId
    private String userId = "Java3y";

    public void sendMessage() {

        // 系统B和系统C都需要拿着系统A的userId去获取一些信息
        systemB.getSomeInfo1(userId);
        systemC.getSomeInfo2(userId);

    }
}
```

ok，一切平安无事度过了几个天。

某一天，系统B的负责人告诉系统A的负责人，现在系统B的`getSomeInfo1(String userId)`这个接口不再使用了，**让系统A别去调它了**。

于是，系统A的负责人说"好的，那我就不调用你了。"，于是就**把调用系统B接口的代码给删掉了**：

```java
public void doSomething() {

  // 系统A不再调用系统B的接口了
  //systemB.getSomeInfo1(userId);
  systemC.SystemCNeed2do(userId);

}
```

又过了几天，系统D的负责人接了个需求，也需要用到系统A的userId，于是就跑去跟系统A的负责人说："老哥，我要用到你的userId，你调一下我的接口吧"

于是系统A说："没问题的，这就搞"

![img](https://pic1.zhimg.com/80/v2-3b3be237d7b92263c705fceea2375daa_1440w.jpg?source=1940ef5c)

然后，系统A的代码如下：

```java
public class SystemA {

    // 已经不再需要系统B的依赖了
    // SystemB systemB = new SystemB();

    // 系统C和系统D的依赖
    SystemC systemC = new SystemC();
    SystemD systemD = new SystemD();

    // 系统A独有的数据
    private String userId = "Java3y";

    public void doSomething() {


        // 已经不再需要系统B的依赖了
        //systemB.getSomeInfo1(userId);

        // 系统C和系统D都需要拿着系统A的userId去操作其他的事
        systemC.getSomeInfo2(userId);
        systemD.getSomeInfo3(userId);

    }
}
```

那这样下去每有一个人需用用A的userId,	我们就需要改一次系统A的代码，而且不仅如此，如果在调用系统C的时候，系统C挂了，系统A还得想办法处理。如果调用系统D时，由于网络延迟，请求超时了，那系统A是反馈`fail`还是重试？

然后有人跟系统A的负责人说**将系统A的userId写到消息队列中，这样系统A就不用经常改动了**。

![img](https://pic2.zhimg.com/80/v2-8b6b8046286c88206fa144136f803af3_1440w.jpg?source=1940ef5c)

系统A将userId写到消息队列中，系统C和系统D从消息队列中拿数据。**这样有什么好处**？

- 系统A**只负责**把数据写到队列中，谁想要或不想要这个数据(消息)，**系统A一点都不关心**。
- 即便现在系统D不想要userId这个数据了，系统B又突然想要userId这个数据了，都跟系统A无关，系统A一点代码都不用改。
- 系统D拿userId不再经过系统A，而是从消息队列里边拿。**系统D即便挂了或者请求超时，都跟系统A无关，只跟消息队列有关**。

这样一来，系统A与系统B、C、D都**解耦**了。

#### 2 异步

我们再来看看下面这种情况：系统A还是**直接调用**系统B、C、D

![img](https://pic1.zhimg.com/80/v2-5c3a3b8277e934440212c9f2591dc656_1440w.jpg?source=1940ef5c)

代码如下：

```java
public class SystemA {

    SystemB systemB = new SystemB();
    SystemC systemC = new SystemC();
    SystemD systemD = new SystemD();

    // 系统A独有的数据
    private String userId ;

    public void doOrder() {

        // 下订单
        userId = this.order();
        // 如果下单成功，则安排其他系统做一些事  
        systemB.SystemBNeed2do(userId);
        systemC.SystemCNeed2do(userId);
        systemD.SystemDNeed2do(userId);

    }
}
```

**假设**系统A运算出userId具体的值需要50ms，调用系统B的接口需要300ms，调用系统C的接口需要300ms，调用系统D的接口需要300ms。那么这次请求就需要`50+300+300+300=950ms`

并且我们得知，系统A做的是**主要的业务**，而系统B、C、D是**非主要**的业务。比如系统A处理的是**订单下单**，而系统B是订单下单成功了，那发送一条短信告诉具体的用户此订单已成功，而系统C和系统D也是处理一些小事而已。

那么此时，为了**提高用户体验和吞吐量**，其实可以**异步地**调用系统B、C、D的接口。所以，我们可以弄成是这样的：

![img](https://pic2.zhimg.com/80/v2-a391345118fc2545b232411efea7b80d_1440w.jpg?source=1940ef5c)

系统A执行完了以后，将userId写到消息队列中，然后就直接返回了(至于其他的操作，则异步处理)。

- 本来整个请求需要用950ms(同步)
- 现在将调用其他系统接口异步化，只需要100ms(异步)

#### 3、削峰/限流

我们再来一个场景，现在我们每个月要搞一次大促，大促期间的并发可能会很高的，比如每秒3000个请求。假设我们现在有两台机器处理请求，并且每台机器只能每次处理1000个请求。

![img](https://pic4.zhimg.com/80/v2-2ab4cb03f2e8a6a7ef28deb130661366_1440w.jpg?source=1940ef5c)

那多出来的1000个请求，可能就把我们**整个系统给搞崩了**...所以，有一种办法，我们可以写到消息队列中：

![img](https://pic3.zhimg.com/80/v2-bfe84bf8578c4e8e47fe527106b6b426_1440w.jpg?source=1940ef5c)

系统B和系统C**根据自己的能够处理的请求数去消息队列中拿数据**，这样即便有每秒有8000个请求，那只是把请求放在消息队列中，去拿消息队列的消息**由系统自己去控制**，这样就不会把整个系统给搞崩。

### 三 使用消息队列带来的一些问题

- **系统可用性降低：** 系统可用性在某种程度上降低，为什么这样说呢？在加入MQ之前，你不用考虑消息丢失或者说MQ挂掉等等的情况，但是，引入MQ之后你就需要去考虑了！

  ![img](https://pic1.zhimg.com/80/v2-56f04a3376f0af3565e363890de22650_1440w.jpg?source=1940ef5c)

- **系统复杂性提高：** 加入MQ之后，你需要保证消息没有被重复消费、处理消息丢失的情况、保证消息传递的顺序性等等问题！、

  我们将数据写到消息队列上，系统B和C还没来得及取消息队列的数据，就挂掉了。**如果没有做任何的措施，我们的数据就丢了**。

  ![img](https://pic2.zhimg.com/80/v2-418113f16d65370c06e4c657b3497e59_1440w.jpg?source=1940ef5c)

- **一致性问题：** 我上面讲了消息队列可以实现异步，消息队列带来的异步确实可以提高系统响应速度。但是，万一消息的真正消费者并没有正确消费消息怎么办？这样就会导致数据不一致的情况了!



 除了这些，我们在**使用的时候**还得考虑各种的问题：

- 消息重复消费了怎么办啊？
- 我想保证消息是**绝对**有顺序的怎么做？
- ……..



### 消息队列技术选型

我们自己来处理这些逻辑显得有些复杂，但我们可以选用市面上常见的几种MQ技术**kafka、activeMq、rabbitMq、rocketMq**

让我们先看下他们的优缺点

| 特性                    | ActiveMQ                                                     | RabbitMQ                                                     | RocketMQ                                                     | Kafka                                                        |
| ----------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 单机吞吐量              | 万级，吞吐量比RocketMQ和Kafka要低了一个数量级                | 万级，吞吐量比RocketMQ和Kafka要低了一个数量级                | 10万级，RocketMQ也是可以支撑高吞吐的一种MQ                   | 10万级别，这是kafka最大的优点，就是吞吐量高。                |
| topic数量对吞吐量的影响 |                                                              |                                                              | topic数量对吞吐量的影响                                      | topic可以达到几百，几千个的级别，吞吐量会有较小幅度的下降,这是RocketMQ的一大优势，在同等机器下，可以支撑大量的topic |
| 时效性                  | ms级                                                         | 微秒级，这是rabbitmq的一大特点，延迟是最低的                 | ms级                                                         | 延迟在ms级以内                                               |
| 可用性                  | 高，基于主从架构实现高可用性                                 | 高，基于主从架构实现高可用性                                 | 高，基于主架构实现高可用性                                   | 非常高，kafka是分布式的，一个数据多个副本，少数机器宕机，不会丢失数据，不会导致不可用 |
| 消息可靠性              | 有较低的概率丢失数据                                         |                                                              | 经过参数优化配置，可以做到0丢失                              | 经过参数优化配置，消息可以做到0丢失                          |
| 功能支持                | MQ领域的功能极其完备                                         | 基于erlang开发，所以并发能力很强，性能极其好，延时很低       | MQ功能较为完善，还是分布式的，扩展性好                       | 功能较为简单，主要支持简单的MQ功能，在大数据领域的实时计算以及日志采集被大规模使用，是事实上的标准 |
| 优劣势总结              | 非常成熟，功能强大，在业内大量的公司以及项目中都有应用，偶尔会有较低概率丢失消息 | erlang语言开发，性能极其好，延时很低；吞吐量到万级，MQ功能比较完备，而且开源提供的管理界面非常棒，用起来很好用，社区相对比较活跃，几乎每个月都发布几个版本分，在国内一些互联网公司近几年用rabbitmq也比较多一些，但是问题也是显而易见的，RabbitMQ确实吞吐量会低一些，这是因为他做的实现机制比较重。而且erlang开发，国内有几个公司有实力做erlang源码级别的研究和定制？如果说你没这个实力的话，确实偶尔会有一些问题，你很难去看懂源码，你公司对这个东西的掌控很弱，基本职能依赖于开源社区的快速维护和修复bug。而且rabbitmq集群动态扩展会很麻烦，不过这个我觉得还好。其实主要是erlang语言本身带来的问题。很难读源码，很难定制和掌控。而且现在社区以及国内应用都越来越少，官方社区现在对ActiveMQ 5.x维护越来越少，几个月才发布一个版本。而且确实主要是基于解耦和异步来用的，较少在大规模吞吐的场景中使用 | 接口简单易用，而且毕竟在阿里大规模应用过，有阿里品牌保障日处理消息上百亿之多，可以做到大规模吞吐，性能也非常好，分布式扩展也很方便，社区维护还可以，可靠性和可用性都是ok的，还可以支撑大规模的topic数量，支持复杂MQ业务场景。而且一个很大的优势在于，阿里出品都是java系的，我们可以自己阅读源码，定制自己公司的MQ，可以掌控社区活跃度相对较为一般，不过也还可以，文档相对来说简单一些，然后接口这块不是按照标准JMS规范走的有些系统要迁移需要修改大量代码。还有就是阿里出台的技术，你得做好这个技术万一被抛弃，社区黄掉的风险，那如果你们公司有技术实力我觉得用RocketMQ挺好的 | 号称大数据的杀手锏，谈到大数据领域内的消息传输，则绕不开Kafka，这款为大数据而生的消息中间件，以其百万级TPS的吞吐量名声大噪，迅速成为大数据领域的宠儿，在数据采集、传输、存储的过程中发挥着举足轻重的作用 |























## RabbitMQ

参考博客[https://www.cnblogs.com/ithushuai/p/12443460.html](https://www.cnblogs.com/ithushuai/p/12443460.html)





### 介绍

>RabbitMQ是一个开源的消息代理和队列服务器，用来通过普通协议在完全不同的应用之间共享数据，RabbitMQ是使用Erlang语言来编写的，并且RabbitMQ是基于AMQP协议的。
>
>Erlang语言最初在于交换机领域的架构模式，这样使得RabbitMQ在Broker之间进行数据交互的性能是非常优秀的
>
>Erlang的优点：Erlang有着和原生Socket一样的延迟



>AMQP定义：是具有现代特征的二进制协议。是一个提供统一消息服务的应用层标准高级消息队列协议，是应用层协议的一个开放标准，为面向消息的中间件设计。
>
>
>![图片描述](https://img1.sycdn.imooc.com/5b99b3800001ab1512380563.png)

### 消息模型

所有 MQ 产品从模型抽象上来说都是一样的过程：
消费者（consumer）订阅某个队列。生产者（producer）创建消息，然后发布到队列（queue）中，最后将消息发送到监听的消费者。

![img](https://upload-images.jianshu.io/upload_images/5015984-066ff248d5ff8eed.png?imageMogr2/auto-orient/strip|imageView2/2/w/401/format/webp)





### RabbitMQ 基本概念

上面只是最简单抽象的描述，具体到 RabbitMQ 则有更详细的概念需要解释。上面介绍过 RabbitMQ 是 AMQP 协议的一个开源实现，所以其内部实际上也是 AMQP 中的基本概念：

![img](https://upload-images.jianshu.io/upload_images/5015984-367dd717d89ae5db.png?imageMogr2/auto-orient/strip|imageView2/2/w/554/format/webp)

#### 名词解释

**Message**
 消息，消息是不具名的，它由消息头和消息体组成。消息体是不透明的，而消息头则由一系列的可选属性组成，这些属性包括routing-key（路由键）、priority（相对于其他消息的优先权）、delivery-mode（指出该消息可能需要持久性存储）等。

**Publisher**
 消息的生产者，也是一个向交换器发布消息的客户端应用程序。

**Exchange**
 交换器，用来接收生产者发送的消息并将这些消息路由给服务器中的队列。

**Binding**
 绑定，用于消息队列和交换器之间的关联。一个绑定就是基于路由键将交换器和消息队列连接起来的路由规则，所以可以将交换器理解成一个由绑定构成的路由表。

**Queue**
 消息队列，用来保存消息直到发送给消费者。它是消息的容器，也是消息的终点。一个消息可投入一个或多个队列。消息一直在队列里面，等待消费者连接到这个队列将其取走。

**Connection**
 网络连接，比如一个TCP连接。

**Channel**
 信道，多路复用连接中的一条独立的双向数据流通道。信道是建立在真实的TCP连接内地虚拟连接，AMQP 命令都是通过信道发出去的，不管是发布消息、订阅队列还是接收消息，这些动作都是通过信道完成。因为对于操作系统来说建立和销毁 TCP 都是非常昂贵的开销，所以引入了信道的概念，以复用一条 TCP 连接。

**Consumer**
 消息的消费者，表示一个从消息队列中取得消息的客户端应用程序。

**Virtual Host**
 虚拟主机，表示一批交换器、消息队列和相关对象。虚拟主机是共享相同的身份认证和加密环境的独立服务器域。每个 vhost 本质上就是一个 mini 版的 RabbitMQ 服务器，拥有自己的队列、交换器、绑定和权限机制。vhost 是 AMQP 概念的基础，必须在连接时指定，RabbitMQ 默认的 vhost 是 / 。

**Broker**
 表示消息队列服务器实体。

从以上可以看出rabbitMQ工作原理大致就是producer把一条消息发送给exchange。rabbitMQ根据routingKey负责将消息从exchange发送到对应绑定的queue中去，这是由rabbitMQ负责做的，而consumer只需从queue获取消息即可。

大致流程如下：

![img](https://upload-images.jianshu.io/upload_images/2231313-c8896e4000585e95?imageMogr2/auto-orient/strip|imageView2/2/w/640/format/webp)

### RabbitMQ 安装

一般来说安装 RabbitMQ 之前要安装 Erlang ，可以去[Erlang官网](http://www.erlang.org/downloads)下载。接着去[RabbitMQ官网](https://link.jianshu.com?t=https://www.rabbitmq.com/download.html)下载安装包，之后解压缩即可。根据操作系统不同官网提供了相应的安装说明：[Windows](https://link.jianshu.com?t=http://www.rabbitmq.com/install-windows.html)、[Debian / Ubuntu](https://link.jianshu.com?t=http://www.rabbitmq.com/install-debian.html)、[RPM-based Linux](https://link.jianshu.com?t=http://www.rabbitmq.com/install-rpm.html)、[Mac](https://link.jianshu.com?t=http://www.rabbitmq.com/install-standalone-mac.html)

在这里我们在自己的服务器里安装rabbitMQ

用docker安装rabbitMQ

```shell
# 拉取rabbitmq镜像
docker pull rabbitmq
# 启动rabbitmq容器
docker run -d --name myRabbitmq -p 5672:5672 -p 15672:15672 -v `pwd`/data:/var/lib/rabbitmq 7471fb821b97
```

说明：

7471fb821b97 为 IMAGE ID 

- -d 后台运行容器；
- --name 指定容器名；
- -p 指定服务运行的端口（5672：应用访问端口；15672：控制台Web端口号）；
- -v 映射目录或文件；

RabbitMQ默认禁用了管理界面，需要通过命令重新开启管理界面，

```shell
#进入容器
docker exec -it rabbitmq bash
#开启管理界面
rabbitmq-plugins enable rabbitmq_management
```

记得打开安全组

访问15672端口出现下面界面代表RabbitMQ安装成功  

![这里写图片描述](https://img-blog.csdn.net/20180628164208377?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dhbmdiaW5nMjUzMDc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

默认账号密码都为guest

![这里写图片描述](https://img-blog.csdn.net/20180628164238267?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dhbmdiaW5nMjUzMDc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)



### rabbitmq 命令

```shell
#1.服务启动相关
systemctl start|restart|stop | status rabbitmq-server

#2.管理命令行用来在不使用web管理界面情况下命令操作RabbitMQ
rabbitmqctl help可以查看更多命令

#3.插件管理命令行
rabbitmq-plugins enable|list|disable
```









### RabbitMQ 五种常用的消息模型



#### 1.1 基本消息模型

这是最简单的消息模型，如下图：

![img](https://img2020.cnblogs.com/blog/1944008/202003/1944008-20200308165428200-1100307615.png)

生产者将消息发送到队列，消费者从队列中获取消息，队列是存储消息的缓冲区。

再演示代码之前，我们先创建一个工程rabbitmq-demo，并编写一个工具类，用于提供与mq服务创建连接以及关闭连接

```java
package com.example.rabbitmqDemo2;

import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import org.junit.Assert;

import java.io.IOException;
import java.util.concurrent.TimeoutException;

/**
 * @author lixiangxiang
 * @description
 * @date 2021/9/13 15:05
 */
public class RabbitmqUtil {

    private  static  ConnectionFactory connectionFactory;

    static {
        connectionFactory = new ConnectionFactory();
        //设置主机
        connectionFactory.setHost("159.75.91.15");
        //设置端口号
        connectionFactory.setPort(5672);
        connectionFactory.setUsername("ems");
        connectionFactory.setPassword("xgx0417");
        connectionFactory.setVirtualHost("/ems");
    }
    public static Connection getConnection(){
        Connection connection  = null;
        try {
            // 获取连接对象
            connection = connectionFactory.newConnection();
        } catch (IOException | TimeoutException e) {
            e.printStackTrace();
        }
        return connection;
    }

    //关闭通道关闭连接工具
    public static void closeConnectionAndChannel(Channel channel,Connection connection) {
        try {
            assert channel != null;
            channel.close();
            assert connection != null;
            connection.close();
        } catch (IOException | TimeoutException e) {
            e.printStackTrace();
        }
    }
}

```

**生产者发送消息**

接下来是生产者发送消息，其过程包括：

1. 与mq服务建立连接

2. 建立通道

3. 声明队列（有相同队列则不创建，没有则创建）

4. 发送消息

代码如下：

```java
public class Provider {
    private static final String QUEUE_NAME = "basic_queue";
    public static void main(String[] args) throws Exception {
        //消息发送端与mq服务创建连接
        Connection connection = ConnectionUtil.getConnection();
        //建立通道
        Channel channel = connection.createChannel();
        // 绑定对应消息队列
        //参数1 队列名称
        //参数2 用来定义队列特性是否需要持久化， true 持久化队列
        //参数3 是否独占队列，
        //参数4 是否在消费完成后自动删除队列
        //参数5 额外参数
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        String message = "hello world";
        //发布消息
        // 参数1交换机名称，参数2队列名称 参数3 传递消息额外设置 参数4：消息的具体内容
        channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
        //发送消息
        System.out.println("生产者已发送：" + message);
         //关闭连接
        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
}
```

**消费者接受消息**

消费者在接收消息的过程需要经历如下几个步骤：

1. 与mqfuwu建立连接

2. 建立通道

3. 声明队列

4. 接收消息

代码如下：

```java
public class Consumer {
    private static final String QUEUE_NAME = "basic_queue";
    public static void main(String[] args) throws Exception {
        //消息消费者与mq服务建立连接
        Connection connection = RabbitmqUtil.getConnection();
        //建立通道
        Channel channel = connection.createChannel();
        //声明队列
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
         //参数1：队列名称
        //参数2：开始消息的自动确认机制
        //参数3：消费时的回调接口
        channel.basicConsume(QUEUE_NAME, true, new DefaultConsumer(channel){
            // 最后一个参数：消息队列中取出的消息
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) 	throws IOException {
                System.out.println("消费者接受到消息"+new String(body));
            }
        }););
    }
}
```

注意：队列需要提前声明，如果未声明就使用队列，则会报错。如果不清楚生产者和消费者谁先声明，为了保证不报错，生产者和消费者都声明队列，队列的创建会保证幂等性，也就是说生产者和消费者都声明同一个队列，则只会创建一个队列

####  1.2 Work Queues工作队列模型

在基本消息模型中，一个生产者对应一个消费者，而实际生产过程中，往往消息生产会发送很多条消息，如果消费者只有一个的话效率就会很低，因此rabbitmq有另外一种消息模型，这种模型下，一个生产发送消息到队列，允许有多个消费者接收消息，但是一条消息只会被一个消费者获取。

![img](https://img2020.cnblogs.com/blog/1944008/202003/1944008-20200308165500153-1391346866.png)

角色：

- P ：生产者
- C1：消费者1 完成任务速度慢
- C2：消费者2 完成任务速度快



>生产者发送消息

与基本消息模型基本一致，这里测试循环发布20条消息：

```java
public class Send {
    private static final String QUEUE_NAME = "work_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        // 循环发布任务
        for (int i = 1; i <= 20; i++) {
            // 消息内容
            String message = "task .. " + i;
            channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
            System.out.println("生产者发送消息：" + message);
            Thread.sleep(500);
        }
        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
}
```

> 消费者1

```java
public class Consumer1 {
    private static final String QUEUE_NAME = "work_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                String msg = new String(body);
                System.out.println("消费者1接收到消息：" + msg);
                try {
                    Thread.sleep(50);//模拟消费耗时
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };
        channel.basicConsume(QUEUE_NAME, true, consumer);
    }
}
```

>消费者2

```java
public class Consumer2 {
    private static final String QUEUE_NAME = "work_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties,byte[] body) throws IOException {
                String msg = new String(body);
                System.out.println("消费者2接收到消息：" + msg);
                try {
                    Thread.sleep(50);//模拟消费耗时
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };
        channel.basicConsume(QUEUE_NAME, true, consumer);
    }
}
```

此时有两个消费者监听同一个队列，当两个消费者都工作时，生成者发送消息，就会按照负载均衡算法分配给不同消费者（默认平均分配），如下图：

![img](https://img2020.cnblogs.com/blog/1944008/202003/1944008-20200308165516887-265282382.png)

### 消息应答

#### **概念**

消费者完成一个任务可能需要一段时间，如果其中一个消费者处理消息的过程中宕机了，会导致丢失正在处理的消息以及后续发送给该消费者的消息。原因是Rabbitmq一但向消费者传递一条消息，便立即将该消息标记为删除。

为保证消息在发送过程中不丢失，rabbitmq引入消息应答机制：消费者在接收到消息并且处理该消息之后，告诉rabbitmq它已经处理了，rabbitmq再把该消息删除。



#### **自动应答**

**消息发送后立即被认为已经传送成功**，这种模式**需要在高吞吐量和数据传输安全性方面做权衡**,因为这种模式如果消息在接收到之前，消费者那边出现连接或者channel关闭，那么消息就丢失了,当然另一方面这种模式消费者那边可以传递过载的消息**，没有对传递的消息数量进行限制**,当然这样有可能使得消费者这边由于接收太多还来不及处理的消息，导致这些消息的积压，最终使得内存耗尽，最终这些消费者线程被操作系统杀死，所以**这种模式仅适用在消费者可以高效并以某种速率能够处理这些消息的情况下使用。**



#### **手动应答的方法**

A. Channel.basicAck(用于肯定确认)

​	 RabbitMQ已知道该消息并且成功的处理消息，可以将其丢弃了

B. Channel.basicNack(用于否定确认)

C. Channel.basicReject(用于否定确认)

​	与Channel.basicNack 相比少一个参数

​	不处理该消息了直接拒绝，可以将其丢弃了

#### Multiple解释

手动应答的好处是可以批量应答并且减少网络堵塞

![image-20211011110208849](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011110208849.png)

- multiple 的`true`和` false `代表不同意思

- true 代表批量应答channel上未应答的消息

​	比如说channel上有传送tag的消息5,6,7,8 当前tag是8那么此时5-8的这些还未应答的消息都会被确认收到消息应答

- false 同上面相比

​	只会应答tag=8的消息5,6,7这三个消息依然不会被确认收到消息应答

![image-20211011110359436](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011110359436.png)

#### 消息重新入队

如果消费者由于某些原因失去连接(其通道已关闭，连接已关闭或TCP连接丢失，导致消息未发送ACK确认，RabbitMQ将了解到消息未完全处理，并将对其重新排队。如果此时其他消费者可以处理，它将很快将其重新分发给另一个消费者。这样，即使某个消费者偶尔死亡，也可以确保不会丢失任何消息。

![image-20211011110754784](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011110754784.png)

#### **消息手动应答代码**

```java
public class Send {
    private static final String QUEUE_NAME = "ack_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNext()) {
            String message = scanner.next();
            //发布任务
            channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
            System.out.println("生产者发送消息：" + message);
        }
        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
}

```



```java
public class Consumer1 {
      private static final String QUEUE_NAME = "ack_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        System.out.println("消费者1消费较慢");
        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties,byte[] body) throws IOException, IOException {
                String msg = new String(body);

                try {
                    //模拟消费耗时 10s
                    Thread.sleep(10000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("消费者1接收到消息：" + msg);
                channel.basicAck(envelope.getDeliveryTag(), false);
            }
        };
        //关闭自动确认
        channel.basicConsume(QUEUE_NAME, false, consumer);
    }
}
```



```java
public class Consumer2 {
   private static final String QUEUE_NAME = "ack_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        System.out.println("消费者2消费速度快");
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties,byte[] body) throws IOException, IOException {
                String msg = new String(body);
                System.out.println("消费者2接收到消息：" + msg);
                channel.basicAck(envelope.getDeliveryTag(), false);
            }
        };
        //关闭自动确认
        channel.basicConsume(QUEUE_NAME, false, consumer);
    }
}
```

消费者1消费的较慢，如果消费过程中宕机了，消息将转给消费者2

### rabbitmq队列持久化和消息持久化

#### 队列持久化

之前我们创建的队列都是非持久化的，rabbitmq如果重启的化，该队列就会被删除掉，如果要队列实现持久化需要在声明队列的时候把durable参数设置为持久化

```java
//让消息队列持久化
boolean durable=true;
channel.queueDeclare (ACK_QUEUB_NAME,durable,false,false,null);
```

但是需要注意的就是如果之前声明的队列不是持久化的，需要把原先队列先删除，或者重新创建一个持久化的队列，不然就会出现错误

#### 消息持久化

要想让消息实现持久化需要在消息生产者修改代码，MessageProperties.PERSISTENT_TEXT_PLAIN添加这个属性。

```java
channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
```

```java
channel.basicPublish("",QUEUE_NAME,MessageProperties.PERSISTENT_TEXT_PLAIN, message.getBytes());
```



### rabbitmq 的消息分发机制

#### **默认的分发机制**

消息队列默认使用的是轮训分发，将消息平均分配给消费者，处理慢的消费者跟处理快的消费者获取的消息数量一致

#### **不公平分发**



意思就是如果这个任务我还没有处理完或者我还没有应答你，你先别分配给我，我目前只能处理一个任务，然后rabbitmq就会把该任务分配给没有那么忙的那个空闲消费者，当然如果所有的消费者都没有完成手上任务，队列还在不停的添加新任务，队列有可能就会遇到队列被撑满的情况，这个时候就只能添加新的worker或者改变其他存储任务的策略。



设置参数 channel.basicQos(1)

```java
public class Consumer1 {
    private static final String QUEUE_NAME = "work_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        channel.basicQos(1);//每次只能消费一个消息
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties,byte[] body) throws IOException {
                String msg = new String(body);
                System.out.println("消费者1接收到消息：" + msg);
                try {
                    Thread.sleep(1000);//模拟消费耗时
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                //参数1：手动确认消息标识 参数2：false 每次确认一个
                channel.basicAck(envelope.getDeliveryTag(), false);
            }
        };
        //关闭自动确认
        channel.basicConsume(QUEUE_NAME, false, consumer);
    }
}
```



```java
public class Consumer2 {
    private static final String QUEUE_NAME = "work_queue";
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        channel.basicQos(1);//每次只能消费一个消息
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties,byte[] body) throws IOException {
                String msg = new String(body);
                System.out.println("消费者2接收到消息：" + msg);
                //参数1：手动确认消息标识 参数2：false 每次确认一个
                channel.basicAck(envelope.getDeliveryTag(), false);
            }
        };
        //关闭自动确认
        channel.basicConsume(QUEUE_NAME, false, consumer);
    }
}
```

![image-20211010093554132](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211010093554132.png)

结果可以看出消费者2执行的快，消费了更多消息

#### 预取值

本身消息的发送就是异步发送的，所以在任何时候,channel上肯定不止只有一个消息另外来自消费者的手动确认本质上也是异步的。因此这里就存在一个未确认的消息缓冲区，因此希望开发人员能**限制此缓冲区的大小，以避免缓冲区里面无限制的未确认消息问题。**这个时候就可以递过使用basic.aos设置“预取计数”值来完成的。**该值定义通道上允许的未确认消息的最大数量。**一旦数量达到配置的数量，RabbitMO将停止在通道上传递更多消息，除非至少有一个未处理的消息被确认 例如：未确认的消息5、6、7，8，并且通道的预取计数设置为4，此时RabbitMQ将不会在该通道上再传递任何消息，除非至少有一个未应答的消息被ack。比方说tag=6这个消息刚刚被确认ACK，RabbitMQ将会感知这个情况到并再发送一条消息。消息应答和QoS预取值对用户吞吐量有重大影响。通常，增加预取将提高向消费者传递消息的速度。**虽然自动应答传输消息速率是最佳的，但是，在这种情况下已传递但尚未处理的消息的数量也会增加，从而增加了消费者的RAM消耗(随机存取存储器)**应该小心使用具有无限预处理的自动确认模式或手动确认模式，消费者消费了大量的消息如果没有确认的话，会导致消费者连接节点的内存消耗变大，所以找到合适的预取值是一个反复试验的过程，不同的负载该值取值也不同100到300范围内的值通常可提供最佳的吞吐量，并且不会给消费者带来太大的风险。预取值为1是最保守的。当然这将使吞吐量变得很低，特别是消费者连接延迟很严重的情况下，特别是在消费者连接等待时间较长的环境中，对于多数应用来说，稍微高一点的值将是最佳的。



![image-20211011164548849](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011164548849.png)



提前指定好每个消费者消费多少条数据

```java
//设置预取值5条
channel.basicQos(5);
```

### 发布确认

#### 发布确认原理

![image-20211012145638063](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211012145638063.png)



#### 开启发布确认的方法

发布确认默认是没有开启的，如果要开启需要调用方法 confirmSelect，每当你要想使用发布确认，都需要在channel 上调用该方法

```java
Connection connection = RabbitmqUtil.getConnection();
Channel channel = connection.createChannel();
//开启发布确认
channel.confirmSelect();
```

#### 单个发布确认

这是一种简单的确认方式，它是一种同步确认发布的方式，也就是发布一个消息之后只有它被确认发布，后续的消息才能继续发布, waitForConfirmsOrDie(long)这个方法只有在消息被确认的时候才返回，如果在指定时间范围内这个消息没有被确认那么它将抛出异常。

这种确认方式有一个最大的缺点就是:**发布速度特别的慢**，因为如果没有确认发布的消息就会阻塞所有后续消息的发布，这种方式最多提供每秒不超过数百条发布消息的吞吐量。当然对于某些应用程序来说这可能已经足够了。

```java
  /**
     * 单个确认
     */
    public static void publicMessageSingle() throws IOException, InterruptedException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        //队列声明
        String queueName = UUID.randomUUID().toString();
        channel.queueDeclare(queueName,true,false,false,null);
        //开启发布确认
        channel.confirmSelect();
        //开始时间
        long begin = System.currentTimeMillis();
        //批量发消息
        for (int i = 0; i < 1000; i++) {
            String message = i+"";
            channel.basicPublish("",queueName,null,message.getBytes());
            //单个消息立马确认
            boolean flag = channel.waitForConfirms();
            if (flag) {
                System.out.println("消息发送成功");
            }
        }
        //结束时间
        long end = System.currentTimeMillis();
        System.out.println("发布1000条单独确认消息,耗时"+(end - begin)+"ms");
    }
```



#### 批量确认发布

上面那种方式非常慢，与单个等待确认消息相比，先发布一批消息然后一起确认可以极大地提高吞吐量，当然这种方式的缺点就是:**当发生故障导致发布出现问题时，不知道是哪个消息出现问题了**，我们必须将整个批处理保存在内存中，以记录重要的信息而后重新发布消息。当然这种方案仍然是同步的，也一样阻塞消息的发布。

```java
 /**
     * 批量确认
     */
    public static void publicMessageBatch() throws IOException, InterruptedException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        //队列声明
        String queueName = UUID.randomUUID().toString();
        channel.queueDeclare(queueName,true,false,false,null);
        //开启发布确认
        channel.confirmSelect();
        //开始时间
        long begin = System.currentTimeMillis();

        //批量确认消息大小
        int batchSize = 100;

        //批量发消息 批量发布确认
        for (int i = 1; i <= 1000; i++) {
            String message = i+"";
            channel.basicPublish("",queueName,null,message.getBytes());
            //判断达到100条消息的时候，批量确认一次
            if (i % batchSize == 0) {
                //发布确认
                channel.waitForConfirms();
            }
        }

        //结束时间
        long end = System.currentTimeMillis();
        System.out.println("发布1000条批量确认消息,耗时"+(end - begin)+"ms");
        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
```



#### 异步发布确认

异步确认虽然编程逻辑比上两个要复杂，但是性价比最高，无论是可靠性还是效率都没得说，他是利用回调函数来达到消息可靠性传递的,这个中间件也是通过函数回调来保证是否投递成功，下面就让我们来详细讲解异步确认是怎么实现的。

![image-20211012152130783](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211012152130783.png)



```java
/**
     * 异步确认发布
     */
    public static void publicMessageAsync() throws IOException, InterruptedException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        //队列声明
        String queueName = UUID.randomUUID().toString();
        channel.queueDeclare(queueName,true,false,false,null);
        //开启发布确认
        channel.confirmSelect();
        //开始时间
        long begin = System.currentTimeMillis();


        //消息确认成功 回调函数
        // 参数1消息的标记 2. 是否为批量确认
        ConfirmCallback ackCallBack = (deliveryTag,multiple)->{
            System.out.println("确认的消息"+deliveryTag);
        };

        //消息确认失败 回调函数
        ConfirmCallback nackCallBack = (deliveryTag,multiple)->{
            System.out.println("未确认的消息"+deliveryTag);
        };
        //准备消息的监听器 监听哪些消息成功了 哪些消息失败了 异步通知
        /**
         * 1.第一个监听哪些成功
         * 2.监听哪些消息失败
         */
        channel.addConfirmListener(ackCallBack,nackCallBack);

        //批量发消息 批量发布确认
        for (int i = 1; i <= 1000; i++) {
            String message = i+"";
            channel.basicPublish("",queueName,null,message.getBytes());
        }



        //结束时间
        long end = System.currentTimeMillis();
        System.out.println("发布1000条批量确认消息,耗时"+(end - begin)+"ms");
//        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
```

#### 如何处理异步未确认的消息

最好的解决的解决方案就是把未确认的消息放到一个基于内存的能被发布线程访问的队列，比如说用ConcurrentLinkedQueue这个队列在confirm callbacks与发布线程之间进行消息的传递。

```java
/**
     * 异步确认发布
     */
    public static void publicMessageAsync() throws IOException, InterruptedException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        //队列声明
        String queueName = UUID.randomUUID().toString();
        channel.queueDeclare(queueName,true,false,false,null);
        //开启发布确认
        channel.confirmSelect();

        //线程安全有序的哈希表，适用于高并发的情况下
        /**
         * 1.轻松的奖序号与消息进行关联
         * 2.轻松批量删除条目，只要给到序号
         * 3.支持高并发。
         */
        ConcurrentSkipListMap<Long,Object> outStandingConfirms = new ConcurrentSkipListMap<>();

        //消息确认成功 回调函数
        // 参数1消息的标记 2. 是否为批量确认
        ConfirmCallback ackCallBack = (deliveryTag,multiple)->{
            if (multiple) {
                //获取已确认的消息
                ConcurrentNavigableMap<Long, Object> confirmed =
                        outStandingConfirms.headMap(deliveryTag);
                //删除已确认的消息
                confirmed.clear();
            } else {
                outStandingConfirms.remove(deliveryTag);
            }
            System.out.println("确认的消息"+deliveryTag);
        };

        //消息确认失败 回调函数
        ConfirmCallback nackCallBack = (deliveryTag,multiple)->{
            String msg = outStandingConfirms.get(deliveryTag).toString();
            System.out.println("未确认的消息"+msg);
        };
        //准备消息的监听器 监听哪些消息成功了 哪些消息失败了 异步通知
        /**
         * 1.第一个监听哪些成功
         * 2.监听哪些消息失败
         */
        channel.addConfirmListener(ackCallBack,nackCallBack);

        //开始时间
        long begin = System.currentTimeMillis();
        //批量发消息 批量发布确认
        for (int i = 1; i <= 1000; i++) {
            String message = i+"";
            channel.basicPublish("",queueName,null,message.getBytes());
            //此处记录下所有要发送的消息 消息的总和
            outStandingConfirms.put(channel.getNextPublishSeqNo(),message);
        }

        //结束时间
        long end = System.currentTimeMillis();
        System.out.println("发布1000条批量确认消息,耗时"+(end - begin)+"ms");
//        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
```



### 交换机三种常见类型 

在之前的模型中，一条消息只能被一个消费者获取，而在订阅模式中，可以实现一条消息被多个消费者获取。在这种模型下，消息传递过程中比之前多了一个exchange交换机，生产者不是直接发送消息到队列，而是先发送给交换机，经由交换机分配到不同的队列，而每个消费者都有自己的队列：

![img](https://img2020.cnblogs.com/blog/1944008/202003/1944008-20200308165532126-1077010904.png)

解读：

1、1个生产者，多个消费者

2、每一个消费者都有自己的一个队列

3、生产者没有将消息直接发送到队列，而是发送到了交换机

4、每个队列都要绑定到交换机

5、生产者发送的消息，经过交换机到达队列，实现一个消息被多个消费者获取的目的

X（exchange）交换机的类型有以下几种：

```java
Fanout：广播，交换机将消息发送到所有与之绑定的队列中去

Direct：定向，交换机按照指定的Routing Key发送到匹配的队列中去

Topics：通配符，与Direct大致相同，不同在于Routing Key可以根据通配符进行匹配
```

注意：在发布订阅模型中，生产者只负责发消息到交换机，至于消息该怎么发，以及发送到哪个队列，生产者都不负责。一般由消费者创建队列，并且绑定到交换机



#### 1.3 fonout模型

在广播模式下，消息发送的流程如下：

1. 可以有多个消费者，每个消费者都有自己的队列
2. 每个队列都要与exchange绑定
3. 生产者发送消息到exchange，交换机决定发送给哪个队列
4. exchange将消息把消息发送到所有绑定的队列中去
5. 消费者从各自的队列中获取消息
6. 队列的消费者都能拿到消息。实现一条消息被多个消费者消费

> 生产者发送消息

```java
public class Send {
    private static final String EXCHANGE_NAME = "fanout_exchange";
    
    public static void main(String[] args) throws Exception {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        // 声明exchange，指定类型为fanout
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.FANOUT);
        String message = "hello world";
        channel.basicPublish(EXCHANGE_NAME, "", null, message.getBytes());
        System.out.println("生产者发送消息：" + message);
        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
}
```

> **消费者**

```java
public class Consumer1 {
    private static final String QUEUE_NAME = "fanout_queue_1";
    private static final String EXCHANGE_NAME = "fanout_exchange";

    public static void main(String[] args) throws Exception {
        Connection connection = ConnectionUtil.getConnection();
        Channel channel = connection.createChannel();
        //消费者声明自己的队列
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        // 声明exchange，指定类型为direct
        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.FANOUT);
        //消费者将队列与交换机进行绑定
        channel.queueBind(QUEUE_NAME, EXCHANGE_NAME, "");
        channel.basicConsume(QUEUE_NAME, true, new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag,
                                       Envelope envelope,
                                       AMQP.BasicProperties properties,
                                       byte[] body)
                    throws IOException
            {
                String msg = new String(body);
                System.out.println("消费者1获取到消息：" + msg);
            }
        });
    }
}
```

其他消费者只需修改QUEUE_NAME即可

注意：exchange与队列一样都需要提前声明，如果未声明就使用交换机，则会报错。如果不清楚生产者和消费者谁先声明，为了保证不报错，生产者和消费者都声明交换机，同样的，交换机的创建也会保证幂等性。

---

#### 1.4 Routing模型       

##### 1.4.1 Routing 之订阅模型-Direct(直连)    

`在fanout模式中，一条消息会被所有订阅的对列消费，但是，在某些场景下，我们希望不同的消息被不同的对列消费。这时就要用到Direct类型的Exchange`       

在Direct模型下：

- 队列与交换机的绑定，不能是任意绑定了，而是要指定一个RoutingKey(路由key)
- 消息的发送方在向Exchange发送消息时，也必须指定消息的 RoutingKey 。
- Exchange不再把消息交给每一个绑定的队列，而是根据消息的Routing Key进行判断，只有队列的Routingkey与消息的Routingkey完全一致,才会接收到消息

![img](https://img2020.cnblogs.com/blog/1944008/202003/1944008-20200308165604637-345033763.png)

图解:

- P:生产者，向Exchange发送消息，发送消息时，会指定一个routing key。
- X: Exchange(交换机)，接收生产者的消息，然后把消息递交给与routing key完全匹配的队列。 
- C1:消费者,其所在队列指定了需要routing key为error的消息。
- C2:消费者,其所在队列指定了需要routing key为 info、error、warning 的消息。

如果发送路由key为error的消息，则C1 和 C2 都能接收到

但如果发送路由key为info的消息，只有C2能接收到



> 生产者发送消息

```java
public class Send {
     private final static String EXCHANGE = "logs_direct";
     public static void main(String[] args) throws IOException {
        Connection connection = RabbitmqUtil.getConnection();
        //获取连接通道
        Channel channel = connection.createChannel();
        //通过通道声明交换机，参数1：交换机名称 参数2：direct 路由模式
        channel.exchangeDeclare(EXCHANGE,"direct");
        //发送消息
        String routingKey = "error";
        String msg = "direct模型发送消息 routing key:["+routingKey+"] ";
        //参数： 1交换机名称，参数2队列名称 参数3 传递消息额外设置 参数4：消息的具体内容
        channel.basicPublish(EXCHANGE,routingKey,null,msg.getBytes());
        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
}
```

> 消费者1

```java
public class Consumer1 {
    private static final String QUEUE_NAME = "direct_queue_1";
    private static final String EXCHANGE_NAME = "direct_exchange";

    public static void main(String[] args) throws Exception {
         Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();

        //绑定交换机
        channel.exchangeDeclare(EXCHANGE,"direct");

        //获取临时队列名
        String queue = channel.queueDeclare().getQueue();

        //绑定队列 交换机和RoutingKey 参数：1 对列名 ，2 交换机名称，3 路由key名称
        channel.queueBind(queue,EXCHANGE,"info");

        //获取消费的消息
        channel.basicConsume(queue,true,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("消费者1："+new String(body));
            }
        });
    }
}
```

```java
public class Consumer2 {
    private final static String EXCHANGE = "logs_direct";
    public static void main(String[] args) throws IOException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();

        //绑定交换机
        channel.exchangeDeclare(EXCHANGE,"direct");

        //临时队列
        String queue = channel.queueDeclare().getQueue();

        //绑定队列 交换机和RoutingKey 参数：1 对列名 ，2 交换机名称，3 路由key名称
        channel.queueBind(queue,EXCHANGE,"info");
        channel.queueBind(queue,EXCHANGE,"error");
        channel.queueBind(queue,EXCHANGE,"warning");

        //获取消费的消息
        channel.basicConsume(queue,true,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("消费者2："+new String(body));
            }
        });
    }
}
```

上述生产者发送的消息，消费者1是可以获取到的

![image-20211011092626820](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011092626820.png)

改变生产者发送的RoutingKey 为error则消费者2和消费者1都能获取到

```java
 String routingKey = "error";
```

![image-20211011092920610](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011092920610.png)

##### 1.4.2 Routing 之订阅模型 -Topics模型

`Topic`类型的`Exchange`与`Direct`相比，都是可以根据`RoutingKey`把消息路由到不同的队列。只不过`Topic`类型`Exchange`可以让队列在绑定`Routing key `的时候使用通配符

`Routingkey` 一般都是有一个或多个单词组成，多个单词之间以”.”分割，例如： `item.insert`

![image-20211011093549577](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011093549577.png)

通配符规则：

```
     #：匹配零个或多个词

     *：匹配不多不少恰好1个词
```

举例：

```
     audit.#：能够匹配audit.irs.corporate 或者 audit.irs

     audit.*：只能匹配audit.irs
```

Topics生产者代码与Direct大致相同，只不过在声明交换机时，将类型设为topic

消费者代码也与Direct大致相同，也是在声明交换机时设置类型为topic，代码不再演示

**生产者**

```java
public class Provider {
    private final static String EXCHANGE = "topic_exchange";
    public static void main(String[] args) throws IOException {
        Connection connection = RabbitmqUtil.getConnection();
        //获取连接通道
        Channel channel = connection.createChannel();
        //通过通道声明交换机，参数1：交换机名称 参数2：direct 路由模式
        channel.exchangeDeclare(EXCHANGE,"topic");
        //发送消息
        String routingKey = "user.save";
        String msg = "topic动态路由模型 routing key:["+routingKey+"] ";
        //参数： 1交换机名称，参数2队列名称 参数3 传递消息额外设置 参数4：消息的具体内容
        channel.basicPublish(EXCHANGE,routingKey,null,msg.getBytes());
        RabbitmqUtil.closeConnectionAndChannel(channel,connection);
    }
}
```

**消费者1**

```java
public class Customer1 {
    private final static String EXCHANGE = "logs_direct";

    public static void main(String[] args) throws IOException {
       Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();

        //绑定交换机
        channel.exchangeDeclare(EXCHANGE,"topic");

        //获取临时队列名
        String queue = channel.queueDeclare().getQueue();

        //绑定队列 交换机和RoutingKey 参数：1 对列名 ，2 交换机名称，3 路由key名称
        channel.queueBind(queue,EXCHANGE,"user.*");

        //获取消费的消息
        channel.basicConsume(queue,true,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("消费者1："+new String(body));
            }
        });
    }
}
```

**消费者2**

```java
public class Customer2 {
    private final static String EXCHANGE = "topic_exchange";

    public static void main(String[] args) throws IOException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();

        //绑定交换机
        channel.exchangeDeclare(EXCHANGE,"topic");

        //获取临时队列名
        String queue = channel.queueDeclare().getQueue();

        //绑定队列 交换机和RoutingKey 参数：1 对列名 ，2 交换机名称，3 路由key名称
        channel.queueBind(queue,EXCHANGE,"user.#");

        //获取消费的消息
        channel.basicConsume(queue,true,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("消费者2："+new String(body));
            }
        });
    }
}
```

![image-20211011095724212](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211011095724212.png)

此时两个消费者都能获取 消息

若生产者路由变为 

```java
String routingKey = "user.save.delete";
```

则只有消费者2能获取到消息。

---



### 死信队列

#### 死信的概念

先从概念解释上搞清楚这个定义，死信，顾名思义就是无法被消费的消息，字面意思可以这样理解，一般来说,producer将消息投递到 broker或者直接到queue里了，consumer 从 queue取出消息进行消费，但某些时候由于特定的原因**导致queue中的某些消息无法被消费**，这样的消息如果没有后续的处理，就变成了死信，有死信自然就有了死信队列。

应用场景:为了保证订单业务的消息数据不丢失，需要使用到RabbitMQ的死信队列机制，当消息消费发生异常时，将消息投入死信队列中.还有比如说:用户在商城下单成功并点击去支付后在指定时间未支付时自动失效

#### 死信的来源

- 消息TIL过期
- 队列达到最大长度(队列满了，无法再添加数据到mq.中)
- 消息被拒绝(basic.reject或 basic.nack)并且requeue=false.

#### 死信实战

![image-20211012161134596](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20211012161134596.png)

#### 消息TTL过期

消息过期后满足死信要求，消费者1若在10s内未能接受消息，则会将消息转移到死信队列，由消费者2来消费。

**生产者**

 ```java
 public class Producer {
     private static final String NORMAL_EXCHANGE = "normal_exchange";
     public static void main(String[] args) throws IOException {
         Connection connection = RabbitmqUtil.getConnection();
         Channel channel = connection.createChannel();
         //死信队列 设置TTL时间 单位ms
         AMQP.BasicProperties properties = new AMQP.BasicProperties().builder().expiration("10000").build();
 
         for (int i = 1; i <= 10; i++) {
             String message = "info" + i;
             channel.basicPublish(NORMAL_EXCHANGE,"zhangsan",properties,message.getBytes());
         }
         RabbitmqUtil.closeConnectionAndChannel(channel,connection);
     }
 }
 
 ```

**消费者1**

```java
public class Consumer1 {
    //普通交换机名称
    public static final String NORMAL_EXCHANGE = "normal_exchange";
    //死信交换机名称
    public static final String DEAD_EXCHANGE = "dead_exchange";
    //普通队列名称
    public static final String NORMAL_QUEUE = "normal_queue";
    //死信队列名称
    public static final String DEAD_QUEUE = "dead_queue";


    public static void main(String[] args) throws IOException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        //声明死信和普通交换机，类型为direct
        channel.exchangeDeclare(NORMAL_EXCHANGE, BuiltinExchangeType.DIRECT);
        channel.exchangeDeclare(DEAD_EXCHANGE,BuiltinExchangeType.DIRECT);
        //声明普通队列
        Map<String,Object> arguments = new HashMap<>();
        //过期时间 10s = 100000ms
//        arguments.put("x-dead-letter-ttl",100000);
        //正常队列设置死信交换机
        arguments.put("x-dead-letter-exchange",DEAD_EXCHANGE);
        //设置死信RoutingKey
        arguments.put("x-dead-letter-routing-key","lisi");
        channel.queueDeclare(NORMAL_QUEUE,false,false,false,arguments);

        // 声明死信队列
        channel.queueDeclare(DEAD_QUEUE,false,false,false,null);

        //绑定普通的交换机与队列
        channel.queueBind(NORMAL_QUEUE,NORMAL_EXCHANGE,"zhangsan");
        //绑定死信交换机与死信队列
        channel.queueBind(DEAD_QUEUE,DEAD_EXCHANGE,"lisi");
        System.out.println("等待接受消息...");

        DeliverCallback deliverCallback = (consumerTag, message) -> {
            System.out.println("consumer1接受的消息是"+new String(message.getBody(),"UTF-8"));
        };
        channel.basicConsume(NORMAL_QUEUE, true, deliverCallback,consumerTag -> {});
    }
}

```

**消费者2**

```java
public class Consumer2 {
    //死信队列名称
    public static final String DEAD_QUEUE = "dead_queue";


    public static void main(String[] args) throws IOException {
        Connection connection = RabbitmqUtil.getConnection();
        Channel channel = connection.createChannel();
        System.out.println("等待接受消息...");
        DeliverCallback deliverCallback = (consumerTag, message) -> {
            System.out.println("consumer2接受的消息是"+new String(message.getBody(),"UTF-8"));
        };
        channel.basicConsume(DEAD_QUEUE, true, deliverCallback,consumerTag -> { });
    }
}

```



#### 队列达到最大长度

c1消费者修改如下代码

```java
//正常队列设置死信交换机
arguments.put("x-dead-letter-exchange",DEAD_EXCHANGE);
//设置死信RoutingKey
arguments.put("x-dead-letter-routing-key","lisi");
//设置正常队列长度的限制
arguments.put("x-max-length",6);
```

生产者修改代码 去掉TTL限制

```java
//死信队列 设置TTL时间 单位ms
//AMQP.BasicProperties properties = new AMQP.BasicProperties().builder().expiration("10000").build();
channel.basicPublish(NORMAL_EXCHANGE,"zhangsan",null,message.getBytes());
```



#### 消息被拒

