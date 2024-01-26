json = require("json")
Atlas = require('atlas')
clamp = utils.clamp

function convertWaypoint(wp)
    local clamp  = utils.clamp
    local deg2rad    = math.pi/180
    local rad2deg    = 180/math.pi
    local epsilon    = 1e-10

    local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local posPattern = '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' .. num ..  ',' .. num .. '}'
    local systemId = wp 

    systemId, bodyId, latitude, longitude, altitude = string.match(wp, posPattern)
    assert(systemId, 'Position string is malformed.')

    systemId  = tonumber(systemId)
    bodyId    = tonumber(bodyId)
    latitude  = tonumber(latitude)
    longitude = tonumber(longitude)
    altitude  = tonumber(altitude)

    if bodyId == 0 then -- this is a hack to represent points in space
    mapPosition =  setmetatable({latitude  = latitude,
                                longitude = longitude,
                                altitude  = altitude,
                                bodyId    = bodyId,
                                systemId  = systemId}, MapPosition)
    else
    mapPosition = setmetatable({latitude  = deg2rad*clamp(latitude, -90, 90),
                                longitude = deg2rad*(longitude % 360),
                                altitude  = altitude,
                                bodyId    = bodyId,
                                systemId  = systemId}, MapPosition)
    end
    if mapPosition.bodyId == 0 then
        return vec3(mapPosition.latitude, mapPosition.longitude, mapPosition.altitude)
    end

    local center = {
        x=Atlas[systemId][bodyId].center[1],
        y=Atlas[systemId][bodyId].center[2],
        z=Atlas[systemId][bodyId].center[3]
    }

    local xproj = math.cos(mapPosition.latitude)
    return center + (Atlas[systemId][bodyId].radius + mapPosition.altitude) *
        vec3(xproj*math.cos(mapPosition.longitude),
            xproj*math.sin(mapPosition.longitude),
            math.sin(mapPosition.latitude))
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function contains(tablelist, val)
    for i=1,#tablelist do
       if tablelist[i] == val then 
          return true
       end
    end
    return false
end

function formatNumber(val, numType)
    if numType == 'speed' then
        local speedString = ''
        if type(val) == 'number' then speedString = string.format('%.0fkm/h',val)
        else speedString = string.format('%skm/h',val)
        end
        return speedString
    elseif numType == 'distance' then
        local distString = ''
        if type(val) == 'number' then
            if val < 1000 then distString = string.format('%.2fm',val)
            elseif val < 100000 then distString = string.format('%.2fkm',val/1000)
            else distString = string.format('%.2fsu',val*.000005)
            end
        else
            distString = string.format('%sm',val)
        end
        return distString
    elseif numType == 'mass' then
        local massStr = ''
        if type(val) == 'number' then
            if val < 1000 then massStr = string.format('%.2fkg',val)
            elseif val < 1000000 then massStr = string.format('%.2ft',val/1000)
            else massStr = string.format('%.2fkt',val/1000000)
            end
        else
            massStr = string.format('%skg',val)
        end
        return massStr
    end
end

function WeaponWidgetCreate(start)
    if type(weapon) == 'table' and #weapon > 0 then
        for i = 1, #weapon do
            if string.starts(weapon[i].getName(),'Stasis') and start then
                stasis = true
                stasisData[weapon[i].getLocalId()] = {}
                stasisData[weapon[i].getLocalId()]['Data'] = weapon[i].getWidgetDataId()
                stasisData[weapon[i].getLocalId()]['type'] = weapon[i].getWidgetType()
            elseif not string.starts(weapon[i].getName(),'Stasis') then
                weaponData[weapon[i].getLocalId()] = {}
                weaponData[weapon[i].getLocalId()]['shown'] = false
                weaponData[weapon[i].getLocalId()]['Data'] = weapon[i].getWidgetDataId()
                weaponData[weapon[i].getLocalId()]['type'] = weapon[i].getWidgetType()

                if weaponWidgets then
                    weaponData[weapon[i].getLocalId()]['shown'] = true
                elseif weapon[i].getAmmo() == 0 then
                    weaponData[weapon[i].getLocalId()]['shown'] = true
                end
            end
        end

        if start then weaponPanel = system.createWidgetPanel("Weapons") end
        for k,weapon in pairs(weaponData) do
            if weapon['shown'] then
                local _widget = nil
                _widget = system.createWidget(weaponPanel, weapon['type'])
                weapon['widget'] = _widget
                system.addDataToWidget(weapon['Data'],_widget)
            end
        end
        if start then
            local _panel = nil
            for k,weapon in pairs(stasisData) do
                local _widget = nil
                if not _panel then
                    _panel = system.createWidgetPanel("Stasis")
                    weapon['panel'] = _panel
                else
                    weapon['panel'] = _panel
                end
                _widget = system.createWidget(_panel, weapon['type'])
                weapon['widget'] = _widget
                system.addDataToWidget(weapon['Data'],_widget)
            end
        end
    end
end

