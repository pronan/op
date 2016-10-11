s=debug.getinfo(1,"S").source
print(s)
s='@./resty/mvc/response.lua'
x=s:match'^@(.*)response.lua$'
print(x)