local ngx_re = require 'ngx.re'
local md5 = require 'resty.md5'
local str = require 'resty.string'
local http = require 'resty.http'
local cjson = require 'cjson'
local uuid = require 'resty.jit-uuid'
local mp = require 'MessagePack'
local s3_client = require 'sm.utils.s3'

local ngx_req_get_headers = ngx.req.get_headers
local ngx_req_get_method = ngx.req.get_method
local ngx_req_remote_addr = ngx.req.remote_addr
local ngx_unescape_uri = ngx.unescape_uri

local log = ngx.log
local OK = ngx.OK
local ERR = ngx.ERR

-- Global response chunk size
local chunk_size = 10485760

local M = {}

-- Initialize md5
local function md5_init()
	if not M.md5 then
		local md5 = md5:new()

		if not md5 then
			return nil, '[Mlcache] Failed to initialize MD5 instance'
		end

		M.md5 = md5
	end

	return
end

-- Sort request uri args
local function sort_args(input)
    local args_table = input
    local args_name = {}
    local newargs = {}

    for name, value in pairs(args_table) do
        if type(value) == 'table' then
            for k, v in pairs(value) do
                table.insert(newargs, name .. '=' .. value[k])
            end
        else
            table.insert(args_name, name)
        end
    end

    for _, name in ipairs(args_name) do
    	-- Lowercase and escape uri
        table.insert(newargs, string.lower(ngx_unescape_uri(name)) .. '=' .. string.lower(ngx_unescape_uri(args_table[name])))
    end
   
    table.sort(newargs) --Sort the table into order

    local output = table.concat(newargs, '&')

    return output --set the args to be the output
end

-- Prepare cache key
function M.prepare_key(backend, uri, uri_args, cache_query)
	local key = backend
	local slice_range = ngx.var.slice_range

	if cache_query == '1' then
		-- Ignore query string
		if next(uri_args) ~= nil then
			-- Get file path without uri
			local res, err = ngx_re.split(uri, '^(.*)\\?(.*)$')

			key = key .. res[2] or uri
		else
			key = key .. uri
		end
	elseif cache_query == '2' then
		-- Sorted query string
		if next(uri_args) ~= nil then
			-- Sort query string
			local sorted_args = sort_args(uri_args)

			-- Get file path without uri
			local res, err = ngx_re.split(uri, '^(.*)\\?(.*)$')

			if res then
				key = key .. res[2] .. '?' .. sorted_args
			else
				key = key .. uri
			end
		else
			key = key .. uri
		end
	else
		-- Use same query string and fallback
		key = key .. uri
	end

	-- Add byte range
	if slice_range then
		key = key .. ngx.var.slice_range
	end

	-- Always call MD5 init
	md5_init()

	local md5 = M.md5

	local ok = md5:update(key)

	if not ok then
		return nil, 'Failed to update MD5 object'
	end

	local digest = md5:final()

	if not digest then
		return nil, 'Failed to finialize MD5 object'
	end

	return str.to_hex(digest)
end

-- Get item from cache library
function M.get(redis, key, https, backend, port, path, ttl, image_compression)
	-- Attempt to fetch metadata
	local res, err = redis.hgetall(key)

	if res then
		-- Fetch item from cache
		local ok, err = M.fetch_from_cache(redis, key, res, ttl, image_compression)

		if not ok then
			log(ERR, 'Failed to fetch from cache: ' .. err)
		end	
	end

	-- Always fetch from origin as fallback
	local ok, err = M.fetch_from_origin(redis, key, https, backend, port, path, ttl, image_compression)

	if not ok then
		return nil, 'Failed to fetch from origin: ' .. err
	end

	return true, nil
end

