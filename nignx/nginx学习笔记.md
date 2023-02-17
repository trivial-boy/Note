## nginx学习笔记

###  nginx 是什么，做什么事情

Nginx ("engine x")是一个高性能的HTTP和反向代理服务器,特点是占有内存少，并发能力强,事实上nginx的并发能力确实在同类型的网页服务器中表现较好,中国大陆使用nginx.网站用户有:百度、京东、新浪、网易、腾讯、淘宝等



### nginx 作用

#### 反向代理

(1) 正向代理

在客户端 配置代理服务器，通过代理服务器进行服务器访问

![image-20210523181140412](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210523181140412.png)

(2) 反向代理

反向代理，其实客户端对代理是无感知的，因为客户端不需要任何配置就可以访问，我们只需要将请求发送到反向代理服务器，由反向代理服务器去选择目标服务器获取数据后，再返回给客户端，此时反向代理服务器和目标服务器对外就是一个服务器，暴露的是代理服务器地址，隐藏了真实服务器IP地址。

#### 动静分离

为了加快网站的解析速度，可以把动态页面和静态页面由不同的服务器来解析，加快解析速度。降低原来单个服务器的压力。(静态资源和动态资源分服务器存放)

![image-20210917173621501](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210917173621501.png)



#### 负载均衡

![image-20210523181825286](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210523181825286.png)

单个服务器解决不了，我们增加服务器的数量，然后将请求分发到各个服务器上，将原先请求集中到单个服务器上的情况改为将请求分发到多个服务器上，将负载分发到不同的服务器，也就是我们所说的负载均衡

![image-20210523182145515](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210523182145515.png)

#### 1.2Nginx作为web服务器
Nginx.可以作为静态页面的web服务器，同时还支持CGI协议的动态语言，比如perl、php等。但是不支持 java。Java 程序只能通过与tomcat配合完成。Nginx,专为性能优化而开发，性能是其最重要的考量,实现上非常注重效率，能经受高负载的考验,有报告表明能支持高达50,000个并发连接数。



### nginx安装、常用命令和配置文件

#### nginx常用命令

```
启动nginx
nginx 
重加载nginx
nginx -s reload
测试 nginx 配置 是否正确
nginx -t

```



#### nginx配置文件

nginx 配置文件由三部分组成

**第一部分： 全局块**

从配置文件开始到events 块之间的内容，主要会设置一些影响nginx 服务器整体运行的配置命令

比如 ：worker_process 1; worker_processes 值越大，可以支持的并发处理量也越多。



**第二部分  events 块：**

events 块涉及的指令主要影响 Nginx 服务器与用户的网络连接

比如 worker_connections 1024 支持最大连接数



**第三部分 http 块:**

Nginx 服务器配置中最频繁的部分
http 块也可以包括http全局块、server 块



### 3. nginx配置实例-反向代理



#### 反向代理实例1

1. 实现效果

   （1） 打开浏览器，在浏览器输入www.123.com,跳转到linux 系统tomcat 主页面中。

步骤：

1. 创建 tomcat 和 nginx docker

使用docker-compose 创建

```yml
version: "3.7"
services:
    nginx:
        image: nginx
        restart: always
        environment: 
            - TZ=Asia/Shanghai
        ports:  
            - "80:80"
            - "443:443"
        volumes:
            - /docker/nginx/conf.d:/ect/nginx/conf.d
            - /docker/nginx/log:/var/log/nginx
            - /root/project/test:/etc/nginx/html
            - /docker/nginx/nginx.conf:/etc/nginx/nginx.conf
        container_name: nginx_test
        
    tomcat:
        restart: always
        image: tomcat:8  
        container_name: tomcat
        ports:
            -8080:8080
        volumes:
            - /root/project/test/webapps:/user/local/tomcat/webapps
```

注：官网的tomcat镜像 webapps 里面没有东西 但是 webapps.dist里面有，我们拷贝一份到webapps里面就好了

2. 本机设置host映射 windows 位置 （C:\Windows\System32\drivers\etc）

   ![image-20210917223332107](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210917223332107.png)

访问www.123.com:8080 成功访问到

![image-20210917223612863](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210917223612863.png)



nginx 配置 反向代理



conf.d 下创建新文件 test.conf 

```shell
server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            proxy_pass http://127.0.0.1:8080;
            index  index.html index.htm;
        }
}
```

重启nginx 成功用www.123.com 访问。



#### 反向代理实例2

1. 实现效果：使用nginx 反向代理，根据访问的路径跳转到不同端口服务中

   nginx 监听端口为80

   访问http://127.0.0.1/edu/a.html直接跳转到 tomcat01 的 a.html

   访问http://127.0.0.1/vod/a.html直接跳转到 tomcat02 的 a.html

