local views = require"app.views"

local urlpatterns = {}
local function url(regex,  func)        
    urlpatterns[regex] = func
end

url('^/users/(?<pk>\\d+?)$', views.json)
url('^/guide$', views.guide)
url('^/inspect/(?<name>.+?)$', views.nginx)

return urlpatterns