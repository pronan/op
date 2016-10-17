local json = require "cjson.safe"
local Response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local query = require"resty.mvc.query".single
local models = require"apps.account.models"
local forms = require"apps.account.forms"

-- function home_view(request)
--     return Response.Template(request, "account/home.html")
-- end

return {
    --  home = home_view,
}