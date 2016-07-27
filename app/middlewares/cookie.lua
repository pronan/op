local function before(req, kwargs)
    req.cookie = require"resty.cookie"()
end
local function after(req, kwargs)
    req.cookie:_save()
    loger('cookie, ', ngx.header['Set-Cookie'])
end
return { before = before, after = after}