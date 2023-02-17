## zookeeper 的特性及其利用场景（分布式锁 和 Master选举）

### zookeeper 的数据结构

 Zookeeper 的数据模型和分布式文件系统类似，是一种层次化的属性结构，如图所示。和文件系统不同的是，Zookeeper的数据是结构化储存的，并没有在物理上体现出文件和目录。

​	Zookeeper 树中的每个节点被称为Znode，Znode维护了一个 Stat状态信息，其中包含数据变化的时间和版本等。并且每个Znode可以设置一个value值，Zookeeper并不用与通信的数据库或者大容量的对象储存，他只是管理和协调有关的数据，所以value的数据大小不建议设置的分长达，较大的数据会带来更大的网络开销。

​	Zookeeper 上的每个节点的数据都是允许读和写的，读表示获得指定Znode上的value数据，写表示修改指定Znode上的value数据。另外，节点的 创建规则和文件系统中文件的创建规则类似。必须按照层级创建。举个简单的例子，如果需要创建/node/node1/node1-1，那么必须先创建/node/node1这两个层级节点。

### Zookeeper 的特性

Zookeeper 中 Znode在被创建的时候，需要指定节点的类型，节点类型分为：

- 持久化节点，节点的数据会被持久化到磁盘、
- 临时节点，节点的生命周期和创建改节点的客户端的声明周期一致，一旦该客户端的会话结束，则改客户端所创建的临时节点也会被删除。
- 有序节点，在创建的节点后面会增加一个递增的序列，该序列在同一级父节点之下是唯一的。需要注意的是，持久化节点或者临时节点也是可以设置为有序节点的。也就是持久化节点或者临时有序节点。

在3.5.3 版本之后又增加了两种类型的节点，分别是

- 容器节点，当容器节点下的最后一个节点被删除时，容器节点就会被删除。
- TTL节点，针对持久化节点或者持久化有序节点，我们可以设置一个存活时间，如果在存活时间之内该节点没有任何修改并且没有任何子节点，它就会被自动删除。

需要注意的是，在同一层级目录下，节点的名称必须是唯一的，就像我们在同一个目录下不能创建两个相同名字的文件夹一样。

### Watcher 机制

Zookeeper 提供了一种针对Znode的订阅/通知机制，也就是当Znode 节点状态发生变化或者Zookeeper 客户端连接状态发生变化时，会触发事件通知。这个机制在服务注册与发现中，针对服务调用者及时感知到服务提供者的变化提供了非常好的解决方案。

在 Zookeeper 提供的 java API 中， 提供了三种机制来针对Znode进行注册监听，分别是：

- getData()，用于获取指定节点的value信息，并且可以注册监听，当监听的节点进行创建、修改、删除操作时，会触发·响应的事件通知。
- getChildren()，用于获取指定及诶单的所有子节点，并且允许注册监听，当监听节点的子节点进行创建、修改、删除操作时，触发响应的事件通知。
- exists()， 用于判断指定节点是否存在，同样可以注册对指定节点的监听，监听的时间类型和getData() 相同。

Watcher 事件的触发都是一次性的，比如客户端通过getData(‘/node’,true)注册监听，如果/node节点发生数据修改，那么该客户端会收到一个修改事件通知，但是/node再次发生变化时，客户端无法收到Watcher事件，为了解决这个问题，客户端必须在收到的事件回调中再测注册事件。

### 常见应用场景分析

基于Zookeeper 中节点的特性，可以为多种应用场景提供解决方案。

#### 分布式锁

我们可以使用zookeeper的特性来实现分布式锁，锁的本质是排他性，就是避免在同一时刻多个进程访问某一个共享资源。

利用临时节点的特性，及同时节点的唯一性就可以完成这一个操作。

- 获取锁的过程

  在获取排他锁时，所有客户端可以去Zookeeper 服务器上 /Exclusive_Locks 节点下创建一个临时节点 /lock。Zookeeper 基于同级节点的唯一性，会保证所有客户端中只有一个客户端能创建成功，创建成功的客户端获得了排他锁，没有获得锁的客户端就需要通过Watcher机制监听/Exclusive_Locks 节点下子节点的变更事件。

- 释放锁的过程

  在获得锁的过程，我们定义的锁节点/lock 为临时节点，根据临时节点的特性，在下面两种情况下会触发锁的释放。

  - 获得锁的客户端因为异常断开了和服务器的连接，基于临时节点，/lock 节点会被自动删除。
  - 获得锁的客户端执行完业务逻辑之后，主动删除了创建的/lock 节点。

  当/ lock 节点被删除后，Zookeeper 会通知其他监听了/Exclusive_Locks 子节点变化的客户端。这些客户端收到通知后，再次发起创建/lock 节点的操作来获得排他锁。

#### Master 选举

Master 选举是分布式系统中非常常见的场景，在分布式架构中，为了保证服务的可用性，通常会采用集群模式，也就是当其中一个机器宕机后，集群中的其他节点会接替故障节点继续工作。在这种场景下，就需要 从集群中选举一个节点作为Master节点，剩余的节点都作为备份节点随时待命。当原有的Master节点出现故障后，还需要从集群中的其他备份节点中选举一个节点作为Master节点继续提供服务。

