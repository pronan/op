local migrate = require "resty.mvc.migrate"

local function _migrate()
    return migrate(nil, true)
end
ngx.timer.at(0, _migrate)
    