Master = {}
Master.__index = Master

local function resetCoeff(cSize, value)
    local coeff = {}
    for i=1,cSize do
        coeff[i] = value or 0
    end 
    return coeff
end 

function Master:new(cRoutes)
    local self = {obj = {}, routes = cRoutes}
    setmetatable(self, Master)
    self.lp = CreateLP()
    self:buildModel()
    return self
end 

function Master:buildModel()
    ---the cost of flights being canceled
    for i=1,#flights do
        if flights[i].dis then
            table.insert(self.obj, (P[1] + (P[6] - 1.5) * flights[i].old.pas - P[2] - 120 * P[5]) * flights[i].wt)   
        else
            table.insert(self.obj, (P[1] + P[6] * flights[i].old.pas) * flights[i].wt)   ---passenger cancel cost may be reduced
        end 
    end 
    
    ---the cost for every route has been found
    for i=1,#self.routes do
        table.insert(self.obj, self.routes[i].cost)
    end 
    SetObjFunction(master, obj, 'min')
    
    ---constraint 1 every flight been execute by only one route or be canceled
    for i=1,#nodes do
        local coeff = resetCoeff(#self.obj)
        coeff[i] = 1
        for j=1,#routes do
            if routes[j]:isIn(flights[i]) then 
                coeff[#flights + j] = 1
            end 
        end 
        AddConstraint(master, coeff, '=', 1)
    end
    
    for i=1,#aircrafts do
        coeff = resetCoeff(#self.obj)
        for j=1,#routes do 
            if routes[j].craft == aircrafts[i].id then 
                coeff[#flights+j] = 1
            end 
        end 
        AddConstraint(master, coeff, '<=', 1)
    end 
    
    --for i=1,4 do                 ---if the flight in day 1,2,3,4
    local coeff = resetCoeff(#self.obj)
    for j=1,#routes do
        coeff[#flights + j] = routes[j].cut
    end 
    AddConstraint(master, coeff, '<=', math.floor(0.05 * dayFlights[i]))
        
--        coeff = resetCoeff(#self.obj)
--        for j=1,#flights do
--            coeff[j] = 1
--        end 
--        AddConstraint(master, coeff, '<=', math.floor(0.1 * dayFlights[i]))
    --end 
    
    ---every aircraft only execute no more than one route

end 

function Master:solve(isInteger)
    if isInteger then
        for i=1,#obj do
            SetBinary(master, i)
        end
    else
        for i=1,#obj do
            coeff = resetCoeff(#self.obj)
            coeff[i] = 1
            AddConstraint(master, coeff, '<=', 1)
        end 
    end
    WriteLP(master, "master.mps")
    os.remove("master_solution.sol")--clear the results
    os.execute("cplex.exe -c \"read master.mps\" \"opt\" \"write master_solution.sol\" \"quit\"")
end 

function Master:getResult()
    local i,j = 1,1
    local self.var = {}
    inputf = io.open("master_solution.sol")
    self.obj = nil
    self.duals = {}
    for line in inputf:lines() do
        if not obj then
            obj = string.match(line, "objectiveValue=\"([-%d%.]+)\"")
        end
        if not self.duals[i] then
            self.duals[i] = string.match(line, "constraint.+dual=\"([-%d%.]+)\"")
            if self.duals[i] then
                self.duals[i] = tonumber(self.duals[i])
                i = i + 1
            end
        end 
        if not self.var[j] then
            self.var[j] = string.match(line, "variable.+value=\"([-%d%.]+)\"")
            if self.var[j] then
                j = j+1
            end
        end
    end
    --local base_cost = 54567
    --print('obj:',obj + base_cost)             ---@@@@@@@@@@@@@@@@@@@
    inputf:close()
    
--    for i=1,#nodes do
--        if var[i]=='1' then 
--            print('flight',nodes[i].info.ID, 'be canceled cost',(1800 + 6 * nodes[i].old.pas) * nodes[i].wt)
--        end     
--    end 
    --return true
end 

function Master:setDuals()
    for f,flight in ipairs(flights) do
        flight.dual = self.duals[f]
    end 
    for c,craft in pairs(aircrafts) do
        craft.dual = self.duals[#flights+c]
    end 
    cut_price = self.duals[#self.duals]
end 

function Master:solveSubproblem()
    local routes = {}
    for c,craft in pairs(aircrafts) do
        local route = craft:findRoute()
        if route.cost < -0.1 then 
            routes[#routes+1] = route
        end
    end 
    return routes 
end 