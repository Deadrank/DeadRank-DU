if string.starts(text,'addWaypoint ') then
    matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches < 2 then
        system.print('-- Requires a position tag with the command --')
    elseif #matches > 3 then
        system.print('-- only a position tag and name can be given with the command --')
        system.print('-- addWaypoint <position tag> [name] --')
    else
        AR_Temp = true
        if #matches == 2 then
            AR_Temp_Points['Temp_' .. tostring(#AR_Temp_Points)] = matches[2]
            system.print(string.format('-- Added waypoint "%s" (%s) --','Temp_' .. tostring(#AR_Temp_Points),matches[2]))
        else
            AR_Temp_Points[matches[3]] = matches[2]
            system.print(string.format('-- Added waypoint "%s" (%s) --',matches[3],matches[2]))
        end
    end
end
if string.starts(text,'delWaypoint ') then
    matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches ~= 2 then
        system.print('-- Requires a waypoint name with the command --')
    else
        local rem = nil
        local count = 0
        for k,v in pairs(AR_Temp_Points) do
            count = count + 1
            if k == matches[2] then
                rem = k
            end
        end
        if rem then AR_Temp_Points[rem] = nil count = count -1 system.print(string.format('-- Removed waypoint "%s"',rem)) end
        if count == 0 then AR_Temp = false end
    end
end
if string.starts(text,'::pos{') then
    matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if trackerMode then
        if #trackerList == 0 then
            table.insert(trackerList,matches[1])
            system.print(string.format('-- 1st Position: %s',matches[1]))
        elseif trackerList[1] == matches[1] then system.print('-- 2nd trajectory point is the same as the first --')
        else
            table.insert(trackerList,1,matches[1])
            system.print(string.format('-- 1st Position: %s',trackerList[2]))
            system.print(string.format('-- 2nd Position: %s',matches[1]))

            AR_Temp_Points['Spotted'] = trackerList[1]
            local P1 = vec3(convertWaypoint(trackerList[2]))
            local P2 = vec3(convertWaypoint(trackerList[1]))
            local T5 = P1+5/.000005*(P2 - P1)/vec3(P2-P1):len()
            local T30 = P1+30/.000005*(P2 - P1)/vec3(P2-P1):len()
            local T50 = P1+50/.000005*(P2 - P1)/vec3(P2-P1):len()
            local t5p = string.format('::pos{0,0,%.2f,%.2f,%.2f}',T5['x'],T5['y'],T5['z'])
            local t30p = string.format('::pos{0,0,%.2f,%.2f,%.2f}',T30['x'],T30['y'],T30['z'])
            local t50p = string.format('::pos{0,0,%.2f,%.2f,%.2f}',T50['x'],T50['y'],T50['z'])
            AR_Temp_Points['T5'] = t5p
            AR_Temp_Points['T30'] = t30p
            AR_Temp_Points['T50'] = t50p

            system.print(string.format('--  5su Position: %s',t5p))
            system.print(string.format('-- 30su Position: %s',t30p))
            system.print(string.format('-- 50su Position: %s',t50p))

            autopilot_dest = T50
            autopilot_dest_pos = string.format('::pos{0,0,%.2f,%.2f,%.2f}',T50['x'],T50['y'],T50['z'])
            system.setWaypoint(autopilot_dest_pos)

            system.print('-- Trajectory points added --')
        end
        if #trackerList == 3 then table.remove(trackerList,3) end
    else
        autopilot_dest = vec3(convertWaypoint(matches[1]))
        autopilot_dest_pos = matches[1]
        system.print('-- Autopilot destination set --')
        system.print(matches[1])
    end
end
if string.starts(text:lower(),'code') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    table.insert(tags,matches[2])
    transponder_1.setTags(tags)
    transponder_1.deactivate()
    tags = transponder_1.getTags()
    system.print('--Transponder Code Added--')
end
if string.starts(text:lower(),'delcode') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    local r = nil
    for i,v in ipairs(tags) do if v == matches[2] then r = i end end
    table.remove(tags,r)
    transponder_1.setTags(tags)
    transponder_1.deactivate()
    tags = transponder_1.getTags()
    system.print('--Transponder Code Removed--')
end
if string.starts(text:lower(),'sp ') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches ~= 2 then system.print('-- Invalid input --')
    elseif resistProfiles[matches[2]:lower()] then shieldProfile = matches[2]:lower() system.print('-- Shield profile set: '..matches[2]:lower())
    else system.print('-- Shield profile not found --') system.print('-- Current profile: '..shieldProfile) end
end