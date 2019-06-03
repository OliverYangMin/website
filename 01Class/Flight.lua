Flight = {}
Flight.__index = Flight

function Flight:new(id, cInf)
    local self = {id = id, date = cInf[2], port1 = cInf[4], port2 = cInf[5], time1 = cInf[6], time2 = cInf[7], wt = cInf[12], water = false, atp = {true, true, true, true}}
    self.info = {ID = cInf[1], flight = cInf[3]}
    self.old  = {cInf[8]; atp = cInf[9], seats = cInf[11], pas = cInf[10]}
    self.ftime = self.time2 - self.time1
    self.date  = self.date - 43158   
    -- .water, .atp = {true, true, true, true}
    setmetatable(self, Flight)
    return self
end 



Airport = {}
Airport.__index = Airport

function Airport:new()
    local self = {atp = {true,true,true,true}, turn = {}}
    setmetatable(self, Airport)
    return self
end 



