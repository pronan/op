local ffi = require("ffi")
ffi.cdef[[
typedef uint32_t time_t;
typedef struct tm {
  int second;        /* Seconds. [0-60] (1 leap second) */
  int minute;        /* Minutes. [0-59] */
  int hour;          /* Hours.   [0-23] */
  int day;           /* Day.     [1-31] */
  int month;         /* Month.   [0-11] */
  int year;          /* Year - 1900.  */
  int wday;          /* Day of week. [0-6] */
  int yday;          /* Days in year.[0-365] */
  int isdst;         /* DST.     [-1/0/1]*/
  long int gmtoff;   /* Seconds east of UTC.  */
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

local function gmtime(timestamp)
    local timestamp_ptr = time_t_ptr_constructor(timestamp)
    local tm_ptr = tm_ptr_constructor()
    ffi.C.gmtime_r(timestamp_ptr, tm_ptr)
    return tm_ptr[0]
end
local function localtime(timestamp)
    local timestamp_ptr = time_t_ptr_constructor(timestamp)
    local tm_ptr = tm_ptr_constructor()
    ffi.C.localtime_r(timestamp_ptr, tm_ptr)
    return tm_ptr[0]
end
local function mktime(tm)
    local tm_ptr = tm_ptr_constructor(tm)
    return ffi.C.mktime(tm_ptr)
end
local function asctime(tm)
    -- 25 seems to be the min number that doesn't cause segmentation fault,
    -- here use 26 for safety.
    local buf = uint8_t_ptr_constructor(26)
    local tm_ptr = tm_ptr_constructor(tm)
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
      tm.year+1900, 
      zerofill(tm.month+1), 
      zerofill(tm.day), 
      zerofill(tm.hour), 
      zerofill(tm.minute), 
      zerofill(tm.second))
end