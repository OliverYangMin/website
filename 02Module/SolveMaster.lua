local function FlightInRoute(route, flight)
    for i=1,#route do
        if route[i].id==flight.id then 
            return true
        end 
    end 
    return false
end

function SolveMaster(relaxed)
    local function reset()
        coeff = {}
        for i=1,#nodes+#routes do
            coeff[i] = 0
        end 
        return coeff
    end

    local master = CreateLP()    
    local obj = {}
    
    ---the cost of flights being canceled
    for i=1,#nodes do
        if nodes[i].dis then
            table.insert(obj, (P[1] + (P[6] - 1.5) * nodes[i].old.pas - P[2] - 120 * P[5]) * nodes[i].wt)    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        else
            table.insert(obj, (P[1] + P[6] * nodes[i].old.pas) * nodes[i].wt)   ---passenger cancel cost may be reduced
        end 
    end 
    ---the cost for every route has been found
    for i=1,#routes do
        table.insert(obj, routes[i].cost)
    end 
    SetObjFunction(master, obj, 'min')
    ---constraint 1 every flight been execute by only one route or be canceled
    for i=1,#nodes do
        reset()
        coeff[i] = 1
        for j=1,#routes do
            if FlightInRoute(routes[j], nodes[i]) then 
                coeff[#nodes+j] = 1
            end 
        end 
        AddConstraint(master, coeff, '=', 1)
    end
   
    for i=1,4 do                 ---@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ if the flight in day 1,2,3,4
        reset()
        for j=1,#routes do
            coeff[#nodes+j] = routes[j].cut
        end 
        AddConstraint(master, coeff, '<=', math.floor(0.05*dayFlights[i]))
        reset()
        for j=1,#nodes do
            coeff[j] = 1
        end 
        AddConstraint(master, coeff, '<=', math.floor(0.1*dayFlights[i]))
    end 
    ---every aircraft only execute no more than one route
    for i=1,#crafts do
        reset()
        for j=1,#routes do 
            if routes[j].craft==crafts[i].id then 
                coeff[#nodes+j] = 1
            end 
        end 
        AddConstraint(master, coeff, '<=', 1)
    end 
    
--    for r,route in ipairs(routes) do
--        routes[r] = nil
--    end 
    
      
    if not relaxed then
        for i=1,#obj do
            SetBinary(master, i)
        end
    else
        for i=1,#obj do
            reset()
            coeff[i] = 1
            AddConstraint(master, coeff, '>=', 0)
            AddConstraint(master, coeff, '<=', 1)
        end 
    end
   
    WriteLP(master, "CG.mps")
    os.remove("CG_solution.sol")--clear the results
    os.execute("cplex.exe -c \"read CG.mps\" \"opt\" \"write CG_solution.sol\" \"quit\"")
    local i,j = 1,1
    local var = {}
    inputf = io.open("CG_solution.sol")
    obj = nil
    dual = {}
    for line in inputf:lines() do
        if not obj then
            obj = string.match(line, "objectiveValue=\"([-%d%.]+)\"")
        end
        if not dual[i] then
            dual[i] = string.match(line, "constraint.+dual=\"([-%d%.]+)\"")
            if dual[i] then
                dual[i] = tonumber(dual[i])
                i = i + 1
            end
        end 
        if not var[j] then
            var[j] = string.match(line, "variable.+value=\"([-%d%.]+)\"")
            if var[j] then
                j = j+1
            end
        end
    end
    local base_cost = 54567
    print('obj:',obj + base_cost)             ---@@@@@@@@@@@@@@@@@@@
    inputf:close()
    
    for i=1,#nodes do
        if var[i]=='1' then 
            print('flight',nodes[i].info.ID, 'be canceled cost',(1800 + 6 * nodes[i].old.pas) * nodes[i].wt)
        end     
    end 
    
    for 
    
    
    Delete(master)
    
    return true
end 