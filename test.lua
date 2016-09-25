-- https://linux.die.net/man/3/localtime_r

-- The localtime() function converts the calendar time timestamp to broken-down time 
-- representation, expressed relative to the user's specified timezone. The function 
-- acts as if it called tzset(3) and sets the external variables tzname with information 
-- about the current timezone, timezone with the difference between Coordinated 
-- Universal Time (UTC) and local standard time in seconds, and daylight to a 
-- nonzero value if daylight savings time rules apply during some part of the 
-- year. The return value points to a statically allocated struct which might be 
-- overwritten by subsequent calls to any of the date and time functions. 
-- The localtime_r() function does the same, but stores the data in a user-supplied 
-- struct. It need not set tzname, timezone, and daylight.

-- The asctime() function converts the broken-down time value tm into a null-terminated 
-- string with the same format as ctime(). The return value points to a statically 
-- allocated string which might be overwritten by subsequent calls to any of the 
-- date and time functions. The asctime_r() function does the same, but stores 
-- the string in a user-supplied buffer which should have room for at least 26 bytes.

-- The mktime() function modifies the fields of the tm structure as follows: 
-- tm_wday and tm_yday are set to values determined from the contents of the other 
-- fields; if structure members are outside their valid interval, they will be 
-- normalized (so that, for example, 40 October is changed into 9 November); 
-- tm_isdst is set (regardless of its initial value) to a positive value or to 0, 
-- respectively, to indicate whether DST is or is not in effect at the specified 
-- time. Calling mktime() also sets the external variable tzname with information 
-- about the current timezone.

-- If the specified broken-down time cannot be represented as calendar time 
-- (seconds since the Epoch), mktime() returns (time_t) -1 and does not alter the 
-- members of the broken-down time structure.

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

local tm_ptr_constructor = ffi.typeof("struct tm[1]")
local time_t_ptr_constructor = ffi.typeof("time_t[1]")
local function gmtime(timestamp)
    local timestamp_ptr = ffi.new("time_t[1]", timestamp)
    local tm_ptr = ffi.new("struct tm[1]")
    ffi.C.gmtime_r(timestamp_ptr, tm_ptr)
    return tm_ptr[0]
end
local function gmtime1(timestamp)
    local timestamp_ptr = time_t_ptr_constructor(timestamp)
    local tm_ptr = tm_ptr_constructor()
    ffi.C.gmtime_r(timestamp_ptr, tm_ptr)
    return tm_ptr[0]
end
local function gmtime2(timestamp)
    local timestamp_ptr = ffi.new("time_t[1]", timestamp)
    local tm = ffi.new("struct tm")
    ffi.C.gmtime_r(timestamp_ptr, tm)
    return tm
end
local function localtime(timestamp)
    local timestamp_ptr = ffi.new("time_t[1]", timestamp)
    local tm_ptr = ffi.new("struct tm[1]")
    ffi.C.localtime_r(timestamp_ptr, tm_ptr)
    return tm_ptr[0]
end
local function mktime(tm)
    if type(tm)~='cdata' then
        tm = ffi.new("struct tm", tm)
    end
    local tm_ptr = ffi.new("struct tm[1]", tm)
    return ffi.C.mktime(tm_ptr)
end
local function asctime(tm)
    -- 25 seems to be the min number that doesn't cause segmentation fault,
    -- here use 26 for safety.
    local buf = ffi.new("uint8_t[?]", 26)
    local tm_ptr = ffi.new("struct tm[1]",tm)
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

t1=os.time()
 for i=1,51344444 do
    r=gmtime(i)
 end
t2=os.time()
print(t2-t1)

t1=os.time()
 for i=1,51344444 do
    r=gmtime2(i)
 end
t2=os.time()
print(t2-t1)
-- local res = localtime(1474739796)
-- print(strfmt(res))
-- local res = gmtime(0)
-- print(strfmt(res))

-- local t = {
--     year=res.year, 
--     month=res.month, 
--     day=res.day, 
--     hour=res.hour, 
--     minute=res.minute, 
--     second=res.second, 
--     -- wday=res.wday, 
--     -- yday=res.yday, 
--     -- isdst=res.isdst,
--     -- zone=ffi.string(res.zone), 
--     -- gmtoff=res.gmtoff
-- }
-- print(mktime( res))
-- print(mktime( t))
-- print( asctime(res))
