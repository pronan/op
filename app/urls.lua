local response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local views = require"app.views"

local function login_require(func)
    return function(request)
        if not request.user then
            request.session.message = '请先登录再进行此操作'
            return response.Redirect('/login?redirect_url='..ngx.var.uri)
        else
            return func(request)
        end
    end
end

return{

    {'^/$', views.home}, 
    {'^/profile$', views.profile}, 
    {'^/login$', views.login}, 
    {'^/oauth/(?<name>.+?)$', views.oauth}, 
    {'^/oauth2/qq$', views.qq}, 
    {'^/oauth2/github$', views.github}, 
    {'^/logout$', views.logout}, 
    {'^/register$', views.register}, 

    {'^/q$', views.q}, 
    {'^/guide$', views.guide}, 

    {'^/log/(?<n>\\d*?)$', views.log}, 
    {'^/global$', views.global}, 
}
