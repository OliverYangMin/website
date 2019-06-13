Airport = {}
Airport.__index = Airport

function Airport:new()
    local self = {atp = {true,true,true,true}, turn = {}}
    setmetatable(self, Airport)
    return self
end 

function Airport:checkTime(time)
    if self.tw then 
        if self.tw[2]>1440 then 
            return not (time % 1440 < port.tw[1] and time % 1440 > port.tw[2] % 1440)
        else
            return time % 1440 < port.tw[1] or time % 1440 > port.tw[2] 
        end 
    end
    return true
end

