local Query = require"resty.model".RawQuery

local function before(req, kwargs)
    loger('session:', req.session)
    req.user = req.session.user
end

return { before = before}