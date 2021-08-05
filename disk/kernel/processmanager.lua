
local syscallm = require("kernel.syscallmanager")



local Process={pid=0,pmanager=nil}

--[[
Process statuses:
-1:Error
0:Inactive
1:Running
2:Finished/Dead
]]

function CStatusToPStatus(CStatus)
  if CStatus == "dead" then return 2 end
  if CStatus == "suspended" or CStatus == "normal" then return 0 end
  if CStatus == "running" then return 1 end
end

function Wait(seconds)
  local start = os.time()
  repeat until os.time() > start + seconds
end


function Process:new(o,pid,pmanager,job)
    o = o or {}
    local obj
    setmetatable(o,self)
    self.__index = self
    self.pid = pid
    self.pmanager=pmanager
    self.pstatus = 0
    self.name = nil
    self.job = coroutine.create(job)
    return o
end

function Process:GetStatus()
  return self.pstatus
end

function Process:SetName(name) self.name = name end
function Process:GetName() return self.name end

function Process:Start(...)
  assert(not (self.pstatus ~= 0),"Process status must be 0.")
  self.pstatus = CStatusToPStatus(coroutine.status(self.job))
  coroutine.resume(self.job,...)
  self.pstatus = CStatusToPStatus(coroutine.status(self.job))
end

function Process:Kill()
    self.pmanager:killproc(self.PID)
end

function Process:Stop()
  assert(self.pstatus==1,"Process status must be 1.")
  self.pstatus=0
  coroutine.yield(self.job)
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
    self.processRunQueue={}
    return o
end

function ProcessManager:procexists(pid)
  return self.processes[pid]~=nil
end

function ProcessManager:addproc(proc)
  if self.processes[proc.pid]~=nil then return end
  self.processes[proc.pid]=proc
end

function ProcessManager:startproc(pid,...)
  if self.processes[pid]==nil then return end
  self.processes[pid]:Start(...)
end

function ProcessManager:killproc(pid)
  if self.processes[pid]==nil then return end
  self.processes[pid]=nil
end