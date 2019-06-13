Delta = {}
Delta.__index = Delta

function Delta:new()
    local self = {}
    setmetatable(self, Delta)
    return self
end 

function Delta:pasDelay(cTime)
    if cTime == 0 then return 0 end 
    local time = {1,2,4,12,24}
    local index = {1,1.5,2,3,5}
    for i=1,#time do
        if cTime <= time[i] * 60 then 
            return index[i]
        end 
    end 
    error('This passenger should be canceled for delay more than 24 hours')
end 

function Delta:flightDelay(cFlight, delay)
    if delay > 0 then 
        if cFlight.dis then 
            return (delay / 2 + (self:pasDelay(delay + 120) - 1.5) * cFlight.old.pas) * cFlight.wt
        else 
            return (1200 + delay / 2 + self:pasDelay(delay) * cFlight.old.pas) * cFlight.wt 
        end 
    end 
    return 0
end

function Delta:swapCraft(cFlight, ncraft)
    local cost = 0 
    if cFlight.old[1] ~= ncraft.id then
        if cFlight.old.atp ~= ncraft.atp then
            local typeSwap = {{0,1,2,3},{1,0,1.5,2.5},{2,1.5,0,2},{3,2.5,2,0}}
            cost = cost + 300 * typeSwap[ncraft.atp][cFlight.old.atp]        
        end 
        if cFlight.old.pas - ncraft.seats > 0 then
            if cFlight.dis then 
                cost = cost + (cFlight.old.pas - ncraft.seats) * (6 - 1.5)
            else 
                cost = cost + (cFlight.old.pas - ncraft.seats) * 6
            end 
        end 
        return cost * cFlight.wt 
    end 
    return 0
end 

function Delta:checkAirport(flight, delay)
    return airports[flight.port1]:checkTime(flight.time1 + delay) and airports[flight.port2]:checkTime(flight.time2 + delay) 
end 