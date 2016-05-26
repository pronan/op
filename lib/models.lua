function pairsb (t, f)
local a = {}
for n in pairs(t) do a[#a + 1] = n end
table.sort(a, f)
local i = 0 -- iterator variable
return function () -- iterator function
i = i + 1
return a[i], t[a[i]]
end
end
t = {a = 1, b = 2, c = 3}
for k in pairs(t) do
    print(k,v)
end