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

 local function Disrupted(cRotation)
    if cRotation[1].port1==57 and cRotation[1].time1<600 and cRotation[1].time1>=480 then
        return true
    elseif cRotation[1].port2==57 and cRotation[1].time2<600 and cRotation[1].time2>=480 then 
        return true
    end 
    return false
end     

local function GetFlights()
    local file1 = 'data\\BD_flights.csv'
    local file2 = 'data\\BD_waterways.csv'
    local file3 = 'data\\BD_line_type.csv'
    
    flights = {}
    local Inf = Csv2Matrix(file1, 1)
    
    for i=1,#Inf do
        local tmp = {}
        tmp = {id=i, date=Inf[i][2], port1=Inf[i][4], port2=Inf[i][5], time1=Inf[i][6], time2=Inf[i][7], wt=Inf[i][12]}
        tmp.info = {ID=Inf[i][1], flight=Inf[i][3]}
        tmp.old  = {Inf[i][8]; atp=Inf[i][9], seats=Inf[i][11], pas=Inf[i][10]}
        tmp.ftime = tmp.time2 - tmp.time1
        tmp.date  = tmp.date - 43158
        --tmp.dual = 0
        table.insert(flights, tmp)
    end
    
    ---the flight is or not water line
    Inf = Csv2Matrix(file2, 1)
    for f,flight in ipairs(flights) do
        flight.water = false
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
        flight.atp = {true, true, true, true}
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
    local file1 = 'data\\BD_airports_type.csv'
    local file2 = 'data\\BD_airports_trunaround.csv'
    local file3 = 'data\\BD_airports_time.csv'
    
    airports = {}
    for f,flight in ipairs(flights) do
        airports[flight.port1] = airports[flight.port1] or {atp={true,true,true,true}, turn={}}
        airports[flight.port2] = airports[flight.port2] or {atp={true,true,true,true}, turn={}}
    end 
    ---airports craft type limitations
    local Inf = Csv2Matrix(file1, 1)
    for i=1,#Inf do 
        if airports[Inf[i][1]] then 
            for j=1,4 do
                airports[Inf[i][1]].atp[j] = Inf[i][j+1]==1
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
    ---airport open time and close time
    Inf = Csv2Matrix(file3, 1)
    for i=1,#Inf do 
        if airports[Inf[i][1]] then 
            airports[Inf[i][1]].tw = {Inf[i][2]*60 + Inf[i][3], Inf[i][4]*60 + Inf[i][5]}
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
    local file1 = 'data\\BD_idle.csv'
    local file2 = 'data\\BD_aircrafts_water.csv'
    ---craft = {id=, rot={}, start=, base={}, water=, }
    aircrafts = {}
    --generate rotation for every craft
    for f,flight in ipairs(flights) do    
        if aircrafts[flight.old[1]] then 
            table.insert(aircrafts[flight.old[1]].rot, flight)
        else
            aircrafts[flight.old[1]] = {id=flight.old[1], rot={flight}, atp=flight.old.atp, seats=flight.old.seats, water=true}
        end 
    end 
    
    for c, craft in pairs(aircrafts) do
        table.sort(craft.rot, function(a,b) return a.time1<b.time1 end)
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
        
        ---the guozhan shijian for every flight
        for i=1,#craft.rot-1 do
          craft.rot[i].gtime = craft.rot[i+1].time1 - craft.rot[i].time2
        end 
        
        ---update the time1,time2 for the disrupted flights
        craft.rot[#craft.rot].gtime = airports[craft.rot[#craft.rot].port2].turn[craft.atp]   ---may should be rewrited
        
        ---earlist available time
        craft.time1 = craft.rot[1].time1   
        if Disrupted(craft.rot) then
            craft.dis = true
            craft.rot[1].dis = true
            craft.rot[1].time1 = craft.rot[1].time1 + 120
            craft.rot[1].time2 = craft.rot[1].time2 + 120
            craft.time1 = 600 
        end 
    end 
    
    --idle crafts
    aircrafts[159].time1 = 600
    aircrafts[148].time1 = 600
    aircrafts[71]  = {time1=600,start=57,atp=2,seats=164,id=71, rot={},water=true,base={57,57,57,57}}
    aircrafts[110] = {time1=600,start=57,atp=2,seats=164,id=110,rot={},water=true,base={57,57,57,57}}
    aircrafts[128] = {time1=600,start=57,atp=3,seats=189,id=128,rot={},water=true,base={57,57,57,57}}
    aircrafts[146] = {time1=600,start=57,atp=2,seats=158,id=146,rot={},water=true,base={57,57,57,57}}
    
    Inf = Csv2Matrix(file2, 1)
    for i=1,#Inf do
        if aircrafts[Inf[i][1]] then 
            aircrafts[Inf[i][1]].water = false
        end 
    end
end 

function GetData()
    --get the data includes:
    --flights, airports, aircrafts
    --nodes, crafts, warehouse, rotations
    GetFlights()
    GetAirports()
    GetAircrafts()
--    dayFlights = {0,0,0,0}
--    for i=1,#flights do
--        dayFlights[flights[i].date] = dayFlights[flights[i].date] + 1
--    end
    --print(math.floor(dayFlights[1]*0.1), '   ', math.floor(dayFlights[1]*0.05))
end 