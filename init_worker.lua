local migrate = require "resty.mvc.migrate"

local drop_table = false

local function _migrate()
    return migrate.main(nil, drop_table)
end

ngx.timer.at(0, _migrate)
    