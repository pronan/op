-- All models and urls should be registered here and referenced by
-- calling functions `get_models` and `get_urls`.
-- Currently this module is required by:
--   resty.mvc.migrate
--   resty.mvc.response
-- which means you can't require these modules during this module(resty.mvc.apps)
-- is required. Or a loop error will raise.
local utils = require"resty.mvc.utils"
local settings = require"resty.mvc.settings"

local is_windows = package.config:sub(1,1) == '\\'

local NAMES, DIR, TEMPLATE_DIRS, NAMES_FROM_SCANNING_DIR, PACKAGE_PREFIX

if settings.APPS then
    DIR = settings.APPS.dir or 'apps/' 
    NAMES_FROM_SCANNING_DIR = settings.APPS.names_from_scanning_dir or true 
    PACKAGE_PREFIX = settings.APPS.package_prefix or 'apps.'    
else
-- directory where app lives, relative to nginx running path
-- you need to end with `\` or `/`
    DIR = 'apps/' 
-- if true and APPS.names is not specified, get all app names 
-- by scanning all directories whose name contains no '__' in DIR
    NAMES_FROM_SCANNING_DIR = true 
    PACKAGE_PREFIX = 'apps.'
end

local function get_names()
    if settings.APPS and settings.APPS.names then
        return settings.APPS.names
    elseif NAMES_FROM_SCANNING_DIR then
        return utils.filter(utils.get_dirs(DIR), 
            function(e) return not e:find('__') end)
    else
        assert(nil, 'app name list should be specified, or enable NAMES_FROM_SCANNING_DIR flag.')
    end    
end
NAMES = get_names()

local function get_template_dirs()
    local res = {}
    for i, name in ipairs(NAMES) do
        res[#res+1] = string.format('%s%s/html/', DIR, name)
    end
    return res
end
TEMPLATE_DIRS = get_template_dirs()

local function get_models()
    local res = {}
    for i, app_name in ipairs(NAMES) do
        local models = require(PACKAGE_PREFIX..app_name..".models")
        for model_name, model in pairs(models) do
            -- app_name: accounts, model_name: User, table_name: accounts_user
            local meta = model.meta
            meta.app_name = app_name
            meta.model_name = model_name
            if not meta.url_model_name then
                meta.url_model_name = model_name:lower()
            end
            if not meta.table_name then
                meta.table_name = string.format('%s_%s', app_name, model_name:lower())
            end
            if not meta.fields_string then
                meta.fields_string = table.concat(
                    utils.map( 
                        meta.field_order,
                        function(e) return string.format("`%s`.`%s`", meta.table_name, e) end),
                    ', ')
            end        
            res[#res + 1] = model
        end
    end
    return res
end
get_models = utils.cache_result(get_models)

local function get_urls()
    local res = {}
    for i, name in ipairs(NAMES) do
        local urls = require(PACKAGE_PREFIX..name..".urls")
        for _, url in ipairs(urls) do
            res[#res+1] = url
        end
    end
    return res
end
get_urls = utils.cache_result(get_urls)

return {
    NAMES = NAMES,
    TEMPLATE_DIRS = TEMPLATE_DIRS,
    DIR = DIR,
    PACKAGE_PREFIX = PACKAGE_PREFIX,
    get_models = get_models, -- function to avoid loop require
    get_urls = get_urls, -- function to avoid loop require
}
