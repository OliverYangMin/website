Route = {}
Route.__index = Route

function Route:new(craft)
    local self = {craft = craft.id}
    setmetatable(self, Route)
    return self
end 

function Route:append(cFlightid)
    self[#self+1] = cFlightid
end 

function Route:isIn(cFlight)
    for i=1,#self do
        if self[i].id == flight.id then 
            return true
        end 
    end
end

