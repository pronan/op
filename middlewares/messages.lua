local function before(req, kwargs)
    req.messages = req.cookie.messages
end

local function after(req, kwargs)
    if req.messages then
        req.cookie.messages = nil
    end
end
return { before=before, after=after}