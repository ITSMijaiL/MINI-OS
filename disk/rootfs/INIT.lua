assert(_G.Kernel ~= nil,"[KERNEL PANIC!] Kernel's object is non-existent!")

--TODO: init all processes listed in /etc/on_init
for i,v in pairs(fs.list("/etc/on_init")) do
    
end