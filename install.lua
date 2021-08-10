term.clear()
print("MINI-OS installer")
print("[V0.0.1]")

print("Are you sure that you want to install this **UNSTABLE** system?")
write("Y/N:")
local yn = io.read()

while string.lower(yn)~="y" and string.lower(yn)~="n" and string.lower(yn)~="no" and string.lower(yn)~="yes" do
    write("Y/N:")
    yn = io.read()
end

if string.lower(yn)=="yes" or string.lower(yn)=="y" then
    print("You've been warned, as of right now this is unstable and untested")
    if not fs.exists("/disk/") then 
        print("/disk/ wasn't found, aborting...")
    return exit()
    end
    --TODO:make directories along with kernel, insert startup.lua, insert libs and insert services to be initiated in (disk/rootfs)/etc/on_init/
    write("Building the root filesystem...")
    local rfs = "/disk/rootfs"
    local rfs2=""
    fs.makeDir(rfs)
    fs.makeDir(rfs.."/bin")
    fs.makeDir(rfs.."/boot")
    fs.makeDir(rfs.."/dev")

    fs.makeDir(rfs.."/etc")
    rfs2=rfs.."/etc"
    fs.makeDir(rfs2.."/on_init")

    fs.makeDir(rfs.."/home")
    fs.makeDir(rfs.."/lib")
    fs.makeDir(rfs.."/opt")
    fs.makeDir(rfs.."/proc")
    fs.makeDir(rfs.."/sbin")
    fs.makeDir(rfs.."/superuser")
    fs.makeDir(rfs.."/tmp")

    fs.makeDir(rfs.."/usr")
    rfs2=rfs.."/usr"
    fs.makeDir(rfs2.."/bin")
    fs.makeDir(rfs2.."/local")
    fs.makeDir(rfs2.."/sbin")

    fs.makeDir("/disk/kernel")

    write("DONE\n")
    print("Downloading files...")
    local files = {"startup.lua","kernel/kmain.lua","kernel/processmanager.lua","rootfs/etc/on_init/minishell.lua","rootfs/lib/fs.lua","rootfs/lib/io.lua","rootfs/lib/standard.lua","rootfs/INIT.lua"}
    local downPath = "https://raw.githubusercontent.com/ITSMijaiL/MINI-OS/main/disk/"
    local localPath = "/disk/"
    print("LEGEND:\nFILENAME DOWNLOAD_STATUS\nWhere C is correct and X means that there was an error while downloading the file")
    for i,v in pairs(files) do
        local r = http.get(downPath..v)
        write("["..tostring(i).."/"..tostring(#files).."] "..v)
        local f = io.open(localPath..v,"w")
        local buff = r.readAll()
        if r==nil or buff=="" then 
            write(" [X]\n")
        else
            f:write(buff)
            write(" [C]\n")
        end
        f:close()
        r.close()
    end
    write("Doing final tweaks...")
    fs.move("/disk/startup.lua","/disk/startup")
    write("DONE\n")
    print("Do you want to reboot now?")
    write("Y/N:")
    local yn = io.read()

    while string.lower(yn)~="y" and string.lower(yn)~="n" and string.lower(yn)~="no" and string.lower(yn)~="yes" do
        write("Y/N:")
        yn = io.read()
    end
    if string.lower(yn)=="yes" or string.lower(yn)=="y" then 
        os.reboot()
    end
end