--local kernel = require("kernel.kmain")

print("INITIALIZING KERNEL...")

parallel.waitForAny(function() dofile("/disk/kernel/kmain.lua") end)

assert(_G.Kernel ~= nil,"[KERNEL PANIC!] Kernel's object is non-existent!")

_G.Kernel:kmain()

