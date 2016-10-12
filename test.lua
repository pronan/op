a={buyer=4,seller=3}
for k, v in pairs(a) do
    print(k, v)
    a[k] = {v}
end