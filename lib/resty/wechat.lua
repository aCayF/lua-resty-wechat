-- Copyright (C) Lice Pan (aCayF)


local sort = table.sort
local concat = table.concat
local sha1_bin = ngx.sha1_bin
local get_uri_args = ngx.req.get_uri_args
local get_method = ngx.req.get_method
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
    XML_ATTRIBUTE_NODE=     2,
    XML_TEXT_NODE=          3,
    XML_CDATA_SECTION_NODE= 4,
    XML_ENTITY_REF_NODE=    5,
    XML_ENTITY_NODE=        6,
    XML_PI_NODE=            7,
    XML_COMMENT_NODE=       8,
    XML_DOCUMENT_NODE=      9,
    XML_DOCUMENT_TYPE_NODE= 10,
    XML_DOCUMENT_FRAG_NODE= 11,
    XML_NOTATION_NODE=      12,
    XML_HTML_DOCUMENT_NODE= 13,
    XML_DTD_NODE=           14,
    XML_ELEMENT_DECL=       15,
    XML_ATTRIBUTE_DECL=     16,
    XML_ENTITY_DECL=        17,
    XML_NAMESPACE_DECL=     18,
    XML_XINCLUDE_START=     19,
    XML_XINCLUDE_END=       20,
    XML_DOCB_DOCUMENT_NODE= 21
} xmlElementType;

typedef xmlElementType xmlNsType;
typedef struct _xmlNs xmlNs;
typedef xmlNs *xmlNsPtr;
struct _xmlNs {
    struct _xmlNs *next;
    xmlNsType type;
    const xmlChar *href;
    const xmlChar *prefix;
    void *_private;
    struct _xmlDoc *context;
};

typedef struct _xmlNode xmlNode;
typedef xmlNode *xmlNodePtr;
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
    xmlNs *ns;
    xmlChar *content;
    struct _xmlAttr *properties;
    xmlNs *nsDef;
    void *psvi;
    unsigned short line;
    unsigned short extra;
};

typedef struct _xmlDoc xmlDoc;
typedef xmlDoc *xmlDocPtr;
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

xmlDocPtr xmlReadMemory(const char * buffe, int size, const char * URL, const char * encoding, int options);

xmlNodePtr xmlDocGetRootElement(xmlDocPtr doc);

void xmlFreeDoc(xmlDocPtr cur);

]]

local mt = { __index = _M }

local lib = ffi.load("xml2")

local str_type = ffi.typeof("uint8_t[?]")


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

    local tmpstr = concat(tmptab, "")
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

    return setmetatable ({
        signature = args.signature, --case insensitive
        timestamp = args.timestamp,
        nonce = args.nonce,
        echostr = args.echostr,
        token = token,
        method = method
    }, mt)
end


return _M
