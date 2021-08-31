term.clear()
term.setCursorPos(1,1)
while true do
      write("->")
      local comm = io.read()
      if comm=="shutdown" then os.shutdown() end 
end
