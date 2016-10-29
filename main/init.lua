local utils = require"resty.mvc.utils"
local settings = require"resty.mvc.settings"
local project_settings = require"main.settings"
local Apps = require"resty.mvc.apps"

-- populate and normalize settings with project settings
settings.normalize(utils.dict_update(settings, project_settings))

-- register apps
local apps = Apps:new()
if not settings.APPS  then
    settings.APPS = utils.filter(
        utils.get_dirs(apps.dir), function(e) return not e:find('__') end)
end
if not settings.TEMPLATE_DIRS then
    local res = {}
    for i, app_name in pairs(settings.APPS) do
        res[#res+1] = string.format('%s%s/html/', apps.dir, app_name)
    end
    settings.TEMPLATE_DIRS = res
end

for i, app_name in ipairs(settings.APPS) do
    local models = require(apps.package_prefix..app_name..".models")
    for model_name, model in pairs(models) do
        -- app_name: accounts, model_name: User, table_name: accounts_user
        apps:register(model:normalize(app_name, model_name))
    end
end

-- '^/product/update/(?<id>\\d+?)$'
-- {
--   "id": "1",
--   0   : "/product/update/1",
--   1   : "1",
-- }

local Router = require"resty.mvc.router"

local router = Router:instance()
for i, v in ipairs(apps:get_public_urls()) do
    router:add(v)
end
for i, v in ipairs(apps:get_admin_urls()) do
    router:add(v)
end

local Dispatcher = require"resty.mvc.dispatcher"

local dispatcher = Dispatcher:instance{
    router = router,
    middlewares = settings.MIDDLEWARES,
    debug = settings.debug,
}

return {
    handler = function() return dispatcher:match(ngx.var.uri) end,
    apps = apps,
}
