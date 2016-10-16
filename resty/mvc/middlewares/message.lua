local function before(request)
    request.message = request.session.message
end

local function after(request)
    if request.message then
        request.session.message = nil
    end
end
return { before=before, after=after}