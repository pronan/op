local get_post = require"resty.reqargs"

local function before(req, kwargs)
    req.GET, req.POST, req.FILES = get_post{}
end
 -- {\\table: 0x001bbb50
 --               "file": "wyj.JPG",  -- or ''
 --               "name": "avatar",
 --               "size": 40509,
 --               "temp": "\s8rk.n",
 --               "type": "image/jpeg",
 --             },
local function after(req, kwargs)
    for k, v in pairs(req.FILES) do
        os.remove(v.temp)
    end
end
return { before=before, after=after}