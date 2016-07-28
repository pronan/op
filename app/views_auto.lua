local query = require"resty.model".RawQuery
local response = require"resty.response"
local User = require"app.models".User
local forms = require"app.forms"

local m={}
function m.register(req, kwargs)
    if req.user then
        return response.Redirect('/profile')
    end
    local form;
    if req.get_method()=='POST' then
        form = forms.UserForm{data=req.POST}
        if form:is_valid() then
            local cd=form.cleaned_data
            local user=User{username=cd.username, password=cd.password}:save()
            req.session.user=user
            req.session.messages = {'恭喜您, 注册成功!'}
            return response.Redirect('/profile')
        end
    else
        form = forms.UserForm{}
    end
    return response.Template("register.html", {form=form})
end
function m.login(req, kwargs)
    if req.user then
        return response.Redirect('/profile')
    end
    local form;
    if req.get_method()=='POST' then
        form = forms.LoginForm{data=req.POST}
        if form:is_valid() then
            req.session.user=form.user
            req.session.messages = {'欢迎您, '..form.user.username}
            return response.Redirect('/profile')
        end
    else
        form = forms.LoginForm{}
    end
    return response.Template("login.html", {form=form})
end
function m.form(req, kwargs)
    local form;
    if req.get_method()=='POST' then
        form = forms.TestForm{data=req.POST, files=req.FILES}
        if form:is_valid() then
            return response.Plain(repr(form))
        end
    else
        form = forms.TestForm{}
    end
    return response.Template("app/form.html", {form=form})
end
function m.edituser(req, kwargs)
    local form;
    if req.get_method()=='POST' then
        form = forms.UserForm{data=req.POST}
        if form:is_valid() then
            return response.Plain(repr(form))
        end
    else
        form = forms.UserForm{instance=User:get{id=2}}
    end
    return response.Template("app/form.html", {form=form})
end
function m.logout(req, kwargs)
    req.session.user = nil
    req.session.messages = {'您已退出'}
    return response.Redirect("/")
end
function m.error(req, kwargs)
    return response.Error("你出错了")
end
function m.profile(req, kwargs)
    return response.Template('profile.html', {})
end
function m.content(req, kwargs)
    req.session.messages = {'hello messages!'}
    return response.Plain('ok')
end
function m.editor(req, kwargs)
    return response.Template("editor.html", {sidebar = 'Profile'})
