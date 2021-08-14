local oldio = io

local io = {}

assert(_G.Kernel~=nil,"[LIB ERROR] Kernel's object is non-existent!")

io.stdin,io.stdout,io.stderr = oldio.stdin,oldio.stdout,oldio.stderr

function io.close(handle) return oldio.close(handle) end

function io.flush() return oldio.flush() end

function io.open(filen,mode) return oldio.open(_G.Kernel.fixPath(filen),mode) end

function io.output(file)
    if type(file)=="string" then
        return oldio.output(_G.Kernel.fixPath(file))
    else
        return oldio.output(file)
    end
end

function io.input(file)
    if type(file)=="string" then
        return oldio.input(_G.Kernel.fixPath(file))
    else
        return oldio.input(file)
    end
end

function io.lines(file,...) 
    return oldio.lines(_G.Kernel.fixPath(file),...)
end

function io.read(...)
    return oldio.read(...)
end

function io.type(handle) return oldio.type(handle) end

function io.write(...) return oldio.write(...) end

return io