local function before(request)
    request.messages = request.session.messages
end

local function after(request)
    if request.messages then
        request.session.messages = nil
    end
end
return { before=before, after=after}