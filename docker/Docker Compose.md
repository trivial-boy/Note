## Docker Compose

### 简介

目前我们使用 Docker 的时候，需要定义 Dockerfile 文件，然后使用 docker build、docker run 等命令操作容器。

微服务项目中有100个微服务！如果有问题重新启动非常麻烦。

- **使用 Docker Compose 可以轻松、高效的管理容器，它是一个用于定义和运行多容器 Docker 的应用程序工具**

#### 官方介绍

定义、运行多个容器

YAML file 配置文件

single command。 命令有哪些？

Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file toconfigure your application's services. Then, with a single command, you create and start all the services from yourconfiguration.To learn more about all the features of Compose, see the list of features.

Compose works inall environment: production,staging , development, testing, as well as Cl workflows. You can learn moreabout each case in Common Use Cases.

**三步骤：**

Using Compose is basically a three-step process:

1. Define your app's environment with a `Dockerfile`so it can be reproduced anywhere.

   Dockerfile 保证我们的项目可以在任何地方运行。

2. Define the services that make up your app in `docker-compose.yml` so they can be run together in an isolated environment.

   services 什么是服务

   docker-compose.yml 这个文件怎么写！

1. Run `docker-compose up` and Compose starts and runs your entire app.

   启动项目

作用: 批量容器编排

Dockerfile让程序在任何地方运行。web服务。redis、mysql、nginx ...多个容器。run

```yaml
version: '2.0'
services:
	web :
		buil1d: .
		ports :
		- "5000:5000"
		volumes :
		- .:/code
		- logvolume01 : /var/log
		links :
		- redis
     redis :
		image: redis
volumes :
	logvolume01:{}
```

docker-compose up 100 个服务

Compose：重要的概念

- 服务services，容器。应用。（web、redis、mysql...）
- 项目project。 一组关联的容器



### 安装compose

1、下载

```shell
#官方
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#国内镜像下载
curl -l "https://get.daocloud.io/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose

```

2. 授权

```shell
sudo chmod +x docker-compose

#使用docker-compose version查看是否开启成功

```

### **官方示例**

1. **编写应用文件 app.py**

```python
import time

import redis
from flask import Flask

app = Flask(__name__)
cache = redis.Redis(host='redis', port=6379)

def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)

@app.route('/')
def hello():
    count = get_hit_count()
    return 'Hello World! I have been seen {} times.\n'.format(count)
```

​	创建`requirements.txt`

```shell
flask
redis
```



2. **创建Dockerfile**

```shell
# syntax=docker/dockerfile:1
FROM python:3.7-alpine
WORKDIR /code
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
RUN apk add --no-cache gcc musl-dev linux-headers
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
EXPOSE 5000
COPY . .
CMD ["flask", "run"]
```

3. 编写 Docker-compose yaml文件（定义整个服务器，需要的环境。wen、redis）

```shell
version: "3.9"
services:
  web:
    build: .
    ports:
      - "5000:5000"
  redis:
    image: "redis:alpine"
```

4. **创建和运行 docker-compose**

```shell
docker-compose up
#后台启动
docker-compose up -d

docker-compose --build 重新构建
```

**docker-compose启动流程**

1. 创建网络
2. 执行Docker-compose
3. 启动服务

成功启动。。。

![image-20210803195422711](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210803195422711.png)

![image-20210803200359589](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210803200359589.png)

默认的容器名 文件名_服务名 _ num



**尝试访问应用，成功。**

```shell
[root@lxx-server ~]# curl http://127.0.0.1:5000
Hello World! I have been seen 1 times.
```



查看网络，发现创建了一个bridge网络



![image-20210803200604256](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210803200604256.png)

![image-20210803200734941](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210803200734941.png)

两容器已加入新建的网络内

如果在同一个网络下，可直接通过域名访问。

**5. 停止**

```shell
1. docker-compose stop/down
2. 直接按ctrl+c关闭
```

### yaml 规则

docekr-compose.yaml 核心

```yaml
# 3 层
version: '' #版本
services: #服务
	服务1: web
		#服务配置
		images
		build
		network
		...
	服务2: redis
    	...
#其他配置
volumes:
networks:
configs:
```



### 实战

1. 编写项目微服务
2. dockerfile 构建镜像
3. docker-compose.yaml 编排项目
4. 放入服务器上， docker-compose up



## 配置文件解析

#### 1.version

指定compose文件的版本号, 有1,2,3个版本，目前最新的是3版本,1版本已经在慢慢弃用，建议使用最新版本，如下命令，指定3版本

```yaml
version: "3"
```

#### 2.services

根节点，编排的服务需要写在services下面，如下配置，在services下编排了web服务和nginx服务，web,nginx服务名称可自己定义

```yaml
version: '3'
services:
    web:
      image: dev_tools_web
    nginx:
       image: my_nginx:v1
```

注意名称不能使用大写。

#### 3.image

指定镜像的名称或镜像ID，先从本地镜像仓库中找，如果找到，使用本地镜像，如果找不到，则从中央仓库下载，如下配置均可以

```yaml
image: dev_tools_web
image: ubuntu:14.04
image: tutum/influxdb
image: example-registry.com:4000/postgresql
image: a4bc65fd
```

#### 4.build

