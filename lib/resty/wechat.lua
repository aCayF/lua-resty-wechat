-- Copyright (C) Lice Pan (aCayF)


local sort = table.sort
local concat = table.concat
local lower = string.lower
local format = string.format
local sha1_bin = ngx.sha1_bin
local get_uri_args = ngx.req.get_uri_args
local get_method = ngx.req.get_method
local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local gsub = ngx.re.gsub
local setmetatable = setmetatable
local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C
local print = print


local _M = { _VERSION = '0.0.1' }

ffi.cdef[[
typedef unsigned char u_char;

u_char * ngx_hex_dump(u_char *dst, const u_char *src, size_t len);

typedef unsigned char xmlChar;

typedef enum {
    XML_ELEMENT_NODE=       1,
    XML_TEXT_NODE=      3,
    XML_CDATA_SECTION_NODE= 4,
} xmlElementType;

struct _xmlNode {
    void *_private;
    xmlElementType type;
    const xmlChar *name;
    struct _xmlNode *children;
    struct _xmlNode *last;
    struct _xmlNode *parent;
    struct _xmlNode *next;
    struct _xmlNode *prev;
    struct _xmlDoc *doc;
    struct _xmlNs *ns;
    xmlChar *content;
    struct _xmlAttr *properties;
    struct _xmlNs *nsDef;
    void *psvi;
    unsigned short line;
    unsigned short extra;
};

struct _xmlDoc {
    void *_private;
    xmlElementType type;
    char *name;
    struct _xmlNode *children;
    struct _xmlNode *last;
    struct _xmlNode *parent;
    struct _xmlNode *next;
    struct _xmlNode *prev;
    struct _xmlDoc *doc;
    int compression;
    int standalone;
    struct _xmlDtd *intSubset;
    struct _xmlDtd *extSubset;
    struct _xmlNs *oldNs;
    const xmlChar *version;
    const xmlChar *encoding;
    void *ids;
    void *refs;
    const xmlChar *URL;
    int charset;
    struct _xmlDict *dict;
    void *psvi;
    int parseFlags;
    int properties;
};

struct _xmlDoc * xmlReadMemory(const char * buffe, int size, const char * URL, const char * encoding, int options);

void xmlFreeDoc(struct _xmlDoc * cur);

void xmlCleanupParser(void);

]]

local rcvmsgfmt = {
    common  = {"tousername", "fromusername", "createtime", "msgtype" },
    msgtype = {
        text     = {"content", "msgid"},
        image    = {"picurl", "msgid", "mediaid"},
        voice    = {"mediaid", "format", "msgid", {"recognition"}},
        video    = {"mediaid", "thumbmediaid", "msgid"},
        location = {"location_x", "location_y", "scale", "label", "msgid"},
        link     = {"title", "description", "url", "msgid"},
        event    = {"event"}
    },
    event   = {
        subscribe   = {{"eventkey"}, {"ticket"}},
        scan        = {"eventkey", "ticket"},
        unsubscribe = {{"eventkey"}},
        location    = {"latitude", "longitude", "precision"},
        click       = {"eventkey"}
    }
}

local sndmsgfmt = {
           --{ "nodename", "childnodetype", { ... }, s=[true or false] }
    common = {
              {"tousername", "c"},
              {"fromusername", "c"},
              {"createtime", "t"},
              {"msgtype", "c"}
             },
    text   = {{"content", "c"}},
    image  = {
              {"image", "e", {
                              {"mediaid", "c"}
                             }
              }
             },
    voice  = {
              {"mediaid", "e", {
                                {"mediaid", "c"}
                               }
              }
             },
    video  = {
              {"video", "e", {
                              {"mediaid", "c"},
                              {"title", "c", o=true},
                              {"description", "c", o=true}
                             }
              }
             },
    music  = {
              {"music", "e", {
                              {"title", "c", o=true},
                              {"description", "c", o=true},
                              {"musicurl", "c", o=true},
                              {"hqmusicurl", "c", o=true},
                              {"thumbmediaid", "c"}
                             }
              }
             },
    news   = {
              {"articlecount", "t"},
              {"articles", "e", {
                                 {"item", "e", {
                                                {"title", "c", o=true},
                                                {"description", "c", o=true},
                                                {"picurl", "c", o=true},
                                                {"url", "c", o=true}
                                               }
                                 }
                                }
              }
             },
}

