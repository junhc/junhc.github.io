---
layout: post
title: "Nginx SSL+Tomcat集群，如何获取到https协议"
date: 2018-06-12 14:32:48
description: "Nginx SSL+Tomcat集群，如何获取到https协议"
categories:
- Linux
permalink: nginx-ssl-tomcat
---

#### 服务器部署 
![](/assets/img/nginx-ssl-tomcat.png)

#### 遇到问题
浏览器访问地址如下  
`https:`//m.xxx.com/index.html  

服务端request.getRequestURL()输出结果为  
`http:`//m.xxx.com/index.html

```vim
request.getScheme()  //总是http，而不是实际的http或https  
request.isSecure()  //总是false（因为总是http）  
request.getRemoteAddr()  //总是nginx请求的IP，而不是用户的IP  
request.getRequestURL()  //总是nginx请求的URL，而不是用户实际请求的URL  
response.sendRedirect(相对url)  //总是重定向到http上（因为认为当前是http请求） 
```

#### 解决方案
Nginx配置新增 `proxy_set_header   X-Forwarded-Proto   $scheme;`
```vim
location  / {
	index   index.html;
	proxy_set_header   Host   $host;
	proxy_set_header   X-Real-IP   $remote_addr;
	proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
	proxy_set_header   X-Forwarded-Proto   $scheme;
	break;
}
```
Tomcat的server.xml配置文件中Engine模块下新增一个Valve
```vim
<Engine name="Catalina" defaultHost="localhost">
    <Valve className="org.apache.catalina.valves.RemoteIpValve" remoteIpHeader="X-Forwarded-For"  protocolHeader="X-Forwarded-Proto" protocolHeaderHttpsValue="https"/>
    ...
```
有关更多信息，请参阅
[http://tomcat.apache.org/tomcat-6.0-doc/api/org/apache/catalina/valves/RemoteIpValve.html](http://tomcat.apache.org/tomcat-6.0-doc/api/org/apache/catalina/valves/RemoteIpValve.html)
源码如下
```java
if (protocolHeader != null) {  
    String protocolHeaderValue = request.getHeader(protocolHeader);  
    if (protocolHeaderValue == null) {  
        // don't modify the secure,scheme and serverPort attributes  
        // of the request  
    } else if (protocolHeaderHttpsValue.equalsIgnoreCase(protocolHeaderValue)) {  
        request.setSecure(true);  
        // use request.coyoteRequest.scheme instead of request.setScheme() because request.setScheme() is no-op in Tomcat 6.0  
        request.getCoyoteRequest().scheme().setString("https");  
          
        request.setServerPort(httpsServerPort);  
    } else {  
        request.setSecure(false);  
        // use request.coyoteRequest.scheme instead of request.setScheme() because request.setScheme() is no-op in Tomcat 6.0  
        request.getCoyoteRequest().scheme().setString("http");  
          
        request.setServerPort(httpServerPort);  
    }  
} 
```
#### HTTP标头
HTTP 请求和 HTTP 响应使用标头字段发送有关 HTTP 消息的信息。标头字段为冒号分隔的名称值对，各个值对之间由回车符 (CR) 和换行符 (LF) 进行分隔。RFC 2616 信息标头中定义了标准 HTTP 标头字段集。此外还有应用程序广泛使用的非标准 HTTP 标头。某些非标准 HTTP 标头具有 X-Forwarded 前缀。传统负载均衡器 支持以下 X-Forwarded 标头。

先决条件
确认您的侦听器设置支持 X-Forwarded 标头。
配置您的 Web 服务器以记录客户端 IP 地址。

##### X-Forwarded 标头
- X-Forwarded-For
- X-Forwarded-Proto
- X-Forwarded-Port

##### X-Forwarded-For
在您使用 HTTP 或 HTTPS 负载均衡器时，X-Forwarded-For 请求标头可帮助您识别客户端的 IP 地址。因为负载均衡器会拦截客户端和服务器之间的流量，因此您的服务器访问日志中将仅含有负载均衡器的 IP 地址。如需查看客户端的 IP 地址，使用 X-Forwarded-For 请求标题。Elastic Load Balancing 会在 X-Forwarded-For 请求标头中存储客户端的 IP 地址，并将标头传递到您的服务器。

X-Forwarded-For 请求标题将采用以下形式：  
`X-Forwarded-For: client-ip-address`    

下面是 IP 地址为 203.0.113.7 的客户端的 X-Forwarded-For 请求标头的示例。  
`X-Forwarded-For: 203.0.113.7`  

下面是 IPv6 地址为 2001:DB8::21f:5bff:febf:ce22:8a2e 的客户端的 X-Forwarded-For 请求标头的示例。  
`X-Forwarded-For: 2001:DB8::21f:5bff:febf:ce22:8a2e`  

如果来自客户端的请求已包含 X-Forwarded-For 标头，则 Elastic Load Balancing 会将客户端的 IP 地址附加到标头值的末尾。在这种情况下，列表中的最后一个 IP 地址是客户端的 IP 地址。  
例如，以下标头包含由客户端添加的可能不可信的两个 IP 地址，以及由 Elastic Load Balancing 添加的客户端 IP 地址：  
`X-Forwarded-For: ip-address-1, ip-address-2, client-ip-address`

##### X-Forwarded-Proto
X-Forwarded-Proto 请求标头可帮助您识别客户端与您的负载均衡器连接时所用的协议 (HTTP 或 HTTPS)。您的服务器访问日志仅包含在服务器和负载均衡器之间使用的协议；不含任何关于在客户端和负载均衡器之间使用的协议之信息。如需判断在客户端和负载均衡器之间使用的协议，使用 X-Forwarded-Proto 请求标题。Elastic Load Balancing 会在 X-Forwarded-Proto 请求标题中存储客户端和负载均衡器之间使用的协议，并随后将标题传递到您的服务器。
您的应用程序或网站可以使用存储在 X-Forwarded-Proto 请求标题中的协议来表现重新导向至适用 URL 的响应。

X-Forwarded-Proto 请求标题将采用以下形式：  
`X-Forwarded-Proto: originatingProtocol`  

下例中包含的 X-Forwarded-Proto 请求标题源自作为 HTTPS 请求生成自客户端的请求：  
`X-Forwarded-Proto: https`

##### X-Forwarded-Port
X-Forwarded-Port 请求标头可帮助您识别客户端与您的负载均衡器连接时所用的端口。
