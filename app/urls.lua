local views = require"app.views"
local views_auto = require"app.views_auto"

local urlpatterns = {}
local function url(regex,  func)
    if regex[1] ~= '^' then
        regex = '^'..regex
    end
    if regex[-1] ~= '$' then
        regex = regex..'$'
    end
    urlpatterns[regex] = func
end

for name, func in pairs(views_auto) do
    url('/'..name, func)
end


url('^/users/(?<pk>\\d+?)$', views.json)
--url('^/guide$', views.guide)
url('^/inspect/(?<name>.+?)$', views.inspect)
url('^/global$', views.global)
url('/init', views.init)

return urlpatterns