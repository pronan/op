local function before(req, kwargs)
    req.message = req.session.message
end

local function after(req, kwargs)
    if req.message then
        req.session.message = nil
    end
end
return { before=before, after=after}