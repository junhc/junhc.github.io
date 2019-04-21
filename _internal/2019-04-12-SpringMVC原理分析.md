---
layout: post
title: "SpringMVC原理分析"
date: 2019-04-12 14:32:48
description: "SpringMVC原理分析"
categories:
- SpringMVC
permalink: springmvc
---

##### SpringMVC工作流程
![](/assets/img/DispatcherServlet工作流程.jpg)

![](/assets/img/DispatcherServlet.png)

##### 1. HttpServletBean
> 实现`EnvironmentCapable`、`EnvironmentAware`接口，继承`HttpServlet`抽象类，负责将`ServletConfig`设置到当前`Servlet`对象中

```vim
// HttpServletBean.java

@Override
public final void init() throws ServletException {
	// Set bean properties from init parameters.
  // <1> 解析 <init-param /> 标签，封装到 PropertyValues pvs 中
	PropertyValues pvs = new ServletConfigPropertyValues(getServletConfig(), this.requiredProperties);
	if (!pvs.isEmpty()) {
		try {
		  // <2.1> 将当前的这个 Servlet 对象，转化成一个 BeanWrapper 对象。
      // 从而能够以 Spring 的方式来将 pvs 注入到该 BeanWrapper 对象中
			BeanWrapper bw = PropertyAccessorFactory.forBeanPropertyAccess(this);
			ResourceLoader resourceLoader = new ServletContextResourceLoader(getServletContext());
			// <2.2> 注册自定义属性编辑器，一旦碰到 Resource 类型的属性，将会使用 ResourceEditor 进行解析
			bw.registerCustomEditor(Resource.class, new ResourceEditor(resourceLoader, getEnvironment()));
      // <2.3> 空实现，留给子类覆盖
			initBeanWrapper(bw);
			// <2.4> 以 Spring 的方式来将 pvs 注入到该 BeanWrapper 对象中
			bw.setPropertyValues(pvs, true);
		} catch (BeansException ex) {
			if (logger.isErrorEnabled()) {
				logger.error("Failed to set bean properties on servlet '" + getServletName() + "'", ex);
			}
			throw ex;
		}
	}

	// Let subclasses do whatever initialization they like.
  // <3> 子类来实现，实现自定义的初始化逻辑。目前，有具体的代码实现。
	initServletBean();
}
```

> `<2.4>`，以Spring的方式将`pvs`注入到`BeanWrapper`对象中，设置到当前的`Servlet`对象中。

```vim
<servlet>
    <servlet-name>spring</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <!-- 可以自定义servlet.xml配置文件的位置和名称，默认为WEB-INF目录下，名称为[<servlet-name>]-servlet.xml，如spring-servlet.xml
    <init-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>/WEB-INF/spring-servlet.xml</param-value> // 默认
    </init-param>
    -->
    <load-on-startup>1</load-on-startup>
</servlet>
<servlet-mapping>
    <servlet-name>spring</servlet-name>
    <url-pattern>*.do</url-pattern>
</servlet-mapping>
```

> 配置了 contextConfigLocation 初始化参数，那么通过`<2.4>`的逻辑，反射设置到`FrameworkServlet.contextConfigLocation`属性

```vim
// FrameworkServlet.java

/** Explicit context config location. */
@Nullable
private String contextConfigLocation;

public void setContextConfigLocation(@Nullable String contextConfigLocation) {
	this.contextConfigLocation = contextConfigLocation;
}
```

##### 2. FrameworkServlet
> 实现`ApplicationContextAware`接口，继承`HttpServletBean`抽象类，负责初始化`Servlet WebApplicationContext`容器

> `#initServletBean()`方法，进一步初始化当前`Servlet`对象。实际上，重心在初始化`Servlet WebApplicationContext`容器

