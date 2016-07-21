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
    log('come from qq:', request.GET, request.POST)
    local code = request.GET.code
    local qq = settings.OAUTH2.qq
    local url = string.format('https://graph.qq.com/oauth2.0/token?grant_type=authorization_code&client_id=%s&client_secret=%s&code=%s&redirect_uri=%s', 
        qq.id, qq.key, code, qq.redirect_uri
    )
    log(url)
    -- local access_token = get_access_token(url)
    local client = require "resty.http":new()
    local res, err = client:request_uri(url, {
        ssl_verify = false, 
    })
    log('err:', err)
    -- access_token=5A7E1A50ED8FF900A58BDBD283C0AE3D&expires_in=7776000&refresh_token=AA851E53744FA5CE43A24722B4FB78D1
    -- local url2 = https://graph.qq.com/oauth2.0/me?access_token=YOUR_ACCESS_TOKEN
    -- local openid = get_openid(url2)
    -- callback( {"client_id":"101337042","openid":"2137B3472EE5068BABF950D73669821F"} );
    -- local info = string.format('https://graph.qq.com/user/get_user_info?access_token=%s&oauth_consumer_key=%s&openid=%s', 
        -- access_token, qq.id, openid)
    --{ "ret": 0, "msg": "", "is_lost":0, "nickname": "楠字数补丁也", "gender": "男", "province": "四川", "city": "成都", "year": "1987", "figureurl": "http:\/\/qzapp.qlogo.cn\/qzapp\/101337042\/2137B3472EE5068BABF950D73669821F\/30", "figureurl_1": "http:\/\/qzapp.qlogo.cn\/qzapp\/101337042\/2137B3472EE5068BABF950D73669821F\/50", "figureurl_2": "http:\/\/qzapp.qlogo.cn\/qzapp\/101337042\/2137B3472EE5068BABF950D73669821F\/100", "figureurl_qq_1": "http:\/\/q.qlogo.cn\/qqapp\/101337042\/2137B3472EE5068BABF950D73669821F\/40", "figureurl_qq_2": "http:\/\/q.qlogo.cn\/qqapp\/101337042\/2137B3472EE5068BABF950D73669821F\/100", "is_yellow_vip": "0", "vip": "0", "yellow_vip_level": "0", "level": "0", "is_yellow_year_vip": "0" } 

    return response.Plain(repr(res)..repr(err))
end
return m