-  同一节点不能重复创建一个已经存在的节点，这个有点类似于分布式锁的实现场景，其实Master选举的场景也是如此。假设集群中有3个节点，需要选举出Master，那么这三个节点同时去Zookeeper服务器上创建一个临时节点 /master-election，由于节点的特性，只有一个客户端会创建成功，针对该节点注册Watcher事件，用于监控当前的Master机器是否存活，一旦发现Master “挂了”，也就是/master-election节点被删除了，那么其他的客户端将会重新发起Master选举操作。

- 利用临时有序节点的特性实现。所有参与选举的客户端在Zookeepeer 服务器的/master节点下创建一个临时有序节点，编号最小的节点表示Master，后续的节点可以监听前一个节点的删除时间，用于触发重新选举。

例子：client01、client02、client03三个节点去Zookeeper Server 的/master 节点下创建临时有序节点，编号最小的节点client01表示Master节点，client02 和 client03 三个节点去 Zookeeper Server 的/master 节点下创建临时有效节点，client01 创建 /client01-0000000001 ,client-02 创建 /client02-0000000003,client-03 创建 /client03-0000000002, 编号最小的节点 client01 表示Master节点，client02 和 clinet03 分别会通过 Watcher 机制监听比自己编号小的一个节点。如client02 监听/client03-0000000002，client03 监听/client01-0000000001, 如果最小的节点被删除了，那么client03便会被选举为Master。

