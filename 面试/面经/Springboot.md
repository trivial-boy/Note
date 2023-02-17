# Springboot 自动装配原理

Springboot 自动装配简单点说，就是自动将Bean装配到Ioc容器中，在了解Springboot 自动装配之前我们先来聊聊Spring 是怎么注入和配置Bean的。

## Spring Ioc/DI

loC ( Inversion of Control)和 DI (Dependency Injection)的全称分别是控制反转和依赖注入。如何理解这两个概念呢?

### loC
loC(控制反转）实际上就是把对象的生命周期托管到Spring容器中，而反转是指对象的获取方式被反转了，这个概念可能不是很好理解，咱们通过两张图来了解一下 loC的作用，下图表示的是传统意义上对象的创建方式，客户端类如果需要用到User 及 UserDetail，需要通过new来构建，这种方式会使代码之间的耦合度非常高。

![image-20220502090416402](https://gitee.com/lxsupercode/picture/raw/master/img/image-20220502090416402.png)

当使用Spring loC容器之后，客户端类不需要再通过new来创建这些对象，图2在图1的基础上增加了loC容器后,客户端类获得User 及 UserDetail对象实例时，不再通过new来构建，而是直接从loC容器中获得。那么Spring loC"容器中的对象是什么时候构建的呢?在早期的Spring中，主要通过XML的方式来定义Bean，Spring 会解析XML文件，把定义的Bean装载到loC容器中。

![图2](https://gitee.com/lxsupercode/picture/raw/master/img/image-20220502105202253.png)

### DI

DI(Dependency Inject)，也就是依赖注入，简单理解就是loC容器在运行期间，动态地把某种依赖关系注入组件中。为了彻底搞明白DI的概念，我们继续看一上面的图2。在Spring配置文件中描述了两个 Bean,分别是User和UserDetail,这两个对象从配置文件上来看是没有任何关系的，但实际上从类的关系图来看，它们之间存在聚合关系。如果我们希望这个聚合关系在 loC容器中自动完成注入，也就是像这段代码一样，通过user.getUserDetail来获得UserDetail 实例，该怎么做呢?

```java
ApplicationContext context = new FileSystemXmlApplicationContext("...");
User user = context.getBean(User.class);
UserDetail userdetail = user.getUserDetail();
```

​	其实，我们只需要在Spring 的配置文件中描述Bean之间的依赖关系，Ioc容器在解析该配置文件的时候，就会根据Bean的依赖关系进行注入，这个过程就是依赖注入

```xml
<bean id="user" class="User">
	<property name="userDetail" ref="userDetail"/>
</bean>
<bean id="userDetail" class="UserDetail"/>
```

​	实现依赖注入的方法有三种，分别是接口注入、构造方法注入和setter方法注入。不过现在基本上都基于注解的方式来描述Bean之间的依赖关系，比如@Autowired、@Inject和@Resource。

### Bean 装配方式的升级

​	基于XML配置的方式很好地完成了对象声明周期的描述和管理,但是随着项目规模不断扩大,XML的配置也逐渐增多，使得配置文件难以管理。另一方面，项目中依赖关系越来越复杂，配置文件变得难以理解。这个时候迫切需要一种方式来解决这类问题。
​	随着JDK 1.5带来的注解支持，Spring 从2.x开始，可以使用注解的方式来对Bean进行声明和注入，大大减少了XML 的配置量。
​	Spring升级到3.x后，提供了JavaConfig 的能力，它可以完全取代XML，通过Java代码的方式来完成 Bean 的注入。所以，现在我们使用的Spring Framework或者Spring Boot，已经看不到XML配置的存在了。

**XML 配置方式**

```xml
<?xm1 version="1.0" encoding="UTF-8"?>
<beans xmIns="http:/ /www . springframework.org/schema/beans"
	   xmIns:xsi="http: / / www. w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">
<! --bean的描述-->
</beans>
```

使用javaConfig形式后，只需要使用@Configuration 注解即可，它等同于XML的配置形式。

```java
@Configuration
public class Springconfigclass{
// Bean 的描述
}
```

**bean装载方式的变化**

基于XML 形式的装载方式

```java
<bean id="beanDefine" class="com.gupaoedu.spring.BeanDefine"/>
```

基于JavaConfig 的配置形式，可以通过@Bean注解来将一个对象注入loC容器中，默认情况下采用方法名称作为该Bean 的id。

```java
@Configuration
public class SpringConfigclass{
    @Bean
	public BeanDefine beanDefine(){
    	return new BeanDefine();
    }
}
```

**依赖注入的变化**

在XML形式中，可以通过三种方式来完成依赖注入，比如setter方式注入

```xml
<bean id="beanDefine" class="com.scmpe.spring.BeanDefine">
	<property name="dependencyBean" ref="dependencyBean"/>
</bean>
<bean id="dependencyBean" class="com.scmpe.spring.dependencyBean"/>
```

在JavaConfig 中，可以这样来表述

```java
public class SpringConfigClass{
    @Bean
    public BeanDefine beanDefine() {
        public BeanDefine=new BeanDefine();
        beanDefine.setDependencyBean(dependencyBean());
        return beanDefine;
    }
	@Bean
    public DependencyBean dependencyBean() {
        return new DependencyBean();
    }
}
```

**其他配置的变化**

除了前面的几种配置，还有常见的配置，比如：

- @ComponentScan对应XML形式的<context:component-scan base-package="">，它会扫描指定包路径下带有@Service、@Repository、@Controller、@Component 等注解的类,将这些类装载到IoC容器。

- @Import对应XML形式的 <import resource=""/>，导入其他的配置文件。

虽然通过注解的方式来装配 Bean，可以在一定程度上减少XML配置带来的问题，但本质问题仍然没有解决，比如:

- 依赖过多。Spring可以整合几乎所有常用的技术框架，比如JSON、MyBatis、Redis、Log等，不同依赖包的版本很容易导致版本兼容的问题。
- 配置太多。以Spring使用JavaConfig方式整合MyBatis为例，需要配置注解驱动、配置数据源、配置MyBatis、配置事物管理器等，这些只是集成一个技术组件需要的基础配置，在一个项目中这类配置很多，开发者需要做很多类似的重复工作。
- 运行和部署很烦琐。需要先把项目打包，再部署到容器上。

如何让开发者不再需要关注这些问题，而专注于业务呢?好在，Spring Boot诞生了。

## SpringBoot

Spring Boot并不是一个新的技术框架，其主要作用就是简化Spring应用的开发，开发者只需要通过少量的代码就可以创建一个产品级的Spring应用，而达到这一目的最核心的思想就是“约定优于配置(Convention over Configuration) ”。

在 Spring Boot 中，约定优于配置的思想主要体现在以下方面（包括但不限于）

- Maven目录结构的约定。
- Spring Boot默认的配置文件及配置文件中配置属性的约定。
- 对于Spring MVC的依赖，自动依赖内置的Tomcat容器。
- 对于Starter 组件自动完成装配。

### Spring Boot的核心

Spring Boot是基于Spring Framework 体系来构建的，所以它并没有什么新的东西，但是要想学好Spring Boot，必须知道它的核心:

- Starter组件，提供开箱即用的组件。

- 自动装配，自动根据上下文完成 Bean的装配。
- Actuator，Spring Boot应用的监控。
- Spring Boot CLI，基于命令行工具快速构建Spring Boot应用。

其中，最核心的部分应该是自动装配，Starter组件的核心部分也是基于自动装配来实现的。



## SpringBoot 自动装配原理

Springboot自动装配简单概述就是自动将Bean装配到Ioc容器中，接下来，我们通过一个Spring boot 整合 Redis 的例子来了解一下自动装配。

- 添加Stater依赖

  ```java
  <dependency>
  	<groupId>org.springframework.boot</groupId>
  	<artifactId>spring-boot-starter-data-redis</artifactId>
  </dependency>
  ```

- 在 application.properties 中配置 Redis的数据源

```properties
spring.redis.host=localhost
spring.redis.port=6379
```

- 在 TestController 中 使用 RedisTemplate实现Redis操作

```java
@Restcontroller
public class HelloController {
	@Autowired
	RedisTemplate<String, string> redisTemplate;
    @GetMapping( "/hello")
    public String hello(){
    	redisTemplate.opsForValue().set("key" , "value");return "He1lo world";
    }
}

```

在这个例子中，我们并没有将RedisTemplate 注入到Ioc容器中， 但是HelloController 中却可以直接使用@Autowired注入redisTemplate实例，这说明，Ioc容器中已经有RedisTemplate 。这就是Spring boot 的自动装配，只需要添加一个Starter依赖，就能完成该依赖组件相关Bean的自动注入，不难猜出，这个机制的实现一定基于某种约定或者规范，只需要Starter组件符合 Springboot 中自动装配约定的规范，就能实现自动装配。

### 自动装配的实现

 自动装配在 Springboot 中是通过 @EnableAutoConfiguration 注解来开启的，这个注解的声明在启动类注解@SpringbootApplication 中。

```java
@SpringBootApplication
public class SpringBootDemoApplication {
	public static void main(String[] args){
		SpringApplication.run(SpringBootDemoApplication.class, args);
    }
}
```

进入@SpringBootApplication可以看到@EnableAutoConfiguration注解

```java
@Target(ElementType. TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = {@Filter(type = FilterType.CUSTOM,classes =TypeExcludeFilter.class),
@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public interface SpringBootApplication {
...
}
```

这里先介绍下@Enable 注解。Spring3.1 版本就开始支持@Enable注解了，他的主要作用是把相关组件的Bean 装配到Ioc 容器中。@Enable 注解对JavaConfig 的进一步完善，为使用 Spring Frameweork 的开发者减少了配置量，降低了使用的难度。比如常见的@Enable注解有 @EnableWebMvc、@EnableSheduling 等。

之前我们说过，如果基于javaConfig 的形式来完成Bean装载，则必须使用 @Configuration注解以及@Bean 注解。而@Enable 本质上就是对这两个注解的封装。如果仔细关注这些注解，就会发现这些注解中都会携带一个@Import 注解，比如@EnableScheduling。

```java
@Target({ElementType. TYPE})
@Retention(RetentionPolicy. RUNTIME)
@Import({SchedulingConfiguration.class})Documented
public @interface EnableScheduling {}
```

使用@Enable注解后，Spring 会解析到@Import 导入的配置类，从而根据这个配置类的描述来实现Bean的装配。那么大家可以思考一下@EnableAutoConfiguration的实现原理是否也是这般呢。

### EnableAutoConfiguration

 进入@EnableAutoConfiguration 注解里，可以看到除@Import注解之外，还多了一个@AutoConfigurationPackage 注解（这个注解的作用是把使用了该注解的类所在的包及其子包下所有组件扫描到Spring Ioc 容器中）。

并且，@Import注解中导入的并不是一个Configuration的配置类，而是一个AutoConfigurationImportSelector 类。

```java
@Target(ElementType. TYPE)
@Retention( RetentionPolicy.RUNTIME)@Documented
@Inherited
@AutoConfigurationPackage
@Import(AutoConfigurationImportSelector.class)public @interface EnableAutoConfiguration
```

不过，不管AutoConfigurationImportSelector 是什么，他一定会实现配置类的导入，至于具体的实现方式，还需要我们继续分析。

### AutoConfigurationImportSelector

AutoConfigurationImportSelector 实现了 ImportSelector ，他只有一个 selectorImports 抽象方法，并且返回一个String数组，这个数组中可以指定需要装配到Ioc容器中的类，当在@Import 中导入了一个ImportSelector实现类之后，会把该实现类中返回的Class名称都装载到Ioc容器中。

```java
public interface ImportSelector {
    String[] selectImports(AnnotationMetadata var1);
}
```

和 @Configuration 不同的是，ImportSelector 可以实现批量装配，并且还可以通过逻辑处理来实现Bean的选择性装配，也就是可以根据上下文来决定能够被Ioc容器初始化。接下来通过一个简单的例子带大家了解ImportSelector 的使用。

- 首先创建两个类，我们需要把这两个类装配到Ioc容器中。

```java
public class Firstclass {
    
}
public class Secondclass {
    
}
```

- 创建一个ImportSelector 的实现类，在实现类中把定义的两个Bean 加入String 数组，这意味着这两个Bean 会装配到Ioc 容器中。

```java
public class GpImportSelector implements ImportSelector {
	@Override
	public String[] selectImports(AnnotationMetadata importingClassMetadata) {
		return new String[]{FirstClass.class.getName() ,SecondClass.class.getName()};
    }
}
```

- 为了模拟EnableAutoConfiguration，我们可以自定义一个类似的注解，通过@Import 导入 GpImportSelecto。

```java
@Target(ElementType. TYPE)
@Retention(RetentionPolicy. RUNTIME)@Documented
@Inherited
@AutoConfigurationPackage
@Import(GpImportSelector.class)
public @interface EnableAutoImport {
}
```

- 创建一个启动类，在启动类上使用@EnableAutoImport 注解后，即可以通过 ca.getBean 从Ioc 容器中得到First 对象实例。

```java
@SpringBootApplication@EnableAutoImport
public class ImportSelectorMain {
public static void main(String[ ] args){
	ConfigurableApplicationcontext ca=SpringApplication.run(ImportSelectorMain.class， args);
	FirstClass fc=ca.getBean(Firstclass.class);
}
```

这种实现方式相比于@Import(*Configuration.class) 的好处在于装配的灵活性，还可以实现批量的装配。比如GpImportSelector还可以直接在String中定于多个Configuration类，由于一个配置类代表的是某一个技术组件批量的Bean声明，所以在自动装配的这个过程中只需要扫描到指定路径下对应的配置类即可。

### 自动装配原理分析

基于前面的分析可以猜想到，自动装配的核心是扫描约定目录下的文件进行解析，解析完成之后把得到的Configuration配置类通过ImportSelector 进行导入，从而完成Bean的自动装配。那么接下来我们通过分析AutoConfigurationImportSelector 的实现来证明这个猜想。

定位到 AutoConfigurationImportSelector 中的 selectImport方法，它是ImportSelector 接口的实现。这个方法中主要有两个功能：

- AutoConfigurationMetadataLoader.loadMetadata从META-INF/spring-autoconfigure-metadata.properties 中加载自动装配的条件元数据，简单来说就是只有满足条件的Bean才能够进行装配。

- 收集所有符合条件的配置类autoConfigurationEntry.getConfigurations()，完成自动装配。

```java
@Override
public String[ ] selectImports(AnnotationMetadata annotationMetadata){
    if ( !isEnabled(annotationMetadata)){
    return NO_IMPORTS;
    }
    AutoConfigurationMetadata autoConfigurationMetadata = 	AutoConfigurationMetadataLoader.loadMetadata(this.beanClassLoader);

    AutoConfigurationEntry autoconfigurationEntry =
    getAutoConfigurationEntry(autoConfigurationMetadata,annotationMetadata);

    return Stringutils.toStringArray(autoConfigurationEntry.getConfigurations());
}
```

这里有个问题`SpringApplication.run(...)`方法怎么调到`selectImports()`方法的 加载过程大概是这样的：

SpringApplication.run(...) -> 

AbstractApplicationContext.refresh() -> 

invokeBeanFactoryPostProcessors(...) ->  

PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(...)  ->

ConfigurationClassPostProcessor.postProcessBeanDefinitionRegistry(..) ->

AutoConfigurationImportSelector.selectImports

​	我们重点分析一下配置类的收集方法getAutoConfigurationEntry，结合之前Starter的作用不难猜测到，这个方法应该会扫描指定路径下的文件解析得到需要装配的配置类，而这里面用到了SpringFactoriesLoader，这块内容后续随着代码的展开再来讲解。简单分析一下这段代码，它主要做几件事情:

- getAttributes 获得 @EnableAutoConfiguration 注解中的·属性 exclude、excludeName 等。
- getCandidateConfigurations 获得所有自动装配的配置类。
- removeDuplicates 去除重复的配置项。
- getExclusions 根据 @EnableAutoConfiguration 注解中配置的exclude等属性，把不需要自动装配的配置类移除。
- fireAutoConfigurationImportEvents 广播事件。
- 最后返回多层判断和过滤之后的配置类集合。

```java
protected AutoConfigurationEntry getAutoConfigurationEntry(AutoConfigurationMetadataautoConfigurationMetadata,AnnotationMetadata annotationMetadata){
    if(!isEnabled(annotationMetadata)){
    	return EMPTY_ENTRY;
    }
    AnnotationAttributes attributes = getAttributes(annotationMetadata);
    List<String> configurations = getcandidateConfigurations(annotationMetadata, attributes);
    configurations = removeDuplicates(configurations);
    Set<String> exclusions = getExclusions( annotationMetadata,attributes);
    checkExcludedclasses( configurations,exclusions);
    configurations. removeAl1(exclusions);
    configurations = filter(configurations,autoConfigurationMetadata);
    fireAutoConfigurationImportEvents(configurations,exclusions);
    return new AutoConfigurationEntry(configurations,exclusions);
}

```

总的来说，它先获得所有的配置类，通过去重、exclude排除等操作，得到最终需要实现自动装配的配置类。这里需要重点关注的是getCandidateConfigurations，它是获得配置类最核心的方法。

```java
protected list<String> getCandidateConfigurations(AnnotationMetadata metadata,AnnotationAttributes attributes) {
	List<String> configurations =
SpringFactoriesLoader.loadFactoryNames(getSpringFactoriesLoaderFactoryclass(),getBeanclassLoader());
	Assert.notEmpty(configurations，"No auto configuration classes found inMETA-INF/spring.factories. If you " + "are using a custom packaging,make sure that file is correct.");
return configurations;
}
```

这里用到了SpringFactoriesLoader，它是Spring 内部提供的一种约定俗成的加载方式，类似于Java中的SPI。简单来说，它会扫描classpath下的META-INF/spring.factories文件，spring.factories文件中的数据以Key=Value形式存储，而SpringFactoriesLoader.loadFactoryNames 会根据Key 得到对应的value值。因此，在这个场景中，Key对应为EnableAutoConfiguration，Value是多个配置类，也就是getCandidateConfigurations方法所返回的值。

打开RabbitAutoConfiguration，可以看到，它就是一个基于JavaConfig形式的配置类。

```java
@Configuration(proxyBeanMethods = false)
@Conditional0nclass({ RabbitTemplate.class,Channe1.class})
@EnableConfigurationProperties(RabbitProperties.class)
@Import(RabbitAnnotationDrivenConfiguration.class)
public class RabbitAutoConfiguration
```

除了基本的@Configuration 注解，还有一个@ConditionalOnClass注解，这个条件控制机制在这里的用途是，判断 classpath 下是否存在RabbitTemplate和Channel 这两个类，如果是，则把当前配置类注册到IloC容器。另外，@EnableConfigurationProperties是属性配置，也就是说我们可以按照约定在application.properties 中配置RabbitMQ的参数，而这些配置会加载到RabbitProperties中。实际上，这些东西都是Spring 本身就有的功能。

- 通过@Import(AutoConfigurationImportSelector)实现配置类的导入，但是这里并不是传统意义上的单个配置类装配
- AutoConfigurationImportSelector类实现了ImportSelector接口，重写了方法 selectImports，它用于实现选择性批量配置类的装配。
- 通过Spring提供的SpringFactoriesLoader机制，扫描classpath路径下的META-INF/spring.factories，读取需要实现自动装配的配置类。
- 通过条件筛选的方式，把不符合条件的配置类移除，最终完成自动装配。通过@Import(AutoConfigurationImportSelector)实现配置类的导入，但是这里并不是传统意义上的单个配置类装配。
- AutoConfigurationImportSelector类实现了ImportSelector接口，重写了方法 selectImports，它用于实现选择性批量配置类的装配。
- 通过Spring提供的SpringFactoriesLoader机制，扫描classpath路径下的META-INF/spring.factories，读取需要实现自动装配的配置类。
- 通过条件筛选的方式，把不符合条件的配置类移除，最终完成自动装配。

