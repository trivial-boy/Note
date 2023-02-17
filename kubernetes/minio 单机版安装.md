# Minio 单机版安装

   1.linux下载minio二进制文件     

```shell
wget https://dl.min.io/server/minio/release/linux-amd64/minio  
```

官网下载不下来下载下面链接

链接：https://pan.baidu.com/s/1DkSK-uL1f9M7XaS8JwSpow  提取码：cu07 
--来自百度网盘超级会员V6的分享

 2.给当前下载的minio应用赋予权限     

```
chmod +x minio 
```

设置账号密码

nginx 配置代理

```shell
# minio 控制台端口
upstream minioconsoleserver{
    server 127.0.0.1:9000;
}
# minio 后端server端口
upstream minioserver {
    server 127.0.0.1:9001;
}

# 代理 minio后端server
server {
    listen       443 ssl default_server;
    server_name  sxweb.sjzc.edu.cn;
    #ssl on;
    
    ssl_certificate /etc/nginx/star_sjzc_edu_cn.pem;
    ssl_certificate_key /etc/nginx/myprivate.key;

    #必须 防止请求头丢失
    underscores_in_headers on;   


    location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_pass http://minioserver;
        client_max_body_size 100g;
        client_body_buffer_size 100m; 
        index  index.html index.htm;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }


  
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

   
}
# 代理minio控制台
server{
    listen 8080;
    #域名，根据实际情况修改
    server_name sxweb.sjzc.edu.cn;
    client_max_body_size 20m;

    access_log /var/log/nginx/host.access.log main;

    #前台，根据实际情况修改
    location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_connect_timeout  300;
        # 设置最大请求体最大大小 （因为要上传大量视频，设置到最大，如果太小会报413 Request Entity Too Large）
        client_max_body_size 100g;
        client_body_buffer_size 100m; 
        # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_pass http://minioconsoleserver;
    }

}
```

注：用nginx为minio管理端配置二级路径会导致静态资源找不到，所以只能用http访问了。

3.控制台运行 

```shell
# 创建文件夹
mkdir /home/minio/data 
# 设置文件存放地址   设置端口号 后台运行minio服务
MINIO_SERVER_URL=https://sxweb.sjzc.edu.cn MINIO_ROOT_USER=train MINIO_ROOT_PASSWORD=train@minio nohup ./minio server /home/minio/data  > /home/minio/logs/minio.log --console-address=":9000" --address=":9001" 2>&1 &
```

> 参数解释：
>
> - MINIO_SERVER_URL minio服务端地址，如果配置了代理这里必须设置，否则默认以内网ip 为serverUrl ,生成的图片地址访问不到
> - MINIO_ROOT_USER 控制台用户名
> - MINIO_ROOT_PASSWORD 密码
> - --console-address 控制台端口号
> - --address 服务端 端口号

补充：docker方式部署

```shell
docker run -d \ 
--name minio \   
--restart=always \   
-p 9000:9000 \   
-p 8080:9001 \   
-e "MINIO_ROOT_USER=minioroot" \   
-e "MINIO_ROOT_PASSWORD=minioroot" \  
-e "MINIO_SERVER_URL=http://sxweb.sjzc.edu.cn:8080"
-v /home/minio/data:/data \   
-v /home/minio/config:/root/.minio  minio/minio:RELEASE.2022-02-12T00-51-25Z server /data --console-address ":9001"
```



# 网络储存—— nfs 安装配置

**搭建目的**

在minio机器上同时部署nfs服务，避免出现大批量文件传输、拷贝的网络IO性能问题。一些服务的文件通过io可以直接上传到该目录下，minio可直接同步访问到。同时minio的文件也可以通过挂载在其他机器上通过io访问。

**配置**

在所有需要挂载机器上下载nfs工具

```shell
#所有机器安装
yum install -y nfs-utils
```

在minio服务器进行如下的操作：

```shell
echo "/home/nfs/data/ 192.168.41.31(insecure,rw,sync,no_root_squash)  192.168.41.33(insecure,rw,sync,no_root_squash) 192.168.41.34(insecure,rw,sync,no_root_squash) 192.168.41.35(insecure,rw,sync,no_root_squash) 192.168.41.36(insecure,rw,sync,no_root_squash)" > /etc/exports
```

 上面的命令表示我们准备在**minio服务器·暴露/home/nfs/data/ 这个目录,限制了能够访问的ip地址 **

 在minio服务器创建要暴露的文件夹：

```java
mkdir -p /home/nfs/data/
```

启动rpc远程绑定同步目录服务,并且是开机自启：

```shell
systemctl enable rpcbind --now
```

下面启动nfs服务器并且使配置生效：

```shell
systemctl enable nfs-server --now
#配置生效
exportfs -r
```

 使用nfs命令检查暴露的目录：

```java
exportfs
```

**在其他服务器进行如下的操作**

使用如下命令进行检查主节点提供了哪些目录可以同步的，是一个检查命令

```shell
showmount -e 192.168.41.33
```

创建挂载目录：

```shell
#执行以下命令挂载 nfs 服务器上的共享目录到本机路径 /nfs/data
mkdir -p /home/nfs/data/
```

上面的/home/nfs/data/目录不一定也要和主节点一样,可以是/nfs/data都行

下面使用挂载命令，同步主节点的目录：

```shell
mount -t nfs 192.168.41.31:/home/nfs/data/ /home/nfs/data/
```

