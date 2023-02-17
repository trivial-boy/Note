## Spring 是如何启动的



## Bean的生命周期

### 从对象创建到对象销毁的过程

1) 通过构造器创建bean实例(执行无参构造)
2) 为bean的属性设置值和对其他bean的引用（调用set方法）
3) 调用bean的初始化的方法。
4) bean可以使用了
5) 当容器关闭时，调用bean的销毁方法（需要进行配置销毁的方法）。 

<img src="https://img.trivial.top/img/image-20221224150217328.png" alt="image-20221224150217328" style="zoom:150%;" />     

### 加上bean 的后置处理器，共有七步

通过构造器创建bean实例(执行无参构造)

为bean的属性设置值和对其他bean的引用（调用set方法）

调用aware接口的 方法 例如beanfactoryAware 和 applicationContextAware 

**把bean的实例传递bean后置处理器的方法**`postProcessBeforeInitialization`

调用bean的初始化的方法。

**把bean的实例传递bean后置处理器的方法** `postProcessAfterInitialization`

bean可以使用了

当容器关闭时，调用bean的销毁方法（需要进行配置销毁的方法）。 

 

## BeanFactory 和 FactoryBean 的区别

#### 1. BeanFactory

BeanFactory定义了 IOC 容器的最基本形式，并提供了 IOC 容器应遵守的的最基本的接口，也就是 Spring IOC 所遵守的最底层和最基本的编程规范。在  Spring 代码中，BeanFactory 只是个接口，并不是 IOC 容器的具体实现，但是 Spring 容器给出了很多种实现，如 **DefaultListableBeanFactory** 、XmlBeanFactory 、 ApplicationContext、**ClassPathXmlApplicationContext** 等，都是附加了某种功能的实现。



#### 2. FactoryBean

FactoryBean是一个接口，当在IOC容器中的Bean实现了FactoryBean后，通过getBean(String BeanName)获取到的Bean对象并不是FactoryBean的实现类对象，而是这个实现类中的getObject()方法返回的对象。要想获取FactoryBean的实现类，就要getBean(&BeanName)，在BeanName之前加上&。

## Spring循环依赖解决方案

使用三级缓存，提前暴露半成品对象来解决。

​    

### 三级缓存分别保存的是什么对象

一级缓存`singletonObjects`保存的成品对象

二级缓存`earlySingletonObjects` 保存的是半成品对象

三级缓存`singletonFactories`保存的是lambda表达式（ObjectFactory）

>ObjectFactory:函数式接口，有且仅有一个方法，可以当做方法的参数传递进去
>
>当指明此类型参数的方法，可以传入一个lambda表达式，在执行的时候并不会执行lambda表达式，而在调用getObject方法的时候才回去调用lambda处理的逻辑

<img src="https://img.trivial.top/img/image-20221224154148785.png" alt="image-20221224154148785" style="zoom: 67%;" />

**三级缓存查询顺序**

一级缓存 -> 二级缓存 -> 三级缓存

**如果只使用1级缓存行不行？**

不行，因为半成品和成品对象会放到一起，在进行对象获取的时候有可能获取到半成品对象。

**如果只有二级缓存？**

只有二级缓存的时候也能解决循环依赖的问题。

####  三级缓存到底做了什么事？ 

如果一个对象需要被代理，生成代理对象，那么这个对象需要预先生成非代理对象吗？

需要

 在当前方法中，有可能会将代理对象替换为非代理对象，如果没有三级缓存的话，那么就无法得到代理对象，换句话说在整个容器中，包含了同名对象的代理对象和非代理对象，你觉得可以吗？

容器中，对象都是单例的，意味着根据名称只能获取一个对象的值，此时同时存在两个对象的话，无法判断取那一个？    

三级缓存是为了解决在aop代理过程中产生的循环依赖问题，如果没有aop的话，二级缓存足矣解决循环依赖问题。

其实相当于是一个回调机制，当我都需要使用当前对象的时候，会判断此对象是否需要被代理实现，如果直接替换，不需要直接返回非代理对象即可。  

#### 为什么三级缓存就可以解决循环依赖中包含代理对象的问题

（1）创建代理对象的时候是否需要创建出原始对象？

需要

（2）同一个容器中能否出现同名的两个不同的对象

不能

（3）如果一个对象被代理，那么代理对象跟原始对象应该如何去存储？

如果需要代理对象，那么代理对象创建完成之后应该覆盖原始对象。

（4）在之前的步骤中，好像出现了覆盖的过程？

在getEarlyBeanReference 方法中，会判断是否需要代理对象，如果创建出代理对象，需要覆盖 

（5）在对象对外暴露的时候，如何准确的给出原始对象或者代理对象？因为正常的代理对象的创建是在BPP的后置处理方法中，在解决循环依赖问题的时候还没有执行到那个地方 。

所以此时需要lambda表达式，类似于是一种回调机制，在确定需要对外暴露的时候，就唯一性的确定到底是代理对象还是



# Spring 中有哪些重要的扩展点

1. BeanFactoryPostProcesscor
2. BeanPostProcessor

## Spring BeanFactory 和 ApplicationContext的区别

applicationContext