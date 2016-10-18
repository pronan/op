local function list(...)
    local total = {}
    for _, t in next, {...} do -- not `ipairs` in case of sparse {...}
        print(_, t)
    end
    return total
end

list(10,'ab',nil,nil, 'c', nil, nil, 'dd',1,2,3,nil)