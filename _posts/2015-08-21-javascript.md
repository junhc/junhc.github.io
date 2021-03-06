---
layout: post
title: "JavaScript"
date: 2015-08-21 16:40:12
description: "JavaScript"
categories:
- JavaScript
permalink: javascript
---

#### 目录
* [1. caller](#1-caller)
* [2. callee](#2-callee)
* [3. apply&call](#3-applycall)
* [4. prototype](#4-prototype)
* [5. 终极弹窗解决方案](#5-终极弹窗解决方案)
* [6. boolean](#6-boolean)
* [7. 封装请求参数](#7-封装请求参数)
* [8. 一道ECMAScript6有趣的面试题](#8-一道ecmascript6有趣的面试题)

##### 1. caller
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
##### 2. callee
属性：`callee`  
说明：`arguments.callee` 返回正被执行的*函数*对象，callee是arguments的一个属性成员，  
它表示对函数对象本身的引用

```vim
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
##### 3. apply&call
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

##### 4. prototype
说明：每个函数都有一个prototype属性，这个属性是一个对象，它的用途是包含可以由特定类型的所有实例共享的属性和方法。  

##### 5. 终极弹窗解决方案
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

##### 6. boolean  
说明：如果逻辑对象无初始值或者其值为 0、-0、null、""、false、undefined 或者 NaN，那么对象的值为 false。否则，其值为 true（即使当自变量为字符串 "false" 时）  

```vim
//返回false
var isFalse = new Boolean();
var isFalse = new Boolean(0);
var isFalse = new Boolean(false);
var isFalse = new Boolean(null);
var isFalse = new Boolean("");
var isFalse = new Boolean(NaN);
//返回true
var isTrue = new Boolean(1);
var isTrue = new Boolean(true);
var isTrue = new Boolean("true");
var isTrue = new Boolean("false");
var isTrue = new Boolean("K.K");
```

##### 7. 封装请求参数  
```vim
;
(function($) {
    $.extend({
        queryString: function(name) {
            function toMap() {
                var p = {},
                    e,
                    a = /\+/g, // Regex for replacing addition symbol with a space
                    r = /([^&=]+)=?([^&]*)/g,
                    d = function(s) {
                        return decodeURIComponent(s.replace(a, " "));
                    },
                    q = window.location.search.substring(1);
                // exec() 方法的功能非常强大
                while ((e = r.exec(q))!=null) {
                    p[d(e[1])] = d(e[2]);
                }
                return p;
            }
            if (!this._queryString) {
                this._queryString = toMap();
            }
            return this._queryString[name];
        }
    });
})(jQuery);
```

##### 8. 一道ECMAScript6有趣的面试题
```vim
const x = ?;
if (('a' in x) && !('a' in x)) {
	console.log('WIN');
}
// 输出WIN
```

```vim
// 使用ES6代理对象..重写has方法..
const x = new Proxy({
   'a': false
}, {
   has(target) {
      return target.a = !target.a;
   }
});

// 另辟蹊径, 两个a的语义不一样..半角英文a和全角英文a..咳咳, 只谈思路的话, 很有想法..
```
