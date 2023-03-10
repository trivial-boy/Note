## Quartz详解

### 一、什么是Quartz



```markdown

Quartz是OpenSymphony开源组织在Job scheduling领域又一个开源项目，完全由Java开发，可以用来执行定时任务，类似于java.util.Timer。但是相较于Timer， Quartz增加了很多功能：

- 持久性作业 - 就是保持调度定时的状态;
- 作业管理 - 对调度作业进行有效的管理;
```



大部分公司都会用到定时任务这个功能。
拿火车票购票来说，当你下单后，后台就会插入一条待支付的task(job)，一般是30分钟，超过30min后就会执行这个job，去判断你是否支付，未支付就会取消此次订单；当你支付完成之后，后台拿到支付回调后就会再插入一条待消费的task（job），Job触发日期为火车票上的出发日期，超过这个时间就会执行这个job，判断是否使用等。



在我们实际的项目中，当Job过多的时候，肯定不能人工去操作，这时候就需要一个任务调度框架，帮我们自动去执行这些程序。那么该如何实现这个功能呢？



**（1）首先我们需要定义实现一个定时功能的接口，我们可以称之为Task（或Job），如定时发送邮件的task（Job），重启机器的task（Job），优惠券到期发送短信提醒的task（Job），实现接口如下：**