2. 准备工作

   1. 创建两个tomcat服务器，一个8080端口，一个8081端口 使用docker-compose 创建
   2. 创建文件夹和测试页面

   ```yaml
   version: "3.7"
   services:
       nginx:
           image: nginx
           restart: always
           environment: 
               - TZ=Asia/Shanghai
           ports:  
               - "80:80"
               - "443:443"
           volumes:
               - /docker/nginx/conf.d:/etc/nginx/conf.d
               - /docker/nginx/log:/var/log/nginx
               - /root/project/test:/etc/nginx/html
               - /docker/nginx/nginx.conf:/etc/nginx/nginx.conf
           container_name: nginx_test
           networks: 
               - net
   
           
       tomcat:
           restart: always
           image: tomcat:8  
           container_name: tomcat01
           ports:
               - 8080:8080
           volumes:
               - /docker/tomcat01/webapps:/usr/local/tomcat/webapps
           networks: 
               - net
   
       tomcat02:
           restart: always
           image: tomcat:8  
           container_name: tomcat02
           ports:
               - 8081:8080
           volumes:
               - /docker/tomcat02/webapps:/usr/local/tomcat/webapps
           networks: 
               - net
   networks: 
       net:
           driver: bridge
   
   ```

   

3. 具体配置

   nginx 配置

   ```shell
   server {
           listen       80;
           server_name  127.0.0.1;
   
          location ~ /edu {
               proxy_pass http://tomcat01:8080;
           }
           location  /vod {
               proxy_pass http://tomcat02:8080;
           }
   }
   ```

   location 指令说明

   ​	该指令用于匹配URL

   ​	语法如下：

   ```
   1、= :用于不含正则表达式的uri前，要求请求字符串与uri严格匹配，如果匹配成功，就停止继续向下搜索并立即处理该请求。
   
   2、~:用于表示uri包含正则表达式，并且区分大小写。
   
   3、~*:用于表示 uri包含正则表达式，并且不区分大小写。
   
   4、^~:用于不含正则表达式的uri前，要求 Nginx服务器找到标识 _uri和请求字符串匹配度最高的location后，立即使用此 location处理请求，而不再使用location块中的正则uri和请求字符串做匹配。
   
   注意:如果uri包含正则表达式，则必须要有~或者~*标识。
   ```

   

### 4.nginx配置实例-负载均衡

负载均衡是将负载分摊到不同的服务单元，既保证服务的可用性，又保证响应足够快,给用户很好的体验。



1. 实现效果：

   （1） 浏览器输入地址 www.123.com/edu/a.html，负载均衡效果，平均 分配到 tomcat01 服务器和tomcat02 服务器

2. 准备 

   （1）准备两台tomcat服务器，一台8080 一台8081

   （2）在两台tomcat里面 webapps,目录中，创建名称edu文件夹，在edu文件夹中创建页面a.html，用于测试

nginx 配置

```shell
upstream myserver{
    server tomcat02:8080;
    server tomcat01:8080;
}

server {
        listen       80;
        server_name  127.0.0.1;

       location  / {
            proxy_pass http://myserver;
            proxy_connect_timeout 10;
        }

}
```

<img src="https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210918170612682.png" alt="image-20210918170612682" style="zoom:80%;" />



<img src="https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210918170625679.png" alt="image-20210918170625679" style="zoom:80%;" />

nginx 负载均衡分配策略

1. 轮询（默认）

   每个请求按时间顺序注意分配到不同的后端服务器，如果服务器挂了，能自动剔除

2. weight

   weight代表权,重默认为1,权重越高被分配的客户端越多

   指定轮询几率，weight和访间比率成正比，用于后端服务器性能不均的情况。例如:

   ```shell
   upstream myserver{
       server tomcat02:8080 weight=1;
       server tomcat01:8080 weight=2;
   }
   ```

   

3. ip_hash

   每个请求按访问ip的hash结果分配，这样每个访客固定访问一个后端服务器,可以解决 session的问题。

   ```shell
   upstream myserver{
       server tomcat02:8080 weight=1;
       server tomcat01:8080 weight=2;
   }
   ```

4. 按后端服务器的响应时间来分配请求，响应时间短的优先分配

   ```shell
   upstream myserver{
       server tomcat02:8080 weight=1;
       server tomcat01:8080 weight=2;
       fair;
   }
   ```

   

### 5. nginx配置实例3-动静分离

​	![image-20210918172230214](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210918172230214.png)

