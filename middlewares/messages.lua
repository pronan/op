local decode = require"cjson.safe".decode

local function before(req, kwargs)
    req.messages = req.session.messages
end

local function after(req, kwargs)
    if req.messages then
        req.session.messages = nil
    end
end
return { before=before, after=after}