local function before(req, kwargs)
    req.cookie = require"resty.cookie"()
    loger('cookie, ', gmt(req.cookie).__index)
end
local function after(req, kwargs)
    req.cookie:_save()
    loger('cookie, ', ngx.header['Set-Cookie'])
end
return { before = before, after = after}