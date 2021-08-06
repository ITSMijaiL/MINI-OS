local Kernel={}

local pm = require("processmanager")
local sm= require("syscallmanager")


Kernel.pmanager = pm.ProcessManager:new()

Kernel.syscall = sm.DoCall

function kmain(...)
  local args = {...}
  Kernel.pmanager:addproc(Process:new(nil, 1, Kernel.pmanager,function() os.run("") end)) 
end 