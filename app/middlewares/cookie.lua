local function before(req, kwargs)
    req.cookie = require"resty.cookie"()
    loger('cookie:', req.cookie)
end
local function after(req, kwargs)
    req.cookie:_save()
end
return { before = before, after = after}