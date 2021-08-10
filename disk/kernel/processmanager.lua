
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


function Process:new(o,pid,pmanager,job)
    o = o or {}
    local obj
    setmetatable(o,self)
    self.__index = self
    self.pid = pid
    self.pmanager=pmanager
    self.pstatus = 0
    self.name = nil
    local err,out = pcall(function()
      self.job = coroutine.create(job())
    end)
    if not err then 
      self.job = coroutine.create(job)
    end
    self.locals = {}
    self.children = {}
    return o
end

function Process:UpdateStatus() self.pstatus = CStatusToPStatus(coroutine.status(self.job)) end

function Process:GetStatus()
  self:UpdateStatus()
  return self.pstatus
end

function Process:GetPID() return self.pid end

function Process:GetChildrenProcesses() return self.children end 

function Process:AddChildrenProcess(proc) 
  --assert(self.children[proc.pid]==nil,"Children process already exists!")
  if self.children[proc:GetPID()]~=nil then return end
  self.children[proc:GetPID()]=proc
end

function Process:StartChildrenProcess(pid,...)
  if self.children[pid]==nil then return end
  self.children[pid]:Start(...)
end

function Process:SetName(name) self.name = name end
function Process:GetName() return self.name end


function Process:Start(...)
  assert(self:GetStatus()==0 or self:GetStatus()==2,"Process status must be 0 or 2.")
  coroutine.resume(self.job,...)
end

function Process:Kill()
    self:UpdateStatus()
    if self.pstatus~=2 and self.pstatus~=0 then return end
    self.pmanager:killproc(self.pid)
end

function Process:ForceKill()
  self:Stop()
  self.pmanager:killproc(self.pid)
end

function Process:Stop()
  assert(self.pstatus==1,"Process status must be 1 or .")
  self.pstatus=0
  coroutine.yield(self.job)
end

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

function ProcessManager:getproc(pid)
  if self.processes[pid]==nil then return end
  return self.processes[pid]
end

function ProcessManager:getprocs() return self.processes end

function ProcessManager:addproc(proc)
  if self.processes[proc:GetPID()]~=nil then return end
  self.processes[proc:GetPID()]=proc
end

function ProcessManager:addproctoqueue(proc,...)
  if self.processes[proc:GetPID()]~=nil then return end
  table.insert(self.processRunQueue,{proc=proc,args=...})
end

function ProcessManager:startproc(pid,...)
  if self.processes[pid]==nil then return end
  self.processes[pid]:Start(...)
end

function ProcessManager:killproc(pid)
  if self.processes[pid]==nil then return end
  self.processes[pid]=nil
end

function ProcessManager:init_loop() 
  coroutine.resume(coroutine.create(function() 
    while true do 
      sleep(0.5)
      --see if there are any processes on queue
      if #self.processRunQueue>0 then
        self:addproc(self.processRunQueue[0]["proc"])
        self:startproc(self.processRunQueue[0]["proc"].pid,self.processRunQueue[0]["args"])
        --run 'em and then remove 'em, easy peasy
        table.remove(self.processRunQueue,0)
      end
    end
  end))
end

return {ProcessManager=ProcessManager,Process=Process}