# nginx-consul-template

此项目参考于 https://github.com/liberalman/nginx-consul-template
改善了Dockerfile构建逻辑，实现动态挂在服务

# 安装与启动

* 物理机环境IP：192.168.12.35
* 构建镜像：docker build -t 192.168.12.35:5000/nginx-consul-template .
* 拉取依赖的其他镜像
* 启动集群：docker-compose up -d --scale mywebapp=3
* 监控服务中心：http://192.168.12.35:8500/ui/#/dc1/services
* 测试负载：http://192.168.12.35:8180/
其中8180端口只是为了避免宿主机80端口冲突，可按你的需求修改 



# 基本原理

这里我们使用 Registrator + Consul + Consul-template + Nginx 这几个开源组件来实现可动态扩展的服务注册与发现机制，当然，毫无疑问他们都跑在docker上。

## Registrator

Registrator：一个由Go语言编写的，针对docker使用的，通过检查本机容器进程在线或者停止运行状态，去注册服务的工具。所以我们要做的实验，所有的工具都是在docker上运行的，就是因为registrator是通过检查docker容器的状态来判断服务状态的，这样就和我们的代码实现完全解耦了，对上层透明化，无感知。它有如下特点

* 通过docker socket直接监听容器event，根据容器启动/停止等event来注册/注销服务
* 每个容器的每个exposed端口对应不同的服务
* 支持可插拔的registry backend，默认支持Consul, etcd and SkyDNS
* 自身也是docker化的，可以容器方式启动
* 用户可自定义配置，如服务TTL（time-to-live）、服务名称、服务tag等

## Consul 服务注册中心

Consul 是一个分布式高可用的服务发现和配置共享的软件。由 HashiCorp 公司用 Go 语言开发。
Consul在这里用来做 docker 实例的注册与配置共享。

特点：

* 一致性协议采用 Raft 算法，比Paxos算法好用. 使用 GOSSIP 协议管理成员和广播消息, 并且支持 ACL 访问控制.
* 支持多数据中心以避免单点故障，内外网的服务采用不同的端口进行监听。而其部署则需要考虑网络延迟, 分片等情况等.zookeeper 和 etcd 均不提供多数据中心功能的支持.
* 健康检查. etcd 没有的.
* 支持 http 和 dns 协议接口. zookeeper 的集成较为复杂, etcd 只支持 http 协议.
* 还有一个web管理界面。

# Consul-template

一开始构建服务发现，大多采用的是zookeeper/etcd+confd。但是复杂难用。consul-template，大概取代了confd的位置，以后可以这样etcd+confd或者consul+consul-template。

consul template的使用场景：consul template可以查询consul中的服务目录、key、key-values等。这种强大的抽象功能和查询语言模板可以使consul template特别适合动态的创建配置文件。例如：创建apache/nginx proxy balancers、haproxy backends、varnish servers、application configurations。

consul-template提供了一个便捷的方式从consul中获取存储的值，consul-template守护进程会查询consul服务，来更新系统上指定的任何模板，当更新完成后，模板可以选择运行一些任意的命令，比如我们这里用它来更新nginx.conf这个配置文件，然后执行nginx -s reload命令，以更新路由，达到动态调节负载均衡的目的。


```
    consul-template和nginx必须装到一台机器，因为consul-template需要动态修改nginx配置文件
```

# 参考资料
https://blog.csdn.net/jek123456/article/details/78083618


# 修改内容

* consul-template.service文件中，通过环境变量获取consul server的IP，并在Dockerfile设置了consul_server_ip环境变量参数
* docker-compose.yml文件中，新增参数SERVICE_NAME变量便于注册服务
* docker-compose.yml文件中，改善expose配置，不暴露宿主机
* docker-compose-slaver.yml文件中，新增参数SERVICE_IP，便于负载机通信


