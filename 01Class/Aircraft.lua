Aircraft = {}
Aircraft.__index = Aircraft 

function Aircraft:new(id, rot, atp, seats)
    local self = {id = id, rot = rot, atp = atp, seats = seats, water = true, base = {}}
    setmetatable(self, Aircraft)
    return self
end 

function Aircraft:getNextNodes(left)
    local tmp = {}
    
    for i=#left,1,-1 do
        if isIndegreeZero(left[i], self.edges) then
            tmp[#tmp+1] = left[i]
            table.remove(left, i)
        end 
    end
    
    if #tmp==0 then return -1 end 
    
    for i=1,#tmp do
        for j=#self.edges,1,-1 do 
            if self.edges[j][1] == tmp[i] then  
                table.remove(self.edges, j)
            end 
        end 
    end 
    return tmp
end 

function Aircraft:topoSort()
    local result, left = {}, {}
    for i=0,#self.fSet do table.insert(left, i) end 
    repeat
        local nodes = self:getNextNodes(left)
        if nodes == -1 then error('there is a circle') end 
        for i=#nodes,1,-1 do
            table.insert(result, nodes[i])
        end 
    until #left == 0 
    
    self.edges = nil
    self.order = result
end 

function Aircraft:filterGraph()   --筛选航班
    local map = {}
    for i,flight in ipairs(flights) do
        if flight.water and (not self.water) then   --涉水约束
            goto continue
        elseif not flight.atp[self.atp] then        --航班类型约束
            goto continue
        elseif flight.time1 < self.time1 then         --飞机最早可用时间约束
            goto continue
        elseif math.abs(flight.old.atp - self.atp)==3 then    ---relaxation
            goto continue
        else
            table.insert(map, i)
        end 
        ::continue::
    end 
    map[0], map[#map+1] = 0, -1 
    flights[0]  = {port2 = self.start,   time1 = self.time1, time2 = self.time1, gtime = 0, id = 0, date = 1, dual = 0} 
    --起点
    flights[-1] = {port1 = self.base[1], time1 = math.huge,  id=#map+1, date=1, dual=0}                  --终点
    return map
end 

function Aircraft:buildGraph()
    self.fSet = self:filterGraph()
    self.edges, self.adj = {}, {}
    for i=0,#self.fSet do self.adj[i] = {} end 
    
    for j=1,#self.fSet-1 do
        if flights[self.fSet[0]].port2 == flights[self.fSet[j]].port1 and flights[self.fSet[0]].time1 <= flights[self.fSet[j]].time1 then
            table.insert(self.edges, {0,j})
            table.insert(self.adj[0], self.fSet[j])
        end 
    end 
    
    for i=1,#self.fSet-1 do
        for j=1,#self.fSet do
            if i~=j then  
                local min_gtime = math.ceil(airports[flights[self.fSet[i]].port2].turn[self.atp] * 2 / 3)
                if flights[self.fSet[i]].port2 == flights[self.fSet[j]].port1 and flights[self.fSet[i]].time1 + min_gtime <= flights[self.fSet[j]].time1 then
                    table.insert(self.edges, {i,j})
                    table.insert(self.adj[i], self.fSet[j])
                end 
            end 
        end 
    end 
    self:topoSort()
end 

function Aircraft:findRoute()
    flights[0]  = {labels = {Label:new()}, port2 = self.start,   time1 = self.time1, time2 = self.time1, gtime = 0, id = 0, date = 1, dual = 0} 
    flight[0].labels[1].cost = - self.dual
    --起点
    flights[-1] = {labels = {}, port1 = self.base[1], time1 = math.huge,  id=#map+1, date=1, dual=0}                  --终点
    for i=1,#self.order do
        for _,label in ipairs(flights[self.fSet[self.order[i]]].labels) do
            for a,adj in ipairs(self.adj[self.order[i]]) do
                label:extend(adj, self)
            end 
        end 
    end 
    local min_route = {cost = -0.1}
    for l,label in ipairs(flights[-1].labels) do
        if label.cost < min_route.cost then
            min_route = label:to_route()
        end 
    end 
    return min_route
end 