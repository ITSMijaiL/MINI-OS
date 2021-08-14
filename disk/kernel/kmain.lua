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

Kernel.process = pm.Process:new(nil,1,Kernel.pmanager,function () end) --Kernel's pseudo-process
Kernel.pmanager:addproc(Kernel.process)

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

    os = os,

    debug = nil,

    syscall = Kernel.syscall,
    
    execprogram = Kernel.execprogram,

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


    exit = function() Kernel.syscall(proc,0) end,
    sleep = sleep, 
    term = term,
    print = print,
    clear = term.clear,
    write = write,
    read = read,
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
    --Kernel.pmanager:shutdown() --TODO
      os.shutdown()
  elseif number==6 then --REBOOT []
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
proc = Kernel.syscall(Kernel.process,7,#Kernel.pmanager:getprocs()+1,func,...) --create process, store it in variable proc
Kernel.syscall(Kernel.process,8,proc) --add process to queue
end

function Kernel.kmain(...)
  local args = {...}
  --Kernel.pmanager:init_loop()
  Kernel.execprogram("/INIT.lua")
  --Kernel.pmanager:addproc(pm.Process:new(nil, 1, Kernel.pmanager,function() dofile(Kernel.fixPath("INIT.lua")) end))
end 