end
function m.pubkey(req, kwargs)
    return response.Plain([[ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDP1qeXu+VLnTZrd1FVNBHuwW/80mkCW3lxnPqc5g5G8tvC6JX5TcIrRHm2qet1CKBqZwFaMpCK8QqsdGcbiuuOm9YPoWkfEEX4ngEnL6HRH1fHCWvP1sUPO+yiKiPlXgjlQrgrghNULH3Y6azrw+VYL1Zihs6LZsm77r+hKa/mhe9FIBQQeSkmZpPff+SgVpTglE9Oi9bY8a/4kueAIrhlKq+4+0S8oX+fWJWuN0KwZV79wy7vmJ6KoL/OcRnqv7cWZXX5B3hCF9nK+j34stR62lu4vIYMrcsCMKJBjWRXHtdblEcWdxm3z579QVARtCDkTYAP0sTieshBV2My7Y8B 280145668@qq.com
]])
end
function m.key(req, kwargs)
    return response.Plain([[-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAz9anl7vlS502a3dRVTQR7sFv/NJpAlt5cZz6nOYORvLbwuiV
+U3CK0R5tqnrdQigamcBWjKQivEKrHRnG4rrjpvWD6FpHxBF+J4BJy+h0R9Xxwlr
z9bFDzvsoioj5V4I5UK4K4ITVCx92Oms68PlWC9WYobOi2bJu+6/oSmv5oXvRSAU
EHkpJmaT33/koFaU4JRPTovW2PGv+JLngCK4ZSqvuPtEvKF/n1iVrjdCsGVe/cMu
75ieiqC/znEZ6r+3FmV1+Qd4QhfZyvo9+LLUetpbuLyGDK3LAjCiQY1kVx7XW5RH
FncZt8+e/UFQEbQg5E2AD9LE4nrIQVdjMu2PAQIDAQABAoIBAHjiWtvwF2+hYxOi
dJXgEUYTEHW2VAlg9wPT0BgN3uP5QUTeTsyQI41S6JALyL1rZRI+ExVJL7UAebrQ
gWANrvBlR14T/bZpmqj+DaGjHLUrS7yiiCh8vGUd74ZqiDJSPU5LPh9gKqncrt3J
HCCM8goWjmIEEoIWKOO7+41bV8n1s05Kp5au9jEWUnXb0LFhHpGjH5P3Ir7/yTy4
7Uj+QCNU1dge1emzi2H9xaAbbIHtyRw9N7DnZdL6F0YYEQHHo8MlRCmlVjW4foVj
RUi3X21L1JnRlDc1Jz2w17ZfyXo3zIYrOp/a1BCCGQeQf6zpMpuQNDwrNdYTgBG9
bZP/GgECgYEA/C9mLkxvvPMecyZbYym5mE0XrNgVBxPGS2UEV0A5yrA5Z9RDdbU4
oFo4T6mrDkPkbn/pMBzOlnfEjjPok0/M13ESsIvS4q/jsCXvvaaVeBHhb4i9hMbi
f2HY1YrBCi8X8sU2+AuRHw0l8c2nZn9KomMDHLZsjFhH9fRVMslK4/ECgYEA0vuF
SQhSPrS1dCXi0dUOAOxJpvEUbljgmiBSqCVKc1S1lMxqPSQCjbNlExyERpoFzTE0
3PlYVqKAkpTNYlcIRhmAxFUcn2H93nd7LXWA54VAa/RskcFOLG5/ELmz8oB0WFgm
NJnmGcCwrXvUsiDyQwJ8vvPpOQ4XbsZljM03LBECgYAY+ykIFRJMiVjO11HeNNfp
ullKCe2rUc4m0c7oRbhz15kYK/KyykzdtZI2cfw74YXTXGBhH7lnNl4GKCY10YXd
IZpUWsV9JydK37cr9kCAMGVAgy8i5ACz1aGBJcmRlLCun9KeJ6csiETl+xVGFf3y
sBQy1+9Qx735I0b9TOtaQQKBgHLU/whvBQSoKpLbBAcdJRAPi07XrD0bFrQMn7Bx
C4KWOnaQg8pfTRx+5aZvQPeEYV/7RkB3XkNZEw20+8xoflJZEyLJCFkfZqOs+FgX
ul9IwXWAhY8XXUsFoRcjW/PDQo/K+pBqqzidDgx+d5e0Iueh9O+hpfCt4MckKKVo
FH1hAoGAPAnSoMv6DGi0W0vZU/cl31AKT2Z8D7m5rdSxDRGLri45NLHBscbiZ9Gh
VyHHBL/WW3Y04P6NUCY8SNFzBjo3MU7rRrwutop7GPkjxV7MsAQ2BeBjxW7xmQ3A
T14kJpgJ3xTAM8kSPoRQB8qCUMOTxL25wsH0FRHtnIa7+fZVt+c=
-----END RSA PRIVATE KEY-----
]])
end
function m.hosts(req, kwargs)
    return response.Plain([[wdksw.com,120.25.103.213 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFmH35GRkf/9o5w66q6WBuNKrM7e2EYBtL4s+TVDcggCQrk9ueiCgnTo9AbWtDIczjm8Jx53ohx4RE3p7gxy8s8=
github.com,192.30.252.131 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
jarsj.cn,120.24.244.38 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFmH35GRkf/9o5w66q6WBuNKrM7e2EYBtL4s+TVDcggCQrk9ueiCgnTo9AbWtDIczjm8Jx53ohx4RE3p7gxy8s8=
120.24.194.166 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFmH35GRkf/9o5w66q6WBuNKrM7e2EYBtL4s+TVDcggCQrk9ueiCgnTo9AbWtDIczjm8Jx53ohx4RE3p7gxy8s8=
git.oschina.net,101.201.240.226 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMuEoYdx6to5oxR60IWj8uoe1aI0X1fKOHWOtLqTg1tsLT1iFwXV5JmFjU46EzeMBV/6EmI1uaRI6HiEPtPtJHE=
bitbucket.org,104.192.143.2 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
104.192.143.3 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
104.192.143.1 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
192.30.252.130 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
192.30.252.120 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
git.coding.net,116.55.237.19 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHOWdwLpkos2CLli6DFvQ36yQE6Pe/PtFp3XwyirfZCIoGWnedaWI8zkJWVCs0wgOB9/urFepTDfV2wN49KGy1sl2/CCDEH2K/zeoEAZlTcBrhU17bwg1yMHCyJ7IM+zdLzItDEKYjgoWqVdUGK1dXQQlwt7GP4W7HqffelQQoVxOMoZ5N50MzD+nvV4y8iq0KwDQNy62iU4hui9ajCSVUDLu/06ucd5IojSI9keRIYAXvQf52TJ5EbvoBggp9RhjuWNEG8IhnPP6rzPS11Ocmwg/HsP8xOKL28AeDBAh6B6MEBDtlyp5Yfu9cwZJ9CFtU/x5fHFPtANmgIphAfwN1
jasygl.cn ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFmH35GRkf/9o5w66q6WBuNKrM7e2EYBtL4s+TVDcggCQrk9ueiCgnTo9AbWtDIczjm8Jx53ohx4RE3p7gxy8s8=
192.30.252.121 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
192.30.252.123 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
192.30.252.129 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
192.30.252.128 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
192.30.252.122 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
]])
end

