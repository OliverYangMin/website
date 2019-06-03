local function Csv2Matrix(data, ifhead)
	local inputdata = io.input(data)
	local matrix = {}
	
	local i = 1
	for line in inputdata:lines() do
		if ifhead == 0 then
			matrix[i] = {}
			for element in string.gmatch(line, "[0-9%.%_%a]+") do
				table.insert(matrix[i], tonumber(string.match(element,'[0-9%.]+')))
                local item = string.match(element,'_[ABCD]')
                if item then 
                    table.insert(matrix[i], string.byte(item, 2) - 64)
                end 
			end
			i = i+1
		else
			ifhead = 0
		end
	end
	return matrix
end

local function FileLoad(url, names, tab)
    local Inf = Csv2Matrix(url, 1)
    local data = {}
    for i=1,#Inf do
        local temp = {}
        for n,name in ipairs(names) do
            if name then 
                temp[name] = Inf[i][n]
            end 
        end 
        if tab then
            temp[tab] = {}
            for j=1,#Inf[i]-#names do
                temp[tab][j] = Inf[i][j+#names] == 1
            end 
        end 
        table.insert(data, temp)
    end
    return data
end 
local function GetFlights()
    local file1 = 'data\\BD_flights.csv'
    local file2 = 'data\\BD_waterways.csv'
    local file3 = 'data\\BD_line_type.csv'
    
    flights = FileLoad(file1, {'id', 'date', false,'dport', 'aport', 'dtime', 'atime', 'origin','atype', 'passenger','seats', 'weight'})
    for f,flight in ipairs(flights) do  
        flight.index = f
        flight.dtime = math.floor((flight.dtime-43159)*1440+0.5)
        flight.atime = math.floor((flight.atime-43159)*1440+0.5)
        flight.ftime = flight.atime - flight.dtime
        flight.date  = flight.date - 43159 + 1
    end 
    
    local Inf = Csv2Matrix(file2, 1)
    for f,flight in ipairs(flights) do
        flight.water = false
        for i=1,#Inf do
            if flight.dport==Inf[i][1] and flight.aport==Inf[i][2] then 
                flight.water = true 
                break
            end
        end     
    end 
    
    Inf = Csv2Matrix(file3, 1)
    for f,flight in ipairs(flights) do
        flight.ptype = {true, true, true, true}
        for i=1,#Inf do
            if flight.dport==Inf[i][1] and flight.aport==Inf[i][2] then 
                for j=1,4 do
                    flight.ptype[j] = Inf[i][2+j]==1
                end 
                break
            end
        end     
    end 
end 

local function GetAirports()
    local file1 = 'data\\BD_airports_type.csv'
    local file2 = 'data\\BD_airports_trunaround.csv'
    local file3 = 'data\\BD_airports_time.csv'
    airports = {}
    for f,flight in ipairs(flights) do
        airports[flight.dport] = airports[flight.dport] or {otime=0, ctime=1440, ptype={true,true,true,true}, turn={}}
        airports[flight.aport] = airports[flight.aport] or {otime=0, ctime=1440, ptype={true,true,true,true}, turn={}}
    end 
    
    local Inf = Csv2Matrix(file1, 1)
    for i=1,#Inf do 
        if airports[i] then 
            for j=1,4 do
                airports[i].ptype[j] = Inf[i][j+1]==1
            end 
        end 
    end 
    
    Inf = Csv2Matrix(file2, 1)
    for i=1,#Inf do 
        if airports[i] then 
            for j=1,4 do
                airports[i].turn[j] = Inf[i][j+1]
            end 
        end 
    end 
    
    Inf = Csv2Matrix(file3, 1)
    for i=1,#Inf do 
        if airports[Inf[i][1]] then 
            airports[Inf[i][1]].otime,airports[Inf[i][1]].ctime = Inf[i][2]*60+Inf[i][3], Inf[i][4]*60+Inf[i][5]
        end 
    end 
end 

local function GetAircrafts()
    local file1 = 'data\\BD_aircrafts_water.csv'
    aircrafts = {}
    for f,flight in ipairs(flights) do        
        if aircrafts[flight.origin] then 
            table.insert(aircrafts[flight.origin].rotation, flight)
        else
            aircrafts[flight.origin] = {id=flight.origin, rotation={flight}, ptype=flight.atype, seats=flight.seats, water=true}
        end 
    end 
    
    for _, craft in pairs(aircrafts) do
        table.sort(craft.rotation, function(a,b) return a.dtime<b.dtime end)
        craft.start = craft.rotation[1].dport
        if craft.start==57 then 
            craft.time1 = 600
        else 
            craft.time1 = airports[craft.start].otime    
        end 
        craft.base = {}
        for i=1,craft.rotation[1].date-1 do
            table.insert(craft.base, craft.rotation[1].dport)
        end 
        for i=2,#craft.rotation do
            if craft.rotation[i].date==#craft.base+1 then
                table.insert(craft.base, craft.rotation[i-1].dport)
            end 
        end 
        for i=1,4-#craft.base do
            table.insert(craft.base, craft.rotation[#craft.rotation].dport)
        end 
    end 
    
    local Inf = Csv2Matrix(file1, 1)
    for i=1,#Inf do
        if aircrafts[Inf[i][1]] then 
            aircrafts[Inf[i][1]].water = false
        end 
    end 
    
    
--    idlecrafts = {}
--    local Inf = Csv2Matrix(file2, 1)
--    local crafts = {}
--    for i=1,#Inf do
--        if crafts[Inf[i][2]] then
        
--        else
--            crafts[Inf[i][2]] = {}
--        end 
--    end 
end 




function ReadData()
    GetFlights()
    GetAirports()
    GetAircrafts()
    dayFlights = {0,0,0,0}
    for i=1,#flights do
        dayFlights[flights[i].date] = dayFlights[flights[i].date] + 1
    end 
end 