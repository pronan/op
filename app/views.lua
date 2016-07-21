local query = require"resty.model".RawQuery
local response = require"resty.response"

local m={}

function m.home(req, kw)
    return response.Template('home.html')
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
function m.global(request, kwargs)
    return response.Plain(repr(gmt(_G).__index))
end
function m.models(req,kw)
    local name=kw.name or 'users'
    local res, err = query("select * from "..name)
    if not res then
        return nil, err
    end
    return response.Template('users.html', {users=res})
end
local json = require "cjson.safe"

function m.session(request, kwargs)
    --ngx.header.content_type = 'text/plain; charset=utf-8'
    local cookie = request.cookie
    local session = request.session
    -- cookie:set{key='a', value='1'}
    -- cookie:set{key='b', value='2'}
    -- cookie:set{key='c', value='3'}
    -- cookie:set{key='d', value='4'}
    session.ui = 123
    return repr(gmt(request.session).data)
end
function m.read_session(request, kwargs)
    local x = 1
    return repr(gmt(request.session).data)
end
function m.check(request, kwargs)
    --local session = require "resty.session".open()
    local session = require "resty.session".start()
    local headers = ngx.req.get_headers()
    local  res = {}
    ngx.header.content_type = 'text/plain; charset=utf-8'
    ngx.header['Set-Cookie'] = {'c=2; Domain=.baidu.com', 'b=; expires=Thu, 01 Jan 1970 00:00:00 GMT'}
    --ngx.header['Set-Cookie'] = 
    res.cookie = headers["Cookie"]
    res.session = session
    res.c = gmt(ngx.var)
    return repr(res)
end
function m.read_session(request, kwargs)
    local x = 1
    return repr(gmt(request.session).data)
end
function m.qq(request, kwargs)
    local qq = require"resty.oauth".qq
    local code = request.GET.code
    local token = qq:get_access_token(code)
    local openid = qq:get_openid(token)
    local user = qq:get_user_info(openid, token)
    return response.Plain(token..openid..repr(user))
end
return m