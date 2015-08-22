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

#### caller
属性：`caller`  
说明：`func.caller` 返回一个*调用方函数*的引用

```JavaScript
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
说明：`apply(this,arguments)`，`call(this,arg0,arg1,...)` 能够扩充函数赖以运行的作用域

```JavaScript
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
