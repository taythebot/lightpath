
-- google brotli ffi binding
-- Written by Soojin Nam. Public Domain.


local ffi = require "ffi"

local C = ffi.C
local ffi_gc = ffi.gc
local ffi_new = ffi.new
local ffi_load = ffi.load
local ffi_copy = ffi.copy
local ffi_str = ffi.string
local ffi_typeof = ffi.typeof

local assert = assert
local tonumber = tonumber
local tab_concat = table.concat
local tab_insert = table.insert
local setmetatable = setmetatable


ffi.cdef[[
void free(void *ptr);

typedef enum BrotliEncoderMode {
  BROTLI_MODE_GENERIC = 0,
  BROTLI_MODE_TEXT = 1,
  BROTLI_MODE_FONT = 2
} BrotliEncoderMode;

typedef enum BrotliEncoderOperation {
  BROTLI_OPERATION_PROCESS = 0,
  BROTLI_OPERATION_FLUSH = 1,
  BROTLI_OPERATION_FINISH = 2,
  BROTLI_OPERATION_EMIT_METADATA = 3
} BrotliEncoderOperation;

typedef enum BrotliEncoderParameter {
  BROTLI_PARAM_MODE = 0,
  BROTLI_PARAM_QUALITY = 1,
  BROTLI_PARAM_LGWIN = 2,
  BROTLI_PARAM_LGBLOCK = 3,
  BROTLI_PARAM_DISABLE_LITERAL_CONTEXT_MODELING = 4,
  BROTLI_PARAM_SIZE_HINT = 5
} BrotliEncoderParameter;

typedef void* (*brotli_alloc_func)(void* opaque, size_t size);
typedef void (*brotli_free_func)(void* opaque, void* address);

typedef struct BrotliEncoderStateStruct BrotliEncoderState;

BrotliEncoderState* BrotliEncoderCreateInstance(
    brotli_alloc_func alloc_func, brotli_free_func free_func, void* opaque);

int BrotliEncoderSetParameter(
    BrotliEncoderState* state, BrotliEncoderParameter param, uint32_t value);

int BrotliEncoderCompressStream(
    BrotliEncoderState* state, BrotliEncoderOperation op, size_t* available_in,
    const uint8_t** next_in, size_t* available_out, uint8_t** next_out,
    size_t* total_out);

size_t BrotliEncoderMaxCompressedSize(size_t input_size);

int BrotliEncoderCompress(
    int quality, int lgwin, BrotliEncoderMode mode, 
    size_t input_size, const uint8_t input_buffer[],
    size_t* encoded_size, uint8_t encoded_buffer[]);

int BrotliEncoderIsFinished(BrotliEncoderState* state);

int BrotliEncoderHasMoreOutput(BrotliEncoderState* state);

void BrotliEncoderDestroyInstance(BrotliEncoderState* state);

uint32_t BrotliEncoderVersion(void);
]]


local _M = { _VERSION = '0.2.0' }


local mt = { __index = _M }


local arr_utint8_t = ffi_typeof("uint8_t[?]")
local pptr_utint8_t = ffi_typeof("uint8_t*[1]")
local pptr_const_utint8_t = ffi_typeof("const uint8_t*[1]")
local ptr_size_t = ffi_typeof("size_t[1]")


local _BUFFER_SIZE = 65536
local BROTLI_TRUE = 1
local BROTLI_FALSE = 0
local BROTLI_DEFAULT_QUALITY = 11
local BROTLI_DEFAULT_WINDOW = 22
local BROTLI_DEFAULT_MODE = C.BROTLI_MODE_GENERIC


local brotlienc = ffi_load("brotlienc")


local function _createInstance (options)
   local state = brotlienc.BrotliEncoderCreateInstance(nil, nil, nil)
   if not state then
      return nil, "out of memory: cannot create encoder instance"
   end   
   brotlienc.BrotliEncoderSetParameter(state,
                                       C.BROTLI_PARAM_QUALITY, options.quality)
   brotlienc.BrotliEncoderSetParameter(state,
                                       C.BROTLI_PARAM_LGWIN, options.lgwin)
   return state
end


function _M.new (self, options)
   local options = options or {}
   options.lgwin = options.lgwin or BROTLI_DEFAULT_WINDOW
   options.quality = options.quality or BROTLI_DEFAULT_QUALITY
   options.mode = options.mode or BROTLI_DEFAULT_MODE

   local state, err = _createInstance(options)
   if not state then
      return nil, err
   end
   return setmetatable( { state = state, options = options }, mt)
end


function _M.destroy (self)
   brotlienc.BrotliEncoderDestroyInstance(self.state)
end


function _M.compress (self, input, options)
   local options = options or {}
   local quality = options.quality or self.options.quality
   local lgwin = options.lgwin or self.options.lgwin
   local mode = options.mode or self.options.mode
   local input_size = #input
   local n = brotlienc.BrotliEncoderMaxCompressedSize(input_size)
   local encoded_size = ffi_new(ptr_size_t, n)
   local encoded_buffer = ffi_new(arr_utint8_t, n)
   local ret = brotlienc.BrotliEncoderCompress(
      quality, lgwin, mode, input_size, input, encoded_size, encoded_buffer)

   assert(ret == BROTLI_TRUE)
   
   return ffi_str(encoded_buffer, encoded_size[0])
end


function _M.compressStream (self, str)
   local state = self.state
   local bufsize = _BUFFER_SIZE
   local buffer = ffi_new(arr_utint8_t, bufsize*2)
   if not buffer then
      return nil, "out of memory"
   end

   local input = buffer
   local output = buffer + bufsize
   local available_in = ffi_new(ptr_size_t, 0)
   local available_out = ffi_new(ptr_size_t, bufsize)
   local next_in = ffi_new(pptr_const_utint8_t)
   local next_out = ffi_new(pptr_utint8_t)
   next_out[0] = output
   local is_ok = true
   local is_eof = false
   
   local res = {}
   local len = #str
   local buff = ffi_new(arr_utint8_t, len, str)
   local p = buff
   
   while true do
      if available_in[0] == 0 and not is_eof then
         local read_size = bufsize
         if len <= bufsize then
            read_size = len
         end
         ffi_copy(input, ffi_str(p, read_size))
         available_in[0] = read_size
         next_in[0] = input
         len = len - read_size
         p = p + read_size
         is_eof = len <= 0
      end
      
      if brotlienc.BrotliEncoderCompressStream(
         state,
         is_eof and C.BROTLI_OPERATION_FINISH or C.BROTLI_OPERATION_PROCESS,
         available_in, next_in, available_out, next_out, nil) == BROTLI_FALSE
      then
         is_ok = false
         break
      end
      
      if available_out[0] ~= bufsize then
         local out_size = bufsize - available_out[0]

         tab_insert(res, ffi_str(output, out_size))
         available_out[0] = bufsize
         next_out[0] = output
      end

      if brotlienc.BrotliEncoderIsFinished(state) == BROTLI_TRUE then
         break
      end
   end

   if is_ok then
      return tab_concat(res)
   end
   
   return nil, "fail to compress"
end


function _M.isFinished (self)
   return brotlienc.BrotliEncoderIsFinished(self.state) == BROTLI_TRUE
end


function _M.hasMoreOutput (self)
   return brotlienc.BrotliEncoderHasMoreOutput(self.state) == BROTLI_TRUE
end


function _M.version (self)
   return tonumber(brotlienc.BrotliEncoderVersion())
end


return _M
