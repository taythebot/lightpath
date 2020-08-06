local balancer = require 'ngx.balancer'
local exit = require 'sm.utils.exit'

local server_id = os_getenv('SERVER_ID')

local remote_addr = ngx.var.remote_addr
local request_id = ngx.var.request_id
local backend_host = ngx.ctx.backend_host
local backend_port = ngx.ctx.backend_port

local ok, err = balancer.set_current_peer(backend_host, backend_port)

if not ok then
	return exit.error(remote_addr, request_id, '[Balancer] Failed to set upstream peer' .. err)
end