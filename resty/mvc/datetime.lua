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
-- local function gmtime(timestamp)
--     local timestamp_ptr = ffi.new("time_t[1]", timestamp)
--     local tm_ptr = ffi.new("struct tm[1]")
--     ffi.C.gmtime_r(timestamp_ptr, tm_ptr)
--     return tm_ptr[0]
-- end
-- local function gmtime(timestamp)
--     local timestamp_ptr = ffi.new("time_t[1]", timestamp)
--     local tm = ffi.new("struct tm")
--     ffi.C.gmtime_r(timestamp_ptr, tm)
--     return tm
-- end
local tm_ptr_constructor = ffi.typeof("struct tm[1]")
local time_t_ptr_constructor = ffi.typeof("time_t[1]")
local uint8_t_ptr_constructor = ffi.typeof("uint8_t[?]")



-- local function gmtime(timestamp)
--     local timestamp_ptr = ffi.new("time_t[1]", timestamp)
--     local tm_ptr = ffi.new("struct tm[1]")
--     ffi.C.gmtime_r(timestamp_ptr, tm_ptr)
--     local  r = tm_ptr[0]
--     return {
--         year  = r.year+1900, 
--         month = r.month+1,
--         day   = r.day,
--         hour  = r.hour,
--         min= r.min,
--         sec= r.sec,
--     }
-- end
-- local function localtime(timestamp)
--     local timestamp_ptr = ffi.new("time_t[1]", timestamp)
--     local tm_ptr = ffi.new("struct tm[1]")
--     ffi.C.localtime_r(timestamp_ptr, tm_ptr)
--     local  r = tm_ptr[0]
--     return {
--         year  = r.year+1900, 
--         month = r.month+1,
--         day   = r.day,
--         hour  = r.hour,
--         min= r.min,
--         sec= r.sec,
--     }
-- end

local function gmtime(timestamp)
    local timestamp_ptr = time_t_ptr_constructor(timestamp)
    local tm_ptr = tm_ptr_constructor()
    ffi.C.gmtime_r(timestamp_ptr, tm_ptr)
    local  r = tm_ptr[0]
    return {
        year  = r.year+1900, 
        month = r.month+1,
        day   = r.day,
        hour  = r.hour,
        min= r.min,
        sec= r.sec,
    }
end
local function localtime(timestamp)
    local timestamp_ptr = time_t_ptr_constructor(timestamp)
    local tm_ptr = tm_ptr_constructor()
    ffi.C.localtime_r(timestamp_ptr, tm_ptr)
    local  r = tm_ptr[0]
    return {
        year  = r.year+1900, 
        month = r.month+1,
        day   = r.day,
        hour  = r.hour,
        min= r.min,
        sec= r.sec,
    }
end

local function mktime(r)
    local tm = ffi.new("struct tm", {
        year  = r.year-1900, 
        month = r.month-1,
        day   = r.day,
        hour  = r.hour,
        min   = r.min,
        sec   = r.sec,
    })
    local tm_ptr = ffi.new("struct tm[1]",tm)
    return ffi.C.mktime(tm_ptr)
end
local function gmtime_ptr(timestamp)
    local timestamp_ptr = time_t_ptr_constructor(timestamp)
    local tm_ptr = tm_ptr_constructor()
    ffi.C.gmtime_r(timestamp_ptr, tm_ptr)
    return tm_ptr
end
local function mktime_ptr(tm_ptr)
    return ffi.C.mktime(tm_ptr)
end
local function asctime(tm)
    -- 25 seems to be the min number that doesn't cause segmentation fault,
    -- here use 26 for safety.
    local buf = ffi.new("uint8_t[?]", 26)
    local tm_ptr = ffi.new("struct tm[1]")
    ffi.C.asctime_r(tm_ptr, buf)
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

local t = 147472847

print(t)
print(strfmt(gmtime(t)))
d = localtime(t)
dp = gmtime_ptr(t)
print(strfmt(d))
print()

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

