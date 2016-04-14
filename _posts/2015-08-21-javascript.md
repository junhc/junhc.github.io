---
layout: post
title: "JavaScript"
date: 2015-08-21 16:40:12
description: "JavaScript"
categories:
- JavaScript
permalink: javascript
---

### 目录
* [caller](#caller)
* [callee](#callee)
* [apply&call](#applycall)
* [prototype](#prototype)
* [终极弹窗解决方案，人类再也无法阻止弹窗了](#windowOpen)

#### caller
属性：`caller`  
说明：`func.caller` 返回一个*调用方函数*的引用

```vim
function func(){
  if(func.caller){
     console.log(func.caller.arguments);
  }else{
     console.log("没有函数调用我！");
  }
}

function handle(){
  func();
}

func();
handle("K.K");
//没有函数调用我！
//["K.K"]
```
#### callee
属性：`callee`  
说明：`arguments.callee` 返回正被执行的*函数*对象，callee是arguments的一个属性成员，  
它表示对函数对象本身的引用

```JavaScript
function func(arg0,arg1){
  console.log(arguments.callee.toString());
  console.log("实参长度："+arguments.length);
  console.log("形参长度："+arguments.callee.length);
}

func();
//function func(arg0,arg1){
//  console.log(arguments.callee.toString());
//  console.log("实参长度："+arguments.length);
//  console.log("形参长度："+arguments.callee.length);
//}
//实参长度：0
//形参长度：2
```
#### apply&call
函数：`apply`，`call`  
说明：使用`apply(this,arguments)`，`call(this,arg0,arg1,...)`在Sub函数的作用域中调用Super函数，因此调用后Sub函数就拥有了Super函数的所有属性和方法。 

```vim
function Super(){
  console.log("执行Super");
  console.log(arguments);
  this.name="我是Super";
  this.message=function(content){
    console.log(content);
  };
}

function Sub(){
  console.log("执行Sub");
  //调用Super，Super构造函数中的this会指向Sub
  Super.apply(this,arguments);
  console.log(this.name);
}

Sub("K.K");
//执行Sub
//执行Super
//["K.K"]
//我是Super

var value="global 变量";

function local(){
   this.value="local 变量";
}

function func(){
   console.log(this.value);
}

func();
func.apply(window); 
func.apply(new local());
//global 变量
//global 变量
//local 变量
```

#### prototype 
说明：每个函数都有一个prototype属性，这个属性是一个对象，它的用途是包含可以由特定类型的所有实例共享的属性和方法。  

### 终极弹窗解决方案，人类再也无法阻止弹窗了  
```vim  
// 跳转
function redirect(url) {
	var form = $("<form method='get' target='_blank' style='display:none;'></form>");
	form.attr({
		"action": url
	});

	if (url.indexOf("?") > -1) {
		var queryString = {};
		url.replace(/(\w+)=(\w+)/ig, function($0, $1, $2) {
			queryString[$1] = $2;
		});
		for (name in queryString) {
			var input = $("<input type='hidden'>");
			input.attr({
				"name": name
			});
			input.val(queryString[name]);
			form.append(input);
		};
	}

	form.append($("<input type='submit'/>"));
	$("body").append(form);
	form.submit();
}

// 下载
function download() {
	var iframe = document.getElementById('iframe_download_file');
	if (!iframe) {
		iframe = document.createElement("iframe");
		iframe.id = 'iframe_download_file';
		iframe.style.display = "none";
		document.body.appendChild(iframe);
	}
	iframe.src = url;
}
```
