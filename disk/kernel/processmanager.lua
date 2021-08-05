local processesQueue={}



local syscallm = require("kernel.syscallmanager")

local Process={pid=0,pmanager=nil}

--[[
Process statuses:
-1:Error
0:Inactive/Dead
1:Running
]]


function Process:new(o,pid,pmanager)
    o = o or {}
    local obj
    setmetatable(o,self)
    self.__index = self
    self.pid = pid
    self.pmanager=pmanager
    self.pstatus = 0
    return o
end

function Process:GetStatus()
  return self.pstatus
end

function Process:kill()
    self.pmanager:killproc(self.PID)
end
--[[
function StartProcess(p)
    if processes[p.PID] ~= nil then return end

end]]

local ProcessManager = {}

function ProcessManager:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    self.processes={}
    return o
end

function ProcessManager:killproc(pid)
  if self.processes[pid]==nil then return end
  self.processes[pid]=nil
end