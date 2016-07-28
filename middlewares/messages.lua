local function before(req, kwargs)
    req.messages = req.cookies.messages
end

local function after(req, kwargs)
    if req.messages then
        req.cookies.messages = nil
    end
end
return { before=before, after=after}