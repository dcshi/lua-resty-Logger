--module("resty.logger", package.seeall)

local bit = require "bit"
local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C;
local bor = bit.bor;
local ngx_today = ngx.today;
local ngx_localtime = ngx.localtime
local setmetatable = setmetatable 
local _error = error    

module(...)

_VERSION = '0.01'

local mt = { __index = _M } 

ffi.cdef[[
int write(int fd, const char *buf, int nbyte);
int open(const char *path, int access, int mode);
int close(int fd);
]]

local O_RDWR   = 0X0002; 
local O_CREAT  = 0x0040;
local O_APPEND = 0x0400;
local S_IRWXU  = 0x01C0;
local S_IRGRP  = 0x0020;
local S_IROTH  = 0x0004;

-- log level
local LVL_DEBUG = 1;
local LVL_INFO  = 2;
local LVL_ERROR = 3;
local LVL_NONE  = 999;

local today = ngx_today();

local logger_level = LVL_INFO;
local logger_file = "/tmp/lomemo_custom.log.";
local logger_fd = C.open(logger_file..today, bor(O_RDWR, O_CREAT, O_APPEND), bor(S_IRWXU, S_IRGRP, S_IROTH));

function shift_file()
	if ngx_today() ~= today then
		C.close(logger_fd);
		today = ngx_today();
		logger_fd = C.open(logger_file..today, bor(O_RDWR, O_CREAT, O_APPEND), bor(S_IRWXU, S_IRGRP, S_IROTH));
	end
end

function debug(msg)
		if logger_level > LVL_DEBUG then return end;
		shift_file();

		local c = ngx_localtime() .. "|" .."D" .. "|" .. msg .. "\n";
		C.write(logger_fd, c, #c);
end

function info(msg)
		if logger_level > LVL_INFO then return end;
		shift_file();
		
		local c = ngx_localtime() .. "|" .."I" .. "|" .. msg .. "\n";
		C.write(logger_fd, c, #c);
end

function error(msg)
		if logger_level > LVL_ERROR then return end;
		shift_file();

		local c = ngx_localtime() .. "|" .."E" .. "|" .. msg .. "\n";
		C.write(logger_fd, c, #c);
end

local class_mt = {
	-- to prevent use of casual module global variables
	__newindex = function (table, key, val)
		_error('attempt to write to undeclared variable "' .. key .. '"')
	end
}

setmetatable(_M, class_mt)
