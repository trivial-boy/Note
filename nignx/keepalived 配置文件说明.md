```shell

# 全局配置
global_defs {
   # 邮件通知信息
   notification_email {
     # 定义收件人
     acassen@firewall.loc
   }
   # 定义发件人
   notification_email_from Alexandre.Cassen@firewall.loc
   # SMTP服务器地址
   smtp_server 192.168.200.1
   smtp_connect_timeout 30
   # 路由器标识，一般不用改，也可以写成每个主机自己的主机名
   router_id LVS_DEVEL
   # VRRP的ipv4和ipv6的广播地址，配置了VIP的网卡向这个地址广播来宣告自己的配置信息，下面是默认值
   vrrp_mcast_group4 224.0.0.18
   vrrp_mcast_group6 ff02::12
}

# 定义用于实例执行的脚本内容，比如可以在线降低优先级，用于强制切换
vrrp_script SCRIPT_NAME {

}

# 一个vrrp_instance就是定义一个虚拟路由器的，实例名称
vrrp_instance VI_1 {
    # 定义初始状态，可以是MASTER或者BACKUP
    state MASTER
    # 工作接口，通告选举使用哪个接口进行
    interface ens33
    # 虚拟路由ID，如果是一组虚拟路由就定义一个ID，如果是多组就要定义多个，而且这个虚拟
    # ID还是虚拟MAC最后一段地址的信息，取值范围0-255
    virtual_router_id 51
    # 使用哪个虚拟MAC地址
    use_vmac XX:XX:XX:XX:XX
    # 监控本机上的哪个网卡，网卡一旦故障则需要把VIP转移出去
    track_interface {
        eth0
        ens33
    }
    # 如果你上面定义了MASTER,这里的优先级就需要定义的比其他的高
    priority 100
    # 通告频率，单位为秒
    advert_int 1
    # 通信认证机制，这里是明文认证还有一种是加密认证
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    # 设置虚拟VIP地址，一般就设置一个，在LVS中这个就是为LVS主机设置VIP的，这样你就不用自己手动设置了
    virtual_ipaddress {
        # IP/掩码 dev 配置在哪个网卡
        192.168.200.16/24 dev eth1
        # IP/掩码 dev 配置在哪个网卡的哪个别名上
        192.168.200.17/24 dev label eth1:1
    }
    # 虚拟路由，在需要的情况下可以设置lvs主机 数据包在哪个网卡进来从哪个网卡出去
    virtual_routes {
        192.168.110.0/24 dev eth2
    }
    # 工作模式，nopreempt表示工作在非抢占模式，默认是抢占模式 preempt
    nopreempt|preempt
    # 如果是抢占默认则可以设置等多久再抢占，默认5分钟
    preempt delay 300
    # 追踪脚本，通常用于去执行上面的vrrp_script定义的脚本内容
    track_script {

    }
    # 三个指令，如果主机状态变成Master|Backup|Fault之后会去执行的通知脚本，脚本要自己写
    notify_master ""
    notify_backup ""
    notify_fault ""
}

# 定义LVS集群服务，可以是IP+PORT；也可以是fwmark 数字，也就是防火墙规则
# 所以通过这里就可以看出来keepalive天生就是为ipvs而设计的
virtual_server 10.10.10.2 1358 {
    delay_loop 6
    # 算法
    lb_algo rr|wrr|lc|wlc|lblc|sh|dh 
    # LVS的模式
    lb_kind NAT|DR|TUN
    # 子网掩码，这个掩码是VIP的掩码
    nat_mask 255.255.255.0
    # 持久连接超时时间
    persistence_timeout 50
    # 定义协议
    protocol TCP
    # 如果后端应用服务器都不可用，就会定向到那个服务器上
    sorry_server 192.168.200.200 1358

    # 后端应用服务器 IP PORT
    real_server 192.168.200.2 1358 {
        # 权重
        weight 1
        # MSIC_CHECK|SMTP_CHEKC|TCP_CHECK|SSL_GET|HTTP_GET这些都是
        # 针对应用服务器做健康检查的方法
        MISC_CHECK {}
        # 用于检查SMTP服务器的
        SMTP_CHEKC {}

        # 如果应用服务器不是WEB服务器，就用TCP_CHECK检查
        TCP_CHECK {
          # 向哪一个端口检查，如果不指定默认使用上面定义的端口
          connect_port <PORT>
          # 向哪一个IP检测，如果不指定默认使用上面定义的IP地址
          bindto <IP>
          # 连接超时时间
          connect_timeout 3
        }

        # 如果对方是HTTPS服务器就用SSL_GET方法去检查，里面配置的内容和HTTP_GET一样
        SSL_GET {}

        # 应用服务器UP或者DOWN，就执行那个脚本
        notify_up "这里写的是路径，如果脚本后有参数，整体路径+参数引起来"
        notify_down "/PATH/SCRIPTS.sh 参数"

        # 使用HTTP_GET方法去检查
        HTTP_GET {
            # 检测URL
            url { 
              # 具体检测哪一个URL
              path /testurl/test.jsp
              # 检测内容的哈希值
              digest 640205b7b0fc66c1ea91c463fac6334d
              # 除了检测哈希值还可以检测状态码，比如HTTP的200 表示正常，两种方法二选一即可
              status_code 200
            }
            url { 
              path /testurl2/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            url { 
              path /testurl3/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            # 向哪一个端口检查，如果不指定默认使用上面定义的端口
            connect_port <PORT>
            # 向哪一个IP检测，如果不指定默认使用上面定义的IP地址
            bindto <IP>
            # 连接超时时间
            connect_timeout 3
            # 尝试次数
            nb_get_retry 3
            # 每次尝试之间间隔几秒
            delay_before_retry 3
        }
    }

    real_server 192.168.200.3 1358 {
        weight 1
        HTTP_GET {
            url { 
              path /testurl/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334c
            }
            url { 
              path /testurl2/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334c
            }
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
        }
    }
}
```

