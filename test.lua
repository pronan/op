local function kv(r, s)
    if s == "formdata" then return end
    local e = s:find("=", 1, true)
    if e then
        r[s:sub(2, e - 1)] = s:sub(e + 2, #s - 1)
    else
        r[#r+1] = s
    end
end
local function parse(s)
    if not s then return nil end
    local r = {}
    local i = 1
    local b = s:find(";", 1, true)
    while b do
        local p = s:sub(i, b - 1)
        kv(r, p)
        i = b + 1
        b = s:find(";", i, true)
    end
    local p = s:sub(i)
    if p ~= "" then kv(r, p) end
    return r
end

for k,v in pairs(parse('a=1;b=2;')) do
    print(k,v)
end