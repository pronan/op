local function before(request)
    req.messages = req.session.messages
end

local function after(request)
    if req.messages then
        req.session.messages = nil
    end
end
return { before=before, after=after}