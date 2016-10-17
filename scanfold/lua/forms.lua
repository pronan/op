local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"${package_prefix}${app_name}.models"
${require_hooks}

${all_forms}

return {
    ${all_form_exports}
}