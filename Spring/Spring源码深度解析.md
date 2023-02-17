# Spring 整体架构

这些模块被总结为以下几部分。

1. Core Container

   Core和Beans模块是框架的基础部分，提供IoC（转控制）和依赖注入特性。这里的基础概念是BeanFactory，它提供对Factory模式的经典实现来消除对程序性单例模式的需要，并真正地允许你从程序逻辑中分离出依赖关系和配置。

Core模块主要包含Spring框架基本的核心工具类，Spring的其他组件都要用到这个包里的类，Core模块是其他组件的基本核心。当然你也可以在自己的应用系统中使用这些工具类。

## 依赖注入方式

1.  构造方法注入
2. setter 注入
3. 接口注入

### 构造方法注入

```java
public FXNewsProvider(IFXNewsListener newsListner,IFXNewsPersister newsPersister) { 
 	this.newsListener = newsListner; 
	this.newPersistener = newsPersister; 
}
```

IoC Service Provider会检查被注入对象的构造方法，取得它所需要的依赖对象列表，进而为其注入相应的对象。同一个对象是不可能被构造两次的，因此，被注入对象的构造乃至其整个生命周期，应该是由IoC Service Provider来管理的。

### setter 方法注入

对于JavaBean对象来说，通常会通过setXXX()和getXXX()方法来访问对应属性。这些setXXX()方法统称为setter方法，getXXX()当然就称为getter方法。通过setter方法，可以更改相应的对象属性，通过getter方法，可以获得相应属性的状态。所以，当前对象只要为其依赖对象所对应的属性添加setter方法，就可以通过setter方法将相应的依赖对象设置到被注入对象中。

```java
public class FXNewsProvider{ 
     private IFXNewsListener newsListener; 
     private IFXNewsPersister newPersistener; 

     public IFXNewsListener getNewsListener() { 
    	 return newsListener; 
     } 
     public void setNewsListener(IFXNewsListener newsListener) { 
     	this.newsListener = newsListener; 
     } 
     public IFXNewsPersister getNewPersistener() { 
    	return newPersistener; 
     } 
     public void setNewPersistener(IFXNewsPersister newPersistener) { 
    	this.newPersistener = newPersistener; 
     } 
}
```

这样，外界就可以通过调用setNewsListener和setNewPersistener方法为FXNewsProvider对象注入所依赖的对象了。

setter方法注入虽不像构造方法注入那样，让对象构造完成后即可使用，但相对来说更宽松一些，可以在对象构造完成后再注入。

### 接口注入

​	相对于前两种注入方式来说，接口注入没有那么简单明了。被注入对象如果想要IoC Service Provider为其注入依赖对象，就必须实现某个接口。这个接口提供一个方法，用来为其注入依赖对象。IoC Service Provider最终通过这些接口来了解应该为被注入对象注入什么依赖对象。下图演示了如何使用接口注入为FXNewsProvider注入依赖对象。

​	FXNewsProvider为了让IoC Service Provider为其注入所依赖的IFXNewsListener，首先需要实现IFXNewsListenerCallable接口，这个接口会声明一个injectNewsListner方法（方法名随意），该方法的参数，就是所依赖对象的类型。这样，InjectionServiceContainer对象，即对应的IoC Service Provider就可以通过这个接口方法将依赖对象注入到被注入对象FXNewsProvider当中。



### 三种注入方式的比较

- 接口注入。从注入方式的使用上来说，接口注入是现在不甚提倡的一种方式，基本处于“退役状态”。因为它强制被注入对象实现不必要的接口，带有侵入性。而构造方法注入和setter方法注入则不需要如此。
- 构造方法注入。这种注入方式的优点就是，对象在构造完成之后，即已进入就绪状态，可以马上使用。缺点就是，当依赖对象比较多的时候，构造方法的参数列表会比较长。而通过反射构造对象的时候，对相同类型的参数的处理会比较困难，维护和使用上也比较麻烦。而且在Java中，构造方法无法被继承，无法设置默认值。对于非必须的依赖处理，可能需要引入多个构造方法，而参数数量的变动可能造成维护上的不便。
- setter方法注入。因为方法可以命名，所以setter方法注入在描述性上要比构造方法注入好一些。 另外，setter方法可以被继承，允许设置默认值，而且有良好的IDE支持。缺点当然就是对象无法在构造完成后马上进入就绪状态。

