local M = {}

local Modules = {'base', 'repr'}

for i, name in Modules do
    for k,v in pairs(require"utils."..name) do
        M[k] = v
    end
end

return M