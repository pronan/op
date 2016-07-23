local function before(req, kwargs)
    assert(not req.messages)
    req.messages = req.session.messages
end

local function after(req, kwargs)
    if req.messages then
        req.session.messages = nil
    end
end
return { before=before, after=after}