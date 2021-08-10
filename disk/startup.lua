term.clear()
--local kernel = require("kernel.kmain")

print("INITIALIZING KERNEL...")
local err,msg = nil,nil
parallel.waitForAny(function() err,msg = pcall(loadfile("/disk/kernel/kmain.lua")) end)

if not err then printError("[KERNEL PANIC!] Kernel's object couldn't be initialized due to an error!\n"..msg) end

assert(_G.Kernel ~= nil,"[KERNEL PANIC!] Kernel's object is non-existent!")

_G.Kernel:kmain()

