
if string.starts(text,'disable ') then
    matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches == 2 then
        text = matches[2]
        local rem = false
        for i,tag in pairs(enabledEngineTags) do
            if tag == text then rem = i break end
        end
        if rem then table.remove(enabledEngineTags,rem) system.print(string.format('-- Engine tag filter removed "%s"',text)) end
        if text == 'ALL' then enabledEngineTags = {} end
        if #enabledEngineTags == 0 then system.print('-- No tag filtering. All engines enabled --') end
    else
        system.print('-- "disable" command requries an engine tag --')
    end
end
if string.starts(text,'enable ') then
    matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches == 2 then
        text = matches[2]
        table.insert(enabledEngineTags,text)
        system.print(string.format('-- Engine tag filter added "%s" --',text))
        
        if text == 'ALL' then enabledEngineTags = {} end
    else
        system.print('-- "enable" command requries an engine tag --')
    end
end
if string.starts(text,'warp') then
    if string.starts(text,'warpFrom') then
        matches = {}
        for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
        if #matches == 3 then
            dest = convertWaypoint(matches[3])
            start = convertWaypoint(matches[2])
        else
            system.print('Invalid entry')
        end
    elseif string.starts(text,'warp ') then
        start = nil
        matches = {}
        for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
        dest = convertWaypoint(matches[2])
    end


    -- Print out a designator to more easily tell
    -- multiple entries apart
    system.print('---------------------')

    -- Set initial minimum distance parameter to nil/empty
    local minDist = nil
    local pipeName = 'None'

    -- If we are entered both a start point and destination
    -- we will print out slightly different output
    if not start then
        curPos = vec3(construct.getWorldPosition())
        system.print('Selected Destination: ' .. text)
    else
        curPos = start
        system.print('Selected start position: ' .. matches[2])
        system.print('Selected Destination: ' .. matches[3])
    end

    -- Loop through all possible warp destinations.
    -- Determine each ones min distance from their
    -- line segment. If that distance is less than
    -- the global minimum, then we have found a new
    -- global minimum
    distType = ''
    for k,v in pairs(warp_beacons) do
        dist,tempType = pipeDist(curPos,v,dest,true)
        if dist ~= nil then
            -- Once we know which one is the smallest, compare
            -- it to our current smallest distance and see who
            -- wins! If this one is smaller, we have a new
            -- winner! Lets record the name and distance of the
            -- new winner.
            if not minDist or dist < minDist then
                minDist = dist
                pipeName = k
                distType = tempType
            end
        end
    end

    -- After we have checked all possible options, print out the final name
    -- and distance.
    system.print(string.format('Closest Warp %s: ',distType) .. pipeName)
    system.print(string.format('Closest Distance: %.2f SU',minDist*0.000005))
    system.print('---------------------')
end
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
if string.starts(text,'distance') then
    system.print('-- Distances to AR Points --')
    local distTable = {}
    local nameTable = {}
    local posTable = {}
    for name,pos in pairs(AR_Generate) do
        local pDist = vec3(pos - constructPosition):len()
        table.insert(distTable,pDist)
        nameTable[tostring(pDist)] = name
        posTable[tostring(pDist)] = string.format('::pos{0,0,%.1f,%.1f,%.1f}',pos['x'],pos['y'],pos['z'])
    end
    table.sort(distTable,function(a, b) return a > b end)
    for _,dist in ipairs(distTable) do
        system.print(string.format('%s -> %s',nameTable[tostring(dist)],formatNumber(dist,'distance')))
        system.print('   ' .. posTable[tostring(dist)])
    end
    system.print('----------------------------')
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
if string.starts(text:lower(),'show codes') then
    unit.setTimer('showCode',1)
    system.print('--Transponder Codes visible--')
end
if text:lower() == 'show' then system.print(tostring(codeCount)) end
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
if string.starts(text,'agc') then
    local matches = {}
    for w in text:gmatch('([^ ]+) ?') do table.insert(matches,w) end
    if (#matches ~= 2 or not tonumber(matches[2])) and codeSeed ~= nil then
        system.print('-- Invalid start command --')
    else
        local t = nil
        if #matches == 2 then t = tonumber(matches[2]) elseif #matches == 1 then t = tonumber(matches[1]) end
        if codeSeed == nil then
            system.print('-- Transponder started --')
            codeSeed = t
            unit.setTimer('code',0.25)
        else
            codeSeed = t
            system.print('-- Code seed changed --')
        end
    end
end
if string.starts(text:lower(),'show ') and not string.starts(text,'show code') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches ~= 2 then
        system.print('-- Invalid command format --')
    elseif not contains(validSizes,matches[2]) then
        system.print(string.format('-- Invalid filter "%s"',matches[2]))
    else
        if contains(filterSize,matches[2]) then
            system.print(string.format('-- Already showing %s core size --',matches[2]))
        else
            system.print(string.format('-- Including %s core size --',matches[2]))
            table.insert(filterSize,matches[2])
        end
    end
end
if string.starts(text:lower(),'hide ') and not string.starts(text,'hide code') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if (#matches ~= 2 ) then
        system.print('-- Invalid command format --')
    else
        if not contains(filterSize,matches[2]) then
            system.print(string.format('-- Already hiding %s core size --',matches[2]))
        else
            local r = nil
            for i,v in ipairs(filterSize) do 
                if v == matches[2] then
                    r = i
                end
            end
            if r ~= nil then
                system.print(string.format('-- Hiding %s core size --',matches[2]))
                table.remove(filterSize,r)
            else
                system.print(string.format('-- %s core size not found --',matches[2]))
            end
        end
    end
end
if text:lower() == 'asteroid pipes on' then asteroidPipes = true system.print('-- Enable Asteroid pipe file --') end
if text:lower() == 'asteroid pipes off' then asteroidPipes = false system.print('-- Disabled Asteroid pipe file --') end
if string.starts(text:lower(),'sp ') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches ~= 2 then system.print('-- Invalid input --')
    elseif resistProfiles[matches[2]:lower()] then shieldProfile = matches[2]:lower() system.print('-- Shield profile set: '..matches[2]:lower())
    else system.print('-- Shield profile not found --') system.print('-- Current profile: '..shieldProfile) end
end
if string.starts(text,'trajectory ') then
    local matches = {}
    for w in text:gmatch('([^ ]+) ?') do table.insert(matches,w) end
    if (#matches ~= 2 or not tonumber(matches[2])) then
        system.print('-- Invalid trajectory command --')
    else
        system.print('TODO')
    end
end