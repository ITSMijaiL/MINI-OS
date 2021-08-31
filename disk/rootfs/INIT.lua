--assert(_G.Kernel ~= nil,"[KERNEL PANIC!] Kernel's object is non-existent!")
syscall(9,self:GetPID())
term.clear()
term.setCursorPos(1,1)
--TODO: init all processes listed in /etc/on_init
--[[
for i,v in pairs(fs.list("/etc/on_init")) do
    write("\nADDDING "..v.." TO QUEUE -> ")
    execprogram("/etc/on_init/"..v)
    write("DONE\n")
end
]]
local function splitstr (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

local processesToStart = splitstr(settings:GetValue("ONINIT"),",")

for _,pfilepath in pairs(processesToStart) do
    print("INITIATING PROCESSESS...")
    local pfix = splitstr(pfilepath,":")
    local pid = execprogram(pfix[1])
    if pfix[2]=="1" then
        syscall(9,pid)
    end
end