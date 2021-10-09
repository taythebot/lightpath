local template = require "resty.template"

local remote_addr = ngx.var.remote_addr
local request_id = ngx.var.request_id
local ngx_status = ngx.status

local ngx_http_internal_error = ngx.HTTP_INTERNAL_SERVER_ERROR
local ngx_http_bad_gateway = ngx.HTTP_BAD_GATEWAY
local ngx_http_service_unavailable = ngx.HTTP_SERVICE_UNAVAILABLE
local ngx_http_gateway_timeout = ngx.HTTP_GATEWAY_TIMEOUT

local statuses = {
    [500] = {
        title = "Internal Server Error",
        code = ngx_http_internal_error
    },
    [502] = {
        title = "Bad Gateway",
        code = ngx_http_gateway_timeout
    },
    [503] = {
        title = "Service Unavailable",
        code = ngx_http_service_unavailable
    },
    [504] = {
        title = "Gateway Timeout",
        code = ngx_http_gateway_timeout
    }
}

-- Exit Nginx with status and exit code
local function clean_exit(html, variables, status, code)
    -- Set default headers
    ngx.header["Content-Type"] = "text/html"

    -- Set status code
    ngx.status = status

    -- Render template
    template.render(html, variables)

    -- Exit nginx
    ngx.exit(code)
end

ngx.log(ngx.OK, "proxy returned status code ", ngx_status)

local status = statuses[ngx_status]

if not status then
    return clean_exit("500.html", 500, ngx.HTTP_INTERNAL_SERVER_ERROR)
else
    return clean_exit("proxy_5xx.html", { title = status["title"], status = ngx_status }, ngx_status, status["code"])
end
