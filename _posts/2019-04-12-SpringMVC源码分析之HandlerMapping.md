---
layout: post
title: "SpringMVC源码分析之HandlerMapping"
date: 2019-04-12 14:32:48
description: "SpringMVC源码分析之HandlerMapping"
categories:
- SpringMVC
permalink: /springmvc/handlermapping
---

```vim
// HandlerMapping.java

public interface HandlerMapping {
    String PATH_WITHIN_HANDLER_MAPPING_ATTRIBUTE = HandlerMapping.class.getName() + ".pathWithinHandlerMapping";
    String BEST_MATCHING_PATTERN_ATTRIBUTE = HandlerMapping.class.getName() + ".bestMatchingPattern";
    String INTROSPECT_TYPE_LEVEL_MAPPING = HandlerMapping.class.getName() + ".introspectTypeLevelMapping";
    String URI_TEMPLATE_VARIABLES_ATTRIBUTE = HandlerMapping.class.getName() + ".uriTemplateVariables";
    String MATRIX_VARIABLES_ATTRIBUTE = HandlerMapping.class.getName() + ".matrixVariables";
    String PRODUCIBLE_MEDIA_TYPES_ATTRIBUTE = HandlerMapping.class.getName() + ".producibleMediaTypes";

    /**
     * 获得请求对应的处理器和拦截器们
     */
    @Nullable
    HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception;
}

// HandlerExecutionChain.java
public class HandlerExecutionChain {
    private static final Log logger = LogFactory.getLog(HandlerExecutionChain.class);
    private final Object handler;
    private HandlerInterceptor[] interceptors;
    private List<HandlerInterceptor> interceptorList;
    private int interceptorIndex;
    ...
}    
```