function updateRadar(filter)
    local data = radar_1.getWidgetData()
    data = data:gsub('{"constructsList":.*%],"currentTargetId":"', '{"constructsList":[],"currentTargetId":"')
    local pData = data

    local master_primary = '0'
    if slave then
        for i,dbName in pairs(db) do
            if dbName.hasKey('primaryTarget') then
                master_primary = dbName.getStringValue('primaryTarget')
                break
            end
        end
    end
    if  slaveRadarPrimary ~= master_primary then
        system.print('-- Master updated primary: '..master_primary)
        slaveRadarPrimary = master_primary
    end

    local inCombat = construct.getPvPTimer() > 0

    local radarList = radar_1.getConstructIds()
    local constructList = {}
    local primaryList = {}
    radarContactNumber = #radarList
    
    local shipsBySize = {}
    shipsBySize['XS'] = {}
    shipsBySize['S'] = {}
    shipsBySize['M'] = {}
    shipsBySize['L'] = {}

    local localIdentifiedBy = 0
    local localAttackedBy = 0
    local tempclosestEnemy = {}
    tempclosestEnemy['id'] = '0'
    tempclosestEnemy['dist'] = 0
    local tempRadarStats = {
        ['enemy'] = {
            ['L'] = 0,
            ['M'] = 0,
            ['S'] = 0,
            ['XS'] = 0
        },
        ['friendly'] = {
            ['L'] = 0,
            ['M'] = 0,
            ['S'] = 0,
            ['XS'] = 0
        }
    }
    
    radarSelected = tostring(radar_1.getTargetId())
    local n = 0 -- Iterator for coroutine
    
    for _,id in pairs(radarList) do
        local constructData = {}
        constructData['constructId'] = tostring(id)
        constructData['distance'] = radar_1.getConstructDistance(id)
        constructData['size'] = radar_1.getConstructCoreSize(id)
        constructData['inIdentifyRange'] = radarRange > constructData['distance']
        constructData['info'] = {}
        constructData['myThreatStateToTarget'] = radar_1.getThreatRateTo(id)
        constructData['targetThreatState'] = radar_1.getThreatRateFrom(id)
        if constructData['targetThreatState'] == 1 then 
            constructData['targetThreatState'] = 0
        elseif constructData['targetThreatState'] > 2 and constructData['targetThreatState'] ~= 5 then
            constructData['targetThreatState'] = 1
        elseif constructData['targetThreatState'] == 5 then
            constructData['targetThreatState'] = 2
        end
        if constructData['targetThreatState'] == 1 then localIdentifiedBy = localIdentifiedBy + 1
        elseif constructData['targetThreatState'] == 2 then localAttackedBy = localAttackedBy + 1
        end

        constructData['kind'] = radar_1.getConstructKind(id)
        
        constructData['isIdentified'] = radar_1.isConstructIdentified(id)
        constructData['hasWeapons'] = nil
        constructData['topSpeed'] = 0
        if constructData['isIdentified'] then
            local info = radar_1.getConstructInfos(id)
            if info['weapons'] ~= 0 then constructData['hasWeapons'] = true else constructData['hasWeapons'] = false end
            
            local mass = radar_1.getConstructMass(id)
            local topSpeed = (50000/3.6-10713*(mass-10000)/(853926+(mass-10000)))*3.6
            constructData['topSpeed'] = clamp(topSpeed,20000,50000)
        elseif radarTrackingData[tostring(id)] then
            if radarTrackingData[tostring(id)]['topSpeed'] > 0 then
                constructData['topSpeed'] = radarTrackingData[tostring(id)]['topSpeed']
            end
        end

        local abandonded = radar_1.isConstructAbandoned(id)
        local uniqueCode = string.sub(tostring(id),-3)
        local coreID = uniqueCode
        local name = radar_1.getConstructName(id)
        if abandonded then
            uniqueCode = 'CORED'
            local core_pos = radar_1.getConstructWorldPos(id)
            if write_db then
                if write_db.hasKey('abnd-'..tostring(id)) then
                    if write_db.getStringValue('abnd-'..tostring(id)) ~= string.format('::pos{0,0,%.2f,%.2f,%.2f}',core_pos[1],core_pos[2],core_pos[3]) then
                        write_db.setStringValue('abnd-'..tostring(id),string.format('::pos{0,0,%.2f,%.2f,%.2f}',core_pos[1],core_pos[2],core_pos[3]))
                        write_db.setStringValue('abnd-name-'..tostring(id),name)
                    end
               else
                    write_db.setStringValue('abnd-'..tostring(id),string.format('::pos{0,0,%.2f,%.2f,%.2f}',core_pos[1],core_pos[2],core_pos[3]))
                   write_db.setStringValue('abnd-name-'..tostring(id),name)
                end
            end
        end

        
        local transponder_match = radar_1.hasMatchingTransponder(id)
        if transponder_match and not abandonded then 
            if constructData['kind'] == 5 then 
                tempRadarStats['friendly'][constructData['size']] = tempRadarStats['friendly'][constructData['size']] + 1
            end
            local owner = radar_1.getConstructOwnerEntity(id)
            if owner['isOrganization'] then
                owner = system.getOrganization(owner['id'])
                owner = string.format('%s',owner['tag'])
            else
                owner = system.getPlayerName(owner['id'])
                owner = string.format('%s',owner)
            end
            constructData['name'] = string.format('[%s] %s',uniqueCode,owner)
            radarFriendlies[id] = {[1] = constructData['name'], [2] = radar_1.getConstructWorldPos(id)}
        else
            if constructData['kind'] == 5 and not abandonded then 
                tempRadarStats['enemy'][constructData['size']] = tempRadarStats['enemy'][constructData['size']] + 1
                if not friendlySIDs['sc-'..id] and tempclosestEnemy['dist'] < constructData['distance']*.000005 then
                    tempclosestEnemy['dist'] = constructData['distance']*.000005
                    tempclosestEnemy['id'] = coreID
                end
            end
            radarFriendlies[id] = nil
        end
        if not constructData['name'] then constructData['name'] = string.format('[%s] %s',uniqueCode,name) end
        local high_value = contains(primaries,tostring(id))
        if not high_value and slave and master_primary == coreID then
            high_value = coreID == tostring(master_primary)
            constructData['name'] = string.format('[%s] %s',uniqueCode,'PRIMARY')
        end
        if scout_info[tostring(id)] then
            constructData['name'] = string.format('[%s] %s',uniqueCode,scout_info[tostring(id)])
        end
        
        radarTrackingData[tostring(id)] = constructData

        local shown = false
        if (targetRadar or slave) and high_value then
            if tostring(id) == radarSelected then
                table.insert(primaryList,1,json.encode(constructData))
            else 
                table.insert(primaryList,json.encode(constructData))
            end
            shown = true
        end

        if not shown then
            if tostring(id) == radarSelected then
                table.insert(constructList,1,json.encode(constructData))
            --elseif radarSelected == '0' and constructData['isIdentified'] then
            --    table.insert(constructList,1,json.encode(constructData))
            --elseif radarSelected ~= '0' and constructData['isIdentified'] then
            --    table.insert(constructList,2,json.encode(constructData))
            elseif radarFilter == 'All' and (not abandonded or not hideAbandonedCores) then
                table.insert(constructList,json.encode(constructData))
            elseif radarFilter == 'enemy' and not transponder_match then
                table.insert(constructList,json.encode(constructData))
            elseif radarFilter == 'identified' and constructData['isIdentified'] then
                table.insert(constructList,json.encode(constructData))
            elseif radarFilter == 'friendly' and transponder_match then
                table.insert(constructList,json.encode(constructData))
            elseif radarFilter == 'primary' and coreID == tostring(primary) then
                table.insert(constructList,json.encode(constructData))
            end
        end

        if n % 50 == 0 then coroutine.yield() end
        n = n + 1
    end
    data = data:gsub('"errorMessage":""','"errorMessage":"'..radarFilter..'-'..radarSort..'"')
    data = data:gsub('"constructsList":%[%]','"constructsList":['..table.concat(constructList,',')..']')

    primaryData = pData:gsub('"constructsList":%[%]','"constructsList":['..table.concat(primaryList,',')..']')

    radarStats = tempRadarStats
    radarWidgetData = data
    identifiedBy = localIdentifiedBy
    attackedBy = localAttackedBy
    closestEnemy = tempclosestEnemy
    return data
