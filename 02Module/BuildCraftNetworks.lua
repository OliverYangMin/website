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

function build_craft_networks()
    nodes = {}
    fSet = {}
    
    for c,craft in pairs(aircrafts) do
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

    for c,craft in pairs(aircrafts) do
        fSet[c] = FilterGraph(nodes, craft)
        
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
                    local min_gtime = math.ceil(airports[fSet[c][i].port2].turn[craft.atp]*2/3)
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
        fSet[c][0].labels = {{0;cost=0, delay=0, cut1=0,cut2=0, cuts={}}}
    end
end 