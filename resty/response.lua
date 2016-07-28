local compile = require"resty.template".compile
local encode = require "cjson.safe".encode

local GLOBAL_CONTEXT = {pjl='大肥白嫩'}

local function render(path, context)
    context=context or {}
    for k, v in pairs(GLOBAL_CONTEXT) do
        if context[k] == nil then
            context[k] = v
        end
    end
    local req = ngx.req
    context.req = req
    context.user = req.user
    context.messages = req.messages
    return compile(path)(context)
end

local M = {}
function M.new(self, init)
    init = init or {}
    self.__index = self
    return setmetatable(init, self)
end

local PlainMeta = M:new{}
PlainMeta.__call = function(tbl, text)
    return tbl:new{text=text}
end

local Plain = PlainMeta:new{}
function Plain.exec(self)
    ngx.header['Content-Type'] = "text/plain; charset=utf-8"
    return ngx.print(self.text)
end

local HtmlMeta = M:new{}
HtmlMeta.__call = function(tbl, text)
    return tbl:new{text=text}
end

local Html = HtmlMeta:new{}
function Html.exec(self)
    ngx.header['Content-Type'] = "text/html; charset=utf-8"
    return ngx.print(self.text)
end

local TemplateMeta = M:new{}
TemplateMeta.__call = function(tbl, path, context)
    return tbl:new{path=path, context=context}
end

local Template = TemplateMeta:new{}
function Template.exec(self)
    ngx.header['Content-Type'] = "text/html; charset=utf-8"
    return ngx.print(render(self.path, self.context))
end

local ErrorMeta = M:new{}
ErrorMeta.__call = function(tbl, message)
    return tbl:new{message=message}
end

local Error = ErrorMeta:new{}
function Error.exec(self)
    ngx.header['Content-Type'] = "text/html; charset=utf-8"
    return ngx.print(render('error.html', {message=self.message}))
end

local RedirectMeta = M:new{}
RedirectMeta.__call = function(tbl, url, status)
    return tbl:new{url=url, status=status or 302}
end

local Redirect = RedirectMeta:new{}
function Redirect.exec(self)
    return ngx.redirect(self.url, self.status)
end

local JsonMeta = M:new{}
JsonMeta.__call = function(tbl, jsondict)
    return tbl:new{jsondict=jsondict}
end

local Json = JsonMeta:new{}
function Json.exec(self)
    ngx.header['Content-Type'] = "application/json; charset=utf-8"
    return ngx.print(encode(self.jsondict))
end



return {
    Template = Template, 
    Json = Json, 
    Redirect = Redirect, 
    Plain = Plain, 
    Html = Html, 
    Error = Error, 
}