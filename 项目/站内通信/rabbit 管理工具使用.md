# rabbitMQdocker安装，rabbitMQ Manager如何添加用户账号，添加虚拟机

### 1. rabbitMQ 安装

docker 安装 rabbitMQ

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

访问15672端口出现下面界面代表RabbitMQ安装成功  该页面即为rabbitMQ 管理界面 默认账号密码都是guest

![这里写图片描述](https://img-blog.csdn.net/20180628164208377?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dhbmdiaW5nMjUzMDc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

 

![这里写图片描述](https://img-blog.csdn.net/20180628164238267?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dhbmdiaW5nMjUzMDc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

### 2. 添加用户

![image-20210219105352831](https://gitee.com/lxsupercode/picture/raw/master/img/20210219105352.png)

![image-20210219105446670](https://gitee.com/lxsupercode/picture/raw/master/img/20210219105446.png)

### 3. 添加虚拟机

rabbitMQ的虚拟机就相当于mysql中的一个表，是与其他虚拟机分割开的

![image-20210219105841037](https://gitee.com/lxsupercode/picture/raw/master/img/20210219105841.png)

创建完成之后表格中会显示

<img src="https://gitee.com/lxsupercode/picture/raw/master/img/20210219105903.png"/>

我们也可以为虚拟机添加账号，现在我的/test下有一个admin账号，我再为其添加一个guest账号

![image-20210219110035159](https://gitee.com/lxsupercode/picture/raw/master/img/20210219110035.png)

![image-20210219110141788](https://gitee.com/lxsupercode/picture/raw/master/img/20210219110141.png)

![image-20210219110149228](https://gitee.com/lxsupercode/picture/raw/master/img/20210219110149.png)

现在显示有两个账号了

![image-20210219110225754](https://gitee.com/lxsupercode/picture/raw/master/img/20210219110225.png)

添加成功。