![image-20220508214723763](https://gitee.com/lxsupercode/picture/raw/master/img/image-20220508214723763.png)

### Zookeeper 注册中心的实现原理

Dubbo 服务注册到Zookeeper 上之后，可以在Zookeeper服务器上看到如下图所示的树形结构。

![image-20220508220735081](https://gitee.com/lxsupercode/picture/raw/master/img/image-20220508220735081.png)

​	当Dubbo服务启动时，会取Zookeeper服务器上的 `/dubbbo/com.scmpe.dubbo.IHelloService/provides`目录下创建当前服务的URL，其中`com.scmpe.dubbo.IHelloService`是发布服务的接口全路径名称，providers表示服务提供者的类型，`dubbo://ip:port `表示服务发布的协议类型及访问地址。其中，URL是临时节点，其他皆为持久化节点。在这里URL为什么使用临时节点呢，因为如果注册该节点的服务器下线了，那么这个服务器·的URL地址就会从Zookeeper服务器上被移除。

​	当Dubbo 服务消费者启动时，会对/dubbbo/com.scmpe.dubbo.IHelloService/provides节点下的子节点注册Watcher监听，这样便可以感知到服务提供方节点的上下线变化，而防止请求发送到已经下线的服务器造成访问失败。同时，服务消费者会在/dubbbo/com.scmpe.dubbo.IHelloService/cosumers 下写入自己的URL，这样做的目的是可以在监控平台上看到某个Dubbo服务正在被哪些服务调用；最重要的是，Dubbo服务的消费者如果需要调用IHelloService服务，那么它先回去/dubbbo/com.scmpe.dubbo.IHelloService/provides 路径下获得所有服务的提供方URL列表，然后通过负载均衡算法计算出一个地址进行远程访问。

​	整体来看，服务注册和动态感知的功能用到了Zookeeper 中的临时节点，持久化节点、Watcher等，回头看前面分析的Zookeeper的应用场景可以发现，几乎所有的场景都是基于这些来完成的。另外，不得不提的是，Dubbo还可以针对不同的情况实现以下功能。

- 基于临时节点的特性，当服务提供者宕机或者下线时，注册中心会自动删除该服务提供者的信息
- 注册中心重启时，Dubbo能够自动回复注册数据及订阅请求。
- 为了保证节点操作的安全性，Zookeeper提供了ACL权限控制，在Dubbo中可以通过 dubbo.registry.username/dubbo.registry.password 设置节点的验证信息。
- 注册中心默认的根节点是/dubbo，如果需要针对不同环境设置不同的根节点，可以使用dubbo.registry.group修改根节点名称。

## Dubbo 高级应用

我们大多只知道Apache Dubbo 作为RPC通信框架的使用方法，以及服务注册中心的应用及原理，这仅仅是它的冰山一角。其实，Apache Dubbo更像一个生态，它提供了很多比较主流框架的集成。比如：

- 支持多种协议的服务发布，默认是dubbo://,还可以支持rest://、webservice://、thrift://等
- 支持多种不同的注册中心，如Nacos、Zookeeper、Redis，未来还会支持Consul、Eureka、Etcd等。
- 支持多种序列化技术，如 avro、fst、fastJson、hessian2、kyro等。

除此之外，Apache Dubbo 在服务治理方面的功能非常完善，比如集群容错、路由服务、负载均衡、服务降级、服务限流、服务监控、安全认证等。

### 容错模式

Dubbo 默认提供了 6中容错模式，默认为Failover Cluster。如果这六种容错模式不能满足你的需求，还可以自行扩展。这就是Dubbo的独特之处，几乎所有功能都提供了插拔式的扩展。

- **Failover Cluster** 失败自动切换，当服务调用失败后，会切换到集群中的其他机器进行重试，默认重试次数为2，通过属性restries = 2可以修改次数，但重试次数增加会带来更长的响应延迟。**这种模式常用于读操作，因为事物型操作会带来数据重复的问题**

- **Failfast Cluster** 快速失败，当服务调用失败后，立即报错，也就是只发起一次调用。**通常用于一些幂等的写操作，比如新增数据**，因为当服务调用失败时，很可能这个请求已经在服务器端处理成功，只是因为网络延迟导致响应失败，为了避免在结果不确定的情况下导致数据重复插入的问题，可以使用这种容错机制。
- **Failsafe Cluster**，失败安全。也就是出现异常时，直接忽略异常。
- **Failback Cluster**，失败后自动回复。服务调用出现异常时，在后台记录这条失败的请求定时重发。**这种模式适合用于消息通知操作，保证这个请求一定发送成功。**

- **Forking Cluster**，并行调用集群中的多个服务，只要其中一个成功就返回。可以通过forks = 2来设置最大并行数。
- **Brodest Cluster**，广播调用所有的服务提供者，任意一个服务报错则表示服务调用失败**，这种机制通常用于通知所有的服务提供者更新缓存或者本地资源**

**配置·方式**

​	在dubbo的@Service注解中增加 cluser = “xx”的参数。

```java
@Service(cluster = "failfast")
public class HelloServiceImpl implents IHelloService {
    
}
```

在实际应用中，查询语句容错侧率建议使用默认的Failover Cluster，而增删改操作建议使用 Fialfast Cluster 或者 FailOver Cluster(restries = “0”) 策略，防止出现数据重复添加等其他问题！建议在设计接口的时候把查询接口方法单独做成一个接口提供查询。

### 负载均衡

​	负载均衡应该不是一个陌生的概念，在访问量较大的情况下，我们可以通过水平扩容的方式增加多个节点来实现负载均衡，从而提升整体服务器的性能。

​	当服务调用者面对5个节点组成的服务提供方集群时，请求应该分发到集群中的哪个节点，取决于负载均衡算法。负载均衡可以分为硬件负载均衡和软件负载均衡，硬件负载均衡比较常见的就是F5，软件负载均衡目前比较主流的是Nginx。

​	在Dubbo 中提供了4中负载均衡算法，默认负载均衡策略是random。dubbo的负载均策略很也可以自行扩展。

- Random LoadBalance 随机算法。 可以针对性能较好的服务器设置较大的权重值，权重值越大，随机的概率越大。
- RoundRobin LoadBalance，轮询。按照公约后的权重设置轮询比例。
- LeastActive LoadBalance，最少活跃调用。处理较慢的节点会收到更少的请求。
- ConsistentHash LoadBalance，一致性Hash。相同参数的请求总是发送到同一个服务提供者。

**配置方式**

```java
@Service(cluster = "failfast",balance = "roundrobin")
```

### 服务降级

服务降级是一种系统保护策略，当服务器访问压力较大时，可以根据当前业务情况对不重要的服务进行降级，保证核心服务的正常运行。所谓降级，就是把一些非必要的功能在流量较大的时间段暂时关闭，比如在双11大促时，淘宝会把查看历史订单、商品评论等功能关闭，从而释放更多的资源来保障大部分用户能够正常完成交易。

 降级有多个层面的分类

- 按照是否自动化可以分为自动降级和人工降级
- 按照功能可以分为读服务降级和写服务降级

人工降级一般具有一定的前置性，比如在电商大促前，暂时关闭某些非核心业务服务。而自动降级更多的来自于系统出现某些异常的时候自动触发“兜底的流畅”，比如：

- 故障降级，调用的远程服务“挂了”，网络故障或者RPC服务返回异常。可以通过兜底的方案响应前端的请求。
- 限流降级，当请求达到阈值时，将后续的请求拦截，将请求放入排队系统或者直接返回降级页面。

Dubbo 提供了一种Mock 服务来实现服务降级，也就是当服务提供方出现网络异常无法访问时，客户端不抛出异常，而是通过降级配置返回兜底数据，操作步骤如下：

- 创建MockHelloService 类，这个类只需要实现需要自动降级的接口即可，然后重写接口中的抽象方法实现本地数据的返回。

```java
public class MockHelloService implents IHelloService {
    @Override
    public String sayHello(String s) {
        return "服务无法访问，返回降级数据";
    }
}
```



- 在 HelloController 类中修改@Reference 注解增加Mock参数。我们将 cluster 设置为 “failfast”, 让其失败立即报错，测试下降级的效果。

```java

@Reference(mock = "com.scmpe.springcloud.consumer.MockHelloSerivce",cluster = "failfast")
private IHelloService helloService;

@GetMapping("/say")
public String sayHello() {
    return helloService.sayHello("Mic");
}
```

- 当Dubbo访问服务提供者异常或者服务端的默认值超过默认时间时，访问/say 接口就会调用MockHelloSerivce的方法，返回降级结果。

### 主机绑定策略

​	主机绑定表示的是Dubbo服务对外发布的IP地址，默认情况下按照以下顺序来查找并绑定主机IP地址

- 查找环境变量中 DUBBO_IP_TO_BIND 属性配置的IP地址。
- 查找 dubbo.protocol.host 属性配置的Ip地址，默认是空，如果没有或者IP不合法，继续往下找。
- 通过LocalHost.getHostAddress 获取本机IP地址，如果获取失败，继续往下找
- 如果配置了注册中心的地址，则使用Socket 通信连接到注册中心的地址，使用for循环通过socket.getLocalAddress().getHostAddress()扫描各个网卡获取网卡IP地址。

​	上述过程·中，任意一个步骤检测到合法的IP地址，便会将其返回作为对外暴露的服务IP地址。需要主要的是，获取的IP地址并不是写入注册中心的地址。默认情况下，写入注册中心的IP地址优先选择环境变量中 DUBBO_IP_TO_REGISTRY 属性配置的IP地址。在这个属性没有配置的情况下，才会选择前面获得的IP地址并写入注册中心。

​	使用默认的主机绑定规则，可能会存在获取的IP地址不正确的情况，导致服务消费者与注册中心上拿到错误的URL 地址进行通信。因为Dubbo检测本地IP的策略是先调用LocalHost.getHostAddress，这个方法的原理是通过获取本机的hostname映射IP地址，如果它指向的是一个错误的IP地址，那么这个错误的地址将会作为服务发布的地址注册到Zookeeper节点上，虽然Dubbo服务能够正常启动，但是服务消费者却无法正常调用。按照Dubbo 中 IP 地址的查找规则，如果遇到这种情况，可以使用多种方式来解决。

- 在 /etc/hosts 中配置机器名对应正确的 IP 地址
- 在环境变量中添加 DUBBO_IP_TO_BIND 或者 DUBBO_IP_TO_REGISTERY 属性，Value值为绑定的主机地址。
- 通过 dubbo.protocol.host 设置主机地址。

​	除获取绑定主机IP地址外，对外发布的端口也是需要注意的，Dubbo框架中针对不同的协议都提供了默认的端口号：

- Dubbo 协议的默认端口后 是 20880
- WebService 协议的默认端口号是 80

在实际使用过程中，建议制定端口后，避免端口冲突。

## Dubbo 核源码分析

Dubbo的有很多的设计值得学习和借鉴。需要理解的几个点：

- SPI 机制
- 自适应扩展点
- Ioc 和 Aop
- Dubbo 如何与 Spring 集成

### Dubbo 核心之SPI

​	在Dubbo的源码中，很多地方会存在下面这样三种代码，分别是自适应扩展点，指定名称的扩展点，激活扩展点：

```java
ExtensionLoader.getExtensionLoader(XXX.class).getAdaptiveExtension();
ExtensionLoader.getExtensionLoader(XXX.class).getExtension(name);
ExtensionLoader.getExtensionLoader(XXX.class).getActivateExtension(url,key);
```

​	这种扩展点实际上就是Dubbo 中的 SPI机制。关于SPI，不知道大家是否还有印象，Springboot 自动装配的SpringFactoiesLoader，它也是一种SPI机制。

#### java SPI 扩展点实现

 SPI 全称是 Service Provider Interface，原本是JDK 内置的一种服务提供发现机制，它主要用来做服务的扩展实现。SPI 机制在很多场景中都有运用，比如数据库连接，JDK提供了 java.sql.Driver 接口，这个驱动类在JDK中并没有实现，而是由不同的数据库厂商来实现，比如Oracle、Mysql这些数据库驱动包都会实现这个接口，然后JDK利用SPI 机制从classpath 下找到相应的驱动来获取得到指定数据库的连接。这种插拔式的扩展加载方式，也同样遵循一定的协议约定，比如所有的扩展点必须要放在 resources/META-INF/services 目录下，SPI机制会默认扫描这个路径下的属性文件来完成加载。

下面举个栗子：

- 创建一个普通的Maven 工程 Driver，定义一个接口。这个接口只是一个规范，并没有实现，由第三方厂商来提供实现。

```java
public interface Driver {
    String connect();
}
```

- 创建另一个普通的Maven工程 Mysql-Driver，添加Driver 的 Maven依赖

```maven
<dependency>
    <groupId>com.scmpe.book.spi</groupId>
    <artifactId>Driver</artifactId>
    <version>1.0-SNAPSHOT</version>
</dependency>

```

- 创建MysqlDriver,实现Driver接口，这个接口表示一个第三方的扩展实现

```java
public class MysqlDriver implements Driver {
    @Override
    public String connect() {
        return "连接Mysql 数据库";
    }
}
```

- 在 resources/META-INF/services 目录下穿件一个以Driver 接口全路径命名的文件com.scmpe.book.spi.Driver ，在里面填写这个Driver的实现类

  ```java
  com.scmpe.book.spi.MysqlDriver
  ```

- 创建一个测试类，使用ServiceLoader 加载

```java
@Test
public void connectTest() {
    ExtensionLoader<Driver> extensionLoader = ExtensionLoader.getExtensionLoder(Driver.class);
    Driver driver = extensionLoader.getExtension("mysqlDriver");
    System.out.println(driver.connect());
}
```

Dubbo SPI 扩展点源码

​	前面我们用 `ExtensionLoader.getExtensionLoader.getExtension() `演示了Dubbo中 SPI 用法，下面我们基于这个方法来分析Dubbo源码中是如何实现SPI的.

​	这段代码分为两个部分：首先我们通过`ExtensionLoader.getExtensionLoader `来获得一个`ExtensionLoader `实例，然后通过`getExtension()` 方法获得指定名称的扩展点。先来分析第一部分。

**ExtensionLoder.getExtensionLoader**

这个方法用于返回一个ExtensionLoader实例，主要逻辑为:

1. 先从缓存中获取与扩展类对应的ExtensionLoader;
2. 如果缓存未命中，则创建一个新的实例，保存到EXTENSION_LOADERS集合中缓存起来。
3. 在 ExtensionLoader 构造方法中，初始化一个objectFactory，后续会用到，暂时先不管

```java
public static <T> ExtensionLoader<T> getExtensionLoader(Class<T> type) {
    // 省略部分代码
    ExtensionLoder<T> loder = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
    if (loder == null) {
        EXTENSION_LOADERS.putIfAbsent(type,new ExtensionLoader<T>(type));
        loder = (ExtensinoLoder<T>) EXTENSION_LOADERS.get(type);
    }
    return loader;
}
//构造方法
private ExtensionLoader(Class<?> type) {
    this.type = type;
    ObjectFactory = (type == ExtensionFactory.class ? null : ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension());
}
```

getExtension()

​	这个方法用于 根据指定名称获得对应的扩展点并返回。在前面的演示案例中，如果name是mysqlDriver，那么返回的实现类应该MysqlDriver。

- name 用于参数的判断，其中，如果 name=“true”, 则返回一个默认的扩展实现。

- 创建一个Holder对象，用户缓存该扩展点的实例。
- 如果缓存中不存在，则通过createExtension(name) 创建一个扩展点。

```java
public T getExtension(String name) {
    if(StringUtils.isEpty(name)) {
        throw new IllegalArgumentException("Extension name = null");
    }
    if ("true".equals(name)) {
        return getDefaultExtension();
    }
    // 创建或者返回一个Holder对象，用于缓存实例
    final Holder<Object> holder = getOrCreateHolder(name);
    Object instance = holder.get();
    if (instance == null) { //如果缓存不存在，则创建一个实例
 		synchronized (holder) {
            instance = holder.get();
			if (instance == null) {
                instance = createExtension(name);
                holder.set(instance);
            }            
        }       
       
    }
    return (T)instance;
}
```

上面代码的意思就是先查缓存，缓存未命中，则创建一个扩展对象。 不难猜出，createExtension() 应该就是去指定路径下找name对应的扩展点的实现，并且实例化之后返回。

- 通过 getExtensionClasses().get(name)获取一个扩展类
- 通过反射实例化之后缓存到EXTENSION_INSTANCES集合中。
- injectExtension 实现依赖注入
- 把扩展类对象通过Wrapper进行包装。

```java
private T createExtension(String name) {
    Class<?> clazz = getExtensionClasses().get(name);
    if (clzz == null) {
        throw findException(name);
    }
    try {
        T instance = (T) EXTENSION_INSTANCES.get(clazz);
        if (instance == null) {
            EXTENSION_INSTANCES.putIfAbsent(clazz,clazz.newInstance());
            instance = (T) EXTENSION_INSTANCES.get(clazz);
        }
        //依赖注入
        injectExtension(instance);
        //通过Wrapper包装
        Set<Class<?>> WrapperClasses = cachedWrapperClasses;
        if (CollectUtils.isNotEmpty(wrapperClasses)) {
        	for(Class<?> wrapperClass : wrapperClasses) {
                instance = injectExtension((T) WrapperClass.getConstructor(type).newInstance(instance))
            }
        }
        initExtension(instance);
        return instance;
    } catch(Throwable t) {
        throw new IllegalStateException()
    }
}
```

- 从·缓存中获取已经被加载的扩展类
- 如果未命中缓存，则调用loadExtensionClasses 加载扩展类

```java
private Map<String,Class<?>> getExtensionClasses() {
    Map<String,Class<?>> classes = cachedClasses.get();
    if (classes == null) {
        synchronized (cachedClasses) {
            classes = cachedClasses.get();
            if (classes == null) {
                classes = loadExtensionClasses();
                cachedClasses.set(classes);
            }
        }
    }
    return classes;
}
```

Dubbo 中代码实现套路基本差不多，先访问缓存，缓存未命中再通过loadExtensionClasses加载2扩展类，这个方法主要做两件事。

- 通过cacheDefaultExtensionName 方法回去当前扩展接口的默认扩展对象，并且缓存
- 同通过过loadDirectory 方法加载指定文件目录下的配置文件。

```java
private Map<String,Class<?>> loadExtensionclasses() {
	cacheDefaultExtensionName();//获得当前type接口默认的扩展类
	Map<String,Class<?>> extensionclasses = new HashMap<>();
    //解析指定路径下的文件
    loadDirectory(extensionclasses, DUBBO_INTERNAL_DIRECTORY, type.getName(), true);
    loadDirectory(extensionClasses, DUBBO_INTERNAL_DIRECTORY, type.getName().replace("org.apache", "com.alibaba"),true);
    loadDirectory(extensionclasses,DUBBO_DIRECTORY,type.getName());
    loadDirectory(extensionClasses, DUBBO_DIRECTORY,type.getName().replace("org.apache","com.alibaba"));
    loadDirectory(extensionclasses,SERVICES_DIRECTORY,type.getName());
    loadDirectory(extensionclasses,SERVICES_DIRECTORY,type.getName().replace("org.apache","com.alibaba"));
    return extensionClasses;
}
```

loadDirectory 方法的逻辑比较简单，就是从指定目录下，根据传入的type全路径名找到对应的文件，解析内容后加载并保存到extensionClasses集合中。

cacheDefaultExtensionName 方法也比较简单，但是它和业务有一定的关系。

- 获得指定扩展接口的@SPI 注解
- 得到@SPI 注解中的名字，保存到cachedDefaultName属性中。

```java
private void cacheDefaultExtensionName() {
    final SPI defaultAnnotation = type.getAnnotation(SPI.class);
    if (defaultAnnotation == null) {
        return;
    }
    // 得到注解中的value值
    String value = defaultAnnotation.value();
    if (value = value.tirm().lenth > 0) {
        String[] names = NAME_SEPARATOR.spilt(value);
        if (names.length > 1) {
            throw new IllegalStateException()
        }
        if (names.lenth == 1) {
            cachedDefault = names[0];
        }
    }
}
```

以 Dubbo 中的org.apache.dubbo.rpc.Protocol 为例，在@SPI 注解中有一个默认值dubbo，这意味着如果没有显式的指定协议类型，默认采用Dubbo协议来发布服务。

```java
@SPI("dubbo")
public interface Protocol {
    //...
}
```

这便是dubbo中指定名称的扩展类加载流程。

### 自适应扩展点

​	自适应扩展点可以理解为适配器扩展点。简单来说就是能够根据上下文动态配一个扩展类。

```java
ExtensionLoder.getExtensionLoader(class).getAdaptiveExtension();
```

自适应扩展点通过@Adaptive注解来声明，它有两种使用方式

- Adaptive 注解定义在类上面，表示当前类为自适应扩展类

  ```java
  @Adaptive
  public class AdativeCompiler implents Compiler {
      // 省略
  }
  ```

  AdaptiveCompiler 类就是自适应扩展类，通过 ExtensionLoader.getExtensionLoader(Compiler.class).getAdaptiveExtension();可以返回AdaptiveCompiler类的实例。

- @Adaptive 注解定义在方法层面，会通过动态代理的方式生成一个动态字节码，进行自适应匹配。、。

```java
public interface Protocol {
    int getDefaultPort();
    
    @Adaptive
    <T> Exporter<T> export(Invoker<T> invoker) throws RpcException;
    @Adaptive
    <T> Invoker<T> refer(Class<T> type,URL url) throws RpcException;
}
```

Protocol 扩展类中的两个方法声明了 @Adaptive 注解，意味着这是一个自适应方法。在Dubbo 源码中有很多地方通过下面这行代码来获得一个自适应扩展点

```java
Protocol protocol = ExtensionLoader.getExtensionLoader(Protocol.class).getAdaptiveExtension();
```

接下来，基于Protocol 的自适应扩展点方法 ExtensionLoader.getExtensinoLoader(Protocol.class).getAdaptiveExtensino() 来分析它的源码实现。

从源码来看，getAdaptiveExtension 方法非常简单，只做了两件事：

- 从缓存中获取自适应扩展点实例。
- 如果缓存未命中，则通过createAdaptiveExtension 创建自适应扩展点。

```java
public T getAdaptiveExtension() {
    Object instance = this.cachedAdaptiveInstance.get();
    if (instance == null) {
        if (this.createAdaptiveInstanceError != null) {
            throw new IllegalStateException();
        }
        // 创建自适应扩展点实例，并放置到缓存中
        synchronized(this.cachedAdativeInstance) {
            instance = this.cachedAdaptiveInstance.get();
            if (instance == null) {
                try {
                    instance = this.createAdaptiveExtension();
                    this.cachedAdaptiveInstance.set(instance);
                }
                }catch(Throwable var5) {
                this.createAdaptiveInstanceError = var5;
                throw new IllegalstateException("Failed to create adaptive instance:+var5.toString(), var5);

            }
            
        }
    }
    return instance;
}
```

按照之前对于自适应扩展点的分析，可以基本猜测出createAdaptiveExtension 方法的实现机制，、

- getAdaptiveExtensionClasses 获取一个自适应扩展类的实例
- injectExtension完成依赖注入

```java
private T createAdaptiveExtension( {
    try {
    return this.injectExtension(this.getAdaptiveExtensionClass().newInstance());}catch (Exception var2){
    throw new IllegalStateException("can't create adaptive extension " + this.type +", cause:" +var2.getMessage(), var2);
    }
}
```

injectExtension后面再分析，先看getAdaptiveExtensinoClass.

- 通过 getExtensionClasses 方法加载当前春如类型的所有扩展点，缓存到一个集合里面
- 如果 cachedAdaptiveClass为空，则调用createAdaptiveExtensionCalss 进行创建

```java
private Class<?> getAdaptiveExtensionClass() {
    this.getExtensionClasses();
    return this.cachedAdaptiveClass != null ? this.cachedAdaptiveClass : (this.cachedAdaptiveClass = this.createAdaptiveExtensionClass());
}
```

getExtensionClasses方法之前讲过，直接看createAdaptiveExtensionClass 方法，它涉及动态字节码的生成·和加载。

- code 是一个动态拼接的类。
- 通过Compiler 进行·动态编译。

```java
private Class<?> createAdaptiveExtensionClass() {
    String code = (new AdaptiveClassCodeGenerator(this.type,this.cachedDefaultName)).generate();
    ClassLoader classLoader = findClassLoader();
    Compiler compiler = (Compiler)getExtensionLoader(Compiler.class).getAdaptiveExtension();
    return compiler.compile(code,classLoader);
}
```

在基于 Protocol接口的自适应扩展点加载中，此时code拼接的字符串如下(为了排版美观，去掉了一些无用的代码)）。

```java
public class Protocol$Adaptive implements Protocol {
    //省略部分代码
    public Exporter export(Invoker arg0) throws org.apache. dubbo.rpc.RpcException {
    if (arge == null) throw new IllegalArgumentException("Invoker argument == null");
    if (arg0.getUrl()== nul1)
    	throw new IllegalArgumentException("Invoker argument getUrl() - null");
    URL url = arg0.getUr1();
    String extName = (url.getProtocol() == null ?"dubbo":url.getProtoco1());\
    if (extName == null)
    	throw new IllegalstateException("Failed to get extension （Protocol) name from”+url.toString() +")use keys([protocol])");
    //根据名称获得指定扩展点
    Protocol extension = ExtensionLoader.getExtensionLoader(Protocol.class).getExtension(extName);
    return extension. export(arg0);
}
```

```java
public Invoker refer(Class arg0，URL arg1) throws RpcException {
    if (arg1 ==null) throw new IllegalArgumentException("url == null");
    URL url = arg1;
   	String extName =(url.getProtocol()== null ? "dubbo":url.getProtocol());
    if (extName == null) throw new IllegalstateException("Failed to get extension (Protocol) name from ur1("+ url.toString() +") use keys([protocol])");
    Protocol extension = ExtensionLoader.getExtensionLoader(Protocol.class).getExtension(extName):
    return extension.refer(arg0,arg1);
}
```

Protocol$Adaptive 是一个动态生成的自适应扩展类，可以按照下面这种方式使用：

```java
Protocol protocol=ExtensionLoader.getExtensionLoader(Protocol.class).getAdaptiveExtension();
protocol.export( ...);
```

当调用 protocol.export() 时，实际上会调用Protocol$Adaptive类中的export方法。而这个方法，无非就是根据Dubbo服务配置的协议名称，通过getExtension获得相应的扩展类。

## Dubbo 中的 IOC 和 AOP

IOC 和 AOP 我们并不陌生，他是Spring Framework中的核心功能，实际上Dubbo中也用到了这两种机制。下面从源码层面逐个分析这两种机制的体现。 

### IOC

​	IoC 中一个非常重要的思想是，系统运行时，动态地向某个对象提供它需要的其他对象，这种机制是通过DI（依赖注入）实现的。

在分析Dubbo SPI机制时，createExtension方法中有一段代码如下：

```java
private T createExtension(String name) {
    try {
        T instance = (T) EXTENSION_INSTANCES.get(clazz);
        if (instance == null) {
            EXTENSION_INSTANCES.putIfAbsent(clazz, clazz.newInstance());
            instance = (T)EXTENSION_INSTANCES.get(clazz);
        }
		injectExtension(instance);
        //省略部分代码
        return instance
    }catch(Throwable t) {
        //省略部分代码
    }
}
```

injectExtension就是依赖注入的实现，整体逻辑比较简单。

- 遍历被加载的扩展类中所有set方法
- 得到set方法中的参数类型，如果参数类型是对象类型，则获得这个set方法中的属性名称。
- 使用自适应扩展点加载该属性名对应的扩展类。
- 调用set方法完成赋值。

```java
private T injectExtension(T instance) {
    if (objectFactory == null) {
        return instance;
    }
   	try {
        for (Method method : instance.getClass().getMethods()) {
            if (!isSetter(method)) {
                continue;
            }
            if (method.getAnnotation(DisableInject.class) != null) {
                continue;
            }
            // 获得扩展类中方法的参数类型
            Class<?> pt = method.getParameterTypes()[0];
            // 如果不是对象类型,跳过
            if (ReflectUtils.isPrimitives(pt)) {
                continue;
            }
            try {
                // 获取方法对应的属性名称
                String property = getSetterProperty(method);
                // 根据class及name，使用自适应扩展点加载并且通过set方法进行赋值
                Object object = objectFactory.getExtension(pt,property);
                if (object != null) {
                    method.invoke(instance,object);
                }
            }catch(Exception e) {
               logger.error("Failed to inject via method " + method.getName()+"of interface " + type.getName() +":" +e.getMessage(),e);
        	} 
        }catch(Exception e) {
                logger.error(e.getMessage,e);
        }
        return instance;
    }
}
```

总结一下，injectExtension主要功能是，如果当前加载的扩展类中存在一个需要注入的对象，（该对象必须提供setter方法）那么就会通过自适应扩展点加载并赋值。

以org.apache.dubbo.registry.integration.RegistryProtocol为例，它里面就有一个Protocol成员对象，并且为它提供了setProtocol方法，那么当RegistryProtocol扩展类被加载时，就会自动注入protocol成员属性的实例。

```java
public class RegistryProtocol implements Protocol {
    //省略部分代码
    private Protocol protocol;
	public void setProtocol(Protocol protocol) {
        this.protocol = protocol;
    }
    //省略部分代码
}
```

### AOP

​	AOP全称为Aspect Oriented Programming，意思是面向切面编程，它是一种思想或者编程范式。它的主要意图是把业务逻辑和功能逻辑分离，然后再运行期间或者类加载期间进行织入。这样做的好处是，可以降低代码的复杂性，提高重用性。

​	在Dubbo API机制中，同样在ExtensionLoader类中的createExtension 方法中体现了AOP的设计思想。

```java
private T createExtension(String name){
    //..
    try {
        //...
        Set<class<?>> wrapperClasses = cachedwrapperClasses;if (collectionutils.isNotEmpty(wrapperclasses)){
        for (class<?> wrapperClass : wrapperClasses){
            instance = injectExtension((T) wrapperclass.getConstructor(type).newInstance(instance));
            }
        }
        initExtension( instance);
        return instance;
    }catch (Throwable t){
        //...
    }
}
```

这段代码再前面的章节中讲过，仔细分析下下面这行代码

```java
instance = injectExtension((T) wrapperClass.getConstructor(type).newInstance(instance));
```

其中分别用了依赖注入和AOP思想，AOP 思想的体现是基于 Wrapper 装饰器类实现对原有的扩展类instance 进行包装。



## 深入解读Nacos源码

Nacos 源码部分，我们主要阅读三部分

- 服务注册
- 服务地址的获取
- 服务地址变化的感知

下面我们基于这三个方面方面来分析Nacos是如何实现的

### SPring Cloud 什么时候完成服务注册

在 Spring-cloud-common 包中有一个类 org.springframework.cloud.clinet.serviceregistry.ServiceRegistry,它是Spring cloud提供的服务注册的标准。集成到Spring Cloud提供的服务注册的标准。集成到 Spring Cloud 中实现服务注册的组件，都会实现该接口。

```java
public interface ServiceRegistry<R extends Registration>{
    void register(R registration);
    void deregister(R registration);
    void close();
    void setStatus(R registration,string status);
    <T>T getStatus(R registration);
}
```

这个接口有一个实现类是com.alibaba.cloud.nacos.registry.NacosServiceRegistry。它是什么时候触发服务注册动作的呢?

**Spring Cloud集成Nacos的实现过程**

在spring-cloud-commons包的META-INF/spring.factories 中包含自动装配的配置信息下:

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.cloud.client.CommonsclientAutoConfiguration,\
org.springframework.cloud.client.ReactiveCommonsClientAutoConfiguration,\
##省略部分代码
org.springframework.cloud.client.serviceregistry.AutoServiceRegistrationAutoConfiguration
```

其中 AutoServiceRegistrationAutoConfiguration 就是服务注册相关的配置类，代码如下：

```java
@Configuration(
	proxyBeanMethods = false
)
@Import({AutoServiceRegistrationConfiguration.class})
@Conditional0nProperty(
    value = { "spring.cloud.service-registry.auto-registration.enabledmatchIfMissing = true"},
    matchIfMissing = true
)
public class AutoServiceRegistrationAutoConfiguration {
    @Autowired(required = false)
	private AutoServiceRegistration autoServiceRegistration;
    
	@Autowired
    private AutoServiceRegistrationProperties properties;
    
    public AutoServiceRegistrationAutoConfiguration() {}
    
    @PostConstruct
    protected void init() {
        if (this.autoServiceRegistration == null && this.properties.isFailFast()){ 
            throw new IllegalStateException("Auto Service Registration has been requested,but there is no AutoServiceRegistration bean");
}
```

在 AutoServiceRegistrationAutoConfiguration 配置类中，可以看到诸如了一个AutoServiceRegistration实例。可以看出，AbstractAutoServiceRegistration 抽象类实现了该接口，并且最重要的是NacosAutoServiceRegistration 继承了 AbstractAutoServiceRegistration。

![image-20220615151408400](http://img.trivial.top/img/image-20220615151408400.png)

我们重点关注 ApplicationListener，熟悉Spring 的读者应该知道它是一种事件监听机制

```java
public interface ApplicationListener<E extends ApplicationEvent> extends EventListener {
	void onApplicationEvent(E var1);
}
```

其中方法的作用是监听某个指定的事件。而AbstractAutoServiceRegistration实现了该抽象方法，并且监听WebServerInitializedEvent事件(当Webserver初始化完成之后)，调用this.bind(event)方法。

```java
public abstract class AbstractAutoServiceRegistration<R extends Registration> implement AutoServiceRegistration,ApplicationContextAware,ApplicationListener<webServerInitializedEvent> {
    public void onApplicationEvent(WebServerInitializedEvent event){
  	  this.bind(event);
    }
}
```

继续跟进this.bind方法,可以发现最终会调用NacosServiceRegistry.register方法进行服务注册。 

