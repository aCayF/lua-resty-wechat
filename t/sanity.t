# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(1);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();
no_diff();

run_tests();

__DATA__

=== TEST 1: valid
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("valid failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end
        ';
    }
--- raw_request eval
["GET /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 101.69.255.134\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n"]
--- response_body
5961398446273956311
--- abort
--- no_error_log
[error]



=== TEST 2: parse text
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("validing failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end

            local ok, err = chat:parse();
            if not ok then 
                ngx.say("parsing failed: ", err);
                return
            end 

            for k, v in pairs(chat.rcvmsg) do
                ngx.say(k, "=", v)
            end
        ';
    }
--- raw_request eval
["POST /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 54.238.220.166\r
Content-Type: text/xml\r
Content-Length: 277\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n".
'<xml><ToUserName><![CDATA[gh_7f1e8c152f69]]></ToUserName>
<FromUserName><![CDATA[o7El5t8T1myjbxlghgzIw3zASQK4]]></FromUserName>
<CreateTime>1389784145</CreateTime>
<MsgType><![CDATA[text]]></MsgType>
<Content><![CDATA[haha]]></Content>
<MsgId>5969077451284321926</MsgId>
</xml>']
--- abort
--- response_body
fromusername=o7El5t8T1myjbxlghgzIw3zASQK4
content=haha
tousername=gh_7f1e8c152f69
createtime=1389784145
msgid=5969077451284321926
msgtype=text
--- no_error_log
[error]



=== TEST 3: parse image
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("validing failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end

            local ok, err = chat:parse();
            if not ok then 
                ngx.say("parsing failed: ", err);
                return
            end 

            for k, v in pairs(chat.rcvmsg) do
                ngx.say(k, "=", v)
            end
        ';
    }
--- raw_request eval
["POST /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 54.238.220.166\r
Content-Type: text/xml\r
Content-Length: 488\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n".
'<xml><ToUserName><![CDATA[gh_7f1e8c152f69]]></ToUserName>
<FromUserName><![CDATA[o7El5t8T1myjbxlghgzIw3zASQK4]]></FromUserName>
<CreateTime>1389946192</CreateTime>
<MsgType><![CDATA[image]]></MsgType>
<PicUrl><![CDATA[http://mmbiz.qpic.cn/mmbiz/D8JCEXQrwkeOGMs3ibzB4EgYTib1ZyNIUeN4VSxboQc68w7AFC76WibqQPA5rpR3OJsia9JibMJV9MoX6vfQVrbdmqw/0]]></PicUrl>
<MsgId>5969773437849736839</MsgId>
<MediaId><![CDATA[IblbErURxw5GlffjlmqJ-y8_-J-H1Nr82b1rQ_BT1mE8pzJm8ZuVLM3Qfcfvl3bD]]></MediaId>
</xml>']
--- abort
--- response_body
fromusername=o7El5t8T1myjbxlghgzIw3zASQK4
mediaid=IblbErURxw5GlffjlmqJ-y8_-J-H1Nr82b1rQ_BT1mE8pzJm8ZuVLM3Qfcfvl3bD
createtime=1389946192
tousername=gh_7f1e8c152f69
picurl=http://mmbiz.qpic.cn/mmbiz/D8JCEXQrwkeOGMs3ibzB4EgYTib1ZyNIUeN4VSxboQc68w7AFC76WibqQPA5rpR3OJsia9JibMJV9MoX6vfQVrbdmqw/0
msgid=5969773437849736839
msgtype=image
--- no_error_log
[error]



=== TEST 4: parse voice
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("validing failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end

            local ok, err = chat:parse();
            if not ok then 
                ngx.say("parsing failed: ", err);
                return
            end 

            for k, v in pairs(chat.rcvmsg) do
                ngx.say(k, "=", v)
            end
        ';
    }
--- raw_request eval
["POST /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 54.238.220.166\r
Content-Type: text/xml\r
Content-Length: 411\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n".
'<xml><ToUserName><![CDATA[gh_7f1e8c152f69]]></ToUserName>
<FromUserName><![CDATA[o7El5t8T1myjbxlghgzIw3zASQK4]]></FromUserName>
<CreateTime>1389960556</CreateTime>
<MsgType><![CDATA[voice]]></MsgType>
<MediaId><![CDATA[FoAaRyjroJLoRE_tbQjb_5gSzInoWr-GI80WRpLL3ceH1TYs7e3w_C8TNiKEiEoZ]]></MediaId>
<Format><![CDATA[amr]]></Format>
<MsgId>5969835130759976584</MsgId>
<Recognition><![CDATA[]]></Recognition>
</xml>']
--- abort
--- response_body
fromusername=o7El5t8T1myjbxlghgzIw3zASQK4
format=amr
mediaid=FoAaRyjroJLoRE_tbQjb_5gSzInoWr-GI80WRpLL3ceH1TYs7e3w_C8TNiKEiEoZ
createtime=1389960556
tousername=gh_7f1e8c152f69
recognition=
msgid=5969835130759976584
msgtype=voice
--- no_error_log
[error]



=== TEST 6: parse location
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("validing failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end

            local ok, err = chat:parse();
            if not ok then 
                ngx.say("parsing failed: ", err);
                return
            end 

            for k, v in pairs(chat.rcvmsg) do
                ngx.say(k, "=", v)
            end
        ';
    }
--- raw_request eval
["POST /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 54.238.220.166\r
Content-Type: text/xml\r
Content-Length: 398\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n".
'<xml><ToUserName><![CDATA[gh_7f1e8c152f69]]></ToUserName>
<FromUserName><![CDATA[o7El5t8T1myjbxlghgzIw3zASQK4]]></FromUserName>
<CreateTime>1390283506</CreateTime>
<MsgType><![CDATA[location]]></MsgType>
<Location_X>28.000000</Location_X>
<Location_Y>120.000000</Location_Y>
<Scale>17</Scale>
<Label><![CDATA[中国浙江省 邮政编码: 300000]]></Label>
<MsgId>5971222190448219785</MsgId>
</xml>']
--- abort
--- response_body
fromusername=o7El5t8T1myjbxlghgzIw3zASQK4
scale=17
tousername=gh_7f1e8c152f69
createtime=1390283506
label=中国浙江省 邮政编码: 300000
msgid=5971222190448219785
msgtype=location
location_x=28.000000
location_y=120.000000
--- no_error_log
[error]



=== TEST 7: parse link
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("validing failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end

            local ok, err = chat:parse();
            if not ok then 
                ngx.say("parsing failed: ", err);
                return
            end 

            for k, v in pairs(chat.rcvmsg) do
                ngx.say(k, "=", v)
            end
        ';
    }
--- raw_request eval
["POST /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 54.238.220.166\r
Content-Type: text/xml\r
Content-Length: 369\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n".
'<xml><ToUserName><![CDATA[gh_7f1e8c152f69]]></ToUserName>
<FromUserName><![CDATA[o7El5t8T1myjbxlghgzIw3zASQK4]]></FromUserName>
<CreateTime>1390285815</CreateTime>
<MsgType><![CDATA[link]]></MsgType>
<Title><![CDATA[题目]]></Title>
<Description><![CDATA[描述]]></Description>
<Url><![CDATA[http://mp.weixin.qq.com/]]></Url>
<MsgId>5971232107527706252</MsgId>
</xml>']
--- abort
--- response_body
fromusername=o7El5t8T1myjbxlghgzIw3zASQK4
createtime=1390285815
title=题目
url=http://mp.weixin.qq.com/
tousername=gh_7f1e8c152f69
description=描述
msgid=5971232107527706252
msgtype=link
--- no_error_log
[error]



=== TEST 8: parse event of subscribe
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("validing failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end

            local ok, err = chat:parse();
            if not ok then 
                ngx.say("parsing failed: ", err);
                return
            end 

            for k, v in pairs(chat.rcvmsg) do
                ngx.say(k, "=", v)
            end
        ';
    }
--- raw_request eval
["POST /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 54.238.220.166\r
Content-Type: text/xml\r
Content-Length: 278\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n".
'<xml><ToUserName><![CDATA[gh_7f1e8c152f69]]></ToUserName>
<FromUserName><![CDATA[o7El5t8T1myjbxlghgzIw3zASQK4]]></FromUserName>
<CreateTime>1390283649</CreateTime>
<MsgType><![CDATA[event]]></MsgType>
<Event><![CDATA[subscribe]]></Event>
<EventKey><![CDATA[]]></EventKey>
</xml>']
--- abort
--- response_body
fromusername=o7El5t8T1myjbxlghgzIw3zASQK4
event=subscribe
tousername=gh_7f1e8c152f69
eventkey=
createtime=1390283649
msgtype=event
--- no_error_log
[error]



=== TEST 10: parse event of unsubscribe
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local wechat = require "resty.wechat"
            local token = "acayf"
            local chat = wechat:new(token)

            local ok, err = chat:valid();
            if not ok then 
                ngx.say("validing failed: ", err);
                return
            end 

            if chat.method == "GET" then
                ngx.say(chat.echostr)
            end

            local ok, err = chat:parse();
            if not ok then 
                ngx.say("parsing failed: ", err);
                return
            end 

            for k, v in pairs(chat.rcvmsg) do
                ngx.say(k, "=", v)
            end
        ';
    }
--- raw_request eval
["POST /t?signature=9c32c80661e38ff5f5bc88cad6f7195d7ad93824&echostr=5961398446273956311&timestamp=1387891159&nonce=1387996234 HTTP/1.0\r
User-Agent: Mozilla/4.0\r
Accept: */*\r
Host: 54.238.220.166\r
Content-Type: text/xml\r
Content-Length: 280\r
Pragma: no-cache\r
Connection: Keep-Alive\r\n\r\n".
'<xml><ToUserName><![CDATA[gh_7f1e8c152f69]]></ToUserName>
<FromUserName><![CDATA[o7El5t8T1myjbxlghgzIw3zASQK4]]></FromUserName>
<CreateTime>1390283618</CreateTime>
<MsgType><![CDATA[event]]></MsgType>
<Event><![CDATA[unsubscribe]]></Event>
<EventKey><![CDATA[]]></EventKey>
</xml>']
--- abort
--- response_body
fromusername=o7El5t8T1myjbxlghgzIw3zASQK4
event=unsubscribe
tousername=gh_7f1e8c152f69
eventkey=
createtime=1390283618
msgtype=event
--- no_error_log
[error]
