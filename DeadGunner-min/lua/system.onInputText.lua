if string.starts(text:lower(),'printcore') then
    local targetID = radar_1.getTargetId()
    if targetID ~= 0 then
        system.print(targetID)
    end
end
if string.starts(text:lower(),'addships') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches > 1 then
        id = matches[2]
        if radar_1.hasMatchingTransponder(id) then
            local owner = radar_1.getConstructOwnerEntity(id)
            if owner['isOrganization'] then
                owner = system.getOrganization(owner['id'])
                owner = owner['tag']
            else
                owner = system.getPlayerName(owner['id'])
            end
            friendlySIDs[id] = owner
            write_db.setStringValue(string.format('sc-%s',id),owner)
            system.print(string.format('-- Added to friendly list (Name: %s | ID: %s)',radar_1.getConstructName(id),id))
        else
            friendlySIDs[id] = 'Auto Add'
            write_db.setStringValue(string.format('sc-%s',id),'Auto Add')
            system.print(string.format('-- Added to friendly list (Name: %s | ID: %s)',radar_1.getConstructName(id),id))
        end
    else
        for _,id in ipairs(radar_1.getConstructIds()) do
            if radar_1.hasMatchingTransponder(id) then
                local owner = radar_1.getConstructOwnerEntity(id)
                if owner['isOrganization'] then
                    owner = system.getOrganization(owner['id'])
                    owner = owner['tag']
                else
                    owner = system.getPlayerName(owner['id'])
                end
                friendlySIDs[id] = owner
                write_db.setStringValue(string.format('sc-%s',id),owner)
                system.print(string.format('-- Added to friendly list (Name: %s | ID: %s)',radar_1.getConstructName(id),id))
            else
                friendlySIDs[id] = 'Auto Add'
                write_db.setStringValue(string.format('sc-%s',id),'Auto Add')
                system.print(string.format('-- Added to friendly list (Name: %s | ID: %s)',radar_1.getConstructName(id),id))
            end
        end
    end
end
if string.starts(text:lower(),'delshipid') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    local r = nil
    for k,v in pairs(friendlySIDs) do if k == matches[2] then r = k end end
    if r ~= nil then friendlySIDs[r] = nil end
    if write_db ~= nil and #matches == 2 then
        if write_db.hasKey('sc-' .. tostring(matches[2])) then write_db.setStringValue('sc-' .. tostring(matches[2]),nil) end
    end
    system.print('-- Construct removed from Friendly ID list --')
