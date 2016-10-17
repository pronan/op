local json = require "cjson.safe"
local Response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local query = require"resty.mvc.query".single
local models = require"${package_prefix}${app_name}.models"
local forms = require"${package_prefix}${app_name}.forms"

-- function home_view(request)
--     return Response.Template(request, "${app_name}/home.html")
-- end

return {
    --  home = home_view,
}