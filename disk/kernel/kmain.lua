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

Kernel.process = pm.Process:new(nil,0,Kernel.pmanager,function () end) --Kernel's pseudo-process
Kernel.pmanager:addproc(Kernel.process)

local blacklistedfuncs = {"getmetatable","setmetatable","rawget","rawequal","rawset","setfenv","collectgarbage","getfenv","load"}

Kernel.environment = setmetatable(
{
    _G = {},
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

    os = os,

    debug = nil,

    syscall = Kernel.syscall,
    
    execprogram = Kernel.execprogram,

    parallel = parallel,

    dofile = function(path) return dofile(_G.Kernel.fixPath(path)) end,
    loadfile = function(path) return loadfile(_G.Kernel.fixPath(path)) end,
    
    proc = nil,

    exit = function() Kernel.syscall(proc,0) end,
    sleep = sleep, 
    term = term, 

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

function Kernel.execprogram(path,...) 
--local args = {...}
local proc;
local func,out = loadfile(Kernel.fixPath(path))
if not func then return out end
local env_copy = {}
for i,v in pairs(Kernel.environment) do
    env_copy[i] = v
end
setfenv(func,env_copy)
Kernel.syscall(Kernel.process,7,proc,#Kernel.pmanager:getprocs(),func) --create process, store it in variable proc
Kernel.syscall(Kernel.process,8,proc,...) --start the process
end

function Kernel.kmain(...)
  local args = {...}
  --Kernel.pmanager:init_loop()
  Kernel.execprogram("/INIT.lua")
  --Kernel.pmanager:addproc(pm.Process:new(nil, 1, Kernel.pmanager,function() dofile(Kernel.fixPath("INIT.lua")) end))
end 