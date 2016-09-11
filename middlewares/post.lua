local get_post = require"resty.reqargs"

local function before(request)
    request.GET, request.POST, request.FILES = get_post{}
end
 -- {\\table: 0x001bbb50
 --               "file": "wyj.JPG",  -- or ''
 --               "name": "avatar",
 --               "size": 40509,
 --               "temp": "\s8rk.n",
 --               "type": "image/jpeg",
 --             },
local function after(request)
    for k, v in pairs(request.FILES) do
        os.remove(v.temp)
    end
end
return { before=before, after=after}