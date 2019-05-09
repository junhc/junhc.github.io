---
layout: post
title: "基于Spring可扩展Schema提供自定义配置支持"
date: 2018-10-09 16:47:54
description: "基于Spring可扩展Schema提供自定义配置支持"
categories:
- spring
permalink: 基于Spring可扩展Schema提供自定义配置支持
---

Spring提供了可扩展Schema的支持，完成一个自定义配置一般需要以下步骤：  

* 一、定义JavaBean配置属性
* 二、编写XSD文件
* 三、编写NamespaceHandler和BeanDefinitionParser完成解析工作
* 四、编写spring.handlers和spring.schemas串联起所有部件
* 五、在XML文件中应用自定义Schema

##### 一、定义JavaBean配置属性

```vim
public class OccPropertyPlaceholderConfigurer {
  private String pool;
  private Integer type;
  ...
}
```

##### 二、编写XSD文件

为上一步设计好的配置项编写XSD文件，XSD是schema的定义文件，配置的输入和解析输出都是以XSD为契约，如下：  

```vim
// occ-client.xsd
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns="http://xxx.xxx.xxx/schema/occ-client"
            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
            targetNamespace="http://xxx.xxx.xxx/schema/occ-client"
            elementFormDefault="qualified"
            attributeFormDefault="unqualified">
    <xsd:import namespace="http://www.springframework.org/schema/beans"/>

    <xsd:element name="configure">
        <xsd:complexType mixed="true">
            <xsd:attribute name="id" type="xsd:string"></xsd:attribute>
            <xsd:attribute name="pool" type="xsd:string"></xsd:attribute>
            <xsd:attribute name="type" type="xsd:integer"></xsd:attribute>
        </xsd:complexType>
    </xsd:element>


</xsd:schema>
```

**关于`xsd:schema`的各个属性具体含义就不作过多解释，可以参见[Schema 教程](http://www.w3school.com.cn/schema/schema_schema.asp)**  

**`<xsd:element name="configure">`对应着配置项节点的名称，因此在应用中会用`configure`作为节点名来引用这个配置**

**`<xsd:attribute name="pool" type="xsd:string" />`和`<xsd:attribute name="type" type="xsd:integer" />`对应着配置项`configure`的两个属性名，因此在应用中可以配置pool和type两个属性，分别是String和Integer类型**  

**完成后需把xsd存放在classpath下，一般都放在`META-INF`目录下**

##### 三、编写NamespaceHandler和BeanDefinitionParser完成解析工作

具体说来`NamespaceHandler`会根据schema和节点名找到某个`BeanDefinitionParser`，然后由`BeanDefinitionParser`完成具体的解析工作。  
因此需要分别完成`NamespaceHandler`和`BeanDefinitionParser`的实现类，Spring提供了默认实现类`NamespaceHandlerSupport`和`AbstractSingleBeanDefinitionParser`，简单的方式就是去继承这两个类。

```vim
import org.springframework.beans.factory.xml.NamespaceHandlerSupport;

public class OccHandler extends NamespaceHandlerSupport {
    public OccHandler() {
    }

    public void init() {
        this.registerBeanDefinitionParser("configure", new OccDefinitionParser());
    }
}
```

其中`registerBeanDefinitionParser("configure", new OccDefinitionParser())`;  
就是用来把节点名和解析类联系起来，在配置中引用`configure`配置项时，就会用`OccDefinitionParser`来解析配置。

```vim
import org.springframework.beans.factory.support.BeanDefinitionBuilder;
import org.springframework.beans.factory.xml.AbstractSingleBeanDefinitionParser;
import org.springframework.util.StringUtils;
import org.w3c.dom.Element;

public class OccDefinitionParser extends AbstractSingleBeanDefinitionParser {
    public OccDefinitionParser() {
    }

    protected Class<OccPropertyPlaceholderConfigurer> getBeanClass(Element element) {
        return OccPropertyPlaceholderConfigurer.class;
    }

    protected void doParse(Element element, BeanDefinitionBuilder bean) {
        String pool = element.getAttribute("pool");
        if (StringUtils.hasText(pool)) {
            bean.addPropertyValue("pool", pool);
        }

        String type = element.getAttribute("type");
        if (StringUtils.hasText(searchType)) {
            bean.addPropertyValue("type", Integer.valueOf(type));
        }
    }
    ...
```

其中`element.getAttribute`就是获取配置中的属性值，`bean.addPropertyValue`就是把属性值设置到bean中。  

##### 四、编写spring.handlers和spring.schemas串联起所有部件

上面几个步骤走下来会发现开发好的`handler`与`xsd`还没法让应用感知到，就这样放上去是没法把前面做的工作纳入体系中的，Spring提供了`spring.handlers`和`spring.schemas`这两个配置文件来完成这项工作，这两个文件需要我们自己编写并放入`META-INF`文件夹中，这两个文件的地址必须是`META-INF/spring.handlers`和`META-INF/spring.schemas`，Spring会默认加载它们。

```vim
// spring.handlers
http\://xxx.xxx.xxx/schema/occ-client=xxx.xxx.xxx.OccHandler

// spring.schemas
http\://xxx.xxx.xxx/schema/occ-client.xsd=META-INF/occ-client.xsd
```

##### 五、在XML文件中应用自定义Schema

```vim
<?xml version="1.0" encoding="UTF-8"?>  
<beans xmlns="http://www.springframework.org/schema/beans"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"   
    xmlns:occ-client="http://xxx.xxx.xxx/schema/occ-client"  
    xsi:schemaLocation="http://www.springframework.org/schema/beans
http://www.springframework.org/schema/beans/spring-beans-2.5.xsd  
http://xxx.xxx.xxx/schema/occ-client.xsd">  
    <occ-client:configure id="occConfigurer" pool="trade"/>
</beans>
```

其中`xmlns:occ-client`用来指定自定义schema，`xsi:schemaLocation`用来指定xsd文件。
