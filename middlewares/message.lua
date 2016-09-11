local function before(request)
    req.message = req.session.message
end

local function after(request)
    if req.message then
        req.session.message = nil
    end
end
return { before=before, after=after}