```vim
// FrameworkServlet.java

@Override
protected final void initServletBean() throws ServletException {
	// 打日志
  getServletContext().log("Initializing Spring " + getClass().getSimpleName() + " '" + getServletName() + "'");
	if (logger.isInfoEnabled()) {
		logger.info("Initializing Servlet '" + getServletName() + "'");
	}

	// 记录开始时间
	long startTime = System.currentTimeMillis();

	try {
	  // 初始化 WebApplicationContext 对象
		this.webApplicationContext = initWebApplicationContext();
		// 空实现。子类有需要，可以实现该方法，实现自定义逻辑
		initFrameworkServlet();
	} catch (ServletException | RuntimeException ex) {
		logger.error("Context initialization failed", ex);
		throw ex;
	}

	// 打日志
	if (logger.isDebugEnabled()) {
		String value = this.enableLoggingRequestDetails ?
				"shown which may lead to unsafe logging of potentially sensitive data" :
				"masked to prevent unsafe logging of potentially sensitive data";
		logger.debug("enableLoggingRequestDetails='" + this.enableLoggingRequestDetails +
				"': request parameters and headers will be " + value);
	}

	// 打日志
	if (logger.isInfoEnabled()) {
		logger.info("Completed initialization in " + (System.currentTimeMillis() - startTime) + " ms");
	}
}
```

```vim
// FrameworkServlet.java

protected WebApplicationContext initWebApplicationContext() {
  // <1> 获得根 WebApplicationContext 对象
	WebApplicationContext rootContext = WebApplicationContextUtils.getWebApplicationContext(getServletContext());

	// <2> 获得 WebApplicationContext wac 变量
	WebApplicationContext wac = null;
	// 第一种情况，如果构造方法已经传入 webApplicationContext 属性，则直接使用
	if (this.webApplicationContext != null) {
		// A context instance was injected at construction time -> use it
    // 赋值给 wac 变量
		wac = this.webApplicationContext;
		// 如果是 ConfigurableWebApplicationContext 类型，并且未激活，则进行初始化
		if (wac instanceof ConfigurableWebApplicationContext) {
			ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) wac;
			if (!cwac.isActive()) { // 未激活
				// The context has not yet been refreshed -> provide services such as
				// setting the parent context, setting the application context id, etc
                // 设置 wac 的父 context 为 rootContext 对象
				if (cwac.getParent() == null) {
					// The context instance was injected without an explicit parent -> set
					// the root application context (if any; may be null) as the parent
					cwac.setParent(rootContext);
				}
				// 配置和初始化 wac
				configureAndRefreshWebApplicationContext(cwac);
			}
		}
	}
	// 第二种情况，从 ServletContext 获取对应的 WebApplicationContext 对象
	if (wac == null) {
		// No context instance was injected at construction time -> see if one
		// has been registered in the servlet context. If one exists, it is assumed
		// that the parent context (if any) has already been set and that the
		// user has performed any initialization such as setting the context id
		wac = findWebApplicationContext();
	}
	// 第三种，创建一个 WebApplicationContext 对象
	if (wac == null) {
		// No context instance is defined for this servlet -> create a local one
		wac = createWebApplicationContext(rootContext);
	}

	// <3> 如果未触发刷新事件，则主动触发刷新事件
	if (!this.refreshEventReceived) {
		// Either the context is not a ConfigurableApplicationContext with refresh
		// support or the context injected at construction time had already been
		// refreshed -> trigger initial onRefresh manually here.
		onRefresh(wac);
	}

	// <4> 将 context 设置到 ServletContext 中
	if (this.publishContext) {
		// Publish the context as a servlet context attribute.
		String attrName = getServletContextAttributeName();
		getServletContext().setAttribute(attrName, wac);
	}

	return wac;
}
```

```vim
// FrameworkServlet.java

/** ServletContext attribute to find the WebApplicationContext in. */
@Nullable
private String contextAttribute;
@Nullable
public String getContextAttribute() {
	return this.contextAttribute;
}

@Nullable
protected WebApplicationContext findWebApplicationContext() {
	String attrName = getContextAttribute();
	// 需要配置了 contextAttribute 属性下，才会去查找
  // 一般情况下不会配置 contextAttribute 属性
	if (attrName == null) {
		return null;
	}
	// 从 ServletContext 中，获得属性名对应的 WebApplicationContext 对象
	WebApplicationContext wac = WebApplicationContextUtils.getWebApplicationContext(getServletContext(), attrName);
	// 如果不存在，则抛出 IllegalStateException 异常
	if (wac == null) {
		throw new IllegalStateException("No WebApplicationContext found: initializer not registered?");
	}
	return wac;
}
```

