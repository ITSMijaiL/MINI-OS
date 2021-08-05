local syscalls = {}


function DoCall(number,...)
    local args = {...}
    local function CheckArgs(argsAmnt) 
        assert(args>argsAmnt-1,"System call #"..tostring(number).." needs "..tostring(argsAmnt).." arguments!")
    end
    if number==0 then --EXIT
        CheckArgs(2)
        
    elseif number==1 then
    end
end


syscalls.OPEN = function(filepath)
    io.open()
end