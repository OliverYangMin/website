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

function ReadCSV(data, ifhead)
	local inputdata = io.input(data)
	local matrix = {}
	
	local i = 1
	for line in inputdata:lines() do
		if ifhead == 0 then
			matrix[i] = {}
			for element in string.gmatch(line, "[0-9%.]+") do
				table.insert(matrix[i], tonumber(string.match(element,'[0-9%.]+')))
			end
			i = i + 1
		else
			ifhead = 0
		end
	end
	return matrix
end

--function isin(tab, value)
--    for i=1,#tab do
--        if tab[i]==value then
--            return i
--        end 
--    end 
--    return false
--end 

function isIndegreeZero(vertex, edges)
    for _,edge in ipairs(edges) do
        if edge[2] == vertex then
            return false
        end
    end
    return true
end