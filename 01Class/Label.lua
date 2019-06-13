Label = {}
Label.__index = Label

function Label:new(tab)
    local self = tab or {0; cost = 0, delay = 0, cut = 0, cuts = {}}
    setmetatable(self, Label)
    return self
end 

function Label:newDelay(flight1, flight2, gtime)
    return math.max(0, flight1.time2 + self.delay + gtime - flight2.time1)
end

function Label:dominate(label)
    if #self == #label then 
        for i=2,#self-1 do
            if self[i] ~= label[i] then 
                return false
            end 
        end 
        return self.cost <= label.cost  and self.cut <= label.cut 
    end 
end 

function Label:extend(id, craft)
    local flight1, flight2 = flights[self.id], flights[id]
    if id > 0 then 
        for t=1,3 do 
            local tag = {cut = self.cut, cuts = DeepCopy(self.cuts)}  --cost=label.cost}--,  --cut=label.cut, cuts=DeepCopy(label.cuts), delay=label.delay,}
            local cut2 = 0
            if t == 1 then 
                tag.delay = self:newDelay(flight1, flight2, flight1.gtime)
            elseif self.delay + flight1.time2 + flight1.gtime > flight2.time1 then
                if t==2 then
                    if flight1.gtime > airports[flight1.port2].turn[craft.atp] then  
                        tag.delay = self:newDelay(flight1, flight2, airports[flight1.port2].turn[craft.atp])
                    else
                        goto continue
                    end 
                elseif t==3 then
                    if flight1.gtime > math.ceil(airports[flight1.port2].turn[craft.atp] * 2 / 3) then  
                        tag.delay = self:newDelay(flight1, flight2, math.ceil(airports[flight1.port2].turn[craft.atp]*2/3))
                        cut2 = math.min(math.floor(airports[flight1.port2].turn[craft.atp] * 1 / 3), airports[flight1.port2].turn[craft.atp] - flight2.time1 + flight1.time2 + self.delay)
                    else 
                        break
                    end 
                end 
                tag.cut = tag.cut + 1
                tag.cuts[#self-1] = cut2
            else 
                break
            end 
            
            if tag.delay>1440 then break end
            
            --if flight2.time2 + tag.delay + math.ceil(airports[flight2.port2].turn[craft.atp]*2/3) > craft.day2 then break end
            ----机场关闭约束
            if not check_airport(flight2, tag.delay) then break end 
            --add the delay cost and aircraft change cost
            tag.cost = label.cost + flight_delay_cost(flight2, tag.delay) + craft_swap_cost(flight2, craft) + cut2 * 20   --- -flight2.dual    
            
            
            local dominated 
            local i = 1
            while true do 
                if i>#flight2.labels then break end 
                if Dominated(flight2.labels[i], tag) then 
                    tag = nil
                    break
                elseif Dominated(tag, flight2.labels[i]) then 
                    table.remove(flight2.labels, i)
                    i = i - 1
                end 
                i = i + 1
            end 
            tag = {unpack(self), index}
            table.insert(craft.labels[id], tag)
            if tag.delay==0 then 
                break 
            end 
            ::continue::
        end 
    else
        local tag = Label:new({unpack(self)}, self.cost, self.delay, label.cut, DeepCopy(label.cuts))
        if tag.delay + flight1.time2 + flight1.gtime > craft.day2 then
            tag.cut = tag.cut + 1
            local cut2 = math.max(0, flight1.time2+tag.delay+airports[flight1.port2].turn[craft.atp]-craft.day2)
            tag.cost = tag.cost + cut2 * 20 
            table.insert(tag.cuts, cut2)
        end 
        table.insert(tag, id)
        table.insert(craft.labels[id], tag)
    end 
end 

function Label:to_route()
    local route = Route:new(self.cost, self.craft, self.cut, self.cuts)
    for i=2,#label-1 do 
        route[#route+1] = self[i]
    end
    return route
end 