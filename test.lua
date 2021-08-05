function Wait(seconds)
  local start = os.time()
  repeat until os.time() > start + seconds
end

co = coroutine.create(function() while true do Wait(5) end end)

coroutine.resume(co)

print(coroutine.status(co))
