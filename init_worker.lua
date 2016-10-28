local migrate = require "resty.mvc.migrate"
local apps = require"main.init".apps
local drop_table = true

local function _migrate()
    return migrate.main(apps:get_models(), drop_table)
end

ngx.timer.at(0, _migrate)
    