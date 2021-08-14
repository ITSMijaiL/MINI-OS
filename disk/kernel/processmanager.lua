
--[[
parallel process execution theory

each process is added onto a list

there is a loop that execute parallel.waitForAny with the list unpacked with table.unpack

each time a process finishes, others yield somehow or save their statuses somehow and waitForAny is executed again on the loop, with that finished process kicked off the list
there must be a special function that does that everytime a program finishes if this is gonna be done

]]

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


function Process:new(o,pid,pmanager,job,args)
    o = o or {}
    local obj
    setmetatable(o,self)
    self.__index = self
    self.pid = pid
    self.pmanager=pmanager
    self.pstatus = 0
    self.name = nil
    self.args = args or {}
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

function Process:GetJob() return self.job end 

function Process:GetArgs() return self.args end

function Process:SetArgs(args) 
self.args = args
end

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

--deprecated, the loop handles resuming jobs
--[[
function Process:Start(...)
  assert(self:GetStatus()==0 or self:GetStatus()==2,"Process status must be 0 or 2.")
  coroutine.resume(self.job,...)
end
]]

function Process:Kill()
    if self:GetStatus()~=2 and self:GetStatus()~=0 then return end
    self.pmanager:delproc(self.pid)
end

function Process:ForceKill()
  self:Stop()
  self.pmanager:delproc(self.pid)
end

function Process:Stop()
  if self:GetStatus()==1 or self:GetStatus()==0 then
    coroutine.yield(self.job)
  end
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

--deprecated, it wont work with the loop
--[[
function ProcessManager:addproc(proc)
  if self.processes[proc:GetPID()]~=nil then return end
  self.processes[proc:GetPID()]={proc=proc,args=nil}
end]]

function ProcessManager:addproctoqueue(proc,...)
  if self.processes[proc:GetPID()]~=nil then return end
  table.insert(self.processRunQueue,proc)
end

--deprecated, it wont work with the loop
--[[
function ProcessManager:startproc(pid,...)
  if self.processes[pid]==nil then return end
  self.processes[pid]:Start(...)
end]]

function ProcessManager:delproc(pid)
  if self.processes[pid]==nil then return end
  self.processes[pid]=nil
end

--deprecated, wont work as intended
--[[
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
]]
function ProcessManager:addprocraw(proc)
  if self.processes[proc:GetPID()]~=nil then return end
  table.insert(self.processes,proc)
end

function ProcessManager:init_loop() --a.k.a. task scheduler
  repeat
    sleep(1)
    if #self.processRunQueue>0 then
      table.insert(self.processes,self.processRunQueue[0])
      table.remove(self.processRunQueue,0)
    end

    for i,v in pairs(self.processes) do
      local ok, out = coroutine.resume(v:GetJob(),table.unpack(v:GetArgs()))
      if not ok then
        printError("PROCESS #"..tostring(v:GetPID()).." HAD AN ERROR:\n")
        printError(out) -- cant concatenate em in an assert call otherwhise it will error whenever out is nil even if the function was executed well
      end
      if v:GetStatus()==2 then
        self.processes[i]=nil
      end
    end
  until #self.processes==0
end

return {ProcessManager=ProcessManager,Process=Process}