> Nginx动静分离简单来说就是把动态跟静态请求分开,不能理解成只是单纯的把动态页面和静态页面物理分离。
>
> 严格意义上说应该是动态请求跟静态请求分开，可以理解成使用Nginx处理静态页面，Tomcat处理动态页面。
>
> 动静分离从目前实现角度来讲大致分为两种：
>
> -  一种是纯粹把静态文件独立成单独的域名,放在独立的服务器上,也是目前主流推崇的方案
>
> - 另外一种方法就是动态跟静态文件混合在一起发布，通过nginx来分开。通过 location指定不同的后缀名实现不同的请求转发。通过 expires参数设置，可以使浏览器缓存过期时间，减少与服务器之前的请求和流量。
>
> 具体 Expires定义:是给一个源设定一个过期时间,也就是说无需去服务端验证,直接通过浏览器自身确认是否过期即可所以不会产生额外的流量。
>
> 此种方法非常适合不经常变动的资源。(如果经常更新的文件不建议使用Expires来缓存），如果设置3d，表示在这3天之内访问这个URL，发一个请求，比对服务器该文件最后更新时间，没有变化，则不会从服务器抓取，返回状态码304，如果有修改，则直接从服务器重新下载，返回状态码200。

**nginx 配置**



```
upstream myserver{
    server tomcat02:8080;
    server tomcat01:8080;
}

server {
        listen       80;
        server_name  127.0.0.1;

       location  / {
            proxy_pass http://myserver;
            proxy_connect_timeout 10;		
	    }

        location /image {
            root /data/image;
            autoindex  on;
        }

        location /www {
            root /data/www;
	    	index index.html index.htm;
        }
}
```

### 6. nginx配置高可用集群

####  

#### 1. 什么是nginx的高可用

目前产生的问题，nginx宕机，将无法像服务器发送请求

![image-20210918202746755](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210918202746755.png)

![image-20210918203215504](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210918203215504.png)

1. 需要两台nginx服务器
2. 需要keepalived
3. 需要虚拟 ip

#### 配置高可用的准备工作

1. 启动两个nginx容器
2. 在两台nginx容器中安装 nginx
3. 在两台服务器安装keepalived

#### 编写docker-compose.yml

```yaml
# nginx 高可用主从配置
version: "3"
services:
    nginx_master:
        build:
            context: ./
            dockerfile: ./Dockerfile
        volumes:
            - /docker/nginx/conf.d:/etc/nginx/conf.d
            - /docker/nginx/log:/var/log/nginx
            - /root/project/test:/etc/nginx/html
            - /docker/nginx/nginx.conf:/etc/nginx/nginx.conf
            - /docker/nginx/keepalived-master.conf:/etc/keepalived/keepalived.conf
        container_name: nginx_master
        networks:
          static-net:
            ipv4_address: 172.26.128.2
    nginx_slave:
        build:
            context: ./
            dockerfile: ./Dockerfile
        volumes:
            - /docker/nginx/conf.d:/etc/nginx/conf.d
            - /docker/nginx/log:/var/log/nginx
            - /root/project/test:/etc/nginx/html
            - /docker/nginx/nginx.conf:/etc/nginx/nginx.conf
            - /docker/nginx/keepalived-slave.conf:/etc/keepalived/keepalived.conf
        container_name: nginx_slave
        networks:
          static-net:
            ipv4_address: 172.26.128.3
    tomcat01:
        restart: always
        image: tomcat:8  
        container_name: tomcat01
        volumes:
            - /docker/tomcat/webapps:/usr/local/tomcat/webapps
        networks:
          static-net:
            ipv4_address: 172.26.128.4
                             
    tomcat02:
        restart: always
        image: tomcat:8  
        container_name: tomcat02
        volumes:
            - /docker/tomcat/webapps:/usr/local/tomcat/webapps
        networks:
          static-net:
            ipv4_address: 172.26.128.5


    tomcat03:
        restart: always
        image: tomcat:8  
        container_name: tomcat03
        volumes:
            - /docker/tomcat/webapps:/usr/local/tomcat/webapps
        networks:
          static-net:
            ipv4_address: 172.26.128.6

networks:
  static-net:
    ipam:
      config:
        - subnet: 172.26.0.0/16

```

#### 编写Dockerfile

```yaml
FROM nginx:1.13.5-alpine

RUN apk update && apk upgrade

RUN apk add --no-cache bash curl ipvsadm iproute2 openrc keepalived && rm -f /var/cache/apk/* /tmp/*

COPY entrypoint.sh /entrypoint.sh

COPY check_nginx.sh /etc/keepalived/check_nginx.sh

RUN chmod +x /entrypoint.sh

RUN chmod +x /etc/keepalived/check_nginx.sh

CMD ["/entrypoint.sh"]

```

#### 编写keepalived配置文件

1. keepalived-master.conf

   ```yaml
   global_defs {
       notification_email {
           762357658@qq.com
       }
       notification_email_from itsection@example.com
       smtp_server mail.example.com
       smtp_connect_timeout 30
       router_id LVS_DEVEL #表示节点id 可以修改
   }
    
    
   vrrp_script chk_nginx {
       script "/etc/keepalived/nginx_check.sh" # 执行检测nginx进程是否正常的脚本
       interval 2
       weight 2
   }
    
    
   vrrp_instance VI_1 {
       state MASTER  # 主机位MASTER 从机是BACKUP
       interface eth0  # 网卡名称 使用ifconfig可以查看
       mcast_src_ip 172.26.128.2 #当前节点ip
       virtual_router_id 2 # 虚拟节点id，需要与backup保持一致
       priority 101 # 优先级 master 要大于 backup
       advert_int 2
       authentication {
           auth_type PASS
           auth_pass 1111
       }
       virtual_ipaddress {
           172.17.0.210  #虚拟节点ip，需要配置，这样在网关处可以访问该ip用来跳转到某一节点。
       }
       track_script {
          chk_nginx # 调用执行脚本的函数，上面已经定义该函数。
       }
    
   }
   ```

2. keepalived-slave.conf

   ```yaml
   global_defs {
       notification_email {
           762357658@qq.com
       }
       notification_email_from itsection@example.com
       smtp_server mail.example.com
       smtp_connect_timeout 30
       router_id LVS_DEVEL #表示节点id 可以修改
   }
    
    
   vrrp_script chk_nginx {
       script "/etc/keepalived/check_nginx.sh" # 执行检测nginx进程是否正常的脚本
       interval 2
       weight 2
   }
    
    
   vrrp_instance VI_1 {
       state BACKUP # 主机位MASTER 从机是BACKUP
       interface eth0  # 网卡名称 使用ifconfig可以查看
       mcast_src_ip 172.26.128.3 #当前节点ip
       virtual_router_id 2 # 虚拟节点id，需要与backup保持一致
       priority 100 # 优先级 master 要大于 backup
       advert_int 2
       authentication {
           auth_type PASS
           auth_pass 1111
       }
       virtual_ipaddress {
           172.17.0.210  #虚拟节点ip，需要配置，这样在网关处可以访问该ip用来跳转到某一节点。
       }
       track_script {
          chk_nginx # 调用执行脚本的函数，上面已经定义该函数。
       }
    
   }
   ```

#### 编写entrypoint.sh 开机启动 keepalived

```yaml
#!/bin/sh

/usr/sbin/keepalived -n -l -D -f /etc/keepalived/keepalived.conf --dont-fork --log-console &

nginx -g "daemon off;"

```

#### 配置 check_nginx 检测nginx是否停止脚本。

```shell
#!/bin/bash
A=`ps -ef | grep nginx | grep -v grep | wc -l`
if [ $A -eq 0 ];then
    nginx
    sleep 2
    if [ `ps -ef | grep nginx | grep -v grep | wc -l` -eq 0 ];then
        #killall keepalived
        killall keepalived
    fi
fi　
```





### 7. nginx原理 

1. **master 和 worker**

![image-20210919170829685](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210919170829685.png)

2. **work是如何工作的**

![image-20210919171002662](https://picture-li.oss-cn-beijing.aliyuncs.com/img/image-20210919171002662.png)

3. **一个master 和 多个worker 好处是：**

- nginx -s reload 利于nginx做热部署
- 每个worker 是独立进程，如果有其中的一个worker出现问题，其他worker独立的，继续进行争抢，实现请求过程，不会赵成服务中断。



4. **设置多少个worker比较合适**

Nginx同redis,类似都采用了io多路复用机制，每个worker都是一个独立的进程，但每个进程里只有一个主线程，通过异步非阻塞的方式来处理请求，即使是千上万个请求也不在话下。每个worker的线程可以把一个cpu 的性能发挥到极致。所以worker数和服务器的cpu数相等是最为适宜的。设少了会浪费cpu，设多了会造成cpu频繁切换上下文带来的损耗。

worker数和服务器的cpu数相等是最为适宜的

5. **连接数worker_connection**

> **第一个:发送请求，占用了woker的几个连接数?**
>
> 答案:2或者4个



> **第二个: nginx有一个master，有四个woker，每个 woker支持最大的连接数1024，支持的最大并发数是多少?**
>
> 普通的静态访问最大并发数是:worker_connections * worker_processes /2
>
> 而如果是HTTP作为反向代理来说，最大并发数量应该是worker_connection * worker_processes/4。





## 补充

ng
