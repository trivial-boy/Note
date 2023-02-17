---
SpringBoot整合quartz框架详解
---
## SpringBoot整合quartz框架详解——el-admin定时任务模块讲解

### 前提提要：

### quartz介绍：

日常生活中，我们经常会有定时执行某个任务的需求，但仅仅是spring提供的@Schedule远远达不到我们的目的，例如我们可能需要监控任务执行的情况，对定时任务进行持久化操作，需要通过图形化界面操纵定时任务。这些复杂的定时任务需求都无法只用一个注解解决，quartz框架实现了定时任务创建、修改、删除、执行、以及监控等操作，完美的帮我们解决了这一系列问题。

### quartz的优点

现在网上常见的定时任务框架有

- Spring Task

- Quartz
- Elastic-job

那么quartz有什么优点呢，让我们了解一下(这点借鉴博客https://blog.csdn.net/lkl_csdn/article/details/73613033)

1. 强大的调度功能，例如支持丰富多样的调度方法，可以满足各种常规及特殊需求；
2. 灵活的应用方式，例如支持任务和调度的多种组合方式，支持调度数据的多种存储方式；
3. 分布式和集群能力，Terracotta 收购后在原来功能基础上作了进一步提升。（Spring task就不支持集群）

最重要的一点，quartz是spring默认的调度框架，Quartz很容易跟Spring集合

### 首先，我们先来了解下quartz的四个核心元素

**1、Scheduler**

它的名字叫任务调度器，主要职责是总体控制任务调度。比如说任务的暂停，开始，创建和删除等操作。

Scheduler主要有三种：RemoteMBeanScheduler、 RemoteScheduler、StdScheduler 最常用的是StdScheduler，本文主要以StdScheduler进行讲述

关于Scheduler的具体介绍我们可以看该博客 https://www.cnblogs.com/laosunlaiye/p/9406784.html

**2、Trigger**

它叫触发器，用于定义任务调度的时间规则。quartz总共有四种触发器，分别是

- SimpleTrigger  

  ​	主要是针对一些相对简单的时间触发进行配置使用，比如在指定的时间开始然后在一定的时间间隔之内重复执行一个Job

- CronTrigger   

  ​	用cron表达式来控制定时任务执行时间，可以配置更复杂的触发时刻表

- DateIntervalTrigger  

  ​	类似于SimpleTrigger 适合调度类似每 N（1, 2, 3...）小时，每 N 天，每 N 周等的任务

- NthIncludedDayTrigger 

  ​	它设计的目标是提供不同时间间隔的第n天执行时刻表。比如，你想在每个月的第15日处理财务发票记帐，那么可以使用NthIncludedDayTrigger来完成这项工作。

当然我们用的最多的还是CronTrigger，它主要是通过cron表达式进行控制时间规则。

这里我简单介绍一下，cron表达式主要用来表达各种时间需求，总共有7位，最后一位可选，至少六位，从左到右各位置分别是：

| 位置 | 意义 | 取值              | 支持的符号        |
| ---- | ---- | ----------------- | ----------------- |
| 1    | 秒   | 0-59              | `, - * /`         |
| 2    | 分   | 0-59              | `, - * /`         |
| 3    | 时   | 0-23              | `, - * /`         |
| 4    | 日   | 1-31              | `, - * ? / L W C` |
| 5    | 月   | 1-12 或 JAN - DEC | `, - * /`         |
| 6    | 周   | 1-7 或 MON - SAT  | `, - * ? / L C #` |
| 7    | 年   | 空或 1970-2099    | `, - * /`         |

注：Cron 表达式对日期英文缩写、特殊字符大小写不敏感。

这是一个常见的cron表达式：“*/5 * * *  * ?” 表示的意义是每五秒执行一次，而CronTrigger的主要作用就是解析弄明白他们，然后控制任务时间。

---

关于cron表达式具体使用我们可以参考该文章https://www.gairuo.com/p/cron-expression-sheet。

**3. Job**

这个单词相信大家都认识，就是工作任务的意思，也就是你具体要执行的任务。Job仅仅只是一个接口，

```java
package org.quartz;

public interface Job {
    void execute(JobExecutionContext var1) throws JobExecutionException;
}
```

可以通过实现该接口来定义需要执行的任务

使用示例：

```java
/**
 *@Description: 打印helloword
 */
public class printHelloWorld implements Job{

    @Override
    public void execute(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        System.out.println("hello world");

    }
}
```

注意一个job可以对应多个触发器Trigger，但一个Trigger只能对应一个job ，他们之间是多对一的关系。（这个我想应该很好理解，同一个工作可以由多个触发器触发，但一个触发器只能触发一个工作。）

**4.JobDetail**

Quartz在执行job的时候，都需要一个job实例，会接受一个job实现类，然后运行的时候通过反射去实例化这个类，所以jobDetail的意义就是用来描述job实现类以及相关静态资源的类。

使用示例：

```java
 JobDetail jobDetail = JobBuilder.newJob(PrintHelloWorld.class).withIdentity("job1").build();
```

这里的newJob的作用就是跟PrintHelloWorld这个job实现类绑定。

---

- 最后提一点，trigger和job是怎么绑定的呢，这其实就是我们的调度器的一个任务，

example：

```java
scheduler.scheduleJob(jobDetail,cronTrigger);
```

这个就是job和Trigger的绑定过程。

**附上核心元素关系图**

![image-20210125143828787](https://gitee.com/lxsupercode/picture/raw/master/img/20210125143828.png)

### 小案例

好的，现在我们已经基本了解了，quartz的四个重要元素，这时候我们可以尝试敲一个案例来试验一下。

**1.首先，我们需要先引入jar包，这里用的是maven引入**

```xml
<!-- https://mvnrepository.com/artifact/org.quartz-scheduler/quartz -->
<dependency>
    <groupId>org.quartz-scheduler</groupId>
    <artifactId>quartz</artifactId>
    <version>2.3.0</version>
</dependency>
```

**2.然后，我们创建一个简单的job**

```java
/**
 *@Description: 打印helloword
 */
public class PrintHelloWorld implements Job{

    @Override
    public void execute(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        System.out.println("hello world");
    }
}
```

**3.再然后，我们就可以创建触发器==Trigger==和调度器==Scheduler==来定时执行job了**

```java
import org.quartz.*;
import org.quartz.impl.StdSchedulerFactory;

import java.util.concurrent.TimeUnit;

import static org.quartz.TriggerBuilder.newTrigger;

/**
 * @author lixiangxiang
 * @description 测试定时任务
 * @date 2021/1/25 8:58
 */
public class TestScheduler {
    public static void main(String[] args) {
        try {
            //1.创建调度器Scheduler实例（SchedulerFactory就是造schduler的工厂，一会还会提）
            SchedulerFactory schedulerFactory = new StdSchedulerFactory();
            Scheduler scheduler = schedulerFactory.getScheduler();
            //2.创建JobDetail实例,并与printHelloWorld绑定 withIdentity是设置该job的唯一标识 bulid就是创建jobDetail对象
            JobDetail jobDetail = JobBuilder.newJob(PrintHelloWorld.class).withIdentity("job1").build();
            //3.构建触发器Trigger,设置每五秒执行一次
            Trigger cronTrigger = newTrigger()
                    //设置触发器的名字 作为任务标识
                    .withIdentity("Trigger1")
                    //立即生效
                    .startNow()
                    //解析cron表达式 创建cronTrigger
                    .withSchedule(CronScheduleBuilder.cronSchedule("*/5 * * *  * ?"))
                    .build();

            //4.注册job和触发器Trigger
            scheduler.scheduleJob(jobDetail,cronTrigger);
            //5.启动调度器
            scheduler.start();
            System.out.println("--------scheduler start ! ------------");
            //睡眠20s
            TimeUnit.SECONDS.sleep(20);
            scheduler.shutdown();
            System.out.println("--------scheduler shutdown ! ------------");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

---

- JobBuilder 是无构造函数，只能通过==JobBuilder== 的静态方法 ==newJob(Class jobClass)==生成 JobBuilder 实例。



这里需要提一下**SchedulerFactory**，我们一般不直接创建==Scheduler==对象，而是==SchedulerFactory==来创建，

==SchedulerFactory==是一个接口，它有两个实现类分别是**==StdSchedulerFactory==**和**==DirectSchedulerFactory==**，

我们最常用的还是==StdSchedulerFactory==，只需要调用==getScheduler()==就能获取一个scheduler实例。

==DirectSchedulerFactory== 使用起来不够方便，需要作许多详细的手工编码设置。



---

**执行结果**

```java
--------scheduler start ! ------------
hello world
hello world
hello world
hello world
--------scheduler shutdown ! ------------
```

### SpringBoot项目集成quartz框架

很好，我们先在已经了解到一个定时任务的执行流程了，但我们现在做的项目都是用的Spring框架，所以我们还需要让quartz能够集成到Spring框架中。

幸好springboot早已经帮我们做了这件事情。我们需要引入jar包

```java
<!--spring boot集成quartz-->
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-quartz</artifactId>
</dependncy>
```

#### SpringBoot整合quartz框架流程

**1.创建job**

spring为quartz提供了一个抽象类QuartzJobBean，QuartzJobBean实现了job，我们只需要继承它实现他，实现他的executeInternal方法即可

这里我们执行一个Spring bean PrintHelloService的 printHello方法 来模拟真实开发中的场景

```java
@Service
public class PrintHelloService {
    public void printHello() {
        System.out.println("hello");
    }
}
```



```java
/**
 * @author lixiangxiang
 * @description 执行bean的方法
 * @date 2021/1/25 8:57
 */
public class PrintHelloJob extends QuartzJobBean {
    
    @Autowired
    PrintHelloService printHelloService;

    @Override
    protected void executeInternal(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        printHelloService.printHello();
    }
}
```



**2.将job注入到bean容器里**

- 之前我们在 scheduler的时候，是通过==SchedulerFactory==创建，这样有一个缺点，遇到需要注入的bean就会报空指针异常

- 出现这个问题是因为定时任务的 Job 对象实例化的过程是通过 Quartz 内部自己完成的，但是我们通过 Spring 进行注入的 Bean 却是由 Spring 容器管理的，Quartz 内部无法感知到 Spring 容器管理的 Bean，所以没有办法在创建 Job 的时候就给装配进去。
- 所以我们要做的是将Job也装配到 Bean容器中，我们知道Job在Spring中是由**SchedulerFactoryBean**创建的，要想将Job放入bean容器，那么必定与==SchedulerFactoryBean==有关。

- 我们通过查看==SchedulerFactoryBean== 源码发现如果 ==jobFactory== 不存在的话，默认会使用 ==AdaptableJobFactory== 实现对 ==job== 的创建。


```java
private Scheduler prepareScheduler(SchedulerFactory schedulerFactory) throws SchedulerException {
   // 省略部分代码...

   // Get Scheduler instance from SchedulerFactory.
   try {
      Scheduler scheduler = createScheduler(schedulerFactory, this.schedulerName);
      populateSchedulerContext(scheduler);

      if (!this.jobFactorySet && !(scheduler instanceof RemoteScheduler)) {
         // Use AdaptableJobFactory as default for a local Scheduler, unless when
         // explicitly given a null value through the "jobFactory" bean property.
         //如果 jobFactory 不存在 则使用 AdaptableJobFactory创建
         this.jobFactory = new AdaptableJobFactory();
      }
      
      if (this.jobFactory != null) {
         if (this.applicationContext != null && this.jobFactory instanceof ApplicationContextAware) {
            ((ApplicationContextAware) this.jobFactory).setApplicationContext(this.applicationContext);
         }
         if (this.jobFactory instanceof SchedulerContextAware) {
            ((SchedulerContextAware) this.jobFactory).setSchedulerContext(scheduler.getContext());
         }
         scheduler.setJobFactory(this.jobFactory);
      }
      return scheduler;
   }
```

- 所以我们就可以继承==AdaptableJobFactory==，自己创建一个==JobFactory==，在创建job实例的同时，通过 `AutowireCapableBeanFactory`将创建好的job对象交给Spring管理，然后再将==JobFactory==传到==SchedulerFactoryBean==对象中，那么就ok了。

上代码 

```java
@Configuration
public class QuartzConfig {

	/**
	 * 解决Job中注入Spring Bean为null的问题
	 */
	@Component("quartzJobFactory")
	public static class QuartzJobFactory extends AdaptableJobFactory {

		private final AutowireCapableBeanFactory capableBeanFactory;

        //通过构造器实现bean注入
		public QuartzJobFactory(AutowireCapableBeanFactory capableBeanFactory) {
			this.capableBeanFactory = capableBeanFactory;
		}

		@Override
		protected Object createJobInstance(TriggerFiredBundle bundle) throws Exception {

			//调用父类的方法创建job实例
			Object jobInstance = super.createJobInstance(bundle);
            //把job实例交个Spring管理
			capableBeanFactory.autowireBean(jobInstance);
			return jobInstance;
		}
	}

	/**
	 * 注入scheduler到spring
	 * @param quartzJobFactory /
	 * @return Scheduler
	 * @throws Exception /
	 */
	@Bean(name = "scheduler")
	public Scheduler scheduler(QuartzJobFactory quartzJobFactory) throws Exception {
		SchedulerFactoryBean factoryBean=new SchedulerFactoryBean();
         // 自定义 JobFactory 使得在 Quartz Job 中可以使用自动注入
		factoryBean.setJobFactory(quartzJobFactory);
		factoryBean.afterPropertiesSet();
		Scheduler scheduler=factoryBean.getScheduler();
		scheduler.start();
		return scheduler;
	}
}
```

- 这部分参考博客https://blog.csdn.net/weixin_39627430/article/details/111194115

---

**3.创建JobDetai CronTrigger 用Scheduler开启任务**

之后的流程与以前的流程基本一致,

```java
/**
 * @author lixiangxiang
 * @description scheduler示例
 * @date 2021/1/25 15:41
 */
@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class SimpleScheduler {
    @Autowired
    private Scheduler scheduler;

    @Test
    public void runJob () {
        try {
            //1.创建JobDetail实例,并与PrintHelloJob绑定
            JobDetail jobDetail = JobBuilder.newJob(PrintHelloJob.class).withIdentity("printHelloJob").build();
            //2.构建触发器Trigger,设置每五秒执行一次
            Trigger cronTrigger = newTrigger()
                    .withIdentity("Trigger1")
                    .startNow()
                    .withSchedule(CronScheduleBuilder.cronSchedule("*/5 * * *  * ?"))
                    .build();

            //3.注册job和触发器Trigger
            scheduler.scheduleJob(jobDetail,cronTrigger);
            //4.启动调度器
            scheduler.start();
            System.out.println("--------scheduler start ! ------------");
            //睡眠20s
            TimeUnit.SECONDS.sleep(20);
            scheduler.shutdown();
            System.out.println("--------scheduler shutdown ! ------------");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

```

我们用单元测试启动该定时任务

可以看到定时任务还跟以前一样成功执行。

![image-20210126083945546](https://gitee.com/lxsupercode/picture/raw/master/img/20210126083945.png)

---

那么到这里为止，springboot项目整合quartz框架的基本流程已经结束。

但是仅仅只是这些当然无法我们项目的需求，我们之前说过quartz框架是能够帮我们实现定时任务的添加，执行，删除，暂停等操作，也就是要实现quartz的动态化操作。

具体如何实现，让我们接着往下看^^

#### 定时任务的动态化（以下代码参考el-admin框架）

关于定时任务的管理，我们的需求其实也就几个。

1. 添加定时任务
2. 删除一个任务
3. 暂停、恢复 一个任务
4. 立即执行一个任务
5. 更新任务的cron表达式

我们需要能够改变定时任务的执行时间，这里我们都用的是==CronTrigger==所以我们要能更新Cron表达式。

**首先我们需要建一个Job类，用于储存job的一些信息。(这里用了lombook的@Data注解)**

```java
@Data
public class QuartzJob implements Serializable {
    public static final String JOB_KEY = "JOB_KEY";

    @ApiModelProperty(value = "ID")
    @TableId(value = "id",type = IdType.AUTO)
    //任务的id
    private Long id;

    //用于子任务唯一标识
    @TableField(exist = false)
    @ApiModelProperty(value = "用于子任务唯一标识", hidden = true)
    private String uuid;

    //job名称
    private String jobName;

    //cron表达式
    private String cronExpression;

    //定时任务的状态 暂停或启动
    private Boolean isPause = false;

   //子任务
    private String subTask;

    //失败后是否暂停 
    private Boolean pauseAfterFailure;


}
```

我们还用之前的==PrintHelloJob==

**建一个任务管理类，对任务进行动态管理**

**添加定时任务**

```java
  /**
     * description: 添加一个任务
     *
     * @author: lixiangxiang
     * @param quartzJob job的信息
     * @return void
     */
     public void addJob(QuartzJob quartzJob){
         try {
             // 构建jobDetail,并与PrintHelloJob类绑定(Job执行内容)
             JobDetail jobDetail = JobBuilder.newJob(PrintHelloJob.class).
                     withIdentity(quartzJob.getId()).build();

             //通过触发器名和cron表达式创建Trigger
             Trigger cronTrigger = newTrigger()
                     .withIdentity(quartzJob.getId())
                     .startNow()
                     .withSchedule(CronScheduleBuilder.cronSchedule(quartzJob.getCronExpression()))
                     .build();
             //把job信息放入jobDataMap中 job_key为标识
             cronTrigger.getJobDataMap().put(QuartzJob.JOB_KEY,quartzJob);

             //重置启动时间
             ((CronTriggerImpl)cronTrigger).setStartTime(new Date());

             //执行定时任务
             scheduler.scheduleJob(jobDetail,cronTrigger);
         } catch (Exception e) {
             //strUtil是hutool的工具类
             log.error(StrUtil.format("【创建定时任务失败】 定时任务id：{}",quartzJob.getId()),e);
         }
     }
```

我们根据quartzJob中job的信息对定时任务进行设置

增加一个定时任务的原理就是将定时任务==job==与 ==Trigger==根据==quartzJob==的信息创建好，然后用==sheduler==将他们绑定并执行。注意我们都用==quartzJob==的id对==job==和==Trigger==进行了唯一标识。这便于我们后面再拿到改job或Trigger

但是我们需要考虑一个问题，增加定时任务时，定时任务默认是开启的，但是quartzJob中的有个属性是isPause是否暂停，所以我们还需要对其进行判断，如果定改属性为true则暂停。我们需要先实现暂停定时任务的方法。

----

**关于jobDataMap 我需要提一下**

**JobDataMap**用来保存任务实例的状态信息。
当一个Job被添加到调度程序(任务执行计划表)scheduler的时候，JobDataMap实例就会存储一次关于该任务的状态信息数据。也可以使用**@PersistJobDataAfterExecution**注解标明在一个任务执行完毕之后就存储一次。

也可以自定义添加内容，他与java的map结构相同。我们可以通过==put(key,value)==向其中储存内容，达到向job传值得目的。

如果需要取出，我们可以通过**JobExecutionContext** （创建job的时候见过）来获取到==JobDataMap==.

后面会具体讲到如何从==JobExecutionContext==中获取JobDataMap中储存的数据。

---

**暂停定时任务**

```java
  * description: 暂停一个job
     *
     * @author: lixiangxiang
     * @param quartzJob /
     * @return void
     */
    public void pauseJob(QuartzJob quartzJob) {
        try {
            //根据之前设的id获取到jobkey
            JobKey jobKey = JobKey.jobKey(quartzJob.getId());
            //根据jobkey暂停任务
            scheduler.pauseJob(jobKey);
        } catch (Exception e) {
          log.error(StrUtil.format("【暂停定时任务失败】定时任务id：{}",quartzJob.getId()),e);
        }
    }
```

**对addJob进行改进**

```java
 /**
     * description: 添加一个任务
     *
     * @author: lixiangxiang
     * @param quartzJob job的信息
     * @return void
     */
     public void addJob(QuartzJob quartzJob){
         try {
             // 构建jobDetail,并与ExecutionJob类绑定(Job执行内容)
             JobDetail jobDetail = JobBuilder.newJob(PrintHelloJob.class).
                     withIdentity(quartzJob.getId()).build();

             //通过触发器名和cron表达式创建Trigger
             Trigger cronTrigger = newTrigger()
                     .withIdentity(quartzJob.getId())
                     .startNow()
                     .withSchedule(CronScheduleBuilder.cronSchedule(quartzJob.getCronExpression()))
                     .build();
             //把job信息放入jobDataMap中 job_key为标识
             cronTrigger.getJobDataMap().put(QuartzJob.JOB_KEY,quartzJob);

             //重置启动时间
             ((CronTriggerImpl)cronTrigger).setStartTime(new Date());

             //执行定时任务
             scheduler.scheduleJob(jobDetail,cronTrigger);
             
             //如果设置暂停，暂停任务
             if (quartzJob.getIsPause()){
                pauseJob(quartzJob);
             }
         } catch (Exception e) {
             //strUtil是hutool的工具类
             log.error(StrUtil.format("【创建定时任务失败】 定时任务id：{}",quartzJob.getId()),e);
         }
     }
```

**恢复定时任务**

```java
 /**
     * description: 恢复一个job
     *
     * @author: lixiangxiang
     * @param quartzJob /
     * @return void
*/
public void resumeJob(QuartzJob quartzJob) {
        try {
            //根据job的id生成TriggerKey 从而获取到 trigger
            TriggerKey triggerKey = TriggerKey.triggerKey(JOB_NAME + quartzJob.getId());
            CronTrigger trigger =(CronTrigger) scheduler.getTrigger(triggerKey);
            //如果trigger不存在创建一个新的定时任务
            if(ObjectUtil.isNull(trigger)) {
                addJob(quartzJob);
            }
            JobKey jobKey = JobKey.jobKey(quartzJob.getId());
            scheduler.resumeJob(jobKey);
        } catch (Exception e) {
            log.error(StrUtil.format("【恢复定时任务失败】定时任务id：{}",quartzJob.getId()),e);
        }
    }
```

为什么我要判断trigger是否为空呢？

因为当项目重新启动时该job将不会在保存在quartz的内存中，你直接用id找是找不到的，所以我们要做的是重新添加。前面的一部分代码就是为了判断该id对应的任务是否还能找到。

这是el-admin的一种独特解决思路，他并没有存到quartz本身设计的数据库中，只是将所有定时任务信息存入数据库，在项目重启时重新添加所有定时任务。这点后面会再次提到。

**更新cron表达式**

```java
/**
 * description: 更新cron表达式
 *
 * @author: lixiangxiang
 * @param quartzJob /
 * @return void
 */
public void updateJobCron(QuartzJob quartzJob) {
    try {
        TriggerKey triggerKey = TriggerKey.triggerKey( quartzJob.getId());
        CronTrigger trigger = (CronTrigger) scheduler.getTrigger(triggerKey);
        //如果不存在创建一个定时任务
        if(ObjectUtil.isNull(trigger)) {
            addJob(quartzJob);
            trigger = (CronTrigger) scheduler.getTrigger(triggerKey);
        }
        //按新的cronExpression表达式重新构建trigger  
        CronScheduleBuilder scheduleBuilder = CronScheduleBuilder.cronSchedule(quartzJob.getCronExpression());
        trigger = trigger.getTriggerBuilder().withIdentity(triggerKey).withSchedule(scheduleBuilder).build();
        //重置启动时间
        ((CronTriggerImpl)trigger).setStartTime(new Date());
        //重新将quartzJob放入map
        trigger.getJobDataMap().put(QuartzJob.JOB_KEY,quartzJob);

        //按新的trigger重新设置scheduler
        scheduler.rescheduleJob(triggerKey,trigger);
        //判断任务是否暂停
        if (quartzJob.getIsPause()) {
            pauseJob(quartzJob);
        }
    } catch (Exception e) {
        log.error(StrUtil.format("【更新定时任务失败】定时任务id：{}",quartzJob.getId()));
    }
}
```



前面一部分代码认识确定该job是存在的，保证获得trigger不为空。

中间有详细的注释就不再提了。

重置scheduler时调用的==rescheduleJob==会导致job重新开始执行，这时候我们需要判断quartzJob的isPause是否为true，如果为true则暂停任务。

**立即执行一个job**

有时候我们需要立即执行一个任务，但不触发他的trigger，就是只执行一次。

```java
/**
     * description: 立即执行任务
     *
     * @author: lixiangxiang
     * @param quartzJob /
     * @return void
     */
    public void runJobNow(QuartzJob quartzJob) {
        try {
            TriggerKey triggerKey = TriggerKey.triggerKey(JOB_NAME + quartzJob.getId());
            CronTrigger trigger = (CronTrigger)scheduler.getTrigger(triggerKey);
            //如果不存在创建一个定时任务
            if(ObjectUtil.isNull(trigger)) {
                addJob(quartzJob);
            }
            //将quartzjob的信息再放入JobDataMap中
            JobDataMap dataMap = new JobDataMap();
            dataMap.put(QuartzJob.JOB_KEY,quartzJob);
            JobKey jobKey = JobKey.jobKey(quartzJob.getId());
            //只执行一次job
            scheduler.triggerJob(jobKey,dataMap);
        } catch (Exception e) {
            log.error(StrUtil.format("【定时任务执行失败】定时任务id：{}",quartzJob.getId()),e);
        }
    }
```

**删除一个job**

```java
 /**
     * 删除一个job
     * @param quartzJob /
     */
    public void deleteJob(QuartzJob quartzJob){
        try {
            JobKey jobKey = JobKey.jobKey(quartzJob.getId());
            //暂停任务
            scheduler.pauseJob(jobKey);
            //删除任务
            scheduler.deleteJob(jobKey);
        } catch (Exception e){
            log.error(StrUtil.format("【删除定时任务失败】定时任务id：{}",quartzJob.getId()));
        }
    }
```

到此为止quartz的动态化操作已经基本结束。

---



现在我们还需要解决一个问题，如何持久化储存我们的定时任务。



#### 定时任务的持久化操作（以下方案参考el-admin）

关于定时任务的持久化操作，其实quartz框架提供了jobStore。

但本篇文章的持久化操作并不是通过该方法实现的。

如果需要用quartz默认的持久化方法可以看https://blog.csdn.net/hxnlyw/article/details/88181226

quartz的==jobStore==使用需要导入很多张表，这对项目开发不太友好，我们能不能只用一个表就完成持久化操作呢。

其实前面的动态化操作已经帮我们解决了这个问题。

我们只需要对quartzJob进行持久化储存即可。

接下来我会演示如何实现定时任务持久化  增删改 操作(==使用技术mybatis-plus==)

**增加一个定时任务**

```java
public void create(QuartzJob resources) {
        //验证cron表达式是否正确，如果不正确抛出异常
        if (!CronExpression.isValidExpression(resources.getCronExpression())){
            throw new BadRequestException("cron表达式格式错误");
        }
        //数据库保存数据 
        quartzJobMapper.insert(resources);
        //quartz增加任务
        quartzManage.addJob(resources);
}
```

 **修改定时任务**

```java
public void update(QuartzJob resources) {
        if(!CronExpression.isValidExpression(resources.getCronExpression())) {
            throw new BadRequestException("cron表达式错误");
        }
    	//通过id修改
        quartzJobMapper.updateById(resources);
    	//更新定时任务cron表达式	
        quartzManage.updateJobCron(resources);
}
```



**删除定时任务（可以删除多个）**

```java
public void delete(Set<Long> ids) {
    for(Long id : ids) {
        QuartzJob quartzJob = findById(id);
        //quartz删除定时任务
        quartzManage.deleteJob(quartzJob);
        //数据库删除该job信息·
        quartzJobMapper.deleteById(id);
    }
 }
```

**立即执行定时任务**

```java
 public void execution(QuartzJob quartzJob) {
     quartzManage.runJobNow(quartzJob);
 }
```

到此为止定时任务的持久化 操作就结束了

---



你以为这就没有了。。。当然不是，还记得我们之前创建的job吗·

```java
/**
 * @author lixiangxiang
 * @description 执行bean的方法
 * @date 2021/1/25 8:57
 */
public class PrintHelloJob extends QuartzJobBean {
    
    @Autowired
    PrintHelloService printHelloService;

    @Override
    protected void executeInternal(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        printHelloService.printHello();
    }
}
```

我们这个job的目的是打印hello。但是未来我们的job肯定不会如此简单，可能我们需要同时执行两个或多个定时任务。

那么这个时候就出现了新的问题，

- 我们必须每次都创建一个新的job类，很麻烦。
- 我们可能需要做一个后台页面来控制定时任务，但是我们绑定定时任务时需要传入job的实现类，前端不可能为我们传一个类过来。
- 我们如何让多个定时任务同时执行。

```java
// 构建jobDetail,并与PrintHelloJob类绑定(Job执行内容)
JobDetail jobDetail = JobBuilder.newJob(PrintHelloJob.class).
    withIdentity(quartzJob.getId()).build();
```



我们能不能把所有定时任务放在一个类中，执行某一个方法即可。或者我们只用绑定一个job类，我们一直用该类作为模板创建==JobDetail==实例，通过传入的job信息来确定执行的方法。

#### 改进方案（参考el-admin）

1. ==JobDetail==只绑定一个Job实现类
2. 在Job实现类中，我们通过bean对象，方法名，参数 反射执行需要执行的方法
3. 使用异步线程池实现多个定时任务同时进行

**首先我们将定时任务的所有信息封装到quartzJob对象中（@ApiModelProperty swagger-ui的注解）**

```java
@Data
public class QuartzJob implements Serializable {
    public static final String JOB_KEY = "JOB_KEY";
    
	@ApiModelProperty(value = "ID")
    private Long id;

    @ApiModelProperty(value = "用于子任务唯一标识", hidden = true)
    private String uuid;

    @ApiModelProperty(value = "定时器名称")
    private String jobName;

    @ApiModelProperty(value = "Bean名称")
    private String beanName;

    @ApiModelProperty(value = "方法名称")
    private String methodName;

    @ApiModelProperty(value = "参数")
    private String params;

    @ApiModelProperty(value = "cron表达式")
    private String cronExpression;

    @ApiModelProperty(value = "状态，暂时或启动")
    private Boolean isPause = false;

    @ApiModelProperty(value = "子任务")
    private String subTask;

    @ApiModelProperty(value = "失败后暂停")
    private Boolean pauseAfterFailure;


}
```

**创建一个job的实现类**

```java
public class ExecutionJob extends QuartzJobBean {

	@Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {
         //通过JobExecutionContext对象得到QuartzJob实例。
        QuartzJob quartzJob =(QuartzJob) context.getMergedJobDataMap().get(QuartzJob.JOB_KEY);
		//反射获取到方法，并执行。
    	runMethod(quartzJob.getBeanName(),quartzJob.getMethodName(),quartzJob.getParams());v 
    }

	/***
     * description:反射执行方法
     *
     * @author: lixiangxiang
     */
    public void runMethod(String beanName,String methodName,String  params) {
        Object target = SpringContextHolder.getBean(beanName);
        Method method = null;
        try{
            //执行的方法只能有两种，有String参数或者无参数，毕竟前端只能传字符串参数给后端。
            if(StringUtils.isNotBlank(params)) {
                //反射获取到方法 两个参数 分别是方法名和参数类型
                method = target.getClass().getDeclaredMethod(methodName,String.class);
            }else {
                method = target.getClass().getDeclaredMethod(methodName);
            }
            //反射执行方法
            ReflectionUtils.makeAccessible(method);
            if(StringUtils.isNotBlank(params)) {
                method.invoke(target,params);
            }else {
                method.invoke(target);
            }
        } catch (Exception e){
            throw new BadRequestException("定时任务执行失败");
        }
    }
```

上文提过我们可以使用==JobExecutionContext==获取到jobDataMap

获得==jobDataMap==的方式有三种

```java
//这个是获取到Trigger中的jobDataMap
context.getTrigger().getJobDataMap();
```

```java
//这个是获取到JobDetail中的jobDataMap
context.getJobDetail().getJobDataMap()
```

```java
//这个是将上面两者合并后获得的DataMap，如果有相同的key，则有一个会被覆盖
context.getMergedJobDataMap()
```

但是这样写并不能同时执行多个定时任务

**创建线程类**

我们可以把反射执行方法的过程写到一个线程类，然后放入线程池中。

```java
/**
 * @author lixiangxiang
 * @description 执行定时任务
 * @date 2021/1/15 9:57
 */
@Slf4j
public class QuartzRunnable implements Callable<Object> {
    private final Object target;
    private final Method method;
    private final String params;
    
    QuartzRunnable(String beanName,String methodName,String  params) throws NoSuchMethodException, ClassNotFoundException {
        //获取到bean对象
        this.target = SpringContextHolder.getBean(beanName);
        //获取到参数
        this.params = params;
        //如果参数不为空
        if(StringUtils.isNotBlank(params)) {
            //反射获取到方法 两个参数 分别是方法名和参数类型
            this.method = target.getClass().getDeclaredMethod(methodName,String.class);
        }else {
            this.method = target.getClass().getDeclaredMethod(methodName);
        }
    }

    /***
     * description: 线程回调函数 反射执行方法
     *
     * @author: lixiangxiang
     */
    @Override
    public Object call() throws Exception {
        ReflectionUtils.makeAccessible(method);
        if(StringUtils.isNotBlank(params)) {
            method.invoke(target,params);
        }else {
            method.invoke(target);
        }
        return null;
    }
}
```

改进==ExecutionJob== 增加异步注解

```java
@Async
public class ExecutionJob extends QuartzJobBean {
    //获取线程池
    private final static ThreadPoolExecutor EXECUTOR = ThreadPoolExecutorUtil.getPoll();

	@Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {
         //通过JobExecutionContext对象得到QuartzJob实例。
        QuartzJob quartzJob =(QuartzJob) context.getMergedJobDataMap().get(QuartzJob.JOB_KEY);
		//执行任务
        try{
            //创建定时任务线程
            QuartzRunnable task = new QuartzRunnable(quartzJob.getBeanName(),quartzJob.getMethodName(),quartzJob.getParams()); 
        	//执行任务并返回future，可以通过future获取线程状态
            Future<?> future = EXECUTOR.submit(task);
        }catch {
            throw new BadRequestException("定时任务执行失败");
        }
    }
 }
```

我们可以再建一个日志信息类

把任务执行的具体日志信息存入数据库中

```java
@Data
public class QuartzLog implements Serializable {

    @ApiModelProperty(value = "ID", hidden = true)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ApiModelProperty(value = "任务名称", hidden = true)
    private String jobName;

    @ApiModelProperty(value = "bean名称", hidden = true)
    private String beanName;

    @ApiModelProperty(value = "方法名称", hidden = true)
    private String methodName;

    @ApiModelProperty(value = "参数", hidden = true)
    private String params;

    @ApiModelProperty(value = "cron表达式", hidden = true)
    private String cronExpression;

    @ApiModelProperty(value = "状态", hidden = true)
    private Boolean isSuccess;

    @ApiModelProperty(value = "异常详情", hidden = true)
    private String exceptionDetail;

    @ApiModelProperty(value = "执行耗时", hidden = true)
    private Long time;

    @ApiModelProperty(value = "创建时间", hidden = true)
    private Timestamp createTime;
}

```

ExecutionJob加入日志

```java
@Async
public class ExecutionJob extends QuartzJobBean {

    //获取线程池
    private final static ThreadPoolExecutor EXECUTOR = ThreadPoolExecutorUtil.getPoll();

    @Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {
        //通过JobExecutionContext对象得到QuartzJob实例。
        QuartzJob quartzJob =(QuartzJob) context.getMergedJobDataMap().get(QuartzJob.JOB_KEY);
        //使用SpringContextHolder获取bean实例
        QuartzLogMapper quartzLogMapper = SpringContextHolder.getBean(QuartzLogMapper.class);
        QuartzJobService quartzJobService = SpringContextHolder.getBean(QuartzJobService.class);

        String uuid = quartzJob.getUuid();

        QuartzLog quartzLog = new QuartzLog();
        quartzLog.setJobName(quartzJob.getJobName());
        quartzLog.setBeanName(quartzJob.getBeanName());
        quartzLog.setMethodName(quartzJob.getMethodName());
        quartzLog.setParams(quartzJob.getParams());
        long startTime = System.currentTimeMillis();
        quartzLog.setCronExpression(quartzJob.getCronExpression());

        //执行任务
        try {
            log.info("-----------------------------------");
            log.info(StrUtil.format("【定时任务开始执行】 任务名称: {} ", quartzJob.getJobName()));
            //创建定时任务线程
            QuartzRunnable task = new QuartzRunnable(quartzJob.getBeanName(),quartzJob.getMethodName(),quartzJob.getParams());
            //用future管理task
            Future<?> future = EXECUTOR.submit(task);
            future.get();
            //计算运行时间
            long times = System.currentTimeMillis() - startTime;
            quartzLog.setTime(times);
            if(StringUtils.isNotBlank(uuid)){
                //将执行结果存入redis，以uuid为唯一标识
                redisUtils.set(uuid,true);
            }
            //任务状态
            quartzLog.setIsSuccess(true);
            log.info(StrUtil.format("【定时任务执行完毕】 任务名称: {}, 执行时间: {} ms", quartzJob.getJobName(),times));
            log.info("------------------------------------------------------")
        } catch (Exception e) {
            //保存执行状态
            if (StringUtils.isNotBlank(uuid)) {
                redisUtils.set(uuid, false);
            }
            log.info(StrUtil.format("【任务执行失败】任务名称: {} ", quartzJob.getJobName()));
            log.info("-------------------------------------------");
            long times = System.currentTimeMillis() - startTime;
            quartzLog.setTime(times);
            //任务状态 0; 成功 1 ;失败 0
            quartzLog.setIsSuccess(false);
            //存入异常信息
            quartzLog.setExceptionDetail(ThrowableUtil.getStackTrace(e));
            //如果任务失败则暂停
            if (quartzJob.getPauseAfterFailure() != null && quartzJob.getPauseAfterFailure()) {
                quartzJob.setIsPause(false);
                //更新状态,让任务暂停
                quartzJobService.updateIsPause(quartzJob);
            }
            e.printStackTrace();
            throw new BadRequestException("定时任务执行失败");
        }finally {
            //日志信息存入数据库
            quartzLogMapper.insert(quartzLog);
        }
    }
}
```

----

### el-admin任务调度模块的使用方法。

**最后再介绍下el-admin任务调度模块的使用方法。**

- 点击新增增加一个定时任务，下面有具体参数介绍

- 点击执行，立即执行一个任务

  你还可以进行定时任务修改、删除、暂停等操作。

![img](https://docimg4.docs.qq.com/image/cbOuqrw1B_qPGOTS9-yYnw?w=1626&h=785)



![img](https://docimg9.docs.qq.com/image/tXTGfky_r7CHUGu_i2uWeA?w=1293&h=744)

新增定时任务的部分参数介绍

- bean名称： 定时任务通过bean名称来获取具体执行的bean对象。需要执行的定时任务类，必须注入spring容器中。
- 执行方法：  需要执行的方法名称，底层是通过反射执行方法。
- cron表达式：定时任务通过cron表达式控制任务执行的时间。
- 子任务id：子任务可以是当前已经定义过的任务的id，传入时需要用多个逗号隔开，当主任务执行后，子任务按顺序依次执行。
- 告警邮箱：定时任务执行失败时会将失败信息通过邮箱发送给用户。如果有多个邮箱可以用逗号隔开，如果不需要则不用填。（该功能暂不支持）
- 失败后暂停：选择定时任务失败后是否暂停当前定时任务。
- 任务状态：选择是否开启当前定时任务。
- 参数内容： 填写参数内容，可向后端传一个字符串参数，具体使用方法见下图

![img](https://docimg5.docs.qq.com/image/GXiIOLrjXP1ay4ms8mK65w?w=1029&h=740)

![img](https://docimg8.docs.qq.com/image/w5eLqGPimPmnh825xss0NQ?w=755&h=371)

![img](https://docimg1.docs.qq.com/image/qg-YW-C1KH9fSmeMsEqyWg?w=1795&h=126)

前端可以根据该参数向后端传需要执行的内容。 

---

**最最最后附上==smpe-admin==的github地址，==smpe-admin==是我们团队基于el-admin自己整合的一个框架，定时任务模块是我负责的。谢谢大家支持哦

|        | 后端源码                                     | 前端源码                                         |
| ------ | -------------------------------------------- | ------------------------------------------------ |
| GitHub | https://github.com/sanyueruanjian/smpe-admin | https://github.com/sanyueruanjian/smpe-admin-web |