### IoC 的好处

​	从主动获取依赖关系的方式转向IoC方式，不只是一个方向上的改变，简单的转变背后实际上蕴藏着更多的玄机。要说IoC模式能带给我们什么好处，可能各种资料或书籍中已经罗列很多了。比如不会对业务对象构成很强的侵入性，使用IoC后，对象具有更好的可测试性、可重用性和可扩展性，等等。不过，泛泛而谈可能无法真正地让你深刻理解IoC模式带来的诸多好处，所以，还是让我们从具体的示例入手，来一探究竟吧。

## IOC Provider

​	虽然业务对象可以通过IOC方式声明相应的依赖，但是还是需要一种服务来将这些相互依赖的对象绑定到一起，而IoC Service Provider就是做这些工作的。

​	Ioc Service Provider 是一个抽象的概念，它可以指代任何将IoC场景中的业务对象绑定到一起的实现方式。它可以是一段代码，也可以是一组相关的类，甚至可以是比较通用的IoC框架或者IoC容器实现。Spring 的 Ioc 容器就是一个提供依赖注入服务的 Ioc Service Provider.

### IoC Service Provider 的职责

IoC Service Provider的职责相对来说比较简单，主要有两个：业务对象的构建管理和业务对象间的依赖绑定。

- **业务对象的构建管理：**在IoC场景中，业务对象无需关心所依赖的对象如何构建如何取得，但这部分工作始终需要有人来做。所以，IoC Service Provider需要将对象的构建逻辑从客户端对象那里剥离出来，以免这部分逻辑污染业务对象的实现。
- **业务对象间的依赖绑定：**对于Ioc Service Provider来说，这个职责是最难也是最重要的。如果这部分职责出问题了，需要注入的对象将找不到需要的依赖对象。Ioc Service Provider 通过结合之前构建和管理的所有业务对象，以及各个业务对象间可以识别的依赖关系，将这些对象所依赖的对象注入绑定，从而保证每个业务对象在使用的时候，可以处于就绪状态。

### IoC Service Provider 如何管理对象间的依赖关系

​	被注入对象可以通过多种方式通知IoC Service Provider为其注入相应依赖。但问题在于，收到通知的IoC Service Provider是否就一定能够完全领会被注入对象的意图，并及时有效地为其提供想要的依赖呢？有些时候，事情可能并非像我们所想象的那样理所当然。对于为被注入对象提供依赖注入的IoC Service Provider来说，他需要知道自己所管理和掌握的被注入对象和依赖对象之间的对应关系。

IoC Service Provider 需要使用一种方式来记录对象之间的对应关系。比如：

- 可以通过基本的文本文件来记录被注入对象和其依赖对象之间的对应关系。
- 可以通过描述性较强的XML文件格式来注册这些对应信息。
- 可以通过编写代码的方式来注册这些对应消息。

那么，实际情况下，各种具体的IoC Service Provider实现又是通过哪些方式来记录“服务信息”的呢？ 我们可以归纳一下，当前流行的IoC Service Provider产品使用的注册对象管理信息的方式主要有以下几种 

#### 直接编码方式

当前大部分的IoC容器都应该支持直接编码方式，比如PicoContainer、Spring、Avalon等。在容器启动之前，我们就可以通过程序编码的方式将被注入对象和依赖对象注册到容器中，并明确它们相互之间的依赖注入关系。

```java
IoContainer container = ...; 
container.register(FXNewsProvider.class,new FXNewsProvider()); 
container.register(IFXNewsListener.class,new DowJonesNewsListener()); 
... 
FXNewsProvider newsProvider = (FXNewsProvider)container.get(FXNewsProvider.class); 
newProvider.getAndPersistNews();
```

