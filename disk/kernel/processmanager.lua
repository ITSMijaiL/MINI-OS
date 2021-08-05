local processes={}

local processesQueue={}



local syscallm = require("kernel.syscallmanager")

local Process={pid=0,pmanager=nil}

function Process:new(o,pid,pmanager)
    o = o or {}
    local obj
    setmetatable(o,self)
    self.__index = self
    self.pid = pid
    self.pmanager=pmanager
    return o
end

function Process:finished()
    syscallm:DoCall(0,self)
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
    return o
end

function ProcessManager