```vim
// FrameworkServlet.java

/**
 * WebApplicationContext implementation class to create.
 *
 * 创建的 WebApplicationContext 类型
 */
private Class<?> contextClass = DEFAULT_CONTEXT_CLASS;
public Class<?> getContextClass() {
	return this.contextClass;
}

protected WebApplicationContext createWebApplicationContext(@Nullable ApplicationContext parent) {
    // <a> 获得 context 的类
	Class<?> contextClass = getContextClass();
	// 如果非 ConfigurableWebApplicationContext 类型，抛出 ApplicationContextException 异常
	if (!ConfigurableWebApplicationContext.class.isAssignableFrom(contextClass)) {
		throw new ApplicationContextException(
				"Fatal initialization error in servlet with name '" + getServletName() +
				"': custom WebApplicationContext class [" + contextClass.getName() +
				"] is not of type ConfigurableWebApplicationContext");
	}
	// <b> 创建 context 类的对象
	ConfigurableWebApplicationContext wac =
			(ConfigurableWebApplicationContext) BeanUtils.instantiateClass(contextClass);

	// <c> 设置 environment、parent、configLocation 属性
	wac.setEnvironment(getEnvironment());
	wac.setParent(parent);
	String configLocation = getContextConfigLocation();
	if (configLocation != null) {
		wac.setConfigLocation(configLocation);
	}

	// <d> 配置和初始化 wac
	configureAndRefreshWebApplicationContext(wac);

	return wac;
}
```

```vim
// FrameworkServlet.java

protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac) {
	// <1> 如果 wac 使用了默认编号，则重新设置 id 属性
    if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
		// The application context id is still set to its original default value
		// -> assign a more useful id based on available information
        // 情况一，使用 contextId 属性
		if (this.contextId != null) {
			wac.setId(this.contextId);
        // 情况二，自动生成
		} else {
			// Generate default id...
			wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
					ObjectUtils.getDisplayString(getServletContext().getContextPath()) + '/' + getServletName());
		}
	}

	// <2> 设置 wac 的 servletContext、servletConfig、namespace 属性
	wac.setServletContext(getServletContext());
	wac.setServletConfig(getServletConfig());
	wac.setNamespace(getNamespace());

	// <3> 添加监听器 SourceFilteringListener 到 wac 中
	wac.addApplicationListener(new SourceFilteringListener(wac, new ContextRefreshListener()));

	// <4>
	// The wac environment's #initPropertySources will be called in any case when the context
	// is refreshed; do it eagerly here to ensure servlet property sources are in place for
	// use in any post-processing or initialization that occurs below prior to #refresh
	ConfigurableEnvironment env = wac.getEnvironment();
	if (env instanceof ConfigurableWebEnvironment) {
		((ConfigurableWebEnvironment) env).initPropertySources(getServletContext(), getServletConfig());
	}

	// <5> 执行处理完 WebApplicationContext 后的逻辑。目前是个空方法，暂无任何实现
	postProcessWebApplicationContext(wac);

	// <6> 执行自定义初始化 context
	applyInitializers(wac);

	// <7> 刷新 wac ，从而初始化 wac
	wac.refresh();
}
```

> #onRefresh(ApplicationContext context) 方法，当 Servlet WebApplicationContext 刷新完成后，触发 Spring MVC 组件的初始化

```vim
// DispatcherServlet.java

/**
 * This implementation calls {@link #initStrategies}.
 */
@Override
protected void onRefresh(ApplicationContext context) {
	initStrategies(context);
}

/**
 * Initialize the strategy objects that this servlet uses.
 * <p>May be overridden in subclasses in order to initialize further strategy objects.
 */
protected void initStrategies(ApplicationContext context) {
    // 初始化 MultipartResolver
	initMultipartResolver(context);
	// 初始化 LocaleResolver
	initLocaleResolver(context);
	// 初始化 ThemeResolver
	initThemeResolver(context);
	// 初始化 HandlerMappings
	initHandlerMappings(context);
	// 初始化 HandlerAdapters
	initHandlerAdapters(context);
	// 初始化 HandlerExceptionResolvers
	initHandlerExceptionResolvers(context);
	// 初始化 RequestToViewNameTranslator
	initRequestToViewNameTranslator(context);
	// 初始化 ViewResolvers
	initViewResolvers(context);
	// 初始化 FlashMapManager
	initFlashMapManager(context);
}
```

