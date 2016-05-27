local views = require"app.views"

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

url('^/users/(?<pk>\\d+?)$', views.json)
url('^/guide$', views.guide)
url('^/inspect/(?<name>.+?)$', views.inspect)
url('^/global$', views.global)
url('/mysql', views._query)


return urlpatterns