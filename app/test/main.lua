local aes          = require "resty.aes"
local cip          = aes.cipher
local hashes       = aes.hash

ngx.header.content_type = 'text/plain; charset=utf-8'
local key = '623q4hR325t36VsCD3g567922IC0073T'
local salt = nil
local text = 'hello, I am...'
local cip = aes:new(key, salt)
local cip2 = aes:new(key, salt)
local en = cip:encrypt(text)
local en2 = cip2:encrypt(text)
local de = cip2:decrypt(en)
local de2 = cip2:decrypt(en2)



say('en :'..repr(ngx.encode_base64(en))..' de:'..repr(de)) 
say('en2:'..repr(ngx.encode_base64(en2))..' de2:'..repr(de2)) 
