module("resty.logger", package.seeall)

_VERSION = '0.01'

local bit = require "bit"
local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C;
local bor = bit.bor;

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

local logger_level = LVL_INFO;
local logger_file = "/tmp/lomemo_custom.log";
local logger_fd = C.open(logger_file, bor(O_RDWR, O_CREAT, O_APPEND), bor(S_IRWXU, S_IRGRP, S_IROTH));

function debug(msg)
		if logger_level > LVL_DEBUG then return end;

		local c = ngx.localtime() .. "|" .."D" .. "|" .. msg .. "\n";
		C.write(logger_fd, c, #c);
end

function info(msg)
		if logger_level > LVL_INFO then return end;
		
		local c = ngx.localtime() .. "|" .."I" .. "|" .. msg .. "\n";
		C.write(logger_fd, c, #c);
end

function error(msg)
		if logger_level > LVL_ERROR then return end;

		local c = ngx.localtime() .. "|" .."E" .. "|" .. msg .. "\n";
		C.write(logger_fd, c, #c);
end

-- to prevent use of casual module global variables
getmetatable(resty.logger).__newindex = function (table, key, val)
	error('attempt to write to undeclared variable "' .. key .. '": '
	.. debug.traceback())
end
