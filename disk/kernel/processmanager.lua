
--[[
parallel process execution theory

each process is added onto a list

there is a loop that execute parallel.waitForAny with the list unpacked with table.unpack

each time a process finishes, others yield somehow or save their statuses somehow and waitForAny is executed again on the loop, with that finished process kicked off the list
there must be a special function that does that everytime a program finishes if this is gonna be done

]]

local Process={pid=0,pmanager=nil}

local utils = dofile("/disk/kernel/utils.lua")

--[[
Process statuses:
-1:Error
0:Inactive
1:Running
2:Finished/Dead
]]

--[[
Permission levels:
0: Super process        (Most privileged, mostly system processes)
1: Privileged process   (On the middle, processes executed as superuser or important daemons)
2: User process         (Least privileged, normal user programs like the shell)
]]

--[[
Extra notes:
* Daemons in mini-os are just processes that arent in the foreground, as simple as that, no need to create a different class or object for it
* Permission levels CAN'T be set after the process was created
]]

function CStatusToPStatus(CStatus)
  if CStatus == "dead" then return 2 end
  if CStatus == "suspended" or CStatus == "normal" then return 0 end
  if CStatus == "running" then return 1 end
end


function Process:new(o,pid,pmanager,job,args,permlevel)
    o = o or {}
    local obj
    setmetatable(o,self)
    self.__index = self
    self.pid = pid
    self.pmanager=pmanager
    self.pstatus = 0
    self.onforeground=false
    self.name = nil
    self.args = args or {}

    local err,out = pcall(function()
      self.job = coroutine.create(job())
    end)
    if not err then 
      self.job = coroutine.create(job)
    end

    self.permlevel = permlevel

    self.STDOUT = utils:make_file({write = self.write})
    self.STDERR = utils:make_file({write = self.error})
    self.STDIN = utils:make_file({readLine = self.read, readAll = self.read, read = self.read})

    self.locals = {}
    self.children = {}
    self.signalstable = {
      SIGKILL=function()
        self:Kill()
      end,
      SIGBG=function()
        self.pmanager:sendprocesstobackground(self.pid)
      end,
      SIGFG=function()
        self.pmanager:bringprocesstoforeground(self.pid)
      end
    }
    return o
end

function Process:GetPermLevel() return self.permlevel end

function Process:UpdateStatus() self.pstatus = CStatusToPStatus(coroutine.status(self.job)) end

function Process:GetStatus()
  self:UpdateStatus()
  return self.pstatus
end

function Process:HandleSignal(proccaller,sig)
  if proccaller:GetPermLevel()>self:GetPermLevel() then return end --we dont want an user process killing a system process, do we?
  if sig==nil then return end
  if self.signalstable[sig]==nil then
    self:error("Signal "..sig.." doesn't exists",0)
    return end
  self.signalstable[sig]()
end

function Process:SetSignal(sig,func)
  if sig==nil or func==nil then return end
  if self.signalstable[sig]==nil then
    self:error("Signal "..sig.." doesn't exists",0)
    return end
  if type(func) ~= "function" then 
    self:error("Arg #2 is required to be a function.",0)
    return end
  self.signalstable[sig]=func
end

function Process:ClearSignalsTable()
  for i,v in pairs(self.signalstable) do
    self.signalstable[i]=nil
  end
end

function Process:IsOnForeground() return self.onforeground end

function Process:BringToForeground() self.onforeground=true end
function Process:SendToBackground() self.onforeground=false end

function Process:write(...)
  local cleantable = {}
  for i,v in {...} do
    cleantable[i]=tostring(v)
  end
  self.STDOUT = self.STDOUT..table.unpack(cleantable)
  if self.onforeground then print(...) end
end

function Process:sleep(secs)
  if self.onforeground then sleep(secs) 
  else return end
end

function Process:pullEvent(filter) 
  if self.onforeground then 
    return os.pullEvent(filter)
  else return end
end

function Process:pullEventRaw(filter) 
  if self.onforeground then 
    return os.pullEventRaw(filter)
  else return end
end

function Process:read(...)
  if not self.onforeground then return end
  local r = io.read(...)
  return r
end

function Process:error(...)
  local cleantable = {}
  for i,v in {...} do
    cleantable[i]=tostring(v)
  end
  self.STDERR = self.STDERR..table.unpack(cleantable)
  if self.onforeground then printError(...) end
end

function Process:clear() self.STDOUT="";term.clear(); end

function Process:GetPID() return self.pid end

function Process:GetJob() return self.job end 

function Process:GetArgs() return self.args end

function Process:SetArgs(args) self.args = args end

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
    self:Stop()
    self.pmanager:delproc(self.pid)
end

function Process:ForceKill()
  self:Stop()
  self.pmanager:delproc(self.pid)
end

function Process:Stop()
  if self:GetStatus()==1 or self:GetStatus()==0 then
    self.pstatus=2
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
    self.processesOnForeground = {}
    return o
end

function ProcessManager:procexists(pid)
  return self.processes[pid]~=nil
end

function ProcessManager:getproc(pid)
  if self.processes[pid]==nil then return end
  return self.processes[pid]
end

function ProcessManager:sendsignal(pid,sig)
  if self.processes[pid]==nil then return end
  return self.processes[pid]:HandleSignal(sig)
end

function ProcessManager:getprocs() return self.processes end
function ProcessManager:getprocs_foreground() return self.processesOnForeground end

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
  if self.processesOnForeground[pid]~=nil then self.processesOnForeground[pid]=nil end 
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

function ProcessManager:bringprocesstoforeground(pid)
  if self.processes[pid]==nil then return end
  if self.processesOnForeground[pid]~=nil then return end
  self.processes[pid]:BringToForeground()
  table.insert(self.processesOnForeground,pid) -- we want only the pid since we dont want to clone the process
end

function ProcessManager:sendprocesstobackground(pid)
  if self.processes[pid]==nil then return end
  if self.processesOnForeground[pid]==nil then return end
  self.processesOnForeground[pid]=nil
  self.processes[pid]:SendToBackground()
end

function ProcessManager:killall()
  for i,v in pairs(self.processesOnForeground) do 
    self.processes[v]:ForceKill()
  end
  for i,v in pairs(self.processes) do
    v:ForceKill()
  end
end

function ProcessManager:init_loop() --a.k.a. task scheduler
  repeat
    sleep(1)
    if #self.processRunQueue>0 then
      table.insert(self.processes,self.processRunQueue[1])
      table.remove(self.processRunQueue,1)
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