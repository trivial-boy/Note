## 三台机器公共操作

### 下载docker

```shell
# 1、卸载旧的版本
yum remove docker \
				docker-client \
				docker-client-lastest \
				docker-common \
				docker-latest \
				docker-latest-logrotate \
				docekr-engine
				
# 2、需要的安装包
yum install -y yum-utils

# 3、设置镜像仓库 （阿里云镜像）
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo 

# 更新yum软件包索引
	yum makecache fast
	
# 4、安装docker相关的内容 docker-ce 社区办 ee企业版 
	yum install -y docker-ce docker-ce-cli containerd.io

# 5、启动docker
	systemctl start docker
	
# 6、测试docker是否启动成功
	docker -version
```

### 安装Kubernetes v1.23.0

**配置安装源地址**

```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```



**安装Kubernetes的关键组件。**

```shell
yum install -y kubeadm-1.23.0  kubelet-1.23.0 kubectl-1.23.0 --disableexcludes=kubernetes
# 启动kubelet、kubeadm、kubectl服务 kubeadm将使用kubelet服务以容器的方式部署和启动Kubernetes的主要服务，所以需要先启动kubelet服务。
systemctl enable kubelet && systemctl start kubelet
```



### **设置hostname**

```shell
hostnamectl set-hostname k8s-master  # master节点的主机名
hostnamectl set-hostname k8s-node1   # node1节点的主机名
hostnamectl set-hostname k8s-node2   # node2节点的主机名

# 在三台机器上打开/etc/hosts加入
192.168.41.34 k8s-master kube-apiserver
192.168.41.35 k8s-node1
192.168.41.36 k8s-node2
```

#### 检查Kubernetes 和 docker 的驱动是否一致

这个后面容易报错，提前规避一下

查看docker驱动

```perl
docker info|grep Driver
```

​	Cgroup Driver: cgroupfs

查看kubelet驱动

```shell
systemctl show --property=Environment kubelet |cat
```

查看配置 cat /var/lib/kubelet/config.yaml 

![image-20220708212716601](http://img.trivial.top/img/image-20220708212716601.png)

如果不一样，修改docker驱动，查看/etc/docker/daemon.json文件，没有的话，手动创建，添加以下内容

```shell
{
  "registry-mirrors": ["https://ogeydad1.mirror.aliyuncs.com"], "exec-opts": ["native.cgroupdriver=systemd"]
}
```

重启docker

```shell
systemctl daemon-reload
 
systemctl restart docker
```

重启kubelet

```shell
systemctl restart kubelet
```

## Master的安装和配置

所有节点关闭Selinux、iptables、swap分区

```shell
systemctl stop firewalld
systemctl disable firewalld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
iptables -P FORWARD ACCEPT
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```

**拉取kubernetes默认配置**

```shell
kubeadm config print init-defaults > init-config.yaml
```

**打开该文件查看，发现配置的镜像仓库如下：**

```shell
imageRepository: k8s.gcr.io
```

该镜像仓库如果连不上，可以用国内的镜像代替：*imageRepository: registry.aliyuncs.com/google_containers*

打开init-config.[yaml](https://so.csdn.net/so/search?q=yaml&spm=1001.2101.3001.7020)，然后进行相应的修改，可以指定kubernetesVersion版本，pod的选址访问等。

**kubernetes镜像拉取**

```yaml
kubeadm config images pull --config=init-config.yaml
```

采用国内镜像的方案，由于coredns的标签问题，会导致拉取coredns:v1.8.4拉取失败，这时候我们可以手动拉取，并自己打标签。失败信息如下：

**解决方案：**手动拉取镜像

从docker hub上手动拉取镜像：

```shell
docker pull registry.aliyuncs.com/google_containers/coredns:1.8.4
```

修改标签：

```shell
# 重命名
docker tag registry.aliyuncs.com/google_containers/coredns:1.8.4 registry.aliyuncs.com/google_containers/coredns:v1.8.4
# 删除原有镜像
docker rmi registry.aliyuncs.com/google_containers/coredns:1.8.4
```

以下是镜像默认的标签：v1.8.4 ，而在镜像中的标签是1.8.4，所以会导致拉取失败。

![在这里插入图片描述](https://img-blog.csdnimg.cn/4d6e6e4adf93410495ee1cbaf7d1db0d.png#pic_center)

```shell
# 安装1.23.0 版本
yum install -y kubeadm-1.23.0-0  kubelet-1.23.0-0 kubectl-1.23.0-0 --disableexcludes=kubernetes
```

初始化 master 节点

```shell
kubeadm init --apiserver-advertise-address 192.168.41.34  --apiserver-bind-port=6443 --pod-network-cidr=10.244.0.0/16  --service-cidr=10.96.0.0/12 --kubernetes-version=1.23.0 --image-repository registry.aliyuncs.com/google_containers
```

>   **--apiserver-advertise-address**  自己机器的ip地址

这时候初始化可能会出现下面的bug

```shell
The HTTP call equal to ‘curl -sSL http://localhost:10248/healthz’ failed with error: Get “http://localhost:10248/healthz”: dial tcp [::1]:10248: connect: connection refused.
```

**解决方案**

大可能是docker 和 k8s 的驱动不一样 解决方案在开始已经提过。

**kubeadm init**安装失败后需要重新执行，此时要先执行**kubeadm reset**命令。

```shell
kubeadm reset

kubeadm init --apiserver-advertise-address 192.168.41.33  --apiserver-bind-port=6443 --pod-network-cidr=10.244.0.0/16  --service-cidr=10.96.0.0/12 --kubernetes-version=1.23.0 --image-repository registry.aliyuncs.com/google_containers
```

初始化完成

![image-20220708213007843](http://img.trivial.top/img/image-20220708213007843.png)

执行提示的命令

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Node 节点安装和配置

### 执行join 命令

```shell
# 该命令来自master安装成功后的最后两行信息
kubeadm join 192.168.41.34:6443 --token wza62z.ee312ga83lcnptrg \
	--discovery-token-ca-cert-hash sha256:1c9685a164324555c0b352f9944aacec4a0137c84db06a86f31b2d3f53caf4cd 
```

> 默认token有效期为24小时，当过期之后，该token就不可用了。这时就需要重新创建token，可以直接使用命令快捷生成：
>
> kubeadm token create --print-join-command

此时，在master节点上执行*kubectl get nodes*能看到该node节点表示成功，此时状态还是**NOT Ready**。

![image-20220708214822715](http://img.trivial.top/img/image-20220708214822715.png)

**安装网络插件 (在master 节点安装)**

```shell
 # 安装Calico CNI插件
  kubectl apply -f "https://docs.projectcalico.org/manifests/calico.yaml"
  # 安装weave插件
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```
