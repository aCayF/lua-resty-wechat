# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();
#no_diff();

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

--- error_log
check signature success

