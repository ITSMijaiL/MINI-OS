--TODO: each time a program runs, it has to be prepared first and for that, lib files will be ran with dofile.

_G.Kernel={}
local Kernel = _G.Kernel
local pm = require("processmanager")

Kernel.pmanager = pm.ProcessManager:new()

Kernel.shutdown = function()
  for i,v in pairs(Kernel.pmanager:getprocs()) do
    v:Kill()
  end
end

Kernel.environment = {}

Kernel.fixPath = function (path)
    if path == nil or path=="" then return "" end
    return fs.combine("/disk/rootfs",path)
end

Kernel.syscall = function(proc,number,...)
  local args = {...}
  local function CheckArgs(argsAmnt) 
      assert(#args>=argsAmnt,"System call #"..tostring(number).." needs "..tostring(argsAmnt).." arguments!")
  end
  local function CheckArgsStrict(argsAmnt) 
      assert(#args==argsAmnt,"System call #"..tostring(number).." needs exactly "..tostring(argsAmnt).." arguments!")
  end
  if number==0 then --EXIT []
      CheckArgsStrict(0)
      proc:kill()
  elseif number==1 then --OPEN [file path, mode]
      CheckArgs(2)
      local filepath = args[1]
      local mode = args[2]
      return io.open(filepath,mode)
  elseif number==2 then --CLOSE [handle]
      CheckArgsStrict(1)
      args[1].close()
  elseif number==3 then --READ [handle]
      CheckArgs(1)
      return args[1]:read("*a")
  elseif number==4 then --WRITE [handle, string]
      CheckArgs(2)
      return args[1].write(args[2])
  elseif number==5 then --SHUTDOWN []
      os.shutdown()
  elseif number==6 then --REBOOT []
      os.reboot()
  elseif number==7 then --CREATE PROCESS [variable used to store the process' class,PID (int),job (function)]
      CheckArgs(3)
      args[1]=pm.Process:new(nil,args[2],Kernel.pmanager,args[3])
  elseif number==8 then --INIT PROCESS [process var, args]
    local argsfix = {}
    for i,v in pairs(args) do if i~=1 then table.insert(argsfix,v) end end
    Kernel.pmanager:addproc(args[1])
    Kernel.pmanager:startproc(args[1].pid,table.unpack(argsfix))
  end
end

function Kernel.kmain(...)
  local args = {...}
  Kernel.pmanager:addproc(pm.Process:new(nil, 1, Kernel.pmanager,function() dofile(Kernel.fixPath("INIT.lua")) end))
end 