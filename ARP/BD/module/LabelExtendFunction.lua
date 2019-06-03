local function PassengerDelay(cTime)
    if cTime==0 then return 0 end 
    local time = {1,2,4,12,24}
    local index = {1,1.5,2,3,5}
    for i=1,#time do
        if cTime<=time[i]*60 then 
            return index[i]
        end 
    end 
    error('This passenger should be canceled for delay more than 24 hours')
    
    return false
end 


local function delayCost(cFlight, delay)
    local cost = delay>0 and 1200 + delay/60*200 + PassengerDelay(delay) * cFlight.passenger or 0    
    return cost * cFlight.importance
end 

local function flightswapCost(cFlight, ncraft)
    local cost = 0 
    if cFlight.atype~=ncraft.ptype then
        local typeSwap = {{0,1,2,3},{1,0,1.5,1.5},{2,1.5,0,2},{3,2.5,2,0}}
        cost = cost + 300 * typeSwap[ncraft.ptype][cFlight.atype]        
    end 
    if cFlight.passenger>ncraft.seats then 
        cost = cost + (cFlight.passenger-ncraft.seats) * 6
    end
    return cost * cFlight.importance
end 



function label_extend(flight1, flight2, craft)
    --every flight has a label set, include a set of labels <totalcost, delay time>, which has no dominance
    --from the start airport to base airport?
    for _, label in ipairs(flight1.labels) do
        ::continue::
        local tag = {cost=0, delay=0, pre=nil}
        --time delay confliction
--        if flight2.dtime<flight1.atime+label.delay+airports[flight1.aport].turn[ptype] then
--            tag.delay = flight1.atime + label.delay + airports[flight1.aport].turn[ptype] - flight2.dtime
--        else
--            tag.delay = 0
--        end 
        tag.delay = math.max(0, flight1.atime + label.delay + airports[flight1.aport].turn[ptype] - flight2.dtime)
        if tag.delay>1440 then goto continue end 
        if tag.delay+flight2.dtime>airports[flight2.dport].ctime or tag.delay+flight2.atime>airports[flight2.aport].ctime then --airport close limitation
            goto continue
        end 
        
        --add the delay cost and aircraft change cost
        tag.cost = tag.cost + delayCost(flight2, tag.delay) - flight2.dual + flightswapCost(flight2, craft)
        local dominate = false 
        for i,ir in ipairs(flight2.labels) do
            if dominated(tag, ir) then 
               dominate = true
               break
            end 
        end
        --test dominate and insert the tag into label set, at last, dominate remaining labels.
        if not dominate then
            for i,ir in ipairs(flight2.labels) do
                if dominated(ir, tag) then 
                   table.remove(flight2.labels, i)
                end 
            end
            tag.pre = flight1.index
            table.insert(flight2.labels, tag)
        end 
    end
end 