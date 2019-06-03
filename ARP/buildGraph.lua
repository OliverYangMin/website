local function FilterGraph(cFlights, craft)   --筛选航班
    local map = {}
    for i,ir in ipairs(cFlights) do
        if ir.water and (not craft.water) then   --涉水约束
            goto continue
        elseif not ir.atp[craft.atp] then        --航班类型约束
            goto continue
        elseif ir.time1<craft.time1 then         --飞机最早可用时间约束
            goto continue
        elseif math.abs(ir.old.atp - craft.atp)==3 then    ---relaxation
            goto continue
        else
            table.insert(map, DeepCopy(ir))
        end 
        ::continue::
    end 
    map[0] = {port2=craft.start, time1=craft.time1, time2=craft.time1, gtime=0, id=0,date=1}--, dual=0} --起点
    map[#map+1] = {port1=craft.base[2], time1=math.huge, id=#map+1,date=2} --, dual=0}                  --终点
    return map
end 

function build_craft_graphs()
    nodes = {}
    crafts = {}
    fSet = {}
    for c,craft in pairs(aircrafts) do 
        if craft.dis then                          --受影响飞机
            table.insert(crafts, craft)
        end 
        if #craft.rot==0 then                      --完全空闲飞机
            table.insert(crafts, craft)
        end 
        if craft.id==148 or craft.id==159 or craft.id==70 or craft==86 or craft==101 then   --部分空闲飞机
            table.insert(crafts, craft)
        end 
    end 
    
    for c,craft in ipairs(crafts) do
        craft.dayN = 1440 * 3
        for i=1,#craft.rot do
            if craft.rot[i].date<=2 then
                craft.rot[i].isin = true
                table.insert(nodes, craft.rot[i])
            end 
            if craft.rot[i].date==3 then
                craft.dayN = craft.rot[i].time1
                break
            end 
        end 
    end
    

    local base_time = os.time{year=YEAR,month=MONTH,day=DAY,hour=0,sec=0}
    io.output('result.csv')
    io.write('ID,date,flight,port1,port2,time1,time2,cID,ctype,pas,seats,wt\n')
    for f,flight in ipairs(flights) do
        if not flight.isin then
            io.write(string.format('%d,', flight.info.ID))
            io.write(os.date(YEAR .. '-%m-%d  %X,', (flight.date-1) * 1440 * 60 + base_time))
            io.write(string.format('3U%d,', flight.info.flight))
            io.write(string.format('AIRPORT_%d,', flight.port1))
            io.write(string.format('AIRPORT_%d,', flight.port2))
            io.write(os.date(YEAR .. '-%m-%d  %X,', flight.time1*60 + base_time))
            io.write(os.date(YEAR .. '-%m-%d  %X,', flight.time2*60 + base_time))
            io.write(string.format('AC_%d,', flight.old[1]))
            io.write('TYPE_', string.char(flight.old.atp+64),',')
            io.write(string.format('%d,', flight.old.pas))
            io.write(string.format('%d,', flight.old.seats))
            io.write(string.format('%d\n',flight.wt))
        end 
    end 

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