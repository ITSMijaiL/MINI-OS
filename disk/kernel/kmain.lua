_G.Kernel={}
local Kernel = _G.Kernel
--require = require("cc.require")
local pm = dofile("/disk/kernel/processmanager.lua")

Kernel.pmanager = pm.ProcessManager:new()

Kernel.shutdown = function()
  for i,v in pairs(Kernel.pmanager:getprocs()) do
    v:Kill()
  end
end

Kernel.process = pm.Process:new(nil,1,Kernel.pmanager,function () end,{},0) --Kernel's pseudo-process
Kernel.pmanager:addprocraw(Kernel.process)

local blacklistedfuncs = {"getmetatable","setmetatable","rawget","rawequal","rawset","setfenv","collectgarbage","getfenv","load","module","package","newproxy"}

Kernel.environment = setmetatable(
{
    _G = {},
    _VERSION = _VERSION,
    --based on lua 5.1's coroutine lib since CC:tweaked and perhaps even the original computercraft runs lua 5.1
    coroutine = {create = coroutine.create, 
    yield = coroutine.yield, resume = coroutine.resume,
    running = coroutine.running, status = coroutine.status
    },

    fs = dofile("/disk/rootfs/lib/fs.lua"),

    math = {abs=math.abs,acos=math.acos,asin=math.asin,
    atan=math.atan,atan2=math.atan2,ceil=math.ceil,
    cos=math.cos,cosh=math.cosh,deg=math.deg,exp=math.exp,
    floor=math.floor,fmod=math.fmod,frexp=math.frexp,
    huge=math.huge,ldexp=math.ldexp,log=math.log,
    log10=math.log10,max=math.max,min=math.min,
    modf=math.modf,pi=math.pi,pow=math.pow,rad=math.rad,
    random=math.random,randomseed=math.randomseed,
    sin=math.sin,sinh=math.sinh,sqrt=math.sqrt,
    tan=math.tan,tanh=math.tanh
    },

    package = nil,

    string = {byte=string.byte, char=string.char, find=string.find, 
    format=string.format, gmatch=string.gmatch, gsub=string.gsub, 
    len=string.len, lower=string.lower, match=string.match, 
    rep=string.rep, reverse=string.reverse, 
    sub=string.sub, upper=string.upper},

    table = {concat=table.concat, insert=table.insert, 
    maxn=table.maxn, remove=table.remove, sort=table.sort, 
    unpack = table.unpack},

    io = dofile("/disk/rootfs/lib/io.lua"),

    settings = dofile("/disk/rootfs/lib/settings.lua"),

    os = os,

    debug = nil,

    --syscall = Kernel.syscall,
    
    execprogram = function(path,...) Kernel.execprogram(2,path,...) end,

    parallel = parallel,

    dofile = function(path) return dofile(_G.Kernel.fixPath(path)) end,
    loadfile = function(path) return loadfile(_G.Kernel.fixPath(path)) end,
    
    proc = nil,
    pcall = pcall,
    xpcall = xpcall,
    next = next,
    pairs = pairs,
    ipairs = ipairs,
    select = select,
    tonumber = tonumber,
    tostring = tostring,

    term = term,
    print = print,
    write = self.write,
    read = self.read,
    error = self.error,
    _HOST = _HOST,
    _CC_DEFAULT_SETTINGS = _CC_DEFAULT_SETTINGS,
    colors = colors,
    colours = colours,
    textutils = textutils,

},{
    __index = function(t,k)
        if rawget(t,k) ~= nil and blacklistedfuncs[k] == nil then
            return rawget(t,k) --rawget to not loop over __index and fill the c stack
        elseif not rawget(t,k) ~= nil and blacklistedfuncs[k] == nil then
            return _G[k]
        elseif blacklistedfuncs[k] ~= nil then
            return nil
        end
    end
})

Kernel.fixPath = function (path)
    if path == nil or path=="" then return "/disk/rootfs" end
    return fs.combine("/disk/rootfs",path)
end