end

function RadarWidgetCreate(title)
    local _data = radar_1.getWidgetData()--updateRadar(radarFilter)
    local _panel = system.createWidgetPanel(title)
    local _widget = system.createWidget(_panel, "radar")
    local ID = system.createData(_data)
    system.addDataToWidget(ID, _widget)
    return ID,_panel
end

function globalDB(action)
    if write_db ~= nil then
        if action == 'get' then
            if write_db.hasKey('printCombatLog') then printCombatLog = write_db.getIntValue('printCombatLog') == 1 end
            if write_db.hasKey('dangerWarning') then dangerWarning = write_db.getIntValue('dangerWarning') end
            if write_db.hasKey('validatePilot') then validatePilot = write_db.getIntValue('validatePilot') == 1 end
            if write_db.hasKey('L_Shield_HP') then L_Shield_HP = write_db.getIntValue('L_Shield_HP') end
            if write_db.hasKey('M_Shield_HP') then M_Shield_HP = write_db.getIntValue('M_Shield_HP') end
            if write_db.hasKey('S_Shield_HP') then S_Shield_HP = write_db.getIntValue('S_Shield_HP') end
            if write_db.hasKey('XS_Shield_HP') then XS_Shield_HP = write_db.getIntValue('XS_Shield_HP') end
            if write_db.hasKey('max_radar_load') then max_radar_load = write_db.getIntValue('max_radar_load') end

            if write_db.hasKey('minimalWidgets') then minimalWidgets = write_db.getIntValue('minimalWidgets') == 1 end
            if write_db.hasKey('weaponWidgets') then weaponWidgets = write_db.getIntValue('weaponWidgets') == 1 end
            if write_db.hasKey('pilotSeat') then pilotSeat = write_db.getIntValue('pilotSeat') == 1 end
            if write_db.hasKey('dmgAvgDuration') then dmgAvgDuration = write_db.getIntValue('dmgAvgDuration') end

            for _,key in pairs(write_db.getKeyList()) do
                if string.starts(key,'sc-') then
                    local id = string.sub(key,4)
                    friendlySIDs[tonumber(id)] = write_db.getStringValue(string.format('sc-%s',id))
                end
            end

        elseif action == 'save' then
            write_db.setStringValue('uc-'..validPilotCode,pilotName)
            if printCombatLog then write_db.setIntValue('printCombatLog',1) else write_db.setIntValue('printCombatLog',0) end
            write_db.setIntValue('dangerWarning',dangerWarning)
            if validatePilot then write_db.setIntValue('validatePilot',1) else write_db.setIntValue('validatePilot',0) end
            write_db.setIntValue('L_Shield_HP',L_Shield_HP)
            write_db.setIntValue('M_Shield_HP',M_Shield_HP)
            write_db.setIntValue('S_Shield_HP',S_Shield_HP)
            write_db.setIntValue('XS_Shield_HP',XS_Shield_HP)
            write_db.setIntValue('max_radar_load',max_radar_load)

            if minimalWidgets then write_db.setIntValue('minimalWidgets',1) else write_db.setIntValue('minimalWidgets',0) end
            if weaponWidgets then write_db.setIntValue('weaponWidgets',1) else write_db.setIntValue('weaponWidgets',0) end
            if pilotSeat then write_db.setIntValue('pilotSeat',1) else write_db.setIntValue('pilotSeat',0) end
            write_db.setIntValue('dmgAvgDuration',dmgAvgDuration)

        end
    end
