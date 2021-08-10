--assert(_G.Kernel ~= nil,"[KERNEL PANIC!] Kernel's object is non-existent!")
term.clear()
term.setCursorPos(1,1)
--TODO: init all processes listed in /etc/on_init
for i,v in pairs(fs.list("/etc/on_init")) do
    write("\nINITIATING "..v.." -> ")
    execprogram("/etc/on_init/"..v)
    write("DONE\n")
end
exit()