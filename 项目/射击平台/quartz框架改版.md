## 定时任务接口使用文档

### 简介

本次项目使用分布式，由于各模块之间bean不能互通，之前定时任务的方案不能再用。

结合本次需求对quartz框架做了一些调整，设计思路和使用方式如下

### 设计思路

![image-20210328165040349](https://gitee.com/lxsupercode/picture/raw/master/img/20210328165040.png)



用户作为customer时调用quartz提供的manage服务管理定时任务，

定时任务执行时作为customer去调用用户提供的，想要执行的方法



用户需要提供具体业务接口，调用定时任务时，告诉定时任务需要执行的类和方法，并对其进行管理

每个模块的用户只需建一个对外接口即可（也可多个，只要正确传入类和方法即可）；



### 使用方式

1. **暴露出需要执行的业务**

   在common模块dubbo.feign下建接口 （最好每个模块新建一个包，好管理）

   ```java
   public interface TestJobFeign {
       /**
        * description: 有参数测试
        *
        * @author: lixiangxiang
        * @param test
        * @return void
        * @date 2021/3/28 11:06
        */
       void test(String test);
   
       /**
        * description: 无参数测试
        *
        * @author: lixiangxiang
        * @return void
        * @date 2021/3/28 11:06
        */
       void test2();
   }
   ```

2. 实现该接口

   ```java
   
   @Slf4j
   @Service(version = "1.0")
   @Component
   public class TestJob implements TestJobFeign {
       @Override
       public void test(String test) {
           System.out.println("test执行成功 message为"+test);
       }
   
       @Override
       public void test2() {
           System.out.println("test2执行成功!!!!");
       }
   }
   ```

3. 调用quartz对外接口进行管理

   ```java
   public class QuartzTestController {
   
       @Reference(version = "1.0")
       QuartzFeign quartzFeign;
   
       @ApiOperation(value = "开启一个定时任务3(自定义，复杂使用)")
       @GetMapping("/start3")
       @AnonymousAccess
       public void testStart3(){
           QuartzDto quartzDto = new QuartzDto();
           quartzDto.setId(3L);
           //设置工作类
           quartzDto.setJob(TestJobFeign.class);
           //dubbo service 版本号
           quartzDto.setVersion("1.0");
           //执行方法名
           quartzDto.setMethodName("test");
           //任务名
           quartzDto.setJobName("测试");
           //任务组
           quartzDto.setJobGroup("sf");
           //方法参数 没有参数可以不传
           quartzDto.setParams(new Object[]{"测试start3"});
           //方法参数类型
           quartzDto.setParamsClassName(new String[]{String.class.getName()});
           //循环时间 分钟为单位
           quartzDto.setMinute(0);
           //循环次数
           quartzDto.setTimes(1);
           quartzFeign.startJob(quartzDto);
       }
   }
   ```

### quartz对外提供接口

1. 自定义的定时任务 可以自定义循环次数，开始时间，结束时间，循环间隔时间（暂以分钟为单位，默认30分钟），传输内容（向job传值）

```java
	/**
     * description: 自定义运行一个定时任务
     *
     * @author: lixiangxiang
     * @param quartzDto /
     * @return void
     * @date 2021/3/22 20:57
     */
    void startJob(QuartzDto quartzDto);
```

2. 根据业务需求，提供只执行一次的定时任务的接口，需传入定时任务开始时间 格式“yyyy-MM-dd HH:mm:ss”

```java
	/**
     * description: 执行一次定时任务，传入任务开始时间
     *
     * @author: lixiangxiang
     * @param quartzSmallDto /
     * @param startTime 定时任务开始时间 格式yyyy-MM-dd HH:mm:ss
     * @return void
     * @date 2021/3/23 12:34
     */
    void startOnceJobWithTime(QuartzSmallDto quartzSmallDto,String startTime);
```

3. 也可传入间隔分钟数，等待一段时间后执行一次

```java
 	/**
     * description: 传入分钟执行一次定时任务
     *
     * @author: lixiangxiang
     * @param quartzSmallDto /
     * @param minute 多少分钟后执行
     * @return void
     * @date 2021/3/23 12:32
     */
    void startOnceJobWithMinute(QuartzSmallDto quartzSmallDto, Integer minute);
```

4 .  关闭任务接口,需传入任务id，任务名称，和任务组

```java
	/**
     * description: 关闭定时任务
     *
     * @author: lixiangxiang
     * @param id 任务id
     * @param jobName 任务名称
     * @param jobGroup 任务组
     * @return void
     * @date 2021/3/23 12:36
     */
     void closeJob(Long id, String jobName, String jobGroup);
```

**使用实例**可以查看==shooting-friend==模块下==marchsoft.modules.system.controller.quatzTest.Controller==

