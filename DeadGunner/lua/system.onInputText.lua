if string.starts(text:lower(),'code') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    table.insert(tags,matches[2])
    transponder_1.setTags(tags)
    transponder_1.deactivate()
    tags = transponder_1.getTags()
    system.print('--Transponder Code Added--')
end
if string.starts(text:lower(),'hide codes') then
    showCode = false
    system.print('--Transponder Codes hidden--')
end
if string.starts(text:lower(),'show codes') then
    showCode = true
    system.print('--Transponder Codes visible--')
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

if string.starts(text:lower(),'addships') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    for _,ship in ipairs(erDisplay) do
        friendlySIDs[ship.id] = 'Auto Add'
        db_1.setStringValue(string.format('sc-%s',ship.id),'Auto Add')
        system.print(string.format('-- Added to friendly list (Name: %s | ID: %s)',ship.name,ship.id))
    end
    for _,ship in ipairs(frDisplay) do
        friendlySIDs[ship.id] = 'Auto Add'
        db_1.setStringValue(string.format('sc-%s',ship.id),'Auto Add')
        system.print(string.format('-- Added to friendly list (Name: %s | ID: %s)',ship.name,ship.id))
    end
end
if string.starts(text:lower(),'addshipid') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches == 3 then
        friendlySIDs[tonumber(matches[2])] = matches[3]
        db_1.setStringValue(string.format('sc-%s',matches[2]),matches[3])
        system.print(string.format('-- ShipID %s (%s) added to friendly list --',matches[2],matches[3]))
    elseif #matches == 2 then
        friendlySIDs[tonumber(matches[2])] = radar_1.getConstructName(matches[2])
        db_1.setStringValue(string.format('sc-%s',matches[2]),'nil')
        system.print(string.format('-- ShipID %s (%s) added to friendly list --',matches[2],radar_1.getConstructName(matches[2])))
    else
        system.print('-- Invalid command "addFreindlyID <shipID> <pilotname>" --')
    end
    system.print('-- Construct ID added to Friendly list --') 
end
if string.starts(text:lower(),'delshipid') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    local r = nil
    for k,v in pairs(friendlySIDs) do if k == matches[2] then r = k end end
    if r ~= nil then friendlySIDs[r] = nil end
    if db_1 ~= nil and #matches == 2 then
        if db_1.hasKey('sc-' .. tostring(matches[2])) == 1 then db_1.setStringValue('sc-' .. tostring(matches[2]),nil) end
    end
    system.print('-- Construct removed from Friendly ID list --')
end

if type(tonumber(text)) == 'number' and (#text == 3 or text == '0') and codeSeed ~= nil then
    if text == '0' then
            system.print('-- Removing primary target filter --')
            primary = nil
            radarFilter = 'All'
    else
        system.print(string.format('-- Adding primary target filter [%s] --',text))
        primary = tostring(text)
        radarFilter = 'primary'
    end
end

if string.starts(text:lower(),'agc') or codeSeed == nil then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if (#matches ~= 2 or not tonumber(matches[2])) and codeSeed ~= nil then
        system.print('-- Invalid start command --')
    else
        local t = nil
        if #matches == 2 then t = tonumber(matches[2]) elseif #matches == 1 then t = tonumber(matches[1]) end
        if codeSeed == nil then
            system.print('-- Booting up --')
            codeSeed = t
            system.showScreen(1)
            unit.setTimer('booting',1)
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
if text:lower() == 'print db' then
    if db_1 ~= nil then
        system.print('-- DB READOUT START --')
        for _,key in pairs(db_1.getKeyList()) do
            if string.find(db_1.getStringValue(key),'::pos') ~= nil or true then
                system.print(string.format('%s: %s',key,db_1.getStringValue(key)))
            end
        end
        system.print('-- DB READOUT END --')
    else
        system.print('-- NO DB ATTACHED --')
    end
end
if text:lower() == 'clear db' then
    if db_1 ~= nil then
        db_1.clear()
        system.print('-- DB CLEARED --')
    else
        system.print('-- NO DB ATTACHED --')
    end
end
if text:lower() == 'coreid' then
    system.print(string.format('-- %.0f --',construct.getId()))
end
if text:lower() == 'clear damage' then
    system.print('-- Clearing damage dealt to target --')
    local targetID = radar_1.getTargetId()
    if targetID == 0 then
        system.print('-- No target selected --')
    else
        if db_1 then
            if db_1.hasKey('damage - ' .. tostring(targetID)) then
                db_1.clearValue('damage - ' .. tostring(targetID))
            end
        end
        dmgTracker[tostring(targetID)] = nil
    end
end
if text:lower() == 'clear all damage' then
    system.print('-- Clearing all damage dealt --')
    dmgTracker = {}
    if db_1 then
        for _,key in pairs(db_1.getKeyList()) do
            if string.starts(key,'damage - ') then
                db_1.clearValue(key)
            end
        end
    end
end
if text:lower() == 'print damage' then
    system.print('-- Printing all damage dealt --')
    if db_1 then
        for _,key in pairs(db_1.getKeyList()) do
            if string.starts(key,'damage - ') then
                system.print(string.format('%s: %.2f',key,db_1.getFloatValue(key)))
            end
        end
    end
end