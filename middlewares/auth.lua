local function before(request, kwargs)
    request.user = request.session.user
end

return { before = before}