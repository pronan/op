-- All models and urls should be registered here and referenced by
-- calling functions `get_models` and `get_urls`.
-- Currently this module is required by:
--   resty.mvc.migrate
--   resty.mvc.response
-- which means you can't require these modules during this module(resty.mvc.apps)
-- is required. Or a loop error will raise.

local is_windows = package.config:sub(1,1) == '\\'

-- a list of app names
local NAMES = {}
-- directory where app lives, relative to nginx running path
-- you need to end with `\` or `/`
local DIR = 'apps/' 
-- if true, get all app names by scanning all directories in DIR
-- ignoring initial NAMES value
local AUTO_SCAN_APPS = true 
local PACKAGE_PREFIX = 'apps.'

local scandir
if is_windows then
    function scandir(directory)
        local t, popen = {}, io.popen
        local pfile = popen('dir "'..directory..'" /b /ad')
        for filename in pfile:lines() do
            if not filename:find('__') then
                t[#t+1] = filename
            end
        end
        pfile:close()
        return t
    end
else
    function scandir(directory)
        local t, popen = {}, io.popen
        local pfile = popen('ls -l "'..directory..'" | grep ^d')
        for filename in pfile:lines() do
            if not filename:find('__') then
                t[#t+1] = filename:match(' (%w+)$')
            end
        end
        pfile:close()
        return t
    end
end
if AUTO_SCAN_APPS then
    NAMES = scandir(DIR)
else
    assert(NAMES and type(NAMES) == 'table', 'you must provided a apps table.')
end

local TEMPLATE_DIRS = {}
for i, name in ipairs(NAMES) do
    TEMPLATE_DIRS[#TEMPLATE_DIRS+1] = string.format('%s%s/html/', DIR, name)
end
local function get_models()
    local res = {}
    for i, app_name in ipairs(NAMES) do
        local models = require(PACKAGE_PREFIX..app_name..".models")
        for _, model in pairs(models) do
            model.__app_name = app_name
            res[model.table_name] = model
        end
    end
    return res
end

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


------------------ clean the constants-------------------
local e = DIR:sub(-1, -1)
if e ~= '/' or e ~= '\\' then
    DIR = DIR..'/'
end
if PACKAGE_PREFIX:sub(-1, -1) ~= '.' then
    PACKAGE_PREFIX = PACKAGE_PREFIX..'.'
end


return {
    NAMES = NAMES,
    DIR = DIR,
    PACKAGE_PREFIX = PACKAGE_PREFIX,
    TEMPLATE_DIRS = TEMPLATE_DIRS,
    get_models = get_models, -- function to avoid loop require
    get_urls = get_urls, -- function to avoid loop require
    
}
