local views = require"views"
local views_auto = require"views_auto"
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

url('^/$', views.home)
url('^/users/(?<pk>\\d+?)$', views.json)
url('^/m/(?<name>\\w+?)$', views.models)
url('^/guide$', views.guide)
url('^/inspect/(?<name>.+?)$', views.inspect)
url('^/global$', views.global)
url('^/session$', views.session)
url('^/read_session$', views.read_session)
url('^/check$', views.check)

url('^/oauth/(?<name>.+?)$', views.oauth)
url('^/oauth2/qq$', views.qq)
url('^/oauth2/github$', views.github)
return urlpatterns