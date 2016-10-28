local utils = require"resty.mvc.utils"
local Response = require"resty.mvc.response"
-- local settings = require"resty.mvc.settings"


local function get_user_model()
    local u = require"resty.mvc.settings".USER_MODEL
    if type(u) == 'string' then
        return require(u)
    elseif type(u) == 'table' then
        return require(u[1])[u[2]]
    elseif u == nil then
        return require('resty.mvc.apps.auth.models').User
    else
        assert(nil, 'invalid USER_MODEL value.')
    end
end

return {

}