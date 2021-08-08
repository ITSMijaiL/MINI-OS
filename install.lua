print("MINI-OS installer")
print("[V0.0.1]")

print("Are you sure that you want to install this unstable system?")
write("Y/N:")
local yn = io.read()

while string.lower(yn)~="y" and string.lower(yn)~="n" and string.lower(yn)~="no" and string.lower(yn)~="yes" do
    write("Y/N:")
    yn = io.read()
end

if string.lower(yn)=="yes" or string.lower(yn)=="y" then
    --TODO:make directories along with kernel, insert startup.lua, insert libs and insert services to be initiated in (disk/rootfs)/etc/on_init/
end