-- Fetch item from global cache storage
function M.fetch_from_cache(redis, key, res, ttl)
	-- Unpack metadata
	local metadata = cjson.decode(mp.unpack(res['metadata']))

	-- Set general response headers
	ngx.header['X-Cache-Status'] = 'HIT'
	ngx.header['X-Cache-TTL'] = ttl
	ngx.header['X-Cache-Item'] = key
	ngx.header['Cache-Control'] = 'max-age=' .. ttl
	ngx.header['Accept-Ranges'] = 'bytes'

	-- Get range header	
	local range_header = ngx_req_get_headers()['range']

	-- Validate range header
	if range_header then
		local start = 0
		local stop = -1

		-- Parse range header with regex
		local matches, err = ngx.re.match(range_header, '^bytes=(\\d+)?-([^\\\\]\\d+)?', 'joi')

		if matches then
			-- Range sanity check
			if matches[1] == nil and matches[2] then
				stop = (metadata['Content-Length'] - 1)
				start = (stop - matches[2]) + 1 
			else
				start = matches[1] or 0
				stop = matches[2] or (metadata['Content-Length'] - 1) 
			end

			-- Make sure requested range is valid
			if tonumber(start) > tonumber(metadata['Content-Length']) or tonumber(stop) > tonumber(metadata['Content-Length'])  then
				ngx.header['Content-Range'] = 'bytes */' .. metadata['Content-Length']
				ngx.status = 416
				return ngx.exit(ngx.OK)
			end
		else
			stop = (metadata['Content-Length'] - 1)
		end

		-- Set status code and response headers for range request
		ngx.status = 206
		ngx.header['Content-Length'] = (stop - (start - 1))
		ngx.header['Content-Range'] = 'bytes ' .. start .. '-' .. stop .. '/' .. metadata['Content-Length']
	else
		-- Set status code and response header for normal request
		ngx.status = 200
		ngx.header['Content-Length'] = metadata['Content-Length']
		ngx.header['Content-Type'] = metadata['Content-Type']
	end

	log(OK, 'Will perform ', res['parts'], ' rounds to fetch data')

	-- Fetch from Redis storage
	if res['hot'] == '1' then
		-- Loop through number of parts and fetch chunks
		for i = 1, res['parts'], 1 do
			local chunk_key = key .. '_' .. i

			log(OK, 'Fetching chunk ', chunk_key, ' from Redis')

			-- Fetch from redis
			local chunk, err = redis.get(chunk_key)

			-- Handle error here
			if not chunk or chunk == ngx.null then
				return nil, 'Error occurred while fetching chunk from Redis ' .. chunk_key .. ' : ' .. err
			end

			-- Return chunk to uesr
			ngx.print(chunk)
			ngx.flush(true)
		end
	else
		-- Fetch from S3 storage

		-- Init s3 client
		local s3, err = s3_client:new('minioadmin', 'minioadmin', 'cdn', '172.18.0.3', 9000, 20000)

		if not s3 then
			log(ERR, err)
			return nil, 'Error occurred while initiating S3 client: ' .. err
		end

		log(OK, 'Fetching key ', key, ' from S3')

		-- Fetch from minio
		local res, httpc, err = s3:get(key, range_header)

		-- Handle error here
		if err then
			return nil, 'Error occured while fetching chunk from S3: ' .. err
		end

		-- Invalid status code recieved, return and fallback to origin
		if res.status ~= 200 and res.status ~= 206 then
			return nil, 'Invalid status code received from S3: ', res.status
		end

		log(OK, 'Status Code: ', res.status)
		log(OK, 'Chunk received #', res.headers['content-length'])

		-- Chunk response back to user
		local reader = res.body_reader

		repeat
			-- Read body by global chunk size
			local chunk, err = reader(chunk_size)

			if err then
				return nil, 'Error occurred while chunking response from S3: ' .. err
			end

			if chunk then
				ngx.print(chunk)
				ngx.flush(true)
			end
		until not chunk

		-- Keep S3 connection alive for future use
		local ok, err = httpc:set_keepalive()

		if not ok then
			log(ERR, 'Failed to set keep alive for S3: ', err)
		end
	end

	-- Always close Redis connection
	redis.close()

	-- Exit nginx with proper exit code
	if ngx.status == 206 then
		return ngx.exit(ngx.HTTP_PARTIAL_CONTENT)
	else
		return ngx.exit(ngx.OK)
	end
