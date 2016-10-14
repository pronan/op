local is_windows = package.config:sub(1,1) == '\\'

-- a list of app names
local LIST = {}
-- directory where app lives, relative to nginx running path
-- you need to end with `\` or `/`
local DIR = 'apps/' 
-- if true, get all app names by scanning all directories in DIR
-- ignoring initial LIST value
local AUTO_SCAN_APPS = true 
local PACKAGE_PREFIX = 'apps.'

local scandir
if is_windows then
    function scandir(directory)
        local t, popen = {}, io.popen
        local pfile = popen('dir "'..directory..'" /b /ad')
        for filename in pfile:lines() do
            if not filename:find('__') then
                t[#t+1] = filename
            end
        end
        pfile:close()
        return t
    end
else
    function scandir(directory)
        local t, popen = {}, io.popen
        local pfile = popen('ls -l "'..directory..'" | grep ^d')
        for filename in pfile:lines() do
            if not filename:find('__') then
                t[#t+1] = filename:match(' (%w+)$')
            end
        end
        pfile:close()
        return t
    end
end
if AUTO_SCAN_APPS then
    LIST = scandir(DIR)
else
    assert(LIST and type(LIST) == 'table', 'you must provided a apps table.')
end



-- clean the constants
local e = DIR:sub(-1, -1)
if e ~= '/' or e ~= '\\' then
    DIR = DIR..'/'
end
if PACKAGE_PREFIX:sub(-1, -1) ~= '.' then
    PACKAGE_PREFIX = PACKAGE_PREFIX..'.'
end

return {
    LIST = LIST,
    DIR = DIR,
    PACKAGE_PREFIX = PACKAGE_PREFIX,
}