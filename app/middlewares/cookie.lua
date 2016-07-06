local function before(req, kwargs)
    req.cookie = require"resty.cookie":new()
end

return { before = before}