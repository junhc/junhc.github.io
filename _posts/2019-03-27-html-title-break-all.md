---
layout: post
title: "Title属性值换行"
date: 2018-03-25 16:44:35
description: "Title属性值换行"
categories:
- Java
permalink: html-title-break-all
---

> 一个`html`标签的`title`属性规定关于元素的额外信息。这些信息通常会在鼠标移到元素上时显示一段工具提示文本（tooltip text）。  
但有时候我们的信息太长需要一行行的显示使其美观，那么就需要换行了~

###### 一种是在html标签上设置`title`属性值时，可以用`&#10;`和`&#13;`，以及直接`回车`，进行换行
```vim
<img src="代码" title="第一行&#10;第二行&#10;第三行"  />
<img src="直接回车" title="第一行
第二行
第三行"  />
```

###### 一种是动态设置`title`属性值时，可以用转义符`\n`回车，`\t`Tab，`\`换行符，进行换行

```vim
$(this).attr(title: "第一行\n第二行\n第三行");
```
