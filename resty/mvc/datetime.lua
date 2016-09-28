local ffi = require("ffi")
ffi.cdef[[
typedef long  time_t;
typedef struct tm {
  int sec;        /* secs. [0-60] (1 leap sec) */
  int min;        /* mins. [0-59] */
  int hour;          /* Hours.   [0-23] */
  int day;           /* Day.     [1-31] */
  int month;         /* Month.   [0-11] */
  int year;          /* Year - 1900.  */
  int wday;          /* Day of week. [0-6] */
  int yday;          /* Days in year.[0-365] */
  int isdst;         /* DST.     [-1/0/1]*/
  long int gmtoff;   /* secs east of UTC.  */
  const char* zone;  /* Timezone abbreviation.  */
} tm;
struct tm* gmtime_r   (const time_t*, struct tm*);
struct tm* localtime_r(const time_t*, struct tm*);
char*      asctime_r  (const struct tm*, char*);
time_t     mktime     (struct tm*);
]]

local p_tm_constructor = ffi.typeof("struct tm[1]")
local tm_constructor = ffi.typeof("struct tm")
local p_time_t_constructor = ffi.typeof("time_t[1]")
local p_uint8_t_constructor = ffi.typeof("uint8_t[?]")

local function gmtime(timestamp)
    return ffi.C.gmtime_r(
        p_time_t_constructor(timestamp), 
        tm_constructor())
end
local function localtime(timestamp)
    return ffi.C.localtime_r(
        p_time_t_constructor(timestamp), 
        tm_constructor())
end
local function mktime(r)
    return ffi.C.mktime(r)
end


local function asctime(tm)
    local buf = p_uint8_t_constructor(26)
    ffi.C.asctime_r(tm, buf)
    return ffi.string(buf)
end

local function zerofill(num)
    if num < 10 then
        return string.format('0%d',num)
    end
    return tostring(num)
end
local function strfmt(tm)
  return string.format('%d-%s-%s %s:%s:%s', 
      tm.year, 
      zerofill(tm.month), 
      zerofill(tm.day), 
      zerofill(tm.hour), 
      zerofill(tm.min), 
      zerofill(tm.sec))
end


local function lookup(t, k)
    --if k=='string' then 

        
        
end
local function sub(t, o)

end
local delta = {
  sec  = 1, 
  min  = 60, 
  hour = 60*60, 
  day  = 60*60*24, 
  month= 60*60*24*30, 
  year = 60*60*24*30*12, 
}

local  dt = {
  __index = lookup, 
}
function  dt.new(cls, arg)        
    local self = {[type(arg)]=arg}
    return setmetatable(self, cls)
end


local t = 1417472847
local t2= delta.day*366+t

print(t)
--print(strfmt(gmtime(t)))
print(strfmt(gmtime(t2)))
d = localtime(t)

print(strfmt(d))
print(mktime(d))
print(asctime(d))

--local d=tm_constructor(50)
print(mktime(d))
local function test(...)
    local times=300000
    t1=os.time()
    for i=1,times do
        local a=os.time(d)
    end
    t2=os.time()
    for i=1,times do
        local a=mktime(d)
    end
    t3=os.time()
    print(mktime(d)==os.time(d))
    print(t2-t1)
    print(t3-t2)
end