end

function weaponsWidget()
    local ww = {}
    ww[#ww+1] = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    local wtext = {}
    if weapon_size > 0 then
        local wStatus = {[1] = 'Idle', [2] = 'Firing', [4] = 'Reloading', [5] = 'Unloading'}
        ww[#ww+1] = [[
            <line x1="]].. 0.02*screenWidth ..[[" y1="]].. 0.665*screenHeight ..[[" x2="]].. 0.15*screenWidth ..[[" y2="]].. 0.665*screenHeight ..[[" style="stroke:lightgrey;stroke-width:0.25;opacity:]].. 1 ..[[;" />
            ]]
        local offset = 1
        for i,w in pairs(weapon) do
            local textColor = 'white'
            local ammoColor = 'white'
            local probColor = 'rgb(255, 60, 60)'
            if w.isOutOfAmmo() then ammoColor = 'rgb(255, 60, 60)' end

            local probs = w.getHitProbability()
            if probs > .7 then probColor = 'rgb(60, 255, 60)' elseif probs > .5 then probColor = 'yellow' end
            
            local weaponName = w.getName():lower()

            local matches = {}
            for w in weaponName:gmatch("([^ ]+) ?") do table.insert(matches,w) end
            local prefix = matches[1]:sub(1,1) .. matches[2]:sub(1,1)
            local wtype = ''
            if string.find(weaponName,'cannon') then wType = 'Cannon'
            elseif string.find(weaponName,'railgun') then wType = 'Railgun'
            elseif string.find(weaponName,'missile') then wType = 'Missile'
            elseif string.find(weaponName,'laser') then wType = 'Laser'
            elseif string.find(weaponName,'stasis') then wType = 'Stasis'
            end
            if wType == 'Stasis' then
                weaponName = wType
            else
                weaponName = prefix .. wType
            end

            local atn = w.getAmmo()
            local ammoType = 'Not loaded'
            if atn ~= 0 then
                ammoType = system.getItem(w.getAmmo())
                ammoType = tostring(ammoType['name']):lower()
                if wType ~= 'Stasis' and weaponData[w.getLocalId()] and bootTimer >= 2 and not weaponWidgets then
                    for k,weapon in pairs(weaponData) do
                        system.destroyWidget(weapon['widget'])
                        weapon['widget'] = nil
                        weapon['shown'] = false
                    end
                end
            elseif wType ~= 'Stasis' and atn == 0 then
                if not weaponData[w.getLocalId()] and bootTimer >= 2 then
                    local _widget = system.createWidget(weaponPanel, weaponData[w.getLocalId()]['type'])
                    weaponData[w.getLocalId()]['widget'] = _widget
                    system.addDataToWidget(weaponData[w.getLocalId()]['Data'],_widget)
                    weaponData[w.getLocalId()]['shown'] = true
                end
            end
            ammoTypeColor = 'white'
            if string.find(ammoType,'antimatter') then ammoTypeColor = 'rgb(56, 255, 56)' ammoType = 'Antimatter'
            elseif string.find(ammoType,'electromagnetic') then ammoTypeColor = 'rgb(27, 255, 217)' ammoType = 'ElectroMagnetic'
            elseif string.find(ammoType,'kinetic') then ammoTypeColor = 'rgb(255, 75, 75)' ammoType = 'Kinetic'
            elseif string.find(ammoType,'thermic') then ammoTypeColor = 'rgb(255, 234, 41)' ammoType = 'Thermic'
            end
            local weaponStr = string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring((0.66 - 0.015*i) * screenHeight) ..'px;left: '.. tostring(0.02* screenWidth) ..'px;"><div style="float: left;color: white;">%s |&nbsp;</div><div style="float: left;color:%s;"> %.2f%% </div><div style="float: left;color: %s;"> | %s |&nbsp;</div><div style="float: left;color: %s;"> '..ammoType..'&nbsp;</div><div style="float: left;color: %s;">(%s) </div></div>',weaponName,probColor,probs*100,textColor,wStatus[w.getStatus()],ammoTypeColor,ammoColor,w.getAmmoCount())
            wtext[#wtext+1] = weaponStr
            offset = i
        end
        wtext = table.concat(wtext,'')
        offset = offset + 1
        ww[#ww+1] = [[
            <line x1="]].. 0.02*screenWidth ..[[" y1="]].. (0.675-offset*0.015)*screenHeight ..[[" x2="]].. 0.15*screenWidth ..[[" y2="]].. (0.675-offset*0.015)*screenHeight ..[[" style="stroke:lightgrey;stroke-width:0.25;opacity:]].. 1 ..[[;" />
            ]]
    end
    ww[#ww+1] = '</svg>' .. wtext
    return table.concat(ww,'')
end

function radarWidget()
    local temp_range = radar_1.getIdentifyRanges()
    if #temp_range > 0 then
        radarRange = temp_range[1]
    end
    local rw = {}
    local friendlyShipNum = radarStats['friendly']['L'] + radarStats['friendly']['M'] + radarStats['friendly']['S'] + radarStats['friendly']['XS']
    local enemyShipNum = radarStats['enemy']['L'] + radarStats['enemy']['M'] + radarStats['enemy']['S'] + radarStats['enemy']['XS']
    local radarRangeString = formatNumber(radarRange,'distance')

    local x, y, s
    if minimalWidgets then 
        y = -0.9
        x = 67.5
        s = 10
    else
        y = 67
        x = 29
        s = 11.25
    end

    rw[#rw+1] = string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.185 * screenHeight) ..'px;left: '.. tostring(.875 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Identification Range:&nbsp;</div><div style="float: left;color: rgb(25, 247, 255);">%s&nbsp;</div></div>]],radarRangeString)
  

    rw[#rw+1] = string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.15 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">Identified By:&nbsp;</div><div style="float: left;color: orange;">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],identifiedBy)

    rw[#rw+1] = string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.165 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Attacked By:&nbsp;</div><div style="float: left;color: rgb(255, 60, 60);">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],attackedBy)

    rw[#rw+1] = [[
        <svg style="position: absolute; top: ]]..y..[[vh; left: ]]..x..[[vw;" viewBox="0 0 286 240" width="]]..s..[[vw">
            <rect x="6%" y="6%" width="87%" height="60%" rx="1%" ry="1%" fill="rgba(100,100,100,.9)" />
            <polygon style="stroke-width: 2px; stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="22 15 266 15 266 32 252 46 22 46"/>
            <polygon style="stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="18 17 12 22 12 62 15 66 15 154 18 157"/>
            <text style="fill: ]]..fontColor..[[; font-size: 17px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="37" y="35">Radar Information (]]..tostring(radarContactNumber)..[[)</text>
        ]]
        rw[#rw+1] = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="54" x2="22" y2="77"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="73">Enemy Ships:</text>
            <text style="fill: rgb(255, 60, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="137" y="73">]]..enemyShipNum..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="81" x2="22" y2="104"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="30" y="100">L:</text>
            <text style="fill: rgb(255, 60, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="50" y="100">]]..radarStats['enemy']['L']..[[</text>

            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="68" y="100">M:</text>
            <text style="fill: rgb(255, 60, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="95" y="100">]]..radarStats['enemy']['M']..[[</text>

            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="115" y="100">S:</text>
            <text style="fill: rgb(255, 60, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="135" y="100">]]..radarStats['enemy']['S']..[[</text>

            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="155" y="100">XS:</text>
            <text style="fill: rgb(255, 60, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="185" y="100">]]..radarStats['enemy']['XS']..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="108" x2="22" y2="131"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="127">Friendly Ships:</text>
            <text style="fill: rgb(60, 255, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="150" y="127">]]..friendlyShipNum..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="135" x2="22" y2="158"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="30" y="154">L:</text>
            <text style="fill: rgb(60, 255, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="50" y="154">]]..radarStats['friendly']['L']..[[</text>

            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="68" y="154">M:</text>
            <text style="fill: rgb(60, 255, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="95" y="154">]]..radarStats['friendly']['M']..[[</text>

            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="115" y="154">S:</text>
            <text style="fill: rgb(60, 255, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="135" y="154">]]..radarStats['friendly']['S']..[[</text>

            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="155" y="154">XS:</text>
            <text style="fill: rgb(60, 255, 60); font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="185" y="154">]]..radarStats['friendly']['XS']..[[</text>
        ]]

        rw[#rw+1] = '</svg>'

    if attackedBy >= dangerWarning or showAlerts then
        warnings['attackedBy'] = 'svgWarning'
    else
        warnings['attackedBy'] = nil
    end

    if closestEnemy['dist'] < 1.35 and closestEnemy['dist'] > 0 and not inSZ then
        warnings['closestEnemy'] = 'svgWarning'
    else
        warnings['closestEnemy'] = nil
    end

    return table.concat(rw,'')
end

function identifiedWidget()
    local id = radar_1.getTargetId()
    local iw = {}
    if id ~= 0 then
        if targetID == 0 then warnings['cored'] = nil warnings['friendly'] = nil end

        local targetSpeedSVG = ''

        local size = radar_1.getConstructCoreSize(id)
        local dmg = 0
        if write_db and dmgTracker[tostring(id)] then write_db.setFloatValue('damage - ' .. tostring(id) .. ' - ' .. pilotName,dmgTracker[tostring(id)]) end
        if #db > 0 then
            for _,dbName in pairs(db) do
                for _,key in pairs(dbName.getKeyList()) do
                    if string.starts(key,'damage - ' .. tostring(id)) then
                        dmg = dmg + dbName.getFloatValue(key)
                    end
                end
            end
        end
        if (dmg == 0 or not write_db) and dmgTracker[tostring(id)] then dmg = dmgTracker[tostring(id)] end
        local dmgRatio = clamp(dmg/shieldDmgTrack[size],0,1)
        if dmg < 1000 then dmg = string.format('%.2f',dmg)
        elseif dmg < 1000000 then dmg = string.format('%.2fk',dmg/1000)
        else dmg = string.format('%.2fm',dmg/1000000)
        end

        local tMatch = radar_1.hasMatchingTransponder(id)
        local shipIDMatch = false
        if useShipID then for k,v in pairs(friendlySIDs) do if id == k then shipIDMatch = true end end end
        local friendly = tMatch or shipIDMatch

        local abandonded = radar_1.isConstructAbandoned(id)
        local cardFill = 'rgba(175, 75, 75, 0.30)'
        local cardText = 'rgba(225, 250, 265, 1)'
        if friendly then cardFill = 'rgba(25, 25, 50, 0.35)' cardText = 'rgba(225, 250, 265, 1)'
        elseif abandonded then cardFill = '	rgba(169, 169, 169,.35)' cardText = 'black'
        end

        local distance = radar_1.getConstructDistance(id)
        local distString = formatNumber(distance,'distance')

        local name = radar_1.getConstructName(id)
        local uniqueCode = string.sub(tostring(id),-3)
        local shortName = name:sub(0,17)
        shortName = shortName:gsub('!','|')

        local lineColor = 'lightgrey'
        local targetIdentified = radar_1.isConstructIdentified(id)


        if abandonded or showAlerts then warnings['cored'] = 'svgTarget' else warnings['cored'] = nil end
        if friendly or showAlerts then warnings['friendly'] = 'svgGroup' else warnings['friendly'] = nil end

        local speedVec = vec3(construct.getWorldVelocity())
        local mySpeed = speedVec:len() * 3.6
        local myMass = construct.getMass()

        local targetSpeedString = 'Not Identified'
        if targetIdentified then targetSpeed = radar_1.getConstructSpeed(id) * 3.6 targetSpeedString = formatNumber(targetSpeed,'speed') end
        local speedDiff = 0
        if targetIdentified then speedDiff = mySpeed-targetSpeed end
        
        local targetSpeedColor = 'white'
        if targetIdentified then
            if speedDiff < -1000 then targetSpeedColor = 'rgb(255, 60, 60)'
            elseif speedDiff > 1000 then targetSpeedColor = 'rgb(56, 255, 56)'
            end
        end
        targetSpeedSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="54" x2="22" y2="77"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="73">Speed:</text>
            <text style="fill: ]]..targetSpeedColor..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="84" y="73">]]..targetSpeedString..[[</text>
        ]]

        local updateTimer = false
        if arkTime - lastUpdateTime > 0.5 and lastUpdateTime ~= 0 then 
            lastUpdateTime = arkTime
            updateTimer = true
        elseif lastUpdateTime == 0 then
            lastUpdateTime = arkTime
            lastDistance = distance
        end

        if updateTimer then
            local localGapCompare = 'Stable'
            local gap = distance - lastDistance
            if gap < -250 then localGapCompare = 'Closing' 
            elseif gap > 250 then localGapCompare = 'Parting'
            end
            gapCompare = localGapCompare
            lastDistance = distance
        end
        local gapColor = 'white'
        if gapCompare == 'Closing' then gapColor = 'rgb(56, 255, 56)' elseif gapCompare == 'Parting' then gapColor = 'rgb(255, 60, 60)' end
        local distanceCompareSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="81" x2="22" y2="104"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="100">Gap:</text>
            <text style="fill: ]]..gapColor..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="69" y="100">]]..tostring(gapCompare)..[[</text>
        ]]

        if updateTimer and targetIdentified then
            local localSpeedCompare = 'No Change'
            if lastSpeed then
                local speedChange = targetSpeed - lastSpeed
                if speedChange < -100 then localSpeedCompare = 'Braking'
                elseif speedChange > 100 then localSpeedCompare = 'Accelerating'
                end
                speedCompare = localSpeedCompare
            end
            lastSpeed = targetSpeed
        elseif not targetIdentified then
            speedCompare = 'Not Identified'
        end
        local speedCompareColor = 'white'
        if speedCompare == 'Braking' then speedCompareColor = 'rgb(255, 60, 60)' elseif speedCompare == 'Accelerating' then speedCompareColor = 'rgb(56, 255, 56)' end
        local speedCompareSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="108" x2="22" y2="131"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="127">&#8796;Speed:</text>
            <text style="fill: ]]..speedCompareColor..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="99" y="127">]]..tostring(speedCompare)..[[</text>
        ]]

        local dmgSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="135" x2="22" y2="158"/>
            <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="154">Damage:</text>
            <text style="fill: orange; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="99" y="154">]]..string.format('%s (%.2f%%)',dmg,(1-dmgRatio)*100)..[[</text>
        ]]

        --local mass = radar_1.getConstructMass(id)
        local topSpeed = radarTrackingData[tostring(id)] ~= nil
        local topSpeedSVG = ''
        if topSpeed then
            if radarTrackingData[tostring(id)]['topSpeed'] > 0 then
                topSpeedSVG = [[
                    <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="162" x2="22" y2="185"/>
                    <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="181">Top Speed:</text>
                    <text style="fill: orange; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="110" y="181">]]..formatNumber(radarTrackingData[tostring(id)]['topSpeed'],'speed')..[[</text>
                ]]
            end
        end

        local info = radar_1.getConstructInfos(id)
        local weapons = 'False'
        if info['weapons'] ~= 0 then weapons = 'True' end
        local dataSVG = ''
        if targetIdentified then
            dataSVG = [[
                <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey;" x1="22" y1="189" x2="22" y2="212"/>
                <text style="fill: white; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="208">Armed:</text>
                <text style="fill: orange; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="95" y="208">]]..weapons..[[</text>
            ]]
        end

        local owner = ''
        if radar_1.hasMatchingTransponder(id) then
            owner = radar_1.getConstructOwnerEntity(id)
            if owner['isOrganization'] then
                owner = system.getOrganization(owner['id'])
                owner = owner['tag']
            else
                owner = system.getPlayerName(owner['id'])
            end
        elseif friendlySIDs[id] then
            owner = friendlySIDs[id]
        end
        if owner ~= '' then 
            owner = [[<text style="fill: white; font-size: 17px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="37" y="5">]]..string.format('Owned by: %s (%s)',owner,id)..[[</text>]]
        end

        local x,y,s
        y = 15
        x = 1.75
        s = 11.25
        iw[#iw+1] = [[
            <svg style="position: absolute; top: ]]..y..[[vh; left: ]]..x..[[vw;" viewBox="0 -10 286 240" width="]]..s..[[vw">
                ]]..owner..[[
                <rect x="6%" y="6%" width="87%" height="90%" rx="1%" ry="1%" fill="rgba(100,100,100,.9)" />
                <polygon style="stroke-width: 2px; stroke-linejoin: round; fill: ]]..cardFill..[[; stroke: ]]..lineColor..[[;" points="22 15 266 15 266 32 252 46 22 46"/>
                <polygon style="stroke-linejoin: round; fill: ]]..cardFill..[[; stroke: ]]..lineColor..[[;" points="18 17 12 22 12 62 15 66 15 225 18 227"/>
                <text style="fill: ]]..cardText..[[; font-size: 17px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="37" y="35">]]..string.format('%s - [%s] %s (%s)',size,uniqueCode,shortName,distString)..[[</text>
                ]]..targetSpeedSVG..[[
                ]]..distanceCompareSVG..[[
                ]]..speedCompareSVG..[[
                ]]..dmgSVG

        if topSpeedSVG then
            iw[#iw+1] = topSpeedSVG .. dataSVG
        end

        iw[#iw+1] = [[
            </svg>
        ]]

        if targetIndicators or showAlerts then
            iw[#iw+1] = [[
                <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
                    <svg width="]].. tostring(.03 * screenWidth) ..[[" height="]].. tostring(.03 * screenHeight) ..[[" x="]].. tostring(.30 * screenWidth) ..[[" y="]].. tostring(.50 * screenHeight) ..[[" style="fill: ]]..speedCompareColor..[[;">
                        ]]..warningSymbols['svgTarget']..[[
                    </svg>
                    <text x="]].. tostring(.327 * screenWidth) ..[[" y="]].. tostring(.51 * screenHeight) .. [[" style="fill: white;" font-size="1.7vh" font-weight="bold">Speed Change:</text>
                    <text x="]].. tostring(.390 * screenWidth) ..[[" y="]].. tostring(.51 * screenHeight) .. [[" style="fill: ]]..speedCompareColor..[[;" font-size="1.7vh" font-weight="bold">]]..speedCompare..[[</text>
                    <text x="]].. tostring(.359 * screenWidth) ..[[" y="]].. tostring(.53 * screenHeight) .. [[" style="fill: white;" font-size="1.7vh" font-weight="bold">Speed: </text>
                    <text x="]].. tostring(.390 * screenWidth) ..[[" y="]].. tostring(.53 * screenHeight) .. [[" style="fill: ]]..speedCompareColor..[[;" font-size="1.7vh" font-weight="bold">]]..targetSpeedString..[[</text>
                </svg>
            ]]
        end
    end
    return table.concat(iw,'')
