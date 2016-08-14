local encode_args = ngx.encode_args
local decode_args = ngx.decode_args
local decode = require"cjson.safe".decode
local http = require"resty.http"
local match = ngx.re.match

local function caller(t, opts) 
    return t:new(opts):initialize() 
end

local qq = setmetatable({
        -- client_id = '1105574772', 
        -- client_secret = 'n6CwihTrv68bJkcz', 
        client_id = '101337042', 
        client_secret = '46310704a4a3295844bf397dd7a3807f', 
        redirect_uri = 'http://www.httper.cn/oauth2/qq',  
        authorize_uri = 'https://graph.qq.com/oauth2.0/authorize', 
        token_uri = 'https://graph.qq.com/oauth2.0/token', 
        me_uri = 'https://graph.qq.com/oauth2.0/me', 
        info_uri = 'https://graph.qq.com/user/get_user_info', 
        user_info_uri = 'https://graph.qq.com/user/get_user_info', 
    }, {__call=caller})
function qq.new(self, init)
    init = init or {}
    self.__index = self
    self.__call = caller
    return setmetatable(init, self)
end
function qq.initialize(self)
    self.login_redirect_uri = self:get_login_redirect_uri()
    self.client = http:new()
    return self
end
function qq.get_login_redirect_uri(self)
    return self.authorize_uri..'?'..encode_args{response_type='code', 
        client_id=self.client_id, redirect_uri=self.redirect_uri}
end
qq.initialize(qq)
-- {
--   "body"    : "access_token=5A7E1A50ED8FF900A58BDBD283C0AE3D&expires_in=7776000&refresh_token=AA851E53744FA5CE43A24722B4FB78D1",
--   "body_reader": "function: 0x40f92d60",
--   "has_body": "true",
--   "headers" : {\\table: 0x40f922d8
--                  "Cache-Control": "no-cache",
--                  "Connection": "keep-alive",
--                  "Content-Length": "111",
--                  "Content-Type": "text/html",
--                  "Date"    : "Thu, 21 Jul 2016 08:13:33 GMT",
--                  "Keep-Alive": "timeout=50",
--                  "Server"  : "tws",
--                },
--   "read_body": "function: 0x40f91058",
--   "read_trailers": "function: 0x40f910c0",
--   "reason"  : "OK",
--   "status"  : 200,
-- }
function qq.get_access_token(self, code)
    local uri = self.token_uri..'?'..encode_args{grant_type='authorization_code', 
        client_id=self.client_id, client_secret=self.client_secret, 
        code=code, redirect_uri=self.redirect_uri}
    local res, err = self.client:request_uri(uri, {ssl_verify = false})
    if not res then
        return nil, err
    end
    local body = decode_args(res.body)
    return body.access_token
end
-- callback( {"client_id":"101337042","openid":"2137B3472EE5068BABF950D73669821F"} );
function qq.get_openid(self, access_token)
    local uri = self.me_uri..'?access_token='..access_token
    local res, err = self.client:request_uri(uri, {ssl_verify = false})
    if not res then
        return nil, err
    end
    local openid = match(res.body, [["openid":"(.+?)"]])[1]
    --log('openid', openid)
    return openid
end
-- user:{\\table: 0x40e80778
--   "city"    : "成都",
--   "figureurl": "http://qzapp.qlogo.cn/qzapp/101337042/2137B3472EE5068BABF950D73669821F/30",
--   "figureurl_1": "http://qzapp.qlogo.cn/qzapp/101337042/2137B3472EE5068BABF950D73669821F/50",
--   "figureurl_2": "http://qzapp.qlogo.cn/qzapp/101337042/2137B3472EE5068BABF950D73669821F/100",
--   "figureurl_qq_1": "http://q.qlogo.cn/qqapp/101337042/2137B3472EE5068BABF950D73669821F/40",
--   "figureurl_qq_2": "http://q.qlogo.cn/qqapp/101337042/2137B3472EE5068BABF950D73669821F/100",
--   "gender"  : "男",
--   "is_lost" : 0,
--   "is_yellow_vip": "0",
--   "is_yellow_year_vip": "0",
--   "level"   : "0",
--   "msg"     : "",
--   "nickname": "楠字数补丁也",
--   "province": "四川",
--   "ret"     : 0,
--   "vip"     : "0",
--   "year"    : "1987",
--   "yellow_vip_level": "0",
-- }
function qq.get_user_info(self, openid, access_token)
    local uri = self.user_info_uri..'?'..encode_args{openid=openid, 
        access_token=access_token, oauth_consumer_key=self.client_id}
    local res, err = self.client:request_uri(uri, {ssl_verify = false})
    if not res then
        return nil, err
    end
    local info = decode(res.body)
    return {username=info.nickname, avatar=info.figureurl_qq_2, openid=openid}
end

local github = setmetatable({
        client_id = '35350283921fce581eb6', 
        client_secret = '75f3157ee95cd436b37ce484b9733beedcfcad66', 
        redirect_uri = 'http://www.httper.cn/oauth2/github',  
        authorize_uri = 'https://github.com/login/oauth/authorize', 
        token_uri = 'https://github.com/login/oauth/access_token', 
        me_uri = 'https://api.github.com/user', 
        -- user_info_uri = 'https://graph.qq.com/user/get_user_info', 
    }, {__call=caller})
function github.new(self, init)
    init = init or {}
    self.__index = self
    self.__call = caller
    return setmetatable(init, self)
end
function github.initialize(self)
    self.client = http:new()
    self.login_redirect_uri = self:get_login_redirect_uri()
    return self
