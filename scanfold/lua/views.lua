local json = require "cjson.safe"
local Response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local query = require"resty.mvc.query".single
local models = require"${package_prefix}${app_name}.models"
local forms = require"${package_prefix}${app_name}.forms"

${all_views}

return {
    ${all_view_exports}
}