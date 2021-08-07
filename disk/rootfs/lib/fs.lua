local oldfs = fs
_G.fs = {}
local fs = _G.fs

assert(_G.Kernel~=nil,"[LIB ERROR] Kernel's object is non-existent!")

--stub
function fs.isDriveRoot(path) end


fs.complete = function(path,location,include_files,include_dirs)
    return oldfs.complete(_G.Kernel.fixPath(path),_G.Kernel.fixPath(location),include_files,include_dirs)
end

fs.list = function(path)
    return oldfs.list(_G.Kernel.fixPath(path))
end

fs.combine = function(path,...)
    return oldfs.combine(_G.Kernel.fixPath(path),...)
end

fs.getName = function(path)
    return oldfs.getName(_G.Kernel.fixPath(path))
end

fs.getDir = function(path)
    return oldfs.getDir(_G.Kernel.fixPath(path))
end

fs.getSize = function(path)
    return oldfs.getSize(_G.Kernel.fixPath(path))
end

fs.exists = function(path)
    return oldfs.exists(_G.Kernel.fixPath(path))
end

fs.isdir = function(path)
    return oldfs.isdir(_G.Kernel.fixPath(path))
end

fs.isReadOnly = function(path)
    return oldfs.isReadOnly(_G.Kernel.fixPath(path))
end

fs.makeDir = function(path)
    return oldfs.makeDir(_G.Kernel.fixPath(path))
end

fs.move = function(path,dest)
    return oldfs.move(_G.Kernel.fixPath(path),_G.Kernel.fixPath(dest))
end

fs.copy = function(path,dest)
    return oldfs.copy(_G.Kernel.fixPath(path),_G.Kernel.fixPath(dest))
end

fs.delete = function(path)
    return oldfs.delete(_G.Kernel.fixPath(path))
end

fs.open= function(path,mode)
    return oldfs.open(_G.Kernel.fixPath(path),mode)
end

fs.getDrive = function(path)
    return oldfs.getDrive(_G.Kernel.fixPath(path))
end

fs.getFreeSpace = function(path)
    return oldfs.getFreeSpace(_G.Kernel.fixPath(path))
end

fs.find = function(path)
    return oldfs.find(_G.Kernel.fixPath(path))
end

fs.getCapacity = function(path)
    return oldfs.getCapacity(_G.Kernel.fixPath(path))
end

fs.attributes = function(path)
    return oldfs.attributes(_G.Kernel.fixPath(path))
end
