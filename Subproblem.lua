function pas_delay_cost(cTime)
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

function flight_delay_cost(cFlight, delay)
    --(delay fixed cost 1200 + delay time cost 30 * hours + pas delay cost) * wt
    --if cFlight.wt then  
        local cost = 0
        if delay>0 then 
            if cFlight.dis then 
                cost = (cost + delay / 2 + (pas_delay_cost(delay+120)-1.5) * cFlight.old.pas) * cFlight.wt
            else 
                cost = (1200 + delay / 2 + pas_delay_cost(delay) * cFlight.old.pas) * cFlight.wt --/60*30
            end 
        end 
        return cost
     --   return delay>0 and (1200 + delay / 2 + pas_delay_cost(delay) * cFlight.old.pas) * cFlight.wt or 0 --/60*30
    --end 
    --return 0 
end

function time_check_airport(port, time)
    if port.tw then 
        if port.tw[2]>1440 then 
            return not (time%1440<port.tw[1] and time%1440>port.tw[2]%1440)
        else
            return time%1440<port.tw[1] or time%1440>port.tw[2] 
        end 
    end
    return true
end 

function craft_swap_cost(cFlight, ncraft)
    local cost = 0 
    if cFlight.old[1]~=ncraft then
        if cFlight.old.atp~=ncraft.atp then
            local typeSwap = {{0,1,2,3},{1,0,1.5,2.5},{2,1.5,0,2},{3,2.5,2,0}}
            cost = cost + 300 * typeSwap[ncraft.atp][cFlight.old.atp]        
        end 
        if cFlight.old.pas-ncraft.seats>0 then
            if cFlight.dis then 
                cost = cost + (cFlight.old.pas - ncraft.seats) * (6-1.5)
            else 
                cost = cost + (cFlight.old.pas - ncraft.seats) * 6
            end 
        end 
        return cost * cFlight.wt ---passenger cancel because of seats decresing
    end 
    return cost 
end 

local function Dominated(label1, label2)
    if #label1==#label2 then 
        for i=2,#label1-1 do
            if label1[i]~=label2[i] then 
                return false
            end 
        end 
        return label1.cost<=label2.cost  and label1.cut<=label2.cut 
    end 
    return false
end 

function Subproblem()
    -- update duals 
    local routes = {}
    for c,craft in ipairs(aircrafts) do
        routes[#routes+1] = craft:buildRoutes()
    end 
end 