##### 3. SourceFilteringListener
> 实现`GenericApplicationListener`、`SmartApplicationListener`监听器，实现将原始对象触发的事件，转发给指定监听器

```vim
// SourceFilteringListener.java

public class SourceFilteringListener implements GenericApplicationListener, SmartApplicationListener {

    /**
     * 原始类
     */
	private final Object source;
    /**
     * 代理的监听器
     */
	@Nullable
	private GenericApplicationListener delegate;

	/**
	 * Create a SourceFilteringListener for the given event source.
	 * @param source the event source that this listener filters for,
	 * only processing events from this source
	 * @param delegate the delegate listener to invoke with event
	 * from the specified source
	 */
	public SourceFilteringListener(Object source, ApplicationListener<?> delegate) {
		this.source = source;
		this.delegate = (delegate instanceof GenericApplicationListener ?
				(GenericApplicationListener) delegate : new GenericApplicationListenerAdapter(delegate));
	}

	/**
	 * Create a SourceFilteringListener for the given event source,
	 * expecting subclasses to override the {@link #onApplicationEventInternal}
	 * method (instead of specifying a delegate listener).
	 * @param source the event source that this listener filters for,
	 * only processing events from this source
	 */
	protected SourceFilteringListener(Object source) {
		this.source = source;
	}


	@Override
	public void onApplicationEvent(ApplicationEvent event) {
		if (event.getSource() == this.source) { // 判断来源
			onApplicationEventInternal(event);
		}
	}

	@Override
	public boolean supportsEventType(ResolvableType eventType) {
		return (this.delegate == null || this.delegate.supportsEventType(eventType));
	}

	@Override
	public boolean supportsEventType(Class<? extends ApplicationEvent> eventType) {
		return supportsEventType(ResolvableType.forType(eventType));
	}

	@Override
	public boolean supportsSourceType(@Nullable Class<?> sourceType) {
		return (sourceType != null && sourceType.isInstance(this.source));
	}

	@Override
	public int getOrder() {
		return (this.delegate != null ? this.delegate.getOrder() : Ordered.LOWEST_PRECEDENCE);
	}


	/**
	 * Actually process the event, after having filtered according to the
	 * desired event source already.
	 * <p>The default implementation invokes the specified delegate, if any.
	 * @param event the event to process (matching the specified source)
	 */
	protected void onApplicationEventInternal(ApplicationEvent event) {
		if (this.delegate == null) {
			throw new IllegalStateException(
					"Must specify a delegate object or override the onApplicationEventInternal method");
		}
		this.delegate.onApplicationEvent(event);
	}

}
```

##### 4. DispatcherServlet

