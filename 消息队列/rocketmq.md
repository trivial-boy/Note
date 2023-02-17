# RocketMQ 

## 为什么需要消息队列

1. 削封

​		节日或活动期间，服务器短时间内吞吐量暴增，这时候如果没有缓冲机制，可能承受不住短时间大流量的冲击。通过利用消息队列，将大量的请求缓存起来，分散到相对长的一段时间进行处理，能大大提供系统的稳定性和用户体验。例如双十一秒杀活动，订单系统在平常每秒能处理一万次下单，这个处理能力相

2. 解耦

​		复杂的应用会存在多个子系统，比如在电商应用中有订单系统、库存系统、物流系统、支付系统等。这时候如果各个子系统之间的耦合性太高，整体系统的可用性就会大幅度降低。例如一个电商系统，用户创建订单后，如果耦合调用库存系统、物流系统、支付系统，任何一个子系统出现了故障或者因为升级等原因暂时不可用，都会造成下单操作异常，影响用户体验。当转变为使用消息队列方式后，下单操作并不需要等到物流系统处理完再向用户返回结果，而是将物流等系统需要处理的任务放进消息队列，直接对用户进行相应。如果物流系统出现了故障，需要一段时间来修复，物流系统需要处理的内容被缓存在消息队列中，当物流系统恢复后，消息队列再将缓存的请求交由系统处理。用户不会感知道物流系统发生过一段时间的故障。

3. 异步

   ​	以上文的电商系统为例，下单这一操作如果按同步操作，我们需要调库存系统减库存、再调支付系统扣减用户账户、物流系统改变物流信息等。这些步骤如果如果时同步的，无疑会造成响应时间增长。引入消息队列后，我们可以将这些步骤都放入队列中用异步的方式去处理，响应时间就会降低。

3. 消息分发

​		在大数据时代，数据对

4. 数据的最终一致性

​		使用异步的方式去处理请求，最大的问题是如何保证数据的最终一致性。也就是分布式事物问题，例如在下单过程中，如果在扣钱这一步骤中出现了问题，而库存此时已经扣减，为了保证数据的最终一致性，我们应该回滚扣钱这一步骤的操作。

## RocketMQ 各部分角色介绍