![img](https://img-blog.csdn.net/20180710135410275?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)





**（2）有了任务之后，还需要一个能够实现触发任务去执行的触发器，触发器Trigger最基本的功能是指定Job的执行时间，执行间隔，运行次数等。**

Trigger，表示触发器，根据配置规则来触发执行计划调度job，它主要包括两个核心组件，即SimpleTrigger和CronTrigger。其他Tigger基本都可以通过这两种实现。Trigger还可以定义错过的任务如何处理。

![这里写图片描述](https://img-blog.csdn.net/20180710135421739?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9pbWcyMDIwLmNuYmxvZ3MuY29tL2Jsb2cvMTY0MjQ4NS8yMDIwMDUvMTY0MjQ4NS0yMDIwMDUwMzIxNTUwNzcwMi05NzcyMDQwMjUucG5n?x-oss-process=image/format,png)

**（3）有了Job和Trigger后，怎么样将两者结合起来呢？即怎样指定Trigger去执行指定的Job呢？这时需要一个Schedule，来负责这个功能的实现。**

![这里写图片描述](https://img-blog.csdn.net/20180710135431806?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

上面三个部分就是Quartz的基本组成部分：

- 调度器：Scheduler
- 任务：JobDetail
- 触发器：Trigger，包括SimpleTrigger和CronTrigger



### 二、Quartz Demo搭建

下面来利用Quartz搭建一个最基本的Demo。	

1、导入依赖的jar包：

```xml
<!-- https://mvnrepository.com/artifact/org.quartz-scheduler/quartz -->
<dependency>
    <groupId>org.quartz-scheduler</groupId>
    <artifactId>quartz</artifactId>
    <version>2.3.0</version>
</dependency>
```

2、新建一个能够打印任意内容的Job：

```java
/**
 * Created by wanggenshen
 * Date: on 2018/7/7 16:28.
 * Description: 打印任意内容
 */
public class PrintWordsJob implements Job{

    @Override
    public void execute(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        String printTime = new SimpleDateFormat("yy-MM-dd HH-mm-ss").format(new Date());
        System.out.println("PrintWordsJob start at:" + printTime + ", prints: Hello Job-" + new Random().nextInt(100));

    }
}
```

3、创建Schedule，执行任务：

```java
/**
 * Created by wanggenshen
 * Date: on 2018/7/7 16:31.
 * Description: XXX
 */
public class MyScheduler {

    public static void main(String[] args) throws SchedulerException, InterruptedException {
        // 1、创建调度器Scheduler
        SchedulerFactory schedulerFactory = new StdSchedulerFactory();
        Scheduler scheduler = schedulerFactory.getScheduler();
        // 2、创建JobDetail实例，并与PrintWordsJob类绑定(Job执行内容)
        JobDetail jobDetail = JobBuilder.newJob(PrintWordsJob.class)
                                        .withIdentity("job1", "group1").build();
        // 3、构建Trigger实例,每隔1s执行一次
        Trigger trigger = TriggerBuilder.newTrigger().withIdentity("trigger1", "triggerGroup1")
                .startNow()//立即生效
                .withSchedule(SimpleScheduleBuilder.simpleSchedule()
                .withIntervalInSeconds(1)//每隔1s执行一次
                .repeatForever()).build();//一直执行

        //4、执行
        scheduler.scheduleJob(jobDetail, trigger);
        System.out.println("--------scheduler start ! ------------");
        scheduler.start();

        //睡眠
        TimeUnit.MINUTES.sleep(1);
        scheduler.shutdown();
        System.out.println("--------scheduler shutdown ! ------------");

    }
}
```

运行程序，可以看到程序每隔1s会打印出内容，且在一分钟后结束：

![这里写图片描述](https://img-blog.csdn.net/20180710135458277?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)



### 三、Quartz核心详解

#### **核心元素**

**Quartz 任务调度的核心元素是 scheduler, trigger 和 job，其中 trigger 和 job 是任务调度的元数据， scheduler 是实际执行调度的控制器。**

> 在 Quartz 中，trigger 是用于定义调度时间的元素，即按照什么时间规则去执行任务。

Quartz 中主要提供了四种类型的 trigger：

- SimpleTrigger
- CronTirgger
- DateIntervalTrigger
-  NthIncludedDayTrigger

> 在 Quartz 中，==job== 用于表示被调度的任务。

主要有两种类型的 job：无状态的（stateless）和有状态的（stateful）。

对于同一个 trigger 来说，有状态的 job 不能被并行执行，只有上一次触发的任务被执行完之后，才能触发下一次执行。

Job 主要有两种属性：volatility 和 durability，其中 volatility 表示任务是否被持久化到数据库存储，而 durability 表示在没有 trigger 关联的时候任务是否被保留。

两者都是在值为 true 的时候任务被持久化或保留。一个 job 可以被多个 trigger 关联，但是一个 trigger 只能关联一个 job。

> 在 Quartz 中， scheduler 由 scheduler 工厂创建：DirectSchedulerFactory 或者 StdSchedulerFactory。

 第二种工厂 StdSchedulerFactory 使用较多，因为 DirectSchedulerFactory 使用起来不够方便，需要作许多详细的手工编码设置。 Scheduler 主要有三种：==RemoteMBeanScheduler， RemoteScheduler 和 StdScheduler==



**涉及关键类有三个：**


1、调度工作类：org.springframework.scheduling.quartz.JobDetailFactoryBean，该对象通过jobClass属性指定调度工作类(做什么)；


2、调度触发器：org.springframework.scheduling.quartz.CronTriggerFactoryBean，该对象通过jobDetail属性指定工作类，通过

cronExpression属性指定调度具体的时间及频率(什么时候做)；



3、调度工厂类：org.springframework.scheduling.quartz.SchedulerFactoryBean，该对象通过triggers属性指定单个或多个触发器(调度安排)。



下面就程序中出现的几个参数，看一下Quartz框架中的几个重要参数：

- Job和JobDetail
- JobExecutionContext
- JobDataMap
- Trigger、SimpleTrigger、CronTrigger

#### （1）Job和JobDetail

Job是Quartz中的一个接口，接口下只有execute方法，在这个方法中编写业务逻辑。
接口中的源码：

![这里写图片描述](https://img-blog.csdn.net/20180710135513678?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

JobDetail用来绑定Job，为Job实例提供许多属性：

- name
- group
- jobClass
- jobDataMap

JobDetail绑定指定的Job，每次Scheduler调度执行一个Job的时候，首先会拿到对应的Job，然后创建该Job实例，再去执行Job中的execute()的内容，任务执行结束后，关联的Job对象实例会被释放，且会被JVM GC清除。

为什么设计成JobDetail + Job，不直接使用Job

> JobDetail定义的是任务数据，而真正的执行逻辑是在Job中。
>
> 这是因为任务是有可能并发执行，如果Scheduler直接使用Job，就会存在对同一个Job实例并发访问的问题。而JobDetail & Job 方式，Sheduler每次执行，都会根据JobDetail创建一个新的Job实例，这样就可以规避并发访问的问题。
>
> 



**QuartzJobBean**

JobDetail 一般会

```java
public abstract class QuartzJobBean implements Job {
    public QuartzJobBean() {
    }

    public final void execute(JobExecutionContext context) throws JobExecutionException {
        try {
            BeanWrapper bw = PropertyAccessorFactory.forBeanPropertyAccess(this);
            MutablePropertyValues pvs = new MutablePropertyValues();
            pvs.addPropertyValues(context.getScheduler().getContext());
            pvs.addPropertyValues(context.getMergedJobDataMap());
            bw.setPropertyValues(pvs, true);
        } catch (SchedulerException var4) {
            throw new JobExecutionException(var4);
        }

        this.executeInternal(context);
    }

    protected abstract void executeInternal(JobExecutionContext var1) throws JobExecutionException;
}
```



#### （2）JobExecutionContext

JobExecutionContext中包含了Quartz运行时的环境以及Job本身的详细数据信息。
当Schedule调度执行一个Job的时候，就会将JobExecutionContext传递给该Job的execute()中，Job就可以通过JobExecutionContext对象获取信息。

![这里写图片描述](https://img-blog.csdn.net/20180710135537517?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

#### （3）JobExecutionContext

**JobExecutionContext定义:**
当Schedule调用一个Job时，就会将JobExecutionContext传递给Job的exceute()方法。
Job能够通过JobExecutionContext对象访问到Quartz运行时候的环境以及Job本身的数据明细。

**JobDataMap定义：**
在进行任务调度时，JobDataMap储存在JobExecutionContext中，非常方便。
在JobDateMap可以用来装载任何可序列化的数据对象，当Job实例对象被执行时这些参数对象会传递给它。
JobDataMap实现了JDK的Map接口，可以以Key-Value的形式存储数据。
JobDetail、Trigger都可以使用JobDataMap来设置一些参数或信息，
Job执行execute()方法的时候，JobExecutionContext可以获取到JobExecutionContext中的信息：
如：

```java
JobDetail jobDetail = JobBuilder.newJob(PrintWordsJob.class).usingJobData("jobDetail1", "这个Job用来测试的")
                  .withIdentity("job1", "group1").build();

 Trigger trigger = TriggerBuilder.newTrigger().withIdentity("trigger1", "triggerGroup1")
      .usingJobData("trigger1", "这是jobDetail1的trigger")                                                                                                                                                                                                                                                                                                                                                              
      .startNow()//立即生效
      .withSchedule(SimpleScheduleBuilder.simpleSchedule()
      .withIntervalInSeconds(1)//每隔1s执行一次
      .repeatForever()).build();//一直执行

```

Job执行的时候，可以获取到这些参数信息：

```java

    public void execute(JobExecutionContext jobExecutionContext) throws JobExecutionException {
 
        System.out.println(jobExecutionContext.getJobDetail().getJobDataMap().get("jobDetail1"));
        System.out.println(jobExecutionContext.getTrigger().getJobDataMap().get("trigger1"));
        String printTime = new SimpleDateFormat("yy-MM-dd HH-mm-ss").format(new Date());
        System.out.println("PrintWordsJob start at:" + printTime + ", prints: Hello Job-" + new Random().nextInt(100));

 
    }
```

#### （4）Trigger、SimpleTrigger、CronTrigger

- **Trigger**

Trigger是Quartz的触发器，会去通知Scheduler何时去执行对应Job。

```java
new Trigger().startAt():表示触发器首次被触发的时间;
new Trigger().endAt():表示触发器结束触发的时间;
```

- **SimpleTrigger**
  SimpleTrigger可以实现在一个指定时间段内执行一次作业任务或一个时间段内多次执行作业任务。
  下面的程序就实现了程序运行5s后开始执行Job，执行Job 5s后结束执行：

```java
Date startDate = new Date();
startDate.setTime(startDate.getTime() + 5000);

 Date endDate = new Date();
 endDate.setTime(startDate.getTime() + 5000);

        Trigger trigger = TriggerBuilder.newTrigger().withIdentity("trigger1", "triggerGroup1")
                .usingJobData("trigger1", "这是jobDetail1的trigger")
                .startNow()//立即生效
                .startAt(startDate)
                .endAt(endDate)
                .withSchedule(SimpleScheduleBuilder.simpleSchedule()
                .withIntervalInSeconds(1)//每隔1s执行一次
                .repeatForever()).build();//一直执行
```

- **CronTrigger**

CronTrigger功能非常强大，是基于日历的作业调度，而SimpleTrigger是精准指定间隔，所以相比SimpleTrigger，CroTrigger更加常用。CroTrigger是基于Cron表达式的，先了解下Cron表达式：
由7个子表达式组成字符串的，格式如下：

> [秒] [分] [小时] [日] [月] [周] [年]

Cron表达式的语法比较复杂，
如：* 30 10 ? * 1/5 *
表示（从后往前看）
[指定年份] 的[  周一到周五 ][ 指定月 ][不指定日][上午10时][30分][指定秒]

又如：00 00 00 ？ * 10,11,12 1#5 2018
表示2018年10、11、12月的第一周的星期五这一天的0时0分0秒去执行任务。

下面是给的一个例子：

![这里写图片描述](https://img-blog.csdn.net/20180710135615747?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

可通过在线生成Cron表达式的工具：http://cron.qqe2.com/ 来生成自己想要的表达式。

![这里写图片描述](https://img-blog.csdn.net/20180710135623995?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25vYW1hbl93Z3M=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

下面的代码就实现了每周一到周五上午10:30执行定时任务

```java
/**
 * Created by wanggenshen
 * Date: on 2018/7/7 20:06.
 * Description: XXX
 */
public class MyScheduler2 {
    public static void main(String[] args) throws SchedulerException, InterruptedException {
        // 1、创建调度器Scheduler
        SchedulerFactory schedulerFactory = new StdSchedulerFactory();
        Scheduler scheduler = schedulerFactory.getScheduler();
        // 2、创建JobDetail实例，并与PrintWordsJob类绑定(Job执行内容)
        JobDetail jobDetail = JobBuilder.newJob(PrintWordsJob.class)
                .usingJobData("jobDetail1", "这个Job用来测试的")
                .withIdentity("job1", "group1").build();
        // 3、构建Trigger实例,每隔1s执行一次
        Date startDate = new Date();
        startDate.setTime(startDate.getTime() + 5000);

        Date endDate = new Date();
        endDate.setTime(startDate.getTime() + 5000);

        CronTrigger cronTrigger = TriggerBuilder.newTrigger().withIdentity("trigger1", "triggerGroup1")
                .usingJobData("trigger1", "这是jobDetail1的trigger")
                .startNow()//立即生效
                .startAt(startDate)
                .endAt(endDate)
                .withSchedule(CronScheduleBuilder.cronSchedule("* 30 10 ? * 1/5 2018"))
                .build();

        //4、执行
        scheduler.scheduleJob(jobDetail, cronTrigger);
        System.out.println("--------scheduler start ! ------------");
        scheduler.start();
        System.out.println("--------scheduler shutdown ! ------------");

    }
}
```



