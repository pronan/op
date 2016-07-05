local _M = {}

local function cookie_middleware_before(req, kwargs)
    req.cookie = require"resty.cookie":new()
end



_M.cookie = {before=cookie_middleware_before}

return _M