end

function dpsWidget()
    local cDPS = 0
    local dmgTime = tonumber(string.format('%.0f',arkTime))
    for k,v in pairs(dpsChart) do
        if k < dmgTime - dmgAvgDuration then
            dpsChart[k] = nil
        else
            cDPS = cDPS + dpsChart[k]
        end
    end
    cDPS = cDPS/dmgAvgDuration

    local dw = string.format([[<svg width="100%%" height="100%%" style="position: absolute;left:0%%;top:0%%;font-family: Calibri;" viewBox="0 0 1920 1080">
                <text x="1.92" y="85" style="fill: lightgreen;" font-size="1.42vh" font-weight="bold">DPS: %.1fk</text></svg>
    ]],cDPS/1000)
    return dw
end

function warningsWidget()
    local ww = {}
    ww[#ww+1] = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    local warningText = {}
    warningText['attackedBy'] = string.format('%.0f ships attacking',attackedBy)
    warningText['cored'] = 'Target is Destroyed'
    warningText['friendly'] = 'Target is Friendly'
    warningText['noRadar'] = 'No Radar Linked'
    warningText['venting'] = 'Shield Venting'
    warningText['radar_delta'] = string.format('Radar Delay %.2fs',cr_delta)
    warningText['closestEnemy'] = string.format('Enemy (%s) at %.2fsu',closestEnemy['id'],closestEnemy['dist'])

    local warningColor = {}
    warningColor['attackedBy'] = 'red'
    warningColor['cored'] = 'orange'
    warningColor['friendly'] = 'green'
    warningColor['noRadar'] = 'red'
    warningColor['venting'] = shieldHPColor
    warningColor['radar_delta'] = 'orange'
    warningColor['closestEnemy'] = 'orange'

    local count = 0
    local y = .06
    if minimalWidgets then y = .14 end
    for k,v in pairs(warnings) do
        if v ~= nil then
            if k == 'closestEnemy' and closestEnemy['dist'] < 1.1 then
                warningColor['closestEnemy'] = 'red'
                ww[#ww+1] = string.format([[
                    <svg width="]].. tostring(.03 * screenWidth) ..[[" height="]].. tostring(.03 * screenHeight) ..[[" x="]].. tostring(0.45 * screenWidth) ..[[" y="]].. tostring(0.40 * screenHeight) ..[[" style="fill: ]]..warningColor[k]..[[;">
                        ]]..warningSymbols[v]..[[
                    </svg>
                    <text x="]].. tostring(.477 * screenWidth) ..[[" y="]].. tostring(0.42 * screenHeight) .. [[" style="fill: ]]..warningColor[k]..[[;" font-size="2vh" font-weight="bold">]]..warningText[k]..[[</text>
                    ]])
            else
                ww[#ww+1] = string.format([[
                    <svg width="]].. tostring(.03 * screenWidth) ..[[" height="]].. tostring(.03 * screenHeight) ..[[" x="]].. tostring(.65 * screenWidth) ..[[" y="]].. tostring(y * screenHeight + .032 * screenHeight * count) ..[[" style="fill: ]]..warningColor[k]..[[;">
                        ]]..warningSymbols[v]..[[
                    </svg>
                    <text x="]].. tostring(.677 * screenWidth) ..[[" y="]].. tostring((y+.02) * screenHeight + .032 * screenHeight * count) .. [[" style="fill: ]]..warningColor[k]..[[;" font-size="1.7vh" font-weight="bold">]]..warningText[k]..[[</text>
                    ]])
                count = count + 1
            end
        end
    end
    ww[#ww+1] = '</svg>'
    return table.concat(ww,'')
end

function generateHTML()
    local htmlTable = {}
    htmlTable[#htmlTable+1] = [[<html> <body style="font-family: Calibri;">]]
    htmlTable[#htmlTable+1] =  arHTML
    if showScreen then
        if weapon_1 then htmlTable[#htmlTable+1] = weaponHTML end
        if radar_1 then htmlTable[#htmlTable+1] = radarHTML end
        if radar_1 then htmlTable[#htmlTable+1] = identHTML end
        if weapon_1 then htmlTable[#htmlTable+1] = dpsHTML end
    end
    htmlTable[#htmlTable+1] = warningsHTML
    htmlTable[#htmlTable+1] = [[ </body> </html> ]]
    system.setScreen(table.concat(htmlTable, ''))
end

