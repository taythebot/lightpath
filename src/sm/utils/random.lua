local ffi = require "ffi"
local ffi_cdef = ffi.cdef
local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_typeof = ffi.typeof
local C = ffi.C
local randomseed = math.randomseed

ffi_cdef [[
typedef unsigned char u_char;
u_char * ngx_hex_dump(u_char *dst, const u_char *src, size_t len);
int RAND_bytes(u_char *buf, int num);
]]

local t = ffi_typeof "uint8_t[?]"

local M = {}

local function bytes(len, format)
    local s = ffi_new(t, len)
    C.RAND_bytes(s, len)
    if not s then
        return nil
    end
    if format == "hex" then
        local b = ffi_new(t, len * 2)
        C.ngx_hex_dump(b, s, len)
        return ffi_str(b, len * 2), true
    else
        return ffi_str(s, len), true
    end
end

function M.seed()
    local a, b, c, d = bytes(4):byte(1, 4)
    return randomseed(a * 0x1000000 + b * 0x10000 + c * 0x100 + d)
end

return M