end

-- Fetch item from origin
function M.fetch_from_origin(redis, key, https, backend, port, path, ttl)
	-- Set basic response headers
	ngx.header['Cache-Control'] = 'no-cache'
	ngx.header['X-Cache-Status'] = 'MISS'
	ngx.header['X-Cache-TTL'] = 0

	-- Compile headers
	local headers = ngx_req_get_headers()
	headers['X-Forwarded-For'] = ngx_req_remote_addr

	-- Make HTTP request
	local httpc = http.new()

	-- Set timeout
	httpc:set_timeout(10000)

	-- Connect to origin
	httpc:connect(backend, port)

	-- Perform SSL handshake
	if https == '1' then
		local ok, err = httpc:ssl_handshake(nil, backend, false)

		if not ok then
			return nil, 'Failed to perform SSL handshake with origin: ' .. err
		end
	end

	-- Make origin request
	local method = ngx_req_get_method()
	local res, err = httpc:request({
		version = 1.1,
		path = path,
		method = method,
		headers = headers,
		ssl_verify = false
	})

	-- Request item to be cached if GET and status code is valid
	if method == 'GET' and (res.status == 200 or res.status == 206) then
		local ok, err = M.queue(redis, key, https, backend, port, path, ttl)

		if not ok then
			log(ERR, 'Failed to queue item for cache warmup: ', err)
		end
	end

	log(OK, 'Starting file chunking')
	local reader = res.body_reader
	local round = 1
	local downloaded = 0

	-- Set response headers from origin
	ngx.status = res.status
	ngx.header['Content-Length'] = res.headers['content-length']
	ngx.header['Content-Type'] = res.headers['content-type']
	ngx.header['Content-Range'] = res.headers['content-range']
	ngx.header['Accept-Ranges'] = res.headers['accept-ranges']

	repeat
		-- Read body by global chunk size
		local chunk, err = reader(chunk_size)

		if err then
			return nil, 'Error occurred while chunking from origin: ' .. err
		end

		if chunk then
			downloaded = downloaded + #chunk
			ngx.log(ngx.OK, 'chunking #', #chunk, ', downloaded ', downloaded, ' out of ', res.headers['content-length'])
			ngx.print(chunk)
			ngx.flush(true)
		end
	until not chunk

	-- Keep connection alive for future use
	local ok, err = httpc:set_keepalive()

	if not ok then
		log(ERR, 'Failed to set keep alive for origin: ' .. err)
	end

	log(OK, 'Done fetching file')

	-- Exit nginx with proper exit code
	if ngx.status == 206 then
		return ngx.exit(ngx.HTTP_PARTIAL_CONTENT)
	else
		return ngx.exit(ngx.OK)
	end
end

-- Queue item for cache warmup
function M.queue(redis, key, https, backend, port, path, ttl)
	-- Ensure unique uuid generation
	uuid.seed()

	-- Prepare body
	local body = cjson.encode({{key, backend, port, https, path, ttl}, {}, {}})

	local msg = cjson.encode({
		['body'] = body,
		['content-encoding'] = 'utf-8',
		['content-type'] = 'application/json',
		['headers'] = {
			['task'] = 'worker.cache',
			['id'] = uuid()
		},
		['properties'] = {
			['delivery_info'] = {
				['exchange'] = 'celery',
				['routing_key'] = 'celery'
			},
			['delivery_tag'] = uuid()
		}
	})

	-- Add task to Redis
	local ok, err = redis.lpush('celery', msg)

	if not ok then
		return nil, err
	end

	return true, nil
end


return M