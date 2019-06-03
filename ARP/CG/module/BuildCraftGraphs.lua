local function FilterGraph(cFlights, craft)
    local map = {}
    for i,ir in ipairs(cFlights) do
        if ir.water and (not craft.water) then
            goto continue
        elseif not ir.atp[craft.atp] then
            goto continue
        elseif ir.time1<craft.time1 then
            goto continue
--        elseif ir.old.atp==4 and craft.atp<3 then    ---relaxation
--            goto continue
        elseif math.abs(ir.old.atp - craft.atp)==3 then    ---relaxation
            goto continue
        else
            table.insert(map, DeepCopy(ir))
        end 
        ::continue::
    end 
    map[#map+1] = {port1=craft.base[1], time1=math.huge, id=#map+1} --, dual=0}
    map[0] = {port2=craft.start, time1=craft.time1, time2=craft.time1, gtime=0, id=0}--, dual=0}
    return map
end 

function build_craft_graphs()
    nodes = {}
    crafts = {}
    fSet = {}
    for c,craft in pairs(aircrafts) do  --or craft.id==128 
--        if #craft.rot==0 then
--            table.insert(crafts, craft)
--        elseif craft.rot[1].date==1 then
--            if craft.start==57 then-- or craft.start==50 then--or craft.start==206  then--or  craft.base[1]==57 or craft.base[1]==50 or craft.base[1]==206 or craft.base[1]==150 then
--                table.insert(crafts, craft)
--            end 
           
--        end 
        if craft.start==57 then 
            if #craft.rot==0  then 
                table.insert(crafts, craft)
            elseif craft.dis then --craft.rot[1].time1<720 then
                table.insert(crafts, craft)
            elseif craft.id==148  then
                table.insert(crafts, craft)
            end 
        elseif craft.start==50 then 
            table.insert(crafts, craft)
        elseif craft.start==206 then
            table.insert(crafts, craft)
        end 
--            if 
--            or craft.rot[1].time1<600 then  
--                if not (#craft.rot>0 and craft.rot[1].date>1) then
--                    table.insert(crafts, craft)
--                end
--            end 
        --end 
    end 
    
    for c,craft in ipairs(crafts) do
        craft.day2 = 2880
        for i=1,#craft.rot do
            if craft.rot[i].date==1 then
                craft.rot[i].isin = true
                table.insert(nodes, craft.rot[i])
            end 
            if craft.rot[i].date==2 then
                craft.day2 = craft.rot[i].time1
                break
            end 
        end 
    end
     local base_time = os.time{year=2018,month=2,day=28,hour=0,sec=0}
    io.output('leftover.csv')
    io.write('ID,date,flight,port1,port2,time1,time2,cID,ctype,pas,seats,wt\n')
    for f,flight in ipairs(flights) do
        if not flight.isin then
            io.write(string.format('%d,', flight.info.ID))
            io.write(os.date('2018-%m-%d  %X,', (flight.date-1) * 1440 * 60 + base_time))
            io.write(string.format('3U%d,', flight.info.flight))
            io.write(string.format('AIRPORT_%d,', flight.port1))
            io.write(string.format('AIRPORT_%d,', flight.port2))
            io.write(os.date('2018-%m-%d  %X,', flight.time1*60 + base_time))
            io.write(os.date('2018-%m-%d  %X,', flight.time2*60 + base_time))
            io.write(string.format('AC_%d,', flight.old[1]))
            io.write('TYPE_', string.char(flight.old.atp+64),',')
            io.write(string.format('%d,', flight.old.pas))
            io.write(string.format('%d,', flight.old.seats))
            io.write(string.format('%d\n',flight.wt))
        end 
    end 
    io.close()
    for c=1,#crafts do
        fSet[c] = FilterGraph(nodes, crafts[c])
        
        local cnodes = {}
        for i=0,#fSet[c] do
            table.insert(cnodes, i)
        end
        local adj = {}   --邻接矩阵
        local edges = {}
        
        adj[0] = {}
        for j=1,#fSet[c]-1 do
            if fSet[c][0].port2==fSet[c][j].port1 and fSet[c][0].time1<=fSet[c][j].time1 then
                table.insert(edges, {0,j})
                table.insert(adj[0], j)
            end 
        end 
        for i=1,#fSet[c]-1 do
            adj[i] = {}
            for j=1,#fSet[c] do
                if i~=j then  
                    local min_gtime = math.ceil(airports[fSet[c][i].port2].turn[crafts[c].atp]*2/3)
                    if fSet[c][i].port2==fSet[c][j].port1 and fSet[c][i].time1+min_gtime<=fSet[c][j].time1 then
                        table.insert(edges, {i,j})
                        table.insert(adj[i], j)
                    end 
                end 
            end 
        end 
        table.insert(adj, {})
        fSet[c].adj = adj
        fSet[c].order = TopoSort(cnodes, edges)
     
        for i=1,#fSet[c] do
            fSet[c][i].labels = {}
        end 
        fSet[c][0].labels = {{0;cost=0, delay=0, cut=0, cuts={}}}
    end
end 