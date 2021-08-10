term.clear()
--local kernel = require("kernel.kmain")

print("INITIALIZING KERNEL...")
local err,msg = nil,""
parallel.waitForAny(function() err,msg = pcall(loadfile("/disk/kernel/kmain.lua")) end)

assert(err,"[KERNEL PANIC!] Kernel's object couldn't be initialized due to an error!\n"..msg)

assert(_G.Kernel ~= nil,"[KERNEL PANIC!] Kernel's object is non-existent!")

_G.Kernel:kmain()

