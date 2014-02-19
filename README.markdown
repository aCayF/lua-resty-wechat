Name
====

lua-resty-wechat

Status
======

项目还处在积极开发一期任务阶段,欢迎兴趣相投者一起参与开发

Description
===========

微信公众平台lua开发包,基于web服务器[nginx](http://nginx.org/)以及相应的一些扩展和第三方库

Requirements
========

[ngx_lua](https://github.com/chaoslawful/lua-nginx-module),
[libxml2](http://www.xmlsoft.org/),
[LuaJIT](http://luajit.org)

Synopsis
========

```lua
    lua_package_path "/path/to/lua-resty-wechat/lib/?.lua;;";

    server {
        location /test {
            content_by_lua '
                local wechat = require "resty.wechat"
                local ok, err, rcvmsg
                local token = "acayf" --填入开发者在微信官网填写的token
                local chat = wechat:new(token)

                ok, err = chat:valid() --验证消息可靠性
                if not ok then
                    print("failed to valid message :" .. err)
                    return
                end

                if chat.method == "GET" then --微信第一次验证开发者URL
                    ngx.print(chat.echostr)
                    return
                end

                rcvmsg, err = chat:parse() --解析出开发者收到的消息
                if err then
                    print("failed to parse message :" .. err)
                    return
                end

                --回复开发者自定义消息
                ok, err = chat:reply({msgtype = "text", content = "hello world!"})
                if not ok then
                    print("failed to reply message :" .. err)
                end
            ';
        }
    }
```
备注：

token在[微信平台上申请](http://mp.weixin.qq.com/cgi-bin/callbackprofile?type=info&t=wxm-developer-ahead&lang=zh_CN)

开发者接收到的消息格式和自定义的发送消息格式都在[微信公众平台开发者文档](http://mp.weixin.qq.com/wiki/index.php?title=%E9%A6%96%E9%A1%B5)中有详细描述

TODO
====

一期:

实现微信官方API

二期:

实现微信非官方发送API

三期:

实现微信非官方登陆API

Authors
=======

"plc1989" <plc1989@gmail.com>

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2013-2014, by aCayF (潘力策) <plc1989@gmail.com>.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