通过为相应的类指定对应的具体实例，可以告知IoC容器，当我们要这种类型的对象实例时，请将容器中注册的、对应的那个具体实例返回给我们。

如果是接口注入，可能伪代码看起来要多一些。不过，道理上是一样的，只不过除了注册相应对象，还要将“注入标志接口”与相应的依赖对象绑定一下，才能让容器最终知道是一个什么样的对应关系。

> 直接编码形式管理基于接口注入的依赖注入方式

```java
IoContainer container = ...;
container.register(FXNewsProvider.class,new FxNewsProvider);
container.register(IFXNewsListener.class,new DowJonesNewsListener);
...
container.bind(IFXNewsListenerCallabe.class,container.get(IFXNewsListener.class));
...
FXNewsProvider newsProvider = (FXNewsProvider)contanier.get(IFXNewsProvider.class);
newProvider.getAndPersistNews();
```

​	通过bind方法可以将“被注入对象”所依赖的对象，绑定为容器中注册过的IFXNewsListener类型的对象实例。容器在返回FXNewsProvider对象实例之前，会根据这个绑定信息，将IFXNewsListener 注册到容器中的对象实例注入到“被注入对象”FxNewsProvider 中，并最终返回已经组装完毕的FXNewsProvider对象。

所以，通过程序编码让最终的IoC Service Provider (也就是各个IoC框架或者容器实现）得以知晓服务的“奥义”，应该是管理依赖绑定关系的最基本方式。

### 配置文件方式

这是一种较为普遍的依赖注入管理方式。像普通文本文件、properties文件、XML文件等，都可以成为管理依赖注入的载体。不过最为常见的还是通过XML文件管理对象注册和对象之间的依赖关系。

```xml
<bean id="newsProvider" class=" ..FXNewsProvider">
	<property name= "newsListener" >
		<ref bean="djNewsListener"/>
    </property>
	<property name="newPersistener">
		<ref bean="djNewsPersister"/>
    </property>
</bean>
<bean id="djNewsListener" class=" ..impl.DowJonesNewsListener" ></bean>
<bean id="djNewsPersister" class=" ..impl.DowJonesNewsPersister"></bean>
```

### 元数据方式

​	这种方式的代表实现是Google Guice，这是Bob Lee在java 5的注解和Generic基础上开发的一套IOC框架。我们可以直接在类中使用元数据信息来标注各个对象之间的依赖关系，Guice框架根据这些注解所提供的信息将这些对象组装后，交给客户端对象使用。

> 使用Guice的注解标注依赖关系后的FXNewsProvider定义

```java
public class FXNewsProvider {
 	private IFXNewsListenernewsListener;private IFXNewsPersister newPersistener ;
    @Inject
    public FXNewsProvider(IFXNewsListener listener,IFXNewsPersister persister) {
        this.newsListener= listener;
        this.newPersistener = persister ;
    }  
}
```

通过@Inject，我们指明需要IoC Service Provider通过构造方法注入方式，为FXNewsProvider注入其所依赖的对象。至于余下的依赖相关信息，在Guice中是由相应的Module来提供的。

>  FXNewsProvider所使用的Module实现

```java
public class NewsBindingModule extends AbstractModule{
@Override
protected void configure() {
	bind (IFXNewsListener.class).to(DowJonesNewsListener.class).in(Scopes.SINGLETON);
    bind (工FXNewsPersister.class).to(DowJonesNewsPersister.class).in (Scopes.SINGLETON)
}
```

通过Module指定进一步的依赖注入相关信息之后，我们就可以直接从Guice那里取得最终已经注入完毕，并直接可用的对象了。

```java
Injector injector = Guice.createInjector(new NewsBindingModule()) ;
FXNewsProvider newsProvider = injector.getInstance (FXNewsProvider.class)newsProvider.getAndPersistNews ( ) ;
```

当然，注解最终也要通过代码处理来确定最终的注入关系，从这点儿来说，注解方式可以算作编码方式的一种特殊情况。

## Spring 的IOC容器之BeanFactory

我们前面说过，Spring的IoC容器是一个IoC Service Provider，但是，这只是它被冠以IoC之名的部分原因，我们不能忽略的是“容器”。Spring的IoC容器是一个提供IoC支持的轻量级容器，除了基本的IoC支持，它作为轻量级容器还提供了IoC之外的支持。如在Spring的IoC容器之上，Spring还提供了相应的AOP框架支持、企业级服务集成等服务。Spring的IoC容器和IoC Service Provider所提供的服务之间存在一定的交集，二者的关系如图所示。

![Spring的IoC容器和IoC Service Provider之间的关系](http://img.trivial.top/img/image-20220606102600176.png)

Spring 提供了两种容器类型 BeanFactory 和 ApplicationContext

- BeanFactory 基础类型IOC 容器，提供完整的IOC服务支持。如果没有特殊指定，默认采用延迟初始化策略（lazy-load）。只有当客户端对象需要访问容器中的某个受管理对象的时候，才会对该受管理对象进行初始化以及依赖注入操作。所以，相对来说，容器启动初期速度较快，所需要的资源有限。对于资源有限，并且功能要求不是很严格的场景，BeanFactory是比较合适的IOC容器选择。
- ApplicationContext。ApplicationContext 在BeanFactory的基础上构建，是相对比较高级的容器实现，除了拥有BeanFactory的所有支持，ApplicationContext还提供了其他高级特性，比如事件发布、国际化信息支持等，这些会在后面详述。ApplicationContext所管理的对象，在该类型容器启动之后，默认全部初始化并绑定完成。所以，相对于BeanFactory来说，ApplicationContext要求更多的系统资源，同时，因为在启动时就完成所有初始化，容器启动时间也较BeanFactory长一些。如果系统资源充足，要求更多功能，ApplicationContext类型的容器比较合适。

> ApplicationContext 和 Beanfactory 之间的关系

![image-20220606103921978](http://img.trivial.top/img/image-20220606103921978.png)

> **注意:** ApplicationContext间接继承于BeanFactory，所以说它是构建与BeanFactory 之上的IOC容器。

​	BeanFactory就像一个汽车生产厂。你从其他汽车零件厂商或者自己的零件生产部门取得汽车零件送入这个汽车生产厂，最后，只需要从生产线的终点取得成品汽车就可以了。相似地，将应用所需的所有业务对象交给BeanFactory之后，剩下要做的，就是直接从BeanFactory取得最终组装完成并且可用的对象。至于这个最终业务对象如何组装，你不需要关心，BeanFactory会帮你搞定。

​	所以，对于客户端来说，与BeanFactory打交道其实很简单。最基本地，BeanFactory肯定会公开一个取得组装完成的对象的方法接口。

> BeanFactory 的定义

```java
public interface BeanFactory {
    String FACTORY_BEAN_PREFIX = "&";
    Object getBean(String name) throws BeansException;
    object getBean(String name，Class requiredType) throws BeansException;
    /**
	 *@since 2.5
	 */
    0bject getBean(String name，Object [] args) throws BeansException;boolean containsBean (string name) ;
    boolean issingleton(String name) throws NoSuchBeanDefinitionException;
    /**
	 *@since 2.0.3
	 */
	boolean isPrototype(String name) throws NoSuchBeanDefinitionException;
    /**
	 * @since 2.0.1
	 */
	boolean isTypeMatch(String name,Class targetType) throws NoSuchBeanDefinitionException;Class getType(String name) throws NoSuchBeanDefinitionException;
	string[] getAliases (string name) ;
}
```

​	上面代码中的方法基本上都是查询相关的方法，例如，取得某个对象的方法(getBean)、查询某个对象是否存在于容器中的方法(containsBean)，或者取得某个bean的状态或者类型的方法等。因为通常情况下，对于独立的应用程序，只有主入口类才会跟容器的API直接耦合。



