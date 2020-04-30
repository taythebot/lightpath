local ffi = require('ffi')
local ffi_new = ffi.new
local ffi_string = ffi.string

ffi.cdef[[
    size_t entities_decode_html(char *dst, const char *src, size_t src_len);
]]


local _M = {
    _VERSION = '0.1.0'
}


local function find_shared_obj(cpath, so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open

    for k in string_gmatch(cpath, "[^;]+") do
        local so_path = string_match(k, "(.*/)")
        so_path = so_path .. so_name

        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io_open(so_path)
        if f ~= nil then
            io.close(f)
            return so_path
        end
    end
end


local setmetatable = setmetatable
local mt = { __index = _M }
local libhtmlentities


function _M.new()
    if libhtmlentities == nil then
        local so_path = find_shared_obj(package.cpath, "libhtmlentities.so")
        if so_path ~= nil then
            libhtmlentities = ffi.load(so_path)
        end
    end

    if libhtmlentities == nil then
        return nil, "fail to load libhtmlentities.so"
    end

    return setmetatable({}, mt)
end


function _M.decode(entities)
    local buf = ffi_new("char[?]", #entities)
    local size = libhtmlentities.entities_decode_html(buf, entities, #entities)

    return ffi_string(buf, size)
end


return _M
