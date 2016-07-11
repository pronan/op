local get_post = require"resty.reqargs"

local function before(req, kwargs)
    req.GET, req.POST, req.FILES = get_post{}
end

return { before = before}