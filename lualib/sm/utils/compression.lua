local magick = require 'magick'

local brotli_accepted = {
	['text/html'] = true,
	['text/richtext'] = true,
	['text/plain'] = true,
	['text/css'] = true,
	['text/x-script'] = true,
	['text/x-component'] = true,
	['text/x-java-source'] = true,
	['text/x-markdown'] = true,
	['application/javascript'] = true,
	['application/x-javascript'] = true,
	['text/javascript'] = true,
	['text/js'] = true,
	['image/x-icon'] = true,
	['application/x-perl'] = true,
	['application/x-httpd-cgi'] = true,
	['text/xml'] = true,
	['application/xml'] = true,
	['application/xml+rss'] = true,
	['application/json'] = true,
	['multipart/bag'] = true,
	['multipart/mixed'] = true,
	['application/xhtml+xml'] = true,
	['font/ttf'] = true,
	['font/otf'] = true,
	['font/x-woff'] = true,
	['image/svg+xml'] = true,
	['application/vnd.ms-fontobject'] = true,
	['application/ttf'] = true,
	['application/x-ttf'] = true,
	['application/otf'] = true,
	['application/x-otf'] = true,
	['application/truetype'] = true,
	['application/opentype'] = true,
	['application/x-opentype'] = true,
	['application/font-woff'] = true,
	['application/eot'] = true,
	['application/font'] = true,
	['application/font-sfnt'] = true,
	['application/wasm'] = true,
}

local M = {}

function M.brotli_check(file_type)
	ngx.log(ngx.OK, 'file type recieved ', file_type)
	if brotli_accepted[file_type] then
		ngx.log(ngx.OK, 'compression match found')
		return true
	else
		return nil
	end
end

function M.image_check(file_type)
	ngx.log(ngx.OK, 'file type recieved ', file_type)
	if image_accepted[file_type] then
		ngx.log(ngx.OK, 'compression match found')
		return true
	else
		return nil
	end
end

function M.compress_image(input)
	local img = assert(magick.load_from_blob(input))
	assert(img:strip())
	local final = img:get_blob()
	img:destroy()
	return final
end

return M