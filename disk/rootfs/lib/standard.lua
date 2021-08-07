assert(_G.Kernel~=nil,"[LIB ERROR] Kernel's object is non-existent!")

local old_dofile = _G.dofile
_G.dofile = function(path) return old_dofile(_G.Kernel.fixPath(path)) end