local mt = { __index = _M }

local lib = ffi.load("xml2")

local str_type = ffi.typeof("uint8_t[?]")


local function _normalize_items(str)
    str = gsub(str, "title[1-9]>", "title>", "i")
    str = gsub(str, "description[1-9]>", "description>", "i")
    str = gsub(str, "picurl[1-9]>", "picurl>", "i")
    str = gsub(str, "url[1-9]>", "url>", "i")

    return str
end


local function _insert_items(n)
    local newsfmts = sndmsgfmt["news"]
    local node = newsfmts[2]
    local tb = node[3]

    for i = 1, n do
        local item = {"item", "e", {
                                    {"title" .. i, "c", o=true},
                                    {"description" .. i, "c", o=true},
                                    {"picurl" .. i, "c", o=true},
                                    {"url" .. i, "c", o=true}
                                   }
                     }
        -- push
        tb[#tb + 1] = item
    end
end


local function _retrieve_content(sndmsg, fmt)
    local name = fmt[1]
    -- TODO
    local content = sndmsg[name] and sndmsg[name] or ""
    local optional = fmt.o

    if not optional and content == "" then
        return nil, "missing required argment -- " .. name
    end

    return content
end


local function _format_xml(sndmsg, fmts, str)
    for i = 1, #fmts do
        local fmt = fmts[i]
        local name = fmt[1]
        local t = fmt[2]
        local subfmts = fmt[3]
        local content, err

        if t == "e" then
            content, err = _format_xml(sndmsg, subfmts, "")
            if err then
               return nil, err
            end

            if content ~= "" then
                content = format("<%s>\n", name) .. content .. format("</%s>\n", name)
            end
        end

        if t == "t" then
            content, err = _retrieve_content(sndmsg, fmt)
            if err then
               return nil, err
            end

            if content ~= "" then
                content = format("<%s>%s</%s>\n", name, content, name)
            end
        end

        if t == "c" then
            content, err = _retrieve_content(sndmsg, fmt)
            if err then
               return nil, err
            end

            if content ~= "" then
                content = format("<%s><![CDATA[%s]]></%s>\n", name, content, name)
            end
        end

        str = str .. content
    end

    return str
end


function _M.build(self, sndmsg)
    local msgtype = sndmsg.msgtype
    local fmts = sndmsgfmt[msgtype]
    local n = sndmsg.articlecount and tonumber(sndmsg.articlecount) or 0
    local rcvmsg = self.rcvmsg
    local stream

    if n > 10 then
        return nil, "invalid articlecount"
    end

    if not fmts then
        return nil, "invalid msgtype"
    end

    if not rcvmsg.fromusername
       or not rcvmsg.tousername then
        return nil, "invalid recieve message"
    end
    sndmsg.tousername = rcvmsg.fromusername
    sndmsg.fromusername = rcvmsg.tousername
    -- TODO
    sndmsg.createtime = rcvmsg.createtime

    if n > 1 then
        _insert_items(n)
    end

    stream = "<xml>"
    stream, err = _format_xml(sndmsg, sndmsgfmt.common, stream)
    if err then
        return nil, err
    end
    stream, err = _format_xml(sndmsg, fmts, stream)
    if err then
        return nil, err
    end
    stream = stream .. "</xml>"

    if n > 1 then
        stream = _normalize_items(stream)
    end

    self.stream = stream
    return true
end


local function _parse_key(nodePtr, key, rcvmsg)
    local node = nodePtr.node
    local name = ffi_str(node[0].name)
    local optional = (type(key) == "table") and true or false
    local k = optional and key[1] or key

    if lower(name) ~= k then -- case insensitive
        if not optional then
            return nil, "invalid node name"
        else
            return true
        end
    end

    if node[0].type ~= lib.XML_ELEMENT_NODE then
        return nil, "invalid node type"
    end

    node = node[0].children
    if node == nil then
        return nil, "invalid subnode"
    end

    if node[0].type ~= lib.XML_TEXT_NODE
       and node[0].type ~= lib.XML_CDATA_SECTION_NODE then
        return nil, "invalid subnode type"
    end

    rcvmsg[k] = ffi_str(node[0].content)

    node = node[0].parent
    if node[0].next ~= nil then
        node = node[0].next
    end
    nodePtr.node = node

    return rcvmsg[k]
end


local function _parse_keytable(nodePtr, keytable, rcvmsg)
    for i = 1, #keytable do
        local key = keytable[i]

        local value, err = _parse_key(nodePtr, key, rcvmsg)
        if err then
            return nil, err
        end
    end

    return true
end


local function _retrieve_keytable(nodePtr, key, rcvmsg)
    local root = rcvmsgfmt.msgtype

    while true do
        if not root[key] then
            return nil, "invalid key"
        end

        -- indicates that no subkeys present
        if not rcvmsgfmt[key] then
            break
        end

        local value, err = _parse_key(nodePtr, key, rcvmsg)
        if err then
            return nil, err
        end

        root = rcvmsgfmt[key]
        key = value
    end

    return root[key]
end


local function _parse_xml(node, rcvmsg)
    local keytable, ok, err

    -- element node named xml is expected
    if node[0].type ~= lib.XML_ELEMENT_NODE
       or ffi_str(node[0].name) ~= "xml" then
        return nil, "parsing xml failed :invalid xml title"
    end

    if node[0].children == nil then
        return nil, "parsing xml failed :invalid xml content"
    end

    -- parse common components
    local nodePtr = { node = node[0].children }
    keytable = rcvmsgfmt.common

    ok, err = _parse_keytable(nodePtr, keytable, rcvmsg)
    if not ok then
        return nil, "common parsing failed :" .. err
    end

    -- retrieve msgtype-specific keytable
    keytable, err = _retrieve_keytable(nodePtr, rcvmsg.msgtype, rcvmsg)
    if err then
        return nil, "retrieving keytable failed :" .. err
    end

    -- parse msgtype-specific components
    ok, err = _parse_keytable(nodePtr, keytable, rcvmsg)
    if not ok then
        return nil, "msgtype-specific parsing failed :" .. err
    end

    return true
end


function _M.parse(self)
    local doc = ffi.new("struct _xmlDoc *")
    local node = ffi.new("struct _xmlNode *")
    local body = self.body
    local rcvmsg = self.rcvmsg

    if not body then
        return nil, "invalid request body"
    end

    doc = lib.xmlReadMemory(body, #body, nil, nil, 0)
    if doc == nil then
        return nil, "invalid xml data"
    end

    -- root node
    node = doc[0].children
    ok, err = _parse_xml(node, rcvmsg)

    -- cleanup used memory anyway
    lib.xmlFreeDoc(doc)
    lib.xmlCleanupParser()

    if not ok then
        return nil, err
    end

    return true
end


local function _to_hex(s)
    local len = #s * 2
    local buf = ffi_new(str_type, len)
    C.ngx_hex_dump(buf, s, #s)
    return ffi_str(buf, len)
end


local function _check_signature(self)
    local signature = self.signature
    local timestamp = self.timestamp
    local nonce = self.nonce
    local token = self.token
    local tmptab = {token, timestamp, nonce}
    sort(tmptab)

    local tmpstr = concat(tmptab)
    --print("sorted string: ", tmpstr)
    tmpstr = sha1_bin(tmpstr)
    tmpstr = _to_hex(tmpstr)
    --print("caculated digest: ", tmpstr)

    if tmpstr ~= signature then
        return nil, "fade signature"
    end

    print("check signature success")
    return true
end


function _M.valid(self)
    if not self.echostr then
        return nil, "missing echostr"
    end

    --print("received echostr: ", self.echostr)
    return _check_signature(self)
end


function _M.new(self,token)
    local args = get_uri_args()
    local method = get_method()

    read_body()
    local body = get_body_data()
    if body then
        body = gsub(body, "[\r\n]*", "", "i")
    end

    return setmetatable ({
        signature = args.signature, --case insensitive
        timestamp = args.timestamp,
        nonce = args.nonce,
        echostr = args.echostr,
        token = token,
        method = method,
        body = body,
        rcvmsg = {}
    }, mt)
end


return _M
