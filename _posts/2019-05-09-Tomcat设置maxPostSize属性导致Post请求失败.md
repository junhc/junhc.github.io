---
layout: post
title: "Tomcat设置maxPostSize导致Post请求失败"
date: 2019-05-09 16:47:54
description: "Tomcat设置maxPostSize导致Post请求失败"
categories:
- tomcat
permalink: Tomcat设置maxPostSize导致Post请求失败
---

当服务器是Tomcat时，通过POST上传的文件大小的最大值为2M（2097152）  

如果想修改该限制，修改方法如下：  

```vim
// Tomcat目录下的conf文件夹下，server.xml 文件中以下的位置中添加maxPostSize参数
<Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443"
               URIEncoding="UTF-8"
               maxPostSize="0"/>
```

`Tomcat 7.0.63`之前，当maxPostSize`<=`0时，POST方式上传的文件大小不会被限制。  

`Tomcat 7.0.63`之后，当maxPostSize`<`0时，POST方式上传的文件大小不会被限制。  

**注意：maxPostSize参数只有当request的Content-Type为“application/x-www-form-urlencoded”时起作用。**