function m.sql(kwargs)
    local u = require"app.models".User
    -- for i,v in ipairs(-u:where{id=1}) do
    --     v.name = 'wwwwwwwwwwwww'
    --     v:save()
    -- end
    local statements = {
        u:where{id = 1}, 
        -- u:where{name='Xihn'}, 
        -- u:select{'id', 'name', 'age'}:where{id__in={1, 2, 6}, age__gte=18}, 
        -- u:select{}:where'id <10 and (sex=1 or age>50)', 
        -- u:select{'sex','count(*) as cnt'}:group'sex':order'cnt desc'
        --u:update{age=888}:where{name='has'}, 

        --u:order'name':select'name, count(*) as cnt':group'name desc', 
        --u:create{age=5, name='yaoming', sex=1}, 
        --u:select"sex, count(*) as cnt":group"sex"
    }
    local tables = {}
    local sqls = {}
    local errors = {}
    for i,v in ipairs(statements) do
        res, err, errno, sqlstate = v:exec()
        sqls[#sqls+1] = v:to_sql() or ''
        tables[#tables+1] = res or {}
        errors[#errors+1] = err or ''
    end
    -- for i,user in ipairs(u:select{'id', 'name', 'age'}:where{id__in={1, 2, 6}, age__gte=18}:exec()) do
    --     user.name = 'Emacs'
    --     user:save()
    -- end
    -- insert_id   0   number
    -- server_status   2   number
    -- warning_count   0   number
    -- affected_rows   1   number
    -- message   (Rows matched: 1  Changed: 0  Warnings: 0   string
    --local res, err = u:update{age=25, name='ppaoloe', sex=2}:where{id = 33}:exec()
    -- local new_user, err = u:create{age = 100, name = 'mmmm', sex = 1}:exec()
    -- new_user.age = 1011
    -- new_user.name = 'xmxmxmxm'
    -- new_user:save()
    -- local res, err = u:get{id = 333}
    -- res.name = 'pjlxx'
    -- res:save()
    -- for i,v in ipairs(-u:where{id__gte=30}:order"age desc") do
    --     say(repr(v), '<br>')
    -- end
    --local res, err = query('delete from user where id=333')
    -- for i,v in pairs(res) do
    --     say(string.format('%s   %s   %s', i,v, type(v)))
    -- end
    return render"app/home.html"{tables=tables, sqls=sqls, errors=errors, len=#statements}
    --return nil
end
function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    local u = require"app.models".User
    local users = u:where{name='yao'}:to_sql()
    say(encode{res=users}) 
end
local function ran(step)
    step = step or 10
    int, _ = math.modf(math.random()*step, step)
    return int
end

--     create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, 
-- Incorrect table definition; there can be only one TIMESTAMP column with CURRENT_TIMESTAMP in DEFAULT or ON UPDATE clause,
function m.init( kw )
    local res, err = query("drop table if exists users")
    if not res then
        return nil, err
    end
    local res, err = query(
    [[create table users
    (
        id serial primary key,
        username varchar(30), 
        avatar varchar(200), 
        openid varchar(64), 
        password varchar(30)
    )default charset=utf8;]]
)
    if not res then
        return nil, err
    else
        return response.Plain'table is created'
    end
end
function m.users( req, kw )
    local users, err = User:all()
    if err then
        return nil, err
    end
    return render('users.html', {users=users})
end
function m.r(req, kwargs)
    return response.Plain(ngx.encode_args{a=1, b=2}..repr(ngx.decode_args'access_token=5A7E1A50ED8FF900A58BDBD283C0AE3D&expires_in=7776000&refresh_token=AA851E53744FA5CE43A24722B4FB78D1'))
end
return m