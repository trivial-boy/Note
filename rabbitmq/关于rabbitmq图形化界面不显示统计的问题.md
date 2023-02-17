## 关于rabbitmq图形化界面不显示统计的问题

### 问题：

用docker开启一个rabbitmq后，发现其图形化界面不显示统计信息，无法打开channel，显示：Stats in management UI are disabled on this node

### 解决办法

```shell
#进入rabbitmq容器
docker exec -it {rabbitmq容器名称或者id} /bin/bash

#进入容器后，cd到以下路径
cd /etc/rabbitmq/conf.d/

#修改 management_agent.disable_metrics_collector = false
echo management_agent.disable_metrics_collector = false > management_agent.disable_metrics_collector.conf

#退出容器
exit

#重启rabbitmq容器
docker retart {rabbitmq容器id}

```

