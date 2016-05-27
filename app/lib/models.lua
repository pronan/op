function sorted( t ,callback)
    local keys = {}
    for k,v in pairs(t) do
        keys[#keys+1] = k
    end
    table.sort(keys)
    for i,v in ipairs(keys) do
        callback(v,t[v])
    end
end

sorted{a = 1,b = 2,c = 3}