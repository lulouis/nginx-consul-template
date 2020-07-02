FROM alpine:latest
MAINTAINER lulouis

ENV consul_server_ip consul
ENV app_name my-web-server
# install nginx runit curl
RUN apk --update --no-cache add nginx curl runit

#ENV CT_URL http://releases.hashicorp.com/consul-template/0.19.0/consul-template_0.19.0_linux_amd64.tgz
#RUN curl -L $CT_URL | tar -C /usr/local/bin/ --strip-components 1 -zxf -
ADD consul-template_0.19.0_linux_amd64.tgz /usr/local/bin/

ADD nginx.service /etc/service/nginx/run
RUN chmod a+x /etc/service/nginx/run
ADD consul-template.service /etc/service/consul-template/run
RUN chmod a+x /etc/service/consul-template/run

RUN rm -v /etc/nginx/conf.d/*
RUN mkdir -p /run/nginx/
ADD nginx.conf.ctmpl /etc/consul-templates/nginx.conf.ctmpl

# CMD ["runsvdir", "/etc/service"]
CMD /usr/sbin/nginx -c /etc/nginx/nginx.conf && consul-template -consul-addr=$(echo $consul_server_ip):8500 -template "/etc/consul-templates/nginx.conf.ctmpl:/etc/nginx/conf.d/app.conf:nginx -s reload"

# 镜像制作语句
# docker build -t 192.168.12.35:5000/nginx-consul-template .
# docker push 192.168.12.35:5000/nginx-consul-template:latest
# docker pull 192.168.12.35:5000/nginx-consul-template:latest
# docker images|grep none|awk '{print $3 }'|xargs docker rmi --force