![rocketmq 技术架构图](https://img.trivial.top/img/image-20221125091059487.png)

RocketMQ由四部分组成

- **producer：**消息发布的角色，支持分布式集群方式部署。Producer通过MQ的负载均衡模块选择相应的Broker集群队列进行消息投递，投递的过程支持快速失败并且低延迟。
- **Consumer：**消息消费的角色，支持分布式集群方式部署。支持以push推，pull拉两种模式对消息进行消费。同时也支持集群方式和广播方式的消费，它提供实时消息订阅机制，可以满足大多数用户的需求。
- **NameServer：**NameServer是一个非常简单的Topic路由注册中心，其角色类似Dubbo中的zookeeper，支持Broker的动态注册与发现。主要包括两个功能：Broker管理，NameServer接受Broker集群的注册信息并且保存下来作为路由信息的基本数据。然后提供心跳检测机制，检查Broker是否还存活；路由信息管理，每个NameServer将保存关于Broker集群的整个路由信息和用于客户端查询的队列信息。然后Producer和Consumer通过NameServer就可以知道整个Broker集群的路由信息，从而进行消息的投递和消费。NameServer通常也是集群的方式部署，各实例间相互不进行信息通讯。Broker是向每一台NameServer注册自己的路由信息，所以每一个NameServer实例上面都保存一份完整的路由信息。当某个NameServer因某种原因下线了，Broker仍然可以向其它NameServer同步其路由信息，Producer和Consumer仍然可以动态感知Broker的路由的信息。 
- **BrokerServer：**Broker主要负责消息的存储、投递和查询以及服务高可用保证，为了实现这些功能，Broker包含了以下几个重要子模块。
  1. Remoting Module：整个Broker的实体，负责处理来自Client端的请求。
  2. Client Manager：负责管理客户端(Producer/Consumer)和维护Consumer的Topic订阅信息。
  3. Store Service：提供方便简单的API接口处理消息存储到物理硬盘和查询功能。
  4. HA Service：高可用服务，提供Master Broker 和 Slave Broker之间的数据同步功能。
  5. Index Service：根据特定的Message key对投递到Broker的消息进行索引服务，以提供消息的快速查询。

![ ](https://img.trivial.top/img/image-20221125091200543.png)

## 快速上手rocketmq

### 下载、安装

RocketMQ的Binary版是一些编译好的jar和辅助的shell脚本，可以直接从官网找到下载链接（http://rocketmq.apache.org/dowloading/releases/ ），也可以下载源码自己编译。

系统要求：64bit的Linux、Unix或Mac。Java版本大于等于JDK1.8。如果需要从GitHub上下载源码和编译的话，需要安装Maven 3.2.x和Git。

RocketMQ当前的最新版本是5.0.0，下面以Binary 4.9.4 版本为例说明如何快速使用：

```
> unzip rocketmq-all-4.9.4-bin-release.zip -d ./rocketmq-all-4.9.4-binls
> cd rocketmq-all-4.9.4-bin/
```

里面含有以下内容：

```
LICENSE  NOTICE  README.md  benchmark/  bin/   conf/  lib/
```

- LICENSE、NOTICE和README.md包括一些版权声明和功能说明信息；

- benchmark里包括运行benchmark程序的shell脚本.
- bin文件夹里含有各种使用RocketMQ的shell脚本（Linux平台）和cmd脚本（Windows平台），比如常用的启动NameServer的脚本mqnamesrv，启动Broker的脚本mqbroker，集群管理脚本mqadmin等；
- conf文件夹里有一些示例配置文件，包括三种方式的broker配置文件、logback日志配置文件等，用户在写配置文件的时候，一般基于这些示例配置文件，加上自己特殊的需求即可
- lib文件夹里包括RocketMQ各个模块编译成的jar包，以及RocketMQ依赖的一些jar包，比如Netty、commons-lang、FastJSON等。

### 启动消息队列服务

启动单机的消息队列服务比较简单，不需要写配置文件，只需要依次启动本机的NameServer和Broker即可。

**启动NameServer：**

```shell
> nohup sh bin/mqnamesrv &
> tail -f ~/Logs/rocketmqLogs/namesrv.Log
The Name Server boot success...
```

**启动Broker：**

```shell
> nohup sh bin/mqbroker –n localhost:9876&
> tail -f ~/Logs/rocketmqLogs/broker.Log
The broker[%s, 192.168.0.233:10911] boot success...
```

### 用命令行发送和接受消息

为了快速展示发送和接收消息，本节展示的是用命令行发送和接收消息，实际上就是运行写好的demo程序，后续我们可以参考这些demo来写自己的发送和接收程序。

```shell
> export NAMESRV_ADDR=localhost:9876
 > sh bin/tools.sh org.apache.rocketmq.example.quickstart.Producer
SendResult [sendStatus=SEND_OK, msgId= ...

> sh bin/tools.sh org.apache.rocketmq.example.quickstart.Consumer
ConsumeMessageThread_%d Receive New Messages: [MessageExt...
```

### 关闭消息队列

```shell
> sh bin/mqshutdown broker
The mqbroker(36695) is running...
Send shutdown request to mqbroker(36695) OK

> sh bin/mqshutdown namesrv
The mqnamesrv(36664) is running...
Send shutdown request to mqnamesrv(36664) OK
```

## 多机集群配置和部署

### 启动多个NameServer和Broker

首先在这两台机器上分别启动NameServer（nohup sh bin/mqnamesrv &），这样我们就得到了一个无单点的NameServer服务，服务地址是“159.75.91.15: 9876；8.141.51.50:9876”。

**配置文件**

然后启动Broker，每台机器上都要分别启动一个Master角色的Broker和一个Slave角色的Broker，并互为主备。可以基于RocketMQ自带的示例配置文件写自己的配置文件（示例配置文件在conf/2m-2s-sync目录下）

1） 159.75.91.15 机器上Master Broker的配置文件

```shell
 namesrvAddr=159.75.91.15:9876; 8.141.51.50:9876
 brokerClusterName=DefaultCluster
 brokerName=broker-a
 brokerId=0
 deleteWhen=04
 fileReservedTime=48
 brokerRole=SYNC_MASTER
 brokerIP1=159.75.91.15
 flushDiskType=ASYNC_FLUSH
 listenPort=10911
 storePathRootDir=/home/rocketmq/store-a
```

2） 8.141.51.50 机器上Master Broker的配置文件：

```shell
namesrvAddr=159.75.91.15:9876; 8.141.51.50:9876
brokerClusterName=DefaultCluster
brokerName=broker-b
brokerId=0
deleteWhen=04
fileReservedTime=48
brokerRole=SYNC_MASTER
brokerIP1=8.141.51.50
flushDiskType=ASYNC_FLUSH
listenPort=10911
storePathRootDir=/home/rocketmq/store-b
```

3）  159.75.91.15机器上Slave Broker的配置文件：

```shell
namesrvAddr=159.75.91.15:9876; 8.141.51.50:9876
brokerClusterName=DefaultCluster
brokerName=broker-b
brokerId=1
deleteWhen=04
fileReservedTime=48
brokerRole=SLAVE
brokerIP1=159.75.91.15
flushDiskType=ASYNC_FLUSH
listenPort=11011
storePathRootDir=/home/rocketmq/store-b
```

4）8.141.51.50  机器上Slave Broker的配置文件：

```shell
namesrvAddr=159.75.91.15:9876; 8.141.51.50:9876
brokerClusterName=DefaultCluster
brokerName=broker-a
brokerId=1
deleteWhen=04
fileReservedTime=48
brokerRole=SLAVE
brokerIP1=8.141.51.50
flushDiskType=ASYNC_FLUSH
listenPort=11011
storePathRootDir=/home/rocketmq/store-a
```

### 配置参数设置

```
1）namesrvAddr=159.75.91.15:9876; 8.141.51.50:9876

NamerServer的地址，可以是多个。

2）brokerClusterName=DefaultCluster

Cluster的地址，如果集群机器数比较多，可以分成多个Cluster，每个Cluster供一个业务群使用。

3）brokerName=broker-a

Broker的名称，Master和Slave通过使用相同的Broker名称来表明相互关系，以说明某个Slave是哪个Master的Slave。

4）brokerId=0

一个Master Borker可以有多个Slave，0表示Master，大于0表示不同Slave的ID。

5）fileReservedTime=48

在磁盘上保存消息的时长，单位是小时，自动删除超时的消息。

6）deleteWhen=04

与fileReservedTime参数呼应，表明在几点做消息删除动作，默认值04表示凌晨4点。

7）brokerRole=SYNC_MASTER

brokerRole有3种：SYNC_MASTER、ASYNC_MASTER、SLAVE。关键词SYNC和ASYNC表示Master和Slave之间同步消息的机制，SYNC的意思是当Slave和Master消息同步完成后，再返回发送成功的状态。

8）flushDiskType=ASYNC_FLUSH

flushDiskType表示刷盘策略，分为SYNC_FLUSH和ASYNC_FLUSH两种，分别代表同步刷盘和异步刷盘。同步刷盘情况下，消息真正写入磁盘后再返回成功状态；异步刷盘情况下，消息写入page_cache后就返回成功状态。

9）listenPort=10911

Broker监听的端口号，如果一台机器上启动了多个Broker，则要设置不同的端口号，避免冲突。

10）storePathRootDir=/home/rocketmq/store-a
存储消息以及一些配置信息的根目录。
```

这些配置参数，在Broker启动的时候生效，如果启动后有更改，要重启Broker。现在使用云服务或多网卡的机器比较普遍，Broker自动探测获得的ip地址可能不符合要求，通过brokerIP1=159.75.91.15这样的配置参数，可以设置Broker机器对外暴露的ip地址。

### 代码示例

**Consumer**

```java
public class SyncConsumer {
    public static void main(String[] args) throws MQClientException {
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("test_group");
        consumer.setNamesrvAddr("159.75.91.15:9876");
        consumer.setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_FIRST_OFFSET);
        consumer.subscribe("TopicTest", "*");
        consumer.registerMessageListener(new MessageListenerConcurrently() {
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs, ConsumeConcurrentlyContext consumeConcurrentlyContext) {
                System.out.printf(Thread.currentThread().getName() + " Receive New Messages: " + msgs + "%n");
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });
        consumer.start();
    }
}
```

**Producer**

```java
public class SyncConsumer {
    public static void main(String[] args) throws MQClientException {
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("test_group");
        consumer.setNamesrvAddr("159.75.91.15:9876");
        consumer.setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_FIRST_OFFSET);
        consumer.subscribe("TopicTest", "*");
        consumer.registerMessageListener(new MessageListenerConcurrently() {
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs, ConsumeConcurrentlyContext consumeConcurrentlyContext) {
                System.out.printf(Thread.currentThread().getName() + " Receive New Messages: " + msgs + "%n");
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });
        consumer.start();
    }

}

```

Consumer或Producer都必须设置**GroupName、NameServer地址以及端口号**。然后**指明要操作的Topic名称**，最后进入**发送和接收逻辑。**

![image-20221125134140497](https://img.trivial.top/img/image-20221125134140497.png)

![image-20221125134123188](https://img.trivial.top/img/image-20221125134123188.png)

## 生产者 

### 生产者概述

**生产者组：**一个逻辑概念，在使用生产者实例的时候需要指定一个组名。一个生产者组可以生产多个Topic的消息。

**生产者实例：**一个生产者组部署了多个进程，每个进程都可以称为一个生产者实例。

**Topic：**主题名字，一个Topic由若干Queue组成。

RocketMQ 客户端中的生产者有两个独立实现类：org.apache.rocketmq.client.producer.DefaultMQProducer和 org.apache.rocketmq.client.producer.TransactionMQProducer。前者用于生产普通消息、顺序消息、单向消息、批量消息、延迟消息，后者主要用于生产事务消息。

### 生产者保证高可用

**1.客户端保证**

**第一种保证机制**：重试机制。Rocketmq支持异步、同步发送， 不管选择哪种方式都可以在配置失败后重试，如果单个Broker发生故障，重试会选择其他Broker保证消息发送正常。

**第二种保证机制：**客户端容错。RocketMQ client 会维护一个“Broker-发送延迟” 关系，根据这个关系选择一个发送延迟级别较低的Broker来发送消息，这样能最大限度地利用Broker的能力，剔除已经宕机、不可用或者发送延迟级别较高的Broker，尽量保证消息的正常发送。

**2. Broker 端保证**

 Broker主从复制分为两种：同步复制和异步复制。

同步复制是指消息发送到Master Broker后，同步到Slave Broker才算发送成功；

异步复制是指消息发送到Master Broker，即为发送成功。

在生产环境中，建议至少部署2个Master和2个Slave，下面分为几种情况详细描述。

（1）1个Slave掉电。Broker同步复制时，生产第一次发送失败，重试到另一组Broker后成功；Broker异步复制时，生产正常不受影响。

（2）2个 Slave掉电。Broker同步复制时，生产失败；Broker异步复制时，生产正常不受影响。

（3）1 个 Master 掉电。Broker 同步复制时，生产第一次失败，重试到另一组 Broker后成功；Broker异步复制时的做法与同步复制相 同。

（4）2个Master掉电。全部生产失败。

（5）同一组Master和Slave掉电。Broker同步复制时，生产第一次发送失败，重试到另一组Broker后成功；Broker异步复制时，生产正常不受影响。
（6）2组机器都掉电：全部生产失败。

综上所述，想要做到绝对的高可靠，将 Broker 配置的主从同步进行复制即可，只要生产者收到消息保存成功的反馈，消息就肯定不会丢失。一般适用于金融领域的特殊场景。





### 生产者启动流程

DefaultMQProducer是RocketMQ中默认的生产者实现，DefaultMQProducer的类之间的继承关系如图2-2所示

### 消息结构和消息类型

#### 消息结构

消息类的核心字段定义如下：

```java
public class Message implements Serializable {                                                               
    private String topic;
    private int flag;
    private Map<String, String> properties;
    private byte[] body;
    private String transactionId;
    public void setKeys(String keys) {
        this.putProperty(MessageConst.PROPERTY_KEYS, keys);
    }
    public void setKeys(Collection<String> keyCollection) {
        String keys = String.join(MessageConst.KEY_SEPARATOR, keyCollection);

        this.setKeys(keys);
    }
    public void putUserProperty(final String name, final String value) {
        if (MessageConst.STRING_HASH_SET.contains(name)) {
            throw new RuntimeException(String.format(
                "The Property<%s> is used by system, input another please", name));
        }

        if (value == null || value.trim().isEmpty()
            || name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException(
                "The name or value of property can not be null or blank string!"
            );
        }

        this.putProperty(name, value);
    }
    public void setTopic(String topic) {
        this.topic = topic;
    }
    public void setTags(String tags) {
        this.putProperty(MessageConst.PROPERTY_TAGS, tags);
    }

    public void setDelayTimeLevel(int level) {
        this.putProperty(MessageConst.PROPERTY_DELAY_TIME_LEVEL, String.valueOf(level));
    }

}
```

**Topic：**主题名字，可以通过RocketMQ Console创建。

**Flag：**目前没用。

**Properties**：消息扩展信息，Tag、keys、延迟级别都保存在这里。

**Body**：消息体，字节数组。需要注意生产者使用什么编码，消费者也必须使用相同编码解码，否则会产生乱码。

**setKeys（）：**设置消息的key，多个key可以用MessageConst.KEY_SEPARATOR（空格）分隔或者直接用另一个重载方法。如果 Broker 中 messageIndexEnable=true 则会根据 key创建消息的Hash索引，帮助用户进行快速查询。

**setTags（）：**消息过滤的标记，用户可以订阅某个Topic的某些Tag，这样Broker只会把订阅了topic-tag的消息发送给消费者。

**setDelayTimeLevel（）**：设置延迟级别，延迟多久消费者可以消费。

**putUserProperty（）：**如果还有其他扩展信息，可以存放在这里。内部是一个Map，重复调用会覆盖旧值。

#### 消息类型

RocketMQ支持普通消息、分区有序消息、全局有序消息、延迟消息和事务消息。

**普通消息：**普通消息也称为并发消息，和传统的队列相比，并发消息没有顺序，但是生产消费都是并行进行的，单机性能可达十万级别的TPS。

**分区有序消息**：与Kafka中的分区类似，把一个Topic消息分为多个分区“保存”和消费，在一个分区内的消息就是传统的队列，遵循FIFO（先进先出）原则。

**全局有序消息：**如果把一个 Topic 的分区数设置为 1，那么该 Topic 中的消息就是单分区，所有消息都遵循FIFO（先进先出）的原则。

**延迟消息：**消息发送后，消费者要在一定时间后，或者指定某个时间点才可以消费。在没有延迟消息时，基本的做法是基于定时计划任务调度，定时发送消息。在 RocketMQ中只需要在发送消息时设置延迟级别即可实现。

**事务消息：**主要涉及分布式事务，即需要保证在多个操作同时成功或者同时失败时，消费者才能消费消息。RocketMQ通过发送Half消息、处理本地事务、提交（Commit）消息或者回滚（Rollback）消息优雅地实现分布式事务。

### 发送消息案例

#### 普通消息

##### 1. 消息发送分类

producer 对于消息的发送方式也有多种选择，不同的方式会产生不同的系统效果。

##### 同步发送消息

同步发送消息是指，Producer发出一条消息后，会在收到MQ返回的ACK之后才发下一条消息。该方式的消息可靠性最高，但消息发送效率太低。

![输入图片说明](https://bright-boy.gitee.io/technical-notes/rocketmq/images/QQ%E6%88%AA%E5%9B%BE20220208145933.png)





##### 异步发送消息

异步发送消息是指，Producer发出消息后无需等待MQ返回ACK，直接发送下一条消息。该方式的消息可靠性可以得到保证，消息效率也可以。

![输入图片说明](https://bright-boy.gitee.io/technical-notes/rocketmq/images/QQ%E6%88%AA%E5%9B%BE20220208150004.png)

##### 单向发送消息

单向发送消息是指Producer仅负责发送消息，不等待、不处理MQ的ACK。该发送方式MQ也不返回ACK。该方式的下剖析发送效率最高，但消息可靠性较差。

![输入图片说明](https://bright-boy.gitee.io/technical-notes/rocketmq/images/QQ%E6%88%AA%E5%9B%BE20220208150023.png)



#### 发送顺序消息

同步发送消息时，根据HashKey将消息发送到指定的分区中，每个分区中的消息都是按照发送顺序保存的，即分区有序。如果 Topic 的分区被设置为 1，这个 Topic 的消息就是全局有序的。注意，顺序消息的发送必须是单线程，多线程将不再有序。

```java
public class OrderProducer {
    public static void main(String[] args) throws Exception {
        // 1. 初始化生产者，配置生产者参数，启动生产者
        DefaultMQProducer producer = new DefaultMQProducer("test-group");
        producer.setNamesrvAddr("159.75.91.15:9876");
        producer.setRetryTimesWhenSendAsyncFailed(2);
        producer.start();
        // 初.始化消息对象
        Message msg = new Message("TopicTest",
                "TagA",
                "test",
                "hello world".getBytes(RemotingHelper.DEFAULT_CHARSET));
        Integer hashKey = 123;
        //核心操作MessageQueueSelector、根据hashKey选择当前消息发送到哪个分区中
        producer.send(msg, (MessageQueueSelector) (mqs, msg1, org) -> {
            Integer id = (Integer) org;
            int index = id % mqs.size();
            return mqs.get(index);
        },hashKey);
        SendResult result = producer.send(msg);
        producer.shutdown();
    }
}
```

#### 发送延迟消息

​	生产者发送消息后，消费者在指定时间才能消费消息，这类消息被称为延迟消息或定时消息。生产者发送延迟消息前需要设置延迟级别，目前开源版本支持18个延迟级别：Broker在接收用户发送的消息后，首先将消息保存到名为SCHEDULE_TOPIC_XXXX的Topic中。此时，消费者无法消费该延迟消息。然后，由Broker端的定时投递任务定时投递给消费者。

![NeatReader-1669356547098](https://img.trivial.top/img/NeatReader-1669356547098.png)

​	保存延迟消息的实现逻辑见org.apache.rocketmq.store.schedule.ScheduleMessageService 类。按照配置的延迟级别初始化多个任务，每秒执行一次。如果消息投递满足时间条件，那么将消息投递到原始的Topic中。消费者此时可以消费该延迟消息。

```java
Message msg = new Message("TopicTest",
                "TagA",
                "test",
                "hello world".getBytes(RemotingHelper.DEFAULT_CHARSET));
msg.setDelayTimeLevel(4);
```

#### 发送事务消息

事务消息的发送、消费流程和延迟消息类似，都是先发送到对消费者不可见的 Topic中。当事务消息被生产者提交后，会被二次投递到原始Topic中，此时消费者正常消费。事务消息的发送具体分为以下两个步骤。

第一步：用户发送一个Half消息到 Broker，Broker设置 queueOffset=0，即对消费者不可见。

第二步：用户本地事务处理成功，发送一个 Commit 消息到 Broker，Broker 修改queueOffset为正常值，达到重新投递的目的，此时消费者可以正常消费；如果本地事务处理失败，那么将发送一个Rollback消息给Broker，Broker将删除Half消息。

**如果生产者忘记了提交或回滚，那么 Broker怎么处理 Half消息呢？**

Broker会定期回查生产者，确认生产者本地事务的执行状态，再决定是提交、回滚还是删除Half消息。

![](https://img.trivial.top/img/NeatReader-1669357602994.png)

```java
```



#### 发送单向消息



#### 批量消息发送





