local query = require"resty.model".RawQuery

local m={}

local function log( ... )
    ngx.log(ngx.ERR, string.format('\n*************************************\n%s\n*************************************', table.concat({...}, "")))
end


local function getfield(f)
    local v = _G -- start with the table of globals
    for w in string.gmatch(f, "[%w_]+") do
        v = v[w]
    end
    return v
end
local function sorted( t ,callback)
    local keys = {}
    for k,v in pairs(t) do
        keys[#keys+1] = k
    end
    table.sort(keys)
    for i,v in ipairs(keys) do
        callback(v,t[v])
    end
end
local function sprint_table(t)
    say('<table>')
    sorted(t, function(k,v )
        say(string.format('<tr><td>%s</td><td>%s</td></tr>',k,tostring(v)))
    end)
    say('</table>')
end
local function print_table(t)
    say('<table>')
    for k,v in pairs(t) do
        say(string.format('<tr><td>%s</td><td>%s</td></tr>',k,tostring(v)))
    end
    say('</table>')
end
function m.inspect(kw)
    ngx.ctx.b = 2
    sprint_table(ngx.ctx)
end
function m.global(kw)
    ngx.header.content_type = 'text/plain'
    local x = {a=1, bddddd={a=1, b=2}}
    return repr(gmt(_G).__index)
end
function m.home(kw)
    return repr(gmt(_G).__index)
end
function m.session(request, kwargs)
    local session = require "resty.session".start()
    session.data.wow = 'yaaaakb12'
    session:save()
    return repr(ngx.var.args)
end
function m.check(request, kwargs)
    local session = require "resty.session".open()
    local ck = ngx.req.get_headers()
    local  res = {}
    ngx.header.content_type = 'text/plain'
    ngx.header.charset = 'utf-8'
    res[#res+1] = tostring(#ck["Cookie"])
    res[#res+1] = ck
    res[#res+1] = session
    return repr(res)
end
return m