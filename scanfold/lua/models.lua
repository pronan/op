local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"
${require_hooks}

${all_models}

return {
    ${all_model_exports}
}