local views=require"config.views"

return {
    ['^/users/(?<pk>\\d+?)$']=views.json,
    ['^/guide$']=views.guide,
    ['^/inspect/(?<name>.+?)$']=views.nginx,
}