除了使用image指定镜像外，还可以通过Dockerfile文件，在up命令启动时执行构建，使用的构建标签就是build，它可以指定Dockerfile文件所在目录，compose可以通过Dockerfile文件生成镜像，然后通过该镜像启动容器服务

Dockerfile文件放在/home/ubuntu/dev_tools目录下，因此可以使用绝对路径

```yaml
version: '3'
services:
    web:
       build: /home/ubuntu/dev_tools
```

也可以使用相对路径，只要能读到Dockerfile文件

```shell
build: ../dev_tools
```

#### 5.context

除了在build中直接指定Dockerfile所在目录的路径外，还可以通过context上下文，指定上下文后，可以基于指定的上下文找Dockerfile文件

```yaml
version: '3'
services:
    web:
       build:
         context: /home/ubuntu
         dockerfile: ./dev_tools/Dockerfile
```

#### 6.container_name

容器的默认名称是<项目名>*<服务名>*<序号>，如果需要指定容器名称，可以使用container_name，在如下配置中，指定容器的名称为my_web

```yaml
version: '3'
services:
    web:
      image: dev_tools_web
      container_name: my_web

```

通过`docker-compose up -d`创建并启动容器后，再使用`docker-compose ps -a`使用查看，发现容器名称已变成my_web

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200501103323100.png)

但是这样会有一个问题，由于容器名称是唯一的，指定容器名称后，就无法进行扩容，比如要把web服务扩容到5个节点，执行扩容命令 `docker-compse scale web=5`，则出现如下错误

#### 7.ports

指定容器的端口映射，是一个数组，使用HOST:CONTAINER格式，或者只是指定容器的端口，宿主机会随机映射端口，如下配置，指定了缩主机(8090)和容器(8081)的端口映射

```yaml
version: '3'
services:
    web:
      image: dev_tools_web
      ports:
        - 8090:8081
```

还可以同时指定多个端口，如下配置均有效

```yaml
ports:
 - "3000"
 - "8090:8081"
 - "49100:22"
 - "127.0.0.1:8001:8001"
```

注意：当使用HOST:CONTAINER格式来映射端口时，如果你使用的容器端口小于60你可能会得到错误得结果，因为YAML将会解析xx:yy这种数字格式为60进制。所以建议采用字符串格式

#### 8.depends_on

如果服务需要依赖于其他服务，可以使用depends_on指定依赖关系，depends_on是一个数组，compose创建并启动一个服务时，会优先启动依赖的服务，如下配置，web服务依赖于redis和db，先启动redis和db后，才会启动web服务

```yaml
version: '3'
services:
    web:
      image: dev_tools_web
      ports:
         - 8081:8081
      depends_on:
       - redis
       - db
    redis:
       image: wodby/redis
       ports:
          - 6379:6379
    db:
       image: mysql
       ports:
          - 3306:3306

```

#### 9.volumes

挂载一个目录或已存在的数据卷容器，可以使用[HOST:CONTAINER]或[HOST:CONTAINER:ro]这样的格式，对于后者来说，数据卷只读，这样可以保证宿主机的文件不被修改
compose的数据卷可以是相对路径，也可以是绝对路径，还可以是已存在的数据卷(但是容器挂载路径只能是绝对路径)

```yaml
version: '3'
services:
    web:
      image: dev_tools_web
      volumes:
       # 只指定容器挂载目录，Docker会制动创建一个数据卷
       - /app/logs
       # 使用绝对路径挂载数据卷
       - /app/data:/tmp/data:ro
       # 以 Compose 配置文件为中心的相对路径作为数据卷挂载到容器
       - ./cache:/tmp/cache
       # 已经存在的数据卷
       - file_data:/tmp/file_data
volumes:
    file_data:
```

以上配置，使用`docker-compose config`检查配置,结果如下

以上结果可看出，挂载目录`./cache:/tmp/cache`和数据卷`file_data`未指定操作权限，默认权限为`rw`–可读可写；如果数据卷需要给其他服务共享，则需要定义在`volumes`标签下，服务启动时，如果数据卷不存在，则先创建数据卷，如下启动结果

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200504114336597.png)

配置 `- /app/logs`未指定数据卷，启动服务时，docker会自动创建一个数据卷，如下结果
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200504114945694.png)
配置 `- /app/data:/tmp/data:ro`和 `- ./cache:/tmp/cache`指定的是宿主机和容器的挂载目录，这种挂载目录只能容器内部使用

#### 10.networks

Docker提供的network功能能够对容器进行网络上的隔离，如下配置，我们创建了三个服务和两个网络，其中proxy和web共用frantnet网络,web和db共用endnet网络

```yaml
version: '3'
services:
    proxy:
      image: nginx
      networks:
        - frantnet
    web:
      image: dev_tools_web
      networks:
        - frantnet
        - endnet
    db:
      image: mysql
      networks:
        - endnet
networks:
   frantnet:
   endnet:
```

使用命令 `docker-compose up -d`启动服务，从执行结果可看出，创建了两个网络和三个容器

两容器连接在同一网桥下时，可用网络别名来访问容器（默认别名是容器名）。 例如：访问db 时我们可以使用db代替ip地址

```shell
networks:
  endnet:
    driver: overlay
  frantnet:
    driver: overlay
```



