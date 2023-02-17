# [Dubbo](https://so.csdn.net/so/search?q=Dubbo&spm=1001.2101.3001.7020)项目将Nacos作为其注册中心和配置中心

## Dubbo整合Nacos

### 服务提供者的相关配置

**依赖**

```xml
<!--dubbo依赖-->
 <!-- SpringCloud Alibaba Nacos -->
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
</dependency>
<!-- SpringCloud Alibaba Nacos Config -->
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
</dependency>
<!-- Dubbo Registry Nacos -->
<dependency>
    <groupId>org.apache.dubbo</groupId>
    <artifactId>dubbo-registry-nacos</artifactId>
    <version>2.7.3</version>
</dependency>

```

```yaml
server:
  port: 14511
spring:
  application:
    name: provider-service
  main:
    allow-bean-definition-overriding: true
dubbo:
  application:
    name: provider-service
  registry:
    address: nacos://127.0.0.1:8848
    username: nacos
    password: nacos
  scan:
    base-packages: com.example.service.impl
  protocol:
    name: dubbo
```

```java
 ErrCode:-400, ErrMsg:com.google.common.collect.Sets$SetView.iterator()Lcom/google/common/collect/UnmodifiableIterator;
```

**错误原因：**jar包冲突

**解决错误：**

```xml
<dependency>
    <groupId>com.scmpe</groupId>
    <artifactId>community-common-datasource</artifactId>
    <exclusions>
        <exclusion>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
        </exclusion>
    </exclusions>
    <version>1.0.0-RELEASE</version>
</dependency>
```

```java
 Injection of @Reference dependencies is failed; nested exception is java.lang.NoClassDefFoundError: org/apache/commons/lang3/StringUtils
```

**错误原因：**缺少commons-lang3的jar包，应该是哪个依赖的版本不对，不好找，所以直接把这个依赖加上就行了

**解决错误：**

```xml
 <dependency>
     <groupId>org.apache.commons</groupId>
     <artifactId>commons-lang3</artifactId>
     <version>3.8.1</version>
</dependency>
```

### gateWay 模块启动报错

```java
Spring MVC found on classpath, which is incompatible with Spring Cloud Gateway at this time. Please remove spring-boot-starter-web dependency.
```

排除springmvc 依赖

```xml
<exclusions>
    <exclusion>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </exclusion>
</exclusions>
```