end
if type(tonumber(text)) == 'number' and (#text == 3 or text == '0') then
    if text == '0' then
            system.print('-- Removing primary target filter --')
            primary = nil
            radarFilter = 'All'
            if not slave and write_db then
                write_db.clearValue('primaryTarget')
            end
    else
        system.print(string.format('-- Adding primary target filter [%s] --',text))
        primary = tostring(text)
        radarFilter = 'primary'
        if not slave and write_db then
            write_db.setStringValue('primaryTarget',tostring(text))
        end
    end
end
if text:lower() == 'print db' then
    if write_db ~= nil then
        system.print('-- DB READOUT START --')
        for _,key in pairs(write_db.getKeyList()) do
            if string.find(write_db.getStringValue(key),'::pos') ~= nil or true then
                system.print(string.format('%s: %s',key,write_db.getStringValue(key)))
            end
        end
        system.print('-- DB READOUT END --')
    else
        system.print('-- NO DB ATTACHED --')
    end
end
if text:lower() == 'clear db' then
    if write_db ~= nil then
        write_db.clear()
        system.print('-- DB CLEARED --')
    else
        system.print('-- NO DB ATTACHED --')
    end
end
if text:lower() == 'coreid' then
    system.print(string.format('-- %.0f --',construct.getId()))
end
if text:lower() == 'clear damage' then
    system.print('-- Clearing damage dealt to target (this seat only) --')
    local targetID = radar_1.getTargetId()
    if targetID == 0 then
        system.print('-- No target selected --')
    else
        if write_db then
            if write_db.hasKey('damage - ' .. tostring(targetID) .. ' - ' .. pilotName) then
                write_db.clearValue('damage - ' .. tostring(targetID) .. ' - ' .. pilotName)
                system.print('Cleared: ' .. 'damage - ' .. tostring(targetID) .. ' - ' .. pilotName)
            end
        end
        dmgTracker[tostring(targetID)] = nil
        system.print('Cleared dmgTracker: ' .. tostring(targetID))
    end
end
if text:lower() == 'clear all damage' then
    system.print('-- Clearing all damage dealt (this seat only) --')
    dmgTracker = {}
    for _,dbName in pairs(db) do
        for _,key in pairs(dbName.getKeyList()) do
            if string.starts(key,'damage - ') then
                dbName.clearValue(key)
            end
        end
    end
end
if text:lower() == 'print damage' then
    system.print('-- Printing all damage dealt --')
    for _,dbName in pairs(db) do
        for _,key in pairs(dbName.getKeyList()) do
            if string.starts(key,'damage - ') then
                system.print(string.format('%s: %.2f',key,dbName.getFloatValue(key)))
            end
        end
    end
end
if string.starts(text,'/G') then
    if write_db ~= nil then
        local matches = {}
        for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
        local found = false
        if #matches > 2 then
            for _,key in pairs(write_db.getKeyList()) do
                if matches[2] == key then
                    found = true
                    write_db.setStringValue(key,matches[3])
                    write_db.setIntValue(key,tonumber(matches[3]))
                    globalDB('get')
                end
            end
            if found then
                system.print(string.format('Set "%s" to "%s"',matches[2],matches[3]))
            else
                system.print('-- INVALID VARIABLE NAME --')
            end
        else
            system.print('-- INVALID COMMAND FORMAT --')
        end
    else
        system.print('-- NO DATABANK --')
    end
end
if string.starts(text,'?') then
    if write_db ~= nil then
        local matches = {}
        for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
        if #matches > 1 then
            system.print('-- DB READOUT START --')
            for _,key in pairs(write_db.getKeyList()) do
                if string.find(key,matches[2]) ~= nil then
                    system.print(string.format('%s = %s',key,write_db.getStringValue(key)))
                end
            end
            system.print('-- DB READOUT END --')
        end
    else
        system.print('-- NO DB ATTACHED --')
    end
end
if string.starts(text:lower(),'abnd') then
    local matches = {}
    for w in text:gmatch("([^ ]+) ?") do table.insert(matches,w) end
    if #matches == 2 then
        abandonedCoreDist = tonumber(matches[2])
        system.print('-- Set cored distance to '..tostring(matches[2])..' --')
    end
end
if string.starts(text:lower(), 'clear abnd') then
    local constructPosition = vec3(construct.getWorldPosition())
    if write_db then
        local clearID = nil
        local closest = nil
        for _,key in pairs(write_db.getKeyList()) do
            if string.starts(key,'abnd-') and not string.starts(key,'abnd-name-') then
                pos = convertWaypoint(write_db.getStringValue(key))
                local pDist = vec3(pos - constructPosition):len()
                if not closest then 
                    clearID = key
                    closest = pDist
                elseif pDist < closest then
                    clearID = key
                    closest = pDist
                end
            end
        end
        if clearID then
            system.print('-- Clearing '..clearID ..' --')
            write_db.clearValue(clearID)
            write_db.clearValue(string.gsub(clearID,'-','-name-'))
        end
    end
end
if text:lower() == 'setfc' then
    if not radar_1 then
        system.print('-- No radar --')
        FC = nil
    elseif radar_1.getTargetId() == 0 then
        system.print('-- No target --')
        FC = nil
    elseif not radar_1.hasMatchingTransponder(radar_1.getTargetId()) then
        system.print('-- Target does not have matching transponder --')
    else
        FC = radar_1.getTargetId()
        system.print('-- Set Fleet Commander --')
    end
end
if text:lower() == 'setsl' then
    if not radar_1 then
        system.print('-- No radar --')
        SL = nil
    elseif radar_1.getTargetId() == 0 then
        system.print('-- No target --')
        SL = nil
    elseif not radar_1.hasMatchingTransponder(radar_1.getTargetId()) then
        system.print('-- Target does not have matching transponder --')
    else
        SL = radar_1.getTargetId()
        system.print('-- Set Squad Leader --')
    end
end
if text:lower() == 'clear tracking' then
    system.print('-- Clearing tracked data --')
    manual_trajectory = {}
    trajectory_calc = {}
end
if text:lower() == 'add' then
    if not contains(primaries,tostring(radarSelected)) and radarSelected ~= '0' then
        system.print(string.format('-- Adding %s to primary radar--',radarSelected))
        table.insert(primaries,tostring(radarSelected))
    end
    for _,t in pairs(primaries) do
        system.print(t)
    end
end
if string.starts(text:lower(), 'd') and (#text == 4 or #text == 2) and type(tonumber(string.sub(text,2))) then
    if string.sub(text,2) == '0' then
        system.print('-- Clearing Primary Radar --')
        primaries = {}
    else
        
        local r = nil
        for k,v in pairs(primaries) do
            if v == string.sub(text,2) then r = k end
        end
        if r then
            system.print(string.format('-- Removing %s from primary radar --',string.sub(text,2)))
            table.remove(primaries,r)
        end
    end
end
if text:lower() == 'primary radar off' then
    targetRadar = false
    if primaryRadarPanelID then
        system.print('-- Disabling primary target radar widget --')
        system.destroyWidgetPanel(primaryRadarPanelID)
        primaryRadarPanelID = nil
    end
end
if text:lower() == 'primary radar on' then
    targetRadar = true
    if not primaryRadarPanelID then
        system.print('-- Enabling primary target radar --')
        primaryRadarID,primaryRadarPanelID = RadarWidgetCreate('PRIMARY TARGETS')
    end
end

if text:lower() == 'show weapons' then
    weaponWidgets = true
    for k,weapon in pairs(weaponData) do
        if not weapon['widget'] then
            local _widget = nil
            _widget = system.createWidget(weaponPanel, weapon['type'])
            weapon['widget'] = _widget
            system.addDataToWidget(weapon['Data'],_widget)
            weapon['shown'] = true
        end
    end
    system.print('-- Showing available weapon widgets --')
end

if text:lower() == 'hide weapons' then
    weaponWidgets = false
    system.print('-- Hiding weapon widgets --')
    for k,weapon in pairs(weaponData) do
        system.destroyWidget(weapon['widget'])
        weapon['widget'] = nil
        weapon['shown'] = false
    end
    WeaponWidgetCreate(false)
end