local views = require"app.views"
local views_auto = require"app.views_auto"
local sub = string.sub

local urlpatterns = {}
local function url(regex,  func)
    if sub(regex, 1, 1) ~= '^' then
        regex = '^'..regex
    end
    if sub(regex, -1) ~= '$' then
        regex = regex..'$'
    end
    urlpatterns[regex] = func
end

for name, func in pairs(views_auto) do
    url('/'..name, func)
end


url('^/users/(?<pk>\\d+?)$', views.json)
url('^/guide$', views.guide)
url('^/inspect/(?<name>.+?)$', views.inspect)
url('^/global$', views.global)
url('^/session$', views.session)
url('^/check$', views.check)
return urlpatterns