
-- google brotli ffi binding
-- Written by Soojin Nam. Public Domain.


local ffi = require "ffi"

local C = ffi.C
local ffi_new = ffi.new
local ffi_load = ffi.load
local ffi_str = ffi.string
local ffi_typeof = ffi.typeof

local assert = assert
local tonumber = tonumber
local tab_concat = table.concat
local tab_insert = table.insert
local setmetatable = setmetatable


ffi.cdef[[
typedef enum {
  BROTLI_DECODER_RESULT_ERROR = 0,
  BROTLI_DECODER_RESULT_SUCCESS = 1,
  BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT = 2,
  BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT = 3
} BrotliDecoderResult;

typedef void* (*brotli_alloc_func)(void* opaque, size_t size);
typedef void (*brotli_free_func)(void* opaque, void* address);

typedef struct BrotliDecoderStateStruct BrotliDecoderState;

BrotliDecoderState* BrotliDecoderCreateInstance(
    brotli_alloc_func alloc_func, brotli_free_func free_func, void* opaque);

void BrotliDecoderDestroyInstance(BrotliDecoderState* state);

BrotliDecoderResult BrotliDecoderDecompressStream(
  BrotliDecoderState* state, 
  size_t* available_in, const uint8_t** next_in,
  size_t* available_out, uint8_t** next_out,
  size_t* total_out);

int BrotliDecoderIsUsed(const BrotliDecoderState* state);

int BrotliDecoderIsFinished(const BrotliDecoderState* state);

uint32_t BrotliDecoderVersion(void);
]]


local _M = { _VERSION = '0.2.0' }


local mt = { __index = _M }


local arr_utint8_t = ffi_typeof("uint8_t[?]")
local pptr_utint8_t = ffi_typeof("uint8_t*[1]")
local pptr_const_utint8_t = ffi_typeof("const uint8_t*[1]")
local ptr_size_t = ffi_typeof("size_t[1]")


local BROTLI_TRUE = 1
local BROTLI_FALSE = 0

local _BUFFER_SIZE = 65536


local brotlidec = ffi_load("brotlidec")


local function _createInstance ()
   local state = brotlidec.BrotliDecoderCreateInstance(nil, nil, nil)
   if not state then
      return nil, "out of memory: cannot create decoder instance"
   end
   return state
end


local function _decompress_stream (encoded_buffer, state)
   local bufsize = _BUFFER_SIZE
   local available_in = ffi_new(ptr_size_t, #encoded_buffer)
   local next_in = ffi_new(pptr_const_utint8_t)
   next_in[0] = encoded_buffer
   local buffer = ffi_new(arr_utint8_t, bufsize)

   local decoded_buffer = {}
   local ret = C.BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT
   while ret == C.BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT do
      local available_out = ffi_new(ptr_size_t, bufsize)
      local next_out = ffi_new(pptr_utint8_t, buffer)
      ret = brotlidec.BrotliDecoderDecompressStream(state,
                                                    available_in, next_in,
                                                    available_out, next_out,
                                                    nil)
      local used_out = bufsize - available_out[0]
      if used_out ~= 0 then
         decoded_buffer[#decoded_buffer+1] = ffi_str(buffer, used_out)
      end
   end
   
   return ret, tab_concat(decoded_buffer)
end


function _M.new (self)
   local state, err = _createInstance()
   if not state then
      return nil, err
   end
   return setmetatable( { state = state }, mt)
end


function _M.destroy (self)
   brotlidec.BrotliDecoderDestroyInstance(self.state)
end


function _M.decompress (self, encoded_buffer)
   local state = _createInstance()
   local ret, buffer = _decompress_stream(encoded_buffer, state)
   assert(ret == C.BROTLI_DECODER_RESULT_SUCCESS)
   brotlidec.BrotliDecoderDestroyInstance(state)   
   return buffer
end


function _M.decompressStream (self, encoded_buffer)
   local state = self.state
   local ret, buffer = _decompress_stream(encoded_buffer, state)
   self.status = ret
   return buffer
end


function _M.resultSuccess (self)
   return self.status == C.BROTLI_DECODER_RESULT_SUCCESS
end


function _M.isUsed (self)
   return brotlidec.BrotliDecoderIsUsed(self.state) == BROTLI_TRUE
end


function _M.isFinished (self)
   return brotlidec.BrotliDecoderIsFinished(self.state) == BROTLI_TRUE
end


function _M.version (self)
   return tonumber(brotlidec.BrotliDecoderVersion())
end


return _M
