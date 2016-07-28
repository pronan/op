local function before(req, kwargs)
    req.message = req.cookies.message
end

local function after(req, kwargs)
    if req.message then
        req.cookies.message = nil
    end
end
return { before=before, after=after}