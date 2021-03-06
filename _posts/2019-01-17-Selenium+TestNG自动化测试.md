---
layout: post
title: "Selenium+TestNG自动化测试"
date: 2019-01-17 15:29:37
description: "Selenium+TestNG自动化测试"
categories:
- Selenium
permalink: selenium
---

##### 目录
- [下载浏览器驱动](下载浏览器驱动)
- [`pom.xml`相关依赖](`pom.xml`相关依赖)
- [`web.xml`相关配置](`web.xml`相关配置)
- [代码示例](代码示例)
- [`TestNG`常用注解](`TestNG`常用注解)
- [可能遇到的问题](可能遇到的问题)


##### 下载浏览器驱动

> http://chromedriver.storage.googleapis.com/index.html


##### `pom.xml`相关依赖

```vim
<!-- 自动化测试 -->
<dependency>
	<groupId>org.seleniumhq.selenium</groupId>
	<artifactId>selenium-java</artifactId>
	<version>3.141.59</version>
</dependency>
<dependency>
	<groupId>org.testng</groupId>
	<artifactId>testng</artifactId>
	<version>6.14.3</version>
	<scope>test</scope>
</dependency>
<dependency>
	<groupId>org.uncommons</groupId>
	<artifactId>reportng</artifactId>
	<version>1.1.4</version>
	<scope>test</scope>
</dependency>
<dependency>
	<groupId>com.google.inject</groupId>
	<artifactId>guice</artifactId>
	<version>4.1.0</version>
	<scope>test</scope>
</dependency>
```


##### `web.xml`相关配置

```vim
<build>
	<plugins>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-compiler-plugin</artifactId>
			<version>3.1</version>
			<configuration>
				<source>1.8</source>
				<target>1.8</target>
				<encoding>UTF-8</encoding>
			</configuration>
		</plugin>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-surefire-plugin</artifactId>
			<version>2.5</version>
			<configuration>
				<testFailureIgnore>true</testFailureIgnore>
				<suiteXmlFiles>
					<file>src/test/resources/main.xml</file>
				</suiteXmlFiles>
				<properties>
					<!--启用 ReportNG 功能-->
					<property>
						<name>usedefaultlisteners</name>
						<value>false</value>
					</property>
					<!--Setting ReportNG listener-->
					<property>
						<name>listener</name>
						<value>org.uncommons.reportng.HTMLReporter, org.uncommons.reportng.JUnitXMLReporter</value>
					</property>
				</properties>
				<workingDirectory>target/</workingDirectory>
				<forkMode>always</forkMode>
			</configuration>
		</plugin>
	</plugins>
</build>
```


##### 代码示例

```vim
...
protected String chromeDriver = "/usr/local/artifacts/selenium/chromedriver";
protected WebDriver driver;
protected WebDriverWait driverWait;
protected Actions action;

@BeforeSuite
public void init() {
   System.setProperty("webdriver.chrome.driver", chromeDriver);
}

@BeforeClass
public void before() {
    driver = new ChromeDriver();
    driverWait = new WebDriverWait(driver, 300L);
    action = new Actions(driver);
    //driver.manage().window().maximize();
    driver.get("http://www.baidu.com");
}

@AfterClass
public void after() {
  if (null != driver) {
      driver.quit();
  }
}
...
```

##### `TestNG`常用注解

|注解|描述|
|:--:|:--|
|@BeforeSuite|	在该套件的所有测试都运行在注释的方法之前，仅运行一次。|
|@AfterSuite|	在该套件的所有测试都运行在注释方法之后，仅运行一次。|
|@BeforeClass|	在调用当前类的第一个测试方法之前运行，注释方法仅运行一次。|
|@AfterClass|	在调用当前类的第一个测试方法之后运行，注释方法仅运行一次|
|@BeforeTest|	注释的方法将在属于<test>标签内的类的所有测试方法运行之前运行。|
|@AfterTest|	注释的方法将在属于<test>标签内的类的所有测试方法运行之后运行。|
|@BeforeGroups|	配置方法将在之前运行组列表。 此方法保证在调用属于这些组中的任何一个的第一个测试方法之前不久运行。|
|@AfterGroups|	此配置方法将在之后运行组列表。该方法保证在调用属于任何这些组的最后一个测试方法之后不久运行。|
|@BeforeMethod|	注释方法将在每个测试方法之前运行。|
|@AfterMethod|	注释方法将在每个测试方法之后运行。|
|@DataProvider|	标记一种方法来提供测试方法的数据。 注释方法必须返回一个Object [] []，其中每个Object []可以被分配给测试方法的参数列表。 要从该DataProvider接收数据的@Test方法需要使用与此注释名称相等的dataProvider名称。|
|@Factory|	将一个方法标记为工厂，返回TestNG将被用作测试类的对象。 该方法必须返回Object []。|
|@Listeners|	定义测试类上的侦听器。|
|@Parameters|	描述如何将参数传递给@Test方法。|
|@Test|	将类或方法标记为测试的一部分。|


##### 可能遇到的问题

> 问题一、`org.openqa.selenium.WebDriverException: unknown error: Element <button class="btn btn-info" ng-click="queryPage(1)">...</button> is not clickable at point (490, 120). Other element would receive the click: <div class="loader ng-scope" ng-if="GlobalLoadingShow">...</div>
`

```vim
..
driverWait.until(ExpectedConditions.elementToBeClickable(By.xpath("//button[contains(@ng-click,'queryPage')]")));
driver.findElement(By.xpath("//button[contains(@ng-click,'queryPage')]")).click();
// 抛出异常..
// 被loading层挡住了..

解决方法
1、使用 Thread.sleep(1000L) 暂停一段时间，再触发click事件。
2、使用 WebDriverWait 等待浮层消失
..
driverWait.until(ExpectedConditions.invisibilityOfElementLocated(By.xpath("//div[contains(@class,'loader ng-scope')]")));
```
