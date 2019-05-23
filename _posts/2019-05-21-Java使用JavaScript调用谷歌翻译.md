---
layout: post
title: "Java使用JavaScript调用谷歌翻译"
date: 2019-05-21 17:19:19
description: "Java使用JavaScript调用谷歌翻译"
categories:
- Java
- JavaScript
permalink: Java使用JavaScript调用谷歌翻译
---

```vim
private static final String tkk =
        "function vq(a,uq) {"
        + "    if (null !== uq)"
        + "        var b = uq;"
        + "    else {"
        + "        b = sq('T');"
        + "        var c = sq('K');"
        + "        b = [b(), c()];"
        + "        b = (uq = window[b.join(c())] || \"\") || \"\""
        + "    }"
        + "    var d = sq('t');"
        + "    c = sq('k');"
        + "    d = [d(), c()];"
        + "    c = \"&\" + d.join(\"\") + \"=\";"
        + "    d = b.split(\".\");"
        + "    b = Number(d[0]) || 0;"
        + "    for (var e = [], f = 0, g = 0; g < a.length; g++) {"
        + "        var l = a.charCodeAt(g);"
        + "        128 > l ? e[f++] = l : (2048 > l ? e[f++] = l >> 6 | 192 : (55296 == (l & 64512) && g + 1 < a.length && 56320 == (a.charCodeAt(g + 1) & 64512) ? (l = 65536 + ((l & 1023) << 10) + (a.charCodeAt(++g) & 1023),"
        + "        e[f++] = l >> 18 | 240,"
        + "        e[f++] = l >> 12 & 63 | 128) : e[f++] = l >> 12 | 224,"
        + "        e[f++] = l >> 6 & 63 | 128),"
        + "        e[f++] = l & 63 | 128)"
        + "    }"
        + "    a = b;"
        + "    for (f = 0; f < e.length; f++)"
        + "        a += e[f],"
        + "        a = tq(a, \"+-a^+6\");"
        + "    a = tq(a, \"+-3^+b+-f\");"
        + "    a ^= Number(d[1]) || 0;"
        + "    0 > a && (a = (a & 2147483647) + 2147483648);"
        + "    a %= 1000000;"
        + "    return c + (a.toString() + \".\" + (a ^ b))"
        + "};"
        + "function sq(a) {"
        + "    return function() {"
        + "        return a"
        + "    }"
        + "};"
        + "function tq(a, b) {"
        + "    for (var c = 0; c < b.length - 2; c += 3) {"
        + "        var d = b.charAt(c + 2);"
        + "        d = \"a\" <= d ? d.charCodeAt(0) - 87 : Number(d);"
        + "        d = \"+\" == b.charAt(c + 1) ? a >>> d : a << d;"
        + "        a = \"+\" == b.charAt(c) ? a + d & 4294967295 : a ^ d"
        + "    }"
        + "    return a"
        + "};";

public static String call(String script, String name, Object... args) {
    try {
        // 创建计算引擎
        ScriptEngineManager manager = new ScriptEngineManager();
        ScriptEngine engine = manager.getEngineByName("JavaScript");
        // Java 8 新特性
        // Nashorn完全支持ECMAScript 5.1规范以及一些扩展
        // ScriptEngine engine = manager.getEngineByName("Nashorn");
        // JS代码构建器
        // 解析动态脚本语言
        engine.eval(script);
        // 传入参数进行计算
        return (String) ((Invocable) engine).invokeFunction(name, args);
    } catch (Exception e) {
        System.out.println(e.getMessage());
    }
    return null;
}

public static void main(String[] args) {
    String q = "我要找到你";
    JSONArray o = JSON.parseArray(translate(q));
    System.out.println(o.toJSONString());
    // [[["I want to find you.","我要找到你",null,null,3],[null,null,null,"Wǒ yào zhǎodào nǐ"]],null,"zh-CN",null,null,[["我要找到你",null,[["I want to find you.",0,true,false],["I need to find you",0,true,false]],[[0,5]],"我要找到你",0,0]],1,null,[["zh-CN"],null,[1],["zh-CN"]]]
}

private static String translate(String q) {
    String url = "http://translate.google.cn/translate_a/single?client=webapp&sl=zh-CN&tl=en&hl=zh-CN&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&source=bh&ssel=0&tsel=0&kc=1&q=";
    url += URLEncoder.encode(q);
    url += JavaScript.call(tkk, "vq", q, "429726.3605868026");
    return WebHttp.doGet(url);
}
```

```vim
public class WebHttp {

    private static final String defaultCharset = "UTF-8";

    /**
     * GET方式请求
     */
    public static String doGet(String url, Map<String, ?> search) {
        if (search != null) {
            boolean isFirst = true;
            StringBuilder s = new StringBuilder();
            for (String key : search.keySet()) {
                if (isFirst) {
                    isFirst = false;
                    s.append("?");
                } else {
                    s.append("&");
                }
                s.append(key).append("=").append(search.get(key));
            }

            url += s.toString();
        }
        return doGet(url);
    }

    public static String doGet(String url) {
        try {
            HttpClient client = new HttpClient();
            GetMethod method = new GetMethod(url);
            // 设置编码格式
            method.setRequestHeader("Content-Type", "application/json; charset=UTF-8");
            method.setRequestHeader("Accept-Encoding", "gzip, deflate, br");
            method.setRequestHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36");
            if (client.executeMethod(method) == HttpStatus.SC_OK) {
                return IOUtils.toString(new GZIPInputStream(method.getResponseBodyAsStream()), defaultCharset);
            }

        } catch (Exception e) {

        }
        return null;
    }

    /**
     * POST方式请求
     */
    public static String doPost(String url, Object requestEntity) {
        try {
            HttpClient client = new HttpClient();
            PostMethod method = new PostMethod(url);
            // 设置编码格式
            method.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
            method.setRequestEntity(new StringRequestEntity(JSON.toJSONString(requestEntity), "application/json", "UTF-8"));
            if (client.executeMethod(method) == HttpStatus.SC_OK) {
                return IOUtils.toString(method.getResponseBodyAsStream(), defaultCharset);
            }
        } catch (Exception e) {
        }
        return null;
    }

    /**
     * 模拟表单提交
     */
    public static JSONObject doPost(String url, NameValuePair[] parametersBody, Cookie... cookies) {
        JSONObject result = new JSONObject();
        try {
            HttpClient client = new HttpClient();
            PostMethod method = new PostMethod(url);
            // 重置
            method.releaseConnection();
            // 设置Cookie
            if (cookies != null && cookies.length > 0) {
                client.getState().addCookies(cookies);
            }
            // 设置编码格式
            method.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
            // 设置参数
            method.setRequestBody(parametersBody);
            //
            String responseBodyString = null;
            if (client.executeMethod(method) == HttpStatus.SC_OK) {
                responseBodyString = IOUtils.toString(method.getResponseBodyAsStream(), defaultCharset);
            }
            result.put("cookies", client.getState().getCookies());
            try {
                result.put("responseBody", JSON.parseObject(responseBodyString));
            } catch (Exception e) {
                result.put("responseBody", responseBodyString);
            }
            return result;
        } catch (Exception e) {
        }
        return null;
    }
}    
```