end
function github.get_login_redirect_uri(self, redi)
    return self.authorize_uri..'?'..encode_args{response_type='code', 
        client_id=self.client_id, redirect_uri=self.redirect_uri..'?redirect_uri='..(redi or '/')}
end
github.login_redirect_uri = github:get_login_redirect_uri()
function github.get_access_token(self, code)
    local uri = self.token_uri..'?'..encode_args{grant_type='authorization_code', 
        client_id=self.client_id, client_secret=self.client_secret, 
        code=code, redirect_uri=self.redirect_uri}
    local res, err = self.client:request_uri(uri, {ssl_verify = false})
    if not res then
        return nil, err
    end
    local body = decode_args(res.body)
    return body.access_token
end
-- "res:" {\\table: 0x40e26e30
     -- "body":{\\table: 0x40de7418
     --          "avatar_url": "https://avatars.githubusercontent.com/u/8246344?v=3",
     --          "bio"     : "userdata: NULL",
     --          "blog"    : "userdata: NULL",
     --          "company" : "userdata: NULL",
     --          "created_at": "2014-07-23T13:21:36Z",
     --          "email"   : "280145668@qq.com",
     --          "events_url": "https://api.github.com/users/pronan/events{/privacy}",
     --          "followers": 0,
     --          "followers_url": "https://api.github.com/users/pronan/followers",
     --          "following": 0,
     --          "following_url": "https://api.github.com/users/pronan/following{/other_user}",
     --          "gists_url": "https://api.github.com/users/pronan/gists{/gist_id}",
     --          "gravatar_id": "",
     --          "hireable": "userdata: NULL",
     --          "html_url": "https://github.com/pronan",
     --          "id"      : 8246344,
     --          "location": "China",
     --          "login"   : "pronan",
     --          "name"    : "zhuanyenan",
     --          "organizations_url": "https://api.github.com/users/pronan/orgs",
     --          "public_gists": 0,
     --          "public_repos": 22,
     --          "received_events_url": "https://api.github.com/users/pronan/received_events",
     --          "repos_url": "https://api.github.com/users/pronan/repos",
     --          "site_admin": "false",
     --          "starred_url": "https://api.github.com/users/pronan/starred{/owner}{/repo}",
     --          "subscriptions_url": "https://api.github.com/users/pronan/subscriptions",
     --          "type"    : "User",
     --          "updated_at": "2016-07-22T09:35:22Z",
     --          "url"     : "https://api.github.com/users/pronan",
     --        }, 
--   "body_reader": "function: 0x40e26de8",
--   "has_body": "true",
--   "headers" : {\\table: 0x40e24d08
--                  "Access-Control-Allow-Origin": "*",
--                  "Access-Control-Expose-Headers": "ETag, Link, X-GitHub-OTP, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, X-OAuth-Scopes, X-Accepted-OAuth-Scopes, X-Poll-Interval",
--                  "Cache-Control": "private, max-age=60, s-maxage=60",
--                  "Content-Length": "1103",
--                  "Content-Security-Policy": "default-src 'none'",
--                  "Content-Type": "application/json; charset=utf-8",
--                  "Date"    : "Fri, 22 Jul 2016 07:46:02 GMT",
--                  "ETag"    : ""ab7788943261207f5b7d01756a541aeb"",
--                  "Last-Modified": "Wed, 06 Jul 2016 01:01:25 GMT",
--                  "Server"  : "GitHub.com",
--                  "Status"  : "200 OK",
--                  "Strict-Transport-Security": "max-age=31536000; includeSubdomains; preload",
--                  "Vary"    : {\\table: 0x40e269a8
--                                 1: "Accept, Authorization, Cookie, X-GitHub-OTP",
--                                 2: "Accept-Encoding",
--                               },
--                  "X-Accepted-OAuth-Scopes": " ",
--                  "X-Content-Type-Options": "nosniff",
--                  "X-Frame-Options": "deny",
--                  "X-GitHub-Media-Type": "github.v3; format=json",
--                  "X-GitHub-Request-Id": "781967D5:1166:61C57E3:5791CF3A",
--                  "X-OAuth-Client-Id": "35350283921fce581eb6",
--                  "X-OAuth-Scopes": " ",
--                  "X-RateLimit-Limit": "5000",
--                  "X-RateLimit-Remaining": "4999",
--                  "X-RateLimit-Reset": "1469177162",
--                  "X-Served-By": "d594a23ec74671eba905bf91ef329026",
--                  "X-XSS-Protection": "1; mode=block",
--                },
--   "read_body": "function: 0x40e1e2e8",
--   "read_trailers": "function: 0x40e1e350",
--   "reason"  : "OK",
--   "status"  : 200,
-- } 
-- function github.get_openid(self, access_token)
--     local client = http:new()
--     local uri = self.me_uri..'?access_token='..access_token
--     local res, err = client:request_uri(uri, {ssl_verify = false})
--     log('res:', res, 'err:', err)
--     local openid = match(res.body, [["openid":"(.+?)"]])[1]
--     --log('openid', openid)
--     return openid
-- end

function github.get_user_info(self, access_token)
    local uri = self.me_uri..'?access_token='..access_token
    local res, err = self.client:request_uri(uri, {ssl_verify = false})
    if not res then
        return nil, err
    end
    local info = decode(res.body)
    return {username=info.name, avatar=info.avatar_url, openid=tostring(info.id)}
end

return {
    qq = qq, 
    github = github, 
}