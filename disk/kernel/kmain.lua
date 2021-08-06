local Kernel={}

local pm = require("processmanager")

Kernel.pmanager = pm.ProcessManager:new()

Kernel.shutdown = function()
  for i,v in pairs(Kernel.pmanager:getprocs()) do
    v:Kill()
  end
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
  end
end

function kmain(...)
  local args = {...}
  Kernel.pmanager:addproc(pm.Process:new(nil, 1, Kernel.pmanager,function() os.run({},"") end))
end 