Kernel.syscall = function(proc,number,...)
  local args = {...}
  local function CheckArgs(argsAmnt)
      if argsAmnt==0 then assert(args==nil,"System call #"..tostring(number).." needs "..tostring(argsAmnt).." arguments!") end
      assert(#args>=argsAmnt,"System call #"..tostring(number).." needs "..tostring(argsAmnt).." arguments!")
  end
  local function CheckArgsStrict(argsAmnt) 
      if argsAmnt==0 then assert(args==nil,"System call #"..tostring(number).." needs exactly "..tostring(argsAmnt).." arguments!") end
      assert(#args==argsAmnt,"System call #"..tostring(number).." needs exactly "..tostring(argsAmnt).." arguments!")
  end
  if number==0 then --EXIT []
      CheckArgs(0)
      proc:Kill()
  elseif number==1 then --OPEN [file path, mode]
      CheckArgs(1)
      local filepath = args[1]
      local mode = args[2] or "rb"
      return io.open(Kernel.fixPath(filepath),mode)
  elseif number==2 then --CLOSE [handle]
      CheckArgsStrict(1)
      args[1]:close()
  elseif number==3 then --READ [handle]
      CheckArgs(2)
      return args[1]:read(args[2])
  elseif number==4 then --WRITE [handle, string]
      CheckArgs(2)
      return args[1].write(args[2])
  elseif number==5 then --SHUTDOWN []
      Kernel.pmanager:killall()
      os.shutdown()
  elseif number==6 then --REBOOT []
      Kernel.pmanager:killall()
      os.reboot()
  elseif number==7 then --CREATE PROCESS [variable used to store the process' class,PID (int),job (function), arguments (array)]
      CheckArgs(2)
      local argsfix = {}
      if #args>2 then 
        for i,v in pairs(args) do if i>2 then table.insert(argsfix,v) end end
      end
      if #argsfix==0 then argsfix=nil end 
      return pm.Process:new(nil,args[1],Kernel.pmanager,args[2],argsfix)
  elseif number==8 then --QUEUE PROCESS [process var]
    CheckArgsStrict(1)
    Kernel.pmanager:addproctoqueue(args[1])
  elseif number==9 then --BRING PROCESS TO FOREGROUND [PID (int)]
    CheckArgsStrict(1)
    Kernel.pmanager:bringprocesstoforeground(args[1])
  elseif number==10 then --SEND PROCESS TO BACKGROUND [PID (int)]
    CheckArgsStrict(1)
    Kernel.pmanager:sendprocesstobackground(args[1])
  elseif number==11 then --SEND SIGNAL TO PROCESS
    CheckArgsStrict(2)
    return Kernel.pmanager:sendsignal(args[1],args[2])
  end
end

function Kernel.execprogram(permslevel,path,...) 
--local args = {...}
local pl = permslevel or 2
local proc;
local func,out = loadfile(Kernel.fixPath(path))
if not func then return out end
local env_copy = {}
for i,v in pairs(Kernel.environment) do
    env_copy[i] = v
end
setfenv(func,env_copy)
--create process, store it in variable proc
proc = Kernel.syscall(Kernel.process,7,#Kernel.pmanager:getprocs()+1,func,...) 

--do final tweaks
env_copy.self = proc
env_copy.self.SendToBackground = nil
env_copy.self.BringToForeground = nil
env_copy.self.HandleSignal = nil
env_copy.self.Kill = nil
env_copy.self.ForceKill = nil
env_copy.self.Stop = nil


env_copy.args = {...}

env_copy.settings:ApplyFromFile("/etc/config")
env_copy.syscall = function(number,...) Kernel.syscall(proc,number,...) end

env_copy.term.write = env_copy.io.write
env_copy.term.clear = env_copy.self.clear
env_copy.clear = env_copy.term.clear
env_copy.sleep = env_copy.self.sleep

env_copy.os.pullEvent = env_copy.self.pullEvent
env_copy.os.pullEventRaw = env_copy.self.pullEventRaw
env_copy.os.shutdown = function() Kernel.syscall(proc,5) end
env_copy.os.reboot = function() Kernel.syscall(proc,6) end

env_copy.io.read = env_copy.self.read
env_copy.io.write = env_copy.self.write

env_copy.io.open = function(filename,mode) return Kernel.syscall(proc,1,filename,mode) end
env_copy.io.close = function(handle) Kernel.syscall(proc,2,handle) end
env_copy.exit = function() Kernel.syscall(proc,0) end

--add process to queue
Kernel.syscall(Kernel.process,8,proc) 
end

function Kernel.kmain(...)
  local args = {...}
  Kernel.execprogram(0,"/INIT.lua")
  Kernel.pmanager:init_loop()
  --Kernel.pmanager:addproc(pm.Process:new(nil, 1, Kernel.pmanager,function() dofile(Kernel.fixPath("INIT.lua")) end))
end 