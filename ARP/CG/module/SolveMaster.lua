local function FlightInRoute(rotation, flight)
    for i=1,#rotation do
        if rotation[i].id==flight.id then 
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
    for i=1,#nodes do
        if nodes[i].dis then
            table.insert(obj, (1800 + 4.5 * nodes[i].old.pas - 1200 - 120/60*30) * nodes[i].wt) 
        else
            table.insert(obj, (1800 + 6 * nodes[i].old.pas) * nodes[i].wt)   ---passenger cancel cost may be reduced
        end 
    end 
    
    for i=1,#routes do
        table.insert(obj, routes[i].cost)
    end 
    SetObjFunction(master, obj, 'min')
    
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
   
    reset()
    for j=1,#routes do
        coeff[#nodes+j] = routes[j].cut
    end 
    AddConstraint(master, coeff, '<=', 23)
    
    
    for i=1,#crafts do
        reset()
        for j=1,#routes do 
            if routes[j].craft==crafts[i].id then 
                coeff[#nodes+j] = 1
            end 
        end 
        AddConstraint(master, coeff, '<=', 1)
    end 
    for r,route in ipairs(routes) do
        routes[r] = nil
    end 
    
      
    if not relaxed then
        for i=1,#obj do
            SetBinary(master, i)
        end
    end
    for i=1,#obj do
        reset()
        coeff[i] = 1
        AddConstraint(master, coeff, '>=', 0)
        AddConstraint(master, coeff, '<=', 1)
    end 
    WriteLP(master, "CG.mps")
    os.remove("CG_solution.sol")--clear the results
    os.execute("cplex.exe -c \"read CG.mps\" \"opt\" \"write CG_solution.sol\" \"quit\"")
    local i=1
    local var = {}
    inputf = io.open("CG_solution.sol")
    obj = nil
    for line in inputf:lines() do
        if not obj then
            obj = string.match(line, "objectiveValue=\"([-%d%.]+)\"")
        end
        if not var[i] then
            var[i] = string.match(line, "variable.+value=\"([-%d%.]+)\"")
            if var[i] then
                i = i+1
            end
        end
    end
    print('obj:',obj+54567)
    inputf:close()
    
    for i=1,#nodes do
        if var[i]=='1' then 
            print('flight',nodes[i].info.ID, 'be canceled cost',(1800 + 6 * nodes[i].old.pas) * nodes[i].wt)
        end     
    end 
--    for i=1,#routes do
--        if var[#nodes+i]=='1' then
--            print(routes[i].cost, ' route', i)
--            io.output('Rots\\route' .. routes[i].craft .. '.csv')
--            io.write('FlightID, Date, port1, port2, time1, time2, craft, atp, pas, seats, wt, ftime, origin gtime, normal gtime, min gtime, cut1, cut2, craft\n')
--            for f,flight in ipairs(routes[i]) do
--                io.write(flight.info.ID,',')
--                io.write(flight.date,',')
--                io.write(flight.port1,',')
--                io.write(flight.port2,',')
--                io.write(flight.time1,',')
--                io.write(flight.time2,',')
--                io.write(flight.old[1],',')
--                io.write(flight.old.atp,',')
--                io.write(flight.old.pas,',')
--                io.write(flight.old.seats,',')
--                io.write(flight.wt,',')
--                io.write(flight.ftime,',')
--                io.write(flight.gtime,',')
--                io.write(airports[flight.port2].turn[aircrafts[routes[i].craft].atp],',')
--                io.write(math.ceil(airports[flight.port2].turn[aircrafts[routes[i].craft].atp]/3*2),',')
--                io.write(routes[i].cuts[f] and 1 or 0,',')
--                io.write(routes[i].cuts[f] and routes[i].cuts[f] or 0,',')
--                io.write(routes[i].craft,'\n')
----                io.write(flight.cut1,',')
----                io.write(flight.cut2,',')
----                io.write(var[NUM*4+num],',')
----                io.write(math.min(var[NUM*0+num]*flight.cut1, var[NUM*4+num]),',')
----                io.write(var[NUM*2+num],'\n')
--            end 
--            io.close()
--        end 
--    end 
    
--    local duals = {GetDuals(master)}
--    for i=1,#nodes do
--        nodes[i].dual = duals[i]
--    end 
--    for i=1,#crafts do
--        crafts[i].dual = duals[#nodes+i]
--    end 
    --print("The objective value of the master: ", GetObjective(master))
    Delete(master)
    return true
end 