```vim
// DispatcherServlet.java

@Override
protected void doService(HttpServletRequest request, HttpServletResponse response) throws Exception {
	// <1> 打印请求日志，并且日志级别为 DEBUG
    logRequest(request);

	// Keep a snapshot of the request attributes in case of an include,
	// to be able to restore the original attributes after the include.
	// <2>
	Map<String, Object> attributesSnapshot = null;
	if (WebUtils.isIncludeRequest(request)) {
		attributesSnapshot = new HashMap<>();
		Enumeration<?> attrNames = request.getAttributeNames();
		while (attrNames.hasMoreElements()) {
			String attrName = (String) attrNames.nextElement();
			if (this.cleanupAfterInclude || attrName.startsWith(DEFAULT_STRATEGIES_PREFIX)) {
				attributesSnapshot.put(attrName, request.getAttribute(attrName));
			}
		}
	}

	// Make framework objects available to handlers and view objects.
	// <3> 设置 Spring 框架中的常用对象到 request 属性中
	request.setAttribute(WEB_APPLICATION_CONTEXT_ATTRIBUTE, getWebApplicationContext());
	request.setAttribute(LOCALE_RESOLVER_ATTRIBUTE, this.localeResolver);
	request.setAttribute(THEME_RESOLVER_ATTRIBUTE, this.themeResolver);
	request.setAttribute(THEME_SOURCE_ATTRIBUTE, getThemeSource());

	// <4>
	if (this.flashMapManager != null) {
		FlashMap inputFlashMap = this.flashMapManager.retrieveAndUpdate(request, response);
		if (inputFlashMap != null) {
			request.setAttribute(INPUT_FLASH_MAP_ATTRIBUTE, Collections.unmodifiableMap(inputFlashMap));
		}
		request.setAttribute(OUTPUT_FLASH_MAP_ATTRIBUTE, new FlashMap());
		request.setAttribute(FLASH_MAP_MANAGER_ATTRIBUTE, this.flashMapManager);
	}

	try {
		// <5> 执行请求的分发
		doDispatch(request, response);
	} finally {
		// <6>
		if (!WebAsyncUtils.getAsyncManager(request).isConcurrentHandlingStarted()) {
			// Restore the original attribute snapshot, in case of an include.
			if (attributesSnapshot != null) {
				restoreAttributesAfterInclude(request, attributesSnapshot);
			}
		}
	}
}

protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
	HttpServletRequest processedRequest = request;
	HandlerExecutionChain mappedHandler = null;
	boolean multipartRequestParsed = false;

	// <1>
	WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);

	try {
		ModelAndView mv = null;
		Exception dispatchException = null;

		try {
			// <2>
			processedRequest = checkMultipart(request);
			multipartRequestParsed = (processedRequest != request);

			// Determine handler for the current request.
			// <3> 获得请求对应的 HandlerExecutionChain 对象
			mappedHandler = getHandler(processedRequest);
			if (mappedHandler == null) { // <3.1> 如果获取不到，则根据配置抛出异常或返回 404 错误
				noHandlerFound(processedRequest, response);
				return;
			}

			// Determine handler adapter for the current request.
			// <4> 获得当前 handler 对应的 HandlerAdapter 对象
			HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());

			// Process last-modified header, if supported by the handler.
			// <4.1>
			String method = request.getMethod();
			boolean isGet = "GET".equals(method);
			if (isGet || "HEAD".equals(method)) {
				long lastModified = ha.getLastModified(request, mappedHandler.getHandler());
				if (new ServletWebRequest(request, response).checkNotModified(lastModified) && isGet) {
					return;
				}
			}

			// <5> 前置处理 拦截器
			if (!mappedHandler.applyPreHandle(processedRequest, response)) {
				return;
			}

			// Actually invoke the handler.
			// <6> 真正的调用 handler 方法，并返回视图
			mv = ha.handle(processedRequest, response, mappedHandler.getHandler());

			// <7>
			if (asyncManager.isConcurrentHandlingStarted()) {
				return;
			}

			// <8> 视图
			applyDefaultViewName(processedRequest, mv);
			// <9> 后置处理 拦截器
			mappedHandler.applyPostHandle(processedRequest, response, mv);
		} catch (Exception ex) {
			dispatchException = ex; // <10> 记录异常
		} catch (Throwable err) {
			// As of 4.3, we're processing Errors thrown from handler methods as well,
			// making them available for @ExceptionHandler methods and other scenarios.
			dispatchException = new NestedServletException("Handler dispatch failed", err); // <10> 记录异常
		}

		// <11> 处理正常和异常的请求调用结果。
		processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
	} catch (Exception ex) {
		// <12> 已完成 拦截器
		triggerAfterCompletion(processedRequest, response, mappedHandler, ex);
	} catch (Throwable err) {
		// <12> 已完成 拦截器
		triggerAfterCompletion(processedRequest, response, mappedHandler,
				new NestedServletException("Handler processing failed", err));
	} finally {
		// <13.1>
		if (asyncManager.isConcurrentHandlingStarted()) {
			// Instead of postHandle and afterCompletion
			if (mappedHandler != null) {
				mappedHandler.applyAfterConcurrentHandlingStarted(processedRequest, response);
			}
		} else {
			// <13.2> Clean up any resources used by a multipart request.
			if (multipartRequestParsed) {
				cleanupMultipart(processedRequest);
			}
		}
	}
}
```
