local _settings = {content = {}}

assert(_G.Kernel~=nil,"[LIB ERROR] Kernel's object is non-existent!")

local function splitstr (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function _settings:GetValue(sett_name)
    return _settings.content[sett_name]
end

function _settings:SetValue(sett_name,val)
    if type(val) ~= "boolean" and type(val) ~= "number" and type(val) ~= "string" and type(val) ~= "nil" and type(val) ~= "table" then
        error("settings:SetValue : Value provided isn't a primitive type.",0)
        return
    end
    _settings.content[sett_name]=val
end


function _settings:ApplyFromFile(filepath) 
    local cont = io.lines(_G.Kernel.fixPath(filepath))
    for line in cont do
        local cache = splitstr(line,"=")
        local name = cache[1]
        local value = cache[2]
        _settings:SetValue(name,value)
    end
end

return _settings