local ClassView = require"resty.mvc.view"
local views = require"${package_prefix}${app_name}.views"
local models = require"${package_prefix}${app_name}.models"
local forms = require"${package_prefix}${app_name}.forms"

return {
${all_urls}
}