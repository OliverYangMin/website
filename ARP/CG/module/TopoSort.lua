local function isin(tab, value)
    for i=1,#tab do
        if tab[i]==value then
            return i
        end 
    end 
    return false
end 

function DeepCopy(object)      
    local SearchTable = {}  

    local function Func(object)  
        if type(object) ~= "table" then  
            return object         
        end  
        local NewTable = {}  
        SearchTable[object] = NewTable  
        for k, v in pairs(object) do  
            NewTable[Func(k)] = Func(v)  
        end     

        return setmetatable(NewTable, getmetatable(object))      
    end    

    return Func(object)  
end 

local function indegree0(v, edges)
    if #v==0 then 
        return false 
    end 
    local tmp = DeepCopy(v)
    for _,edge in pairs(edges) do
        local include = isin(tmp, edge[2]) 
        if include then 
            table.remove(tmp, include)
        end 
    end 
    if #tmp==0 then 
        return -1
    end 
    for _,node in ipairs(tmp) do
        for _,edge in pairs(edges) do
            if edge[1]==node or edge[2]==node then 
                edges[_] = nil
            end 
        end 
    end 
    for i=1,#tmp do
        local pos = isin(v, tmp[i])
        table.remove(v, pos)
    end 
    return tmp
end 


function TopoSort(v, e)
    local result = {}
    while true do
        local nodes = indegree0(v, e)
        if not nodes then break end 
        if nodes==-1 then 
            error('there is a circle')
            return false 
        end 
        for i=1,#nodes do
            table.insert(result, nodes[i])
        end 
    end 
    return result
end 

--v = {1,2,3,4,5}
--e = {{1,2},{1,4},{2,3},{4,3},{4,5},{5,3}}

--res = topoSort(v, e)
--print(table.concat(res))




