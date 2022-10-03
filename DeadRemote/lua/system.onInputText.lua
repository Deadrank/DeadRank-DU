
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
            -- winner! Let's record the name and distance of the
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
    autopilot_dest = vec3(convertWaypoint(matches[1]))
    autopilot_dest_pos = matches[1]
    system.print('-- Autopilot destination set --')
    system.print(matches[1])
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