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

 local function Disrupted(cRotations)
    if     cRotations[1].port1 == PORT1 and cRotations[1].time1 < OTIME1 and cRotations[1].time1 >= CTIME1 then
        return 1
    elseif cRotations[1].port2 == PORT1 and cRotations[1].time2 < OTIME1 and cRotations[1].time2 >= CTIME1 then 
        return 2
    end 
    return false
end     

local function GetFlights()  
    local file1 = '00Data\\BD_flights.csv'
    local file2 = '00Data\\BD_waterways.csv'
    local file3 = '00Data\\BD_line_type.csv'
    
    flights = {}
    local Inf = Csv2Matrix(file1, 1)
    
    for i=1,#Inf do
        flights[#flights+1] = Flight:new(i, Inf[i])
    end
    
    ---the flight is or not water line
    Inf = Csv2Matrix(file2, 1)
    for f,flight in ipairs(flights) do
        --flight.water = false
        for i=1,#Inf do
            if flight.port1==Inf[i][1] and flight.port2==Inf[i][2] then 
                flight.water = true 
                break
            end
        end     
    end 
    ---the flight`s craft type limitation
    Inf = Csv2Matrix(file3, 1)
    for f,flight in ipairs(flights) do
        --flight.atp = {true, true, true, true}
        for i=1,#Inf do
            if flight.port1==Inf[i][1] and flight.port2==Inf[i][2] then 
                for j=1,4 do
                    flight.atp[j] = Inf[i][2+j]==1
                end 
                break
            end
        end     
    end 
end 

local function GetAirports()
    local file1 = '00Data\\BD_airports_type.csv'
    local file2 = '00Data\\BD_airports_trunaround.csv'
    local file3 = '00Data\\BD_airports_time.csv'
    
    airports = {}
    for f,flight in ipairs(flights) do
        airports[flight.port1] = airports[flight.port1] or Airport:new()
        airports[flight.port2] = airports[flight.port2] or Airport:new()
    end 
    
    ---airports craft type limitations
    local Inf = Csv2Matrix(file1, 1)
    for i=1,#Inf do 
        if airports[Inf[i][1]] then 
            for j=1,4 do
                airports[Inf[i][1]].atp[j] = Inf[i][j+1] == 1
            end 
        end 
    end 
    
    ---airport min turnaround time for each craft type
    Inf = Csv2Matrix(file2, 1)
    for i=1,#Inf do 
        if airports[Inf[i][1]] then 
            for j=1,4 do
                airports[Inf[i][1]].turn[j] = Inf[i][j+1]
            end 
        end 
    end 
    
    ---airport open time and close time, no tw mean this airport open all the day
    Inf = Csv2Matrix(file3, 1)
    for i=1,#Inf do 
        if airports[Inf[i][1]] then 
            airports[Inf[i][1]].tw = {Inf[i][2] * 60 + Inf[i][3], Inf[i][4] * 60 + Inf[i][5]}
        end 
    end 
    
    ---add the limitations of airport not allow craft type to flights
    for f,flight in ipairs(flights) do
        for i=1,4 do
            if flight.atp[i] then
                if (not airports[flight.port1].atp[i]) or (not airports[flight.port2].atp[i]) then
                    flight.atp[i] = false
                end 
            end 
        end 
    end     
end 

local function GetAircrafts()
    local file1 = '00Data\\BD_idle.csv'
    local file2 = '00Data\\BD_aircrafts_water.csv'
   
    aircrafts = {} 
    --generate rotation for every craft
    for f,flight in ipairs(flights) do    
        if aircrafts[flight.old[1]] then 
            table.insert(aircrafts[flight.old[1]].rot, flight)
        else
            aircrafts[flight.old[1]] = Aircraft:new(flight.old[1], {flight}, flight.old.atp, flight.old.seats)  
        end 
    end 
    
    for c, craft in pairs(aircrafts) do
        table.sort(craft.rot, function(a,b) return a.time1 < b.time1 end)
        ---initial airport
        craft.start = craft.rot[1].port1
        ---craft`s four day bases
        craft.base = {}
        for i=1,craft.rot[1].date-1 do
            table.insert(craft.base, -1)
        end 
        
        for i=2,#craft.rot do
            if craft.rot[i].date~=craft.rot[i-1].date then
                table.insert(craft.base, craft.rot[i-1].port2)
            end 
        end 
        
        for i=1,4-#craft.base do
            table.insert(craft.base, craft.rot[#craft.rot].port2)
        end 
        
        ---the initial turnaround time for every flight
        for i=1,#craft.rot-1 do
          craft.rot[i].gtime = craft.rot[i+1].time1 - craft.rot[i].time2
        end 
        craft.rot[#craft.rot].gtime = airports[craft.rot[#craft.rot].port2].turn[craft.atp]   ---may should be rewrited
        
        ---earlist available time
        craft.time1 = craft.rot[1].time1
        local dis = Disrupted(craft.rot)
        if dis == 1 then
            craft.dis = true
            craft.rot[1].dis   = true
            craft.rot[1].time1 = craft.rot[1].time1 + OTIME1 - CTIME1
            craft.rot[1].time2 = craft.rot[1].time2 + OTIME1 - CTIME1
            craft.time1 = OTIME1 
        elseif dis == 2 then
            craft.dis = true
            craft.rot[1].dis   = true
            craft.rot[1].time1 = craft.rot[1].time1 + OTIME1 - CTIME1
            craft.rot[1].time2 = craft.rot[1].time2 + OTIME1 - CTIME1
        end 
    end 

    Inf = Csv2Matrix(file1, 1)
    for i=1,#Inf do
        if not aircrafts[Inf[i][2]] then 
            aircrafts[Inf[i][2]] = Aircraft:new(Inf[i][2], {}, c, Inf[i][5])
            aircrafts[Inf[i][2]].start = Inf[i][4]
            for j=1,Inf[i][1]-1 do
                table.insert(aircrafts[Inf[i][2]].base, -1)
            end 
            for j=Inf[i][1],4 do
                table.insert(aircrafts[Inf[i][2]].base, aircrafts[Inf[i][2]].start)
            end 
            if Inf[i][4] == PORT1 and Inf[i][1] == 1 then
                aircrafts[Inf[i][2]].time1 = OTIME1
            else
                aircrafts[Inf[i][2]].time1 = airports[aircrafts[Inf[i][2]].start].tw and airports[aircrafts[Inf[i][2]].start].tw[1] or 300 + 1440 * (Inf[i][1] - 1)
            end 
        end 
    end
    
    Inf = Csv2Matrix(file2, 1)
    for i=1,#Inf do
        if aircrafts[Inf[i][1]] then 
            aircrafts[Inf[i][1]].water = false
        end 
    end
end 

function GetData()
    GetFlights()
    GetAirports()
    GetAircrafts()
    
    for i=#flights,1,-1 do
        if flights[i].date>1 then
            table.remove(flights, i)
        end 
    end 
    
    
    dayFlights = {0,0,0,0}
    for i=1,#flights do
        dayFlights[flights[i].date] = dayFlights[flights[i].date] + 1
    end
end 