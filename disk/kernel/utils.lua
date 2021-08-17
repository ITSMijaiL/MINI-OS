local utils = {}

local expect, type_of = dofile("rom/modules/main/cc/expect.lua").expect, _G.type

local function checkResult(handle, ...)
    if ... == nil and handle._autoclose and not handle._closed then handle:close() end
    return ...
end

local handleMetatable
handleMetatable = {
    __name = "FILE*",
    __tostring = function(self)
        if self._closed then
            return "file (closed)"
        else
            local hash = tostring(self._handle):match("table: (%x+)")
            return "file (" .. hash .. ")"
        end
    end,

    __index = {
        --- Close this file handle, freeing any resources it uses.
        --
        -- @treturn[1] true If this handle was successfully closed.
        -- @treturn[2] nil If this file handle could not be closed.
        -- @treturn[2] string The reason it could not be closed.
        -- @throws If this handle was already closed.
        close = function(self)
            if type_of(self) ~= "table" or getmetatable(self) ~= handleMetatable then
                error("bad argument #1 (FILE expected, got " .. type_of(self) .. ")", 2)
            end
            if self._closed then error("attempt to use a closed file", 2) end

            local handle = self._handle
            if handle.close then
                self._closed = true
                handle.close()
                return true
            else
                return nil, "attempt to close standard stream"
            end
        end,

        --- Flush any buffered output, forcing it to be written to the file
        --
        -- @throws If the handle has been closed
        flush = function(self)
            if type_of(self) ~= "table" or getmetatable(self) ~= handleMetatable then
                error("bad argument #1 (FILE expected, got " .. type_of(self) .. ")", 2)
            end
            if self._closed then error("attempt to use a closed file", 2) end

            local handle = self._handle
            if handle.flush then handle.flush() end
            return true
        end,

        lines = function(self, ...)
            if type_of(self) ~= "table" or getmetatable(self) ~= handleMetatable then
                error("bad argument #1 (FILE expected, got " .. type_of(self) .. ")", 2)
            end
            if self._closed then error("attempt to use a closed file", 2) end

            local handle = self._handle
            if not handle.read then return nil, "file is not readable" end

            local args = table.pack(...)
            return function()
                if self._closed then error("file is already closed", 2) end
                return checkResult(self, self:read(table.unpack(args, 1, args.n)))
            end
        end,

        read = function(self, ...)
            if type_of(self) ~= "table" or getmetatable(self) ~= handleMetatable then
                error("bad argument #1 (FILE expected, got " .. type_of(self) .. ")", 2)
            end
            if self._closed then error("attempt to use a closed file", 2) end

            local handle = self._handle
            if not handle.read and not handle.readLine then return nil, "Not opened for reading" end

            local n = select("#", ...)
            local output = {}
            for i = 1, n do
                local arg = select(i, ...)
                local res
                if type_of(arg) == "number" then
                    if handle.read then res = handle.read(arg) end
                elseif type_of(arg) == "string" then
                    local format = arg:gsub("^%*", ""):sub(1, 1)

                    if format == "l" then
                        if handle.readLine then res = handle.readLine() end
                    elseif format == "L" and handle.readLine then
                        if handle.readLine then res = handle.readLine(true) end
                    elseif format == "a" then
                        if handle.readAll then res = handle.readAll() or "" end
                    elseif format == "n" then
                        res = nil -- Skip this format as we can't really handle it
                    else
                        error("bad argument #" .. i .. " (invalid format)", 2)
                    end
                else
                    error("bad argument #" .. i .. " (expected string, got " .. type_of(arg) .. ")", 2)
                end

                output[i] = res
                if not res then break end
            end

            -- Default to "l" if possible
            if n == 0 and handle.readLine then return handle.readLine() end
            return table.unpack(output, 1, n)
        end,

        seek = function(self, whence, offset)
            if type_of(self) ~= "table" or getmetatable(self) ~= handleMetatable then
                error("bad argument #1 (FILE expected, got " .. type_of(self) .. ")", 2)
            end
            if self._closed then error("attempt to use a closed file", 2) end

            local handle = self._handle
            if not handle.seek then return nil, "file is not seekable" end

            -- It's a tail call, so error positions are preserved
            return handle.seek(whence, offset)
        end,

        --[[- Sets the buffering mode for an output file.
        This has no effect under ComputerCraft, and exists with compatility
        with base Lua.
        @tparam string mode The buffering mode.
        @tparam[opt] number size The size of the buffer.
        @see file:setvbuf Lua's documentation for `setvbuf`.
        @deprecated This has no effect in CC.
        ]]
        setvbuf = function(self, mode, size) end,

        --- Write one or more values to the file
        --
        -- @tparam string|number ... The values to write.
        -- @treturn[1] Handle The current file, allowing chained calls.
        -- @treturn[2] nil If the file could not be written to.
        -- @treturn[2] string The error message which occurred while writing.
        write = function(self, ...)
            if type_of(self) ~= "table" or getmetatable(self) ~= handleMetatable then
                error("bad argument #1 (FILE expected, got " .. type_of(self) .. ")", 2)
            end
            if self._closed then error("attempt to use a closed file", 2) end

            local handle = self._handle
            if not handle.write then return nil, "file is not writable" end

            for i = 1, select("#", ...) do
                local arg = select(i, ...)
                expect(i, arg, "string", "number")
                handle.write(arg)
            end
            return self
        end,
    },
}

function utils:make_file(handle)
    return setmetatable({ _handle = handle }, handleMetatable)
end

return utils