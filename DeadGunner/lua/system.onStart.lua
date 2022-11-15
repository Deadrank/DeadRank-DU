json = require("dkjson")
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

function WeaponWidgetCreate()
    if type(weapon) == 'table' and #weapon > 0 then
        local _panel = system.createWidgetPanel("Weapons")
        weaponDataList = {}
        for i = 1, #weapon do
            local weaponDataID = weapon[i].getWidgetDataId()
            local widgetType = weapon[i].getWidgetType()
            local _widget = system.createWidget(_panel, "weapon")
            system.addDataToWidget(weaponDataID,system.createWidget(_panel, widgetType))
            if i % maxWeaponsPerWidget == 0 and i < #weapon then _panel = system.createWidgetPanel("Weapons") end
        end
    end
end

function updateRadar(filter)
    local data = radar_1.getWidgetData()

    local radarList = radar_1.getConstructIds()
    local constructList = {}
    if #radarList > max_radar_load then radarOverload = true else radarOverload = false end
    radarContactNumber = #radarList

    local enemyLShips = 0
    local friendlyLShips = 0
    
    local shipsBySize = {}
    shipsBySize['XS'] = {}
    shipsBySize['S'] = {}
    shipsBySize['M'] = {}
    shipsBySize['L'] = {}

    local localIdentifiedBy = 0
    local localAttackedBy = 0
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
    
    local target = tostring(radar_1.getTargetId())
    --for n,id in pairs(radarList) do
    local n = 0
    for id in data:gmatch('{"constructId":"([%d%.]*)"') do
        local identified = radar_1.isConstructIdentified(id) == 1--construct.isIdentified--
        local shipType = radar_1.getConstructKind(id)
        local abandonded = radar_1.isConstructAbandoned(id) == 1
        local nameOrig = radar_1.getConstructName(id) --construct.name--
        if abandonded then
            local core_pos = radar_1.getConstructWorldPos(id)
            if write_db then
                if write_db.hasKey('abnd-'..tostring(id)) then
                    if write_db.getStringValue('abnd-'..tostring(id)) ~= string.format('::pos{0,0,%.2f,%.2f,%.2f}',core_pos[1],core_pos[2],core_pos[3]) then
                        write_db.setStringValue('abnd-'..tostring(id),string.format('::pos{0,0,%.2f,%.2f,%.2f}',core_pos[1],core_pos[2],core_pos[3]))
                        write_db.setStringValue('abnd-name-'..tostring(id),nameOrig)
                    end
                else
                    write_db.setStringValue('abnd-'..tostring(id),string.format('::pos{0,0,%.2f,%.2f,%.2f}',core_pos[1],core_pos[2],core_pos[3]))
                    write_db.setStringValue('abnd-name-'..tostring(id),nameOrig)
                end
            end
        end

        if  (radarOverload and shipType == 5 and not abandonded) or identified or id == target or (not radarOverload and not (hideAbandonedCores and abandonded)) then
            local shipSize = radar_1.getConstructCoreSize(id)--construct.size--
            local threatLevel = radar_1.getThreatRateFrom(id)--construct.targetThreatState--
            if threatLevel == 2 then localIdentifiedBy = localIdentifiedBy + 1
            elseif threatLevel == 5 then localAttackedBy = localAttackedBy + 1
            end
            local tMatch = radar_1.hasMatchingTransponder(id) == 1
            local name = nameOrig--:gsub('%[',''):gsub('%]','')
            nameOrig = nameOrig:gsub('%]','%%]'):gsub('%[','%%['):gsub('%(','%%('):gsub('%)','%%)')
            local uniqueCode = string.sub(tostring(id),-3)
            local uniqueName = string.format('[%s] %s',uniqueCode,name)
            if tMatch then 
                local owner = radar_1.getConstructOwnerEntity(id)
                if owner['isOrganization'] then
                    owner = system.getOrganization(owner['id'])
                    uniqueName = string.format('[%s] %s',owner['tag'],name)
                else
                    owner = system.getPlayerName(owner['id'])
                    uniqueName = string.format('[%s] %s',owner,name)
                end
            elseif abandonded then
                uniqueName = string.format('[CORED] %s',name)
            end

            local shipIDMatch = false
            if useShipID then for k,v in pairs(friendlySIDs) do if id == k then shipIDMatch = true end end end
            local friendly = tMatch or shipIDMatch
            
            if shipType == 5 and not abandonded then
                if friendly then tempRadarStats['friendly'][shipSize] = tempRadarStats['friendly'][shipSize] + 1
                else tempRadarStats['enemy'][shipSize] = tempRadarStats['enemy'][shipSize] + 1
                end
            end

            if contains(filterSize,shipSize) or tostring(id) == target then
                if filter == 'enemy' and not friendly then
                    local rawData = data:gmatch('{"constructId":"'..tostring(id)..'"[^}]*}[^}]*}') 
                    for str in rawData do
                        local replacedData = str:gsub(nameOrig,uniqueName)
                        if identified then
                            table.insert(constructList,1,replacedData)
                        elseif radarSort == 'Size' then
                            table.insert(shipsBySize[shipSize],replacedData)
                        else
                            table.insert(constructList,replacedData)
                        end
                    end
                elseif filter == 'identified' and identified then
                    local rawData = data:gmatch('{"constructId":"'..tostring(id)..'"[^}]*}[^}]*}') 
                    for str in rawData do
                        local replacedData = str:gsub(nameOrig,uniqueName)
                        if radarSort == 'Size' then
                            table.insert(shipsBySize[shipSize],replacedData)
                        else
                            table.insert(constructList,replacedData)
                        end
                    end
                elseif filter == 'friendly' and friendly then
                    local rawData = data:gmatch('{"constructId":"'..tostring(id)..'"[^}]*}[^}]*}') 
                    for str in rawData do
                        local replacedData = str:gsub(nameOrig,uniqueName)
                        if identified then
                            table.insert(constructList,1,replacedData)
                        elseif radarSort == 'Size' then
                            table.insert(shipsBySize[shipSize],replacedData)
                        else
                            table.insert(constructList,replacedData)
                        end
                    end
                elseif filter == 'primary' and tostring(primary) == uniqueCode then
                    local rawData = data:gmatch('{"constructId":"'..tostring(id)..'"[^}]*}[^}]*}') 
                    for str in rawData do
                        local replacedData = str:gsub(nameOrig,uniqueName)
                        if identified then
                            table.insert(constructList,1,replacedData)
                        elseif radarSort == 'Size' then
                            table.insert(shipsBySize[shipSize],replacedData)
                        else
                            table.insert(constructList,replacedData)
                        end
                    end
                elseif radarFilter == 'All' then
                    local rawData = data:gmatch('{"constructId":"'..tostring(id)..'"[^}]*}[^}]*}') 
                    for str in rawData do
                        local replacedData = str:gsub(nameOrig,uniqueName)
                        if identified or tostring(id) == target then
                            table.insert(constructList,1,replacedData)
                        elseif radarSort == 'Size' then
                            table.insert(shipsBySize[shipSize],replacedData)
                        else
                            table.insert(constructList,replacedData)
                        end
                    end
                end
            end
            if n % 50 == 0 then coroutine.yield() end
        end
        n = n + 1
    end

    coroutine.yield()
    data = data:gsub('{"constructId[^}]*}[^}]*},*', "")
    data = data:gsub('"errorMessage":""','"errorMessage":"'..radarFilter..'-'..radarSort..'"')
    if radarSort == 'Size' then
        for _,ship in pairs(shipsBySize['XS']) do table.insert(constructList,ship) end
        for _,ship in pairs(shipsBySize['S']) do table.insert(constructList,ship) end
        for _,ship in pairs(shipsBySize['M']) do table.insert(constructList,ship) end
        for _,ship in pairs(shipsBySize['L']) do table.insert(constructList,ship) end
        data = data:gsub('"constructsList":%[%]','"constructsList":['..table.concat(constructList,',')..']')
    else
        data = data:gsub('"constructsList":%[%]','"constructsList":['..table.concat(constructList,',')..']')
    end

    radarStats = tempRadarStats
    radarWidgetData = data
    identifiedBy = localIdentifiedBy
    attackedBy = localAttackedBy
    return data
end

function RadarWidgetCreate()
    local _data = radar_1.getWidgetData()--updateRadar(radarFilter)
    local _panel = system.createWidgetPanel("RADAR")
    local _widget = system.createWidget(_panel, "radar")
    radarDataID = system.createData(_data)
    system.addDataToWidget(radarDataID, _widget)
    return radarDataID
end

function ARWidget()
    local arw = ARSVG
    --test = arw .. [[
    --    <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
    --        <text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring(.03 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size="1.42vh" font-weight="bold">Augmented Reality Mode: ]]..AR_Mode..[[</text>
    --    </svg>
    --]]

    return arw
end

function globalDB(action)
    if write_db ~= nil then
        if action == 'get' then
            if write_db.hasKey('printCombatLog') == 1 then printCombatLog = write_db.getIntValue('printCombatLog') == 1 end
            if write_db.hasKey('dangerWarning') == 1 then dangerWarning = write_db.getIntValue('dangerWarning') end
            if write_db.hasKey('validatePilot') == 1 then validatePilot = write_db.getIntValue('validatePilot') == 1 end
            if write_db.hasKey('bottomHUDLineColorSZ') == 1 then bottomHUDLineColorSZ = write_db.getStringValue('bottomHUDLineColorSZ') end
            if write_db.hasKey('bottomHUDFillColorSZ') == 1 then bottomHUDFillColorSZ = write_db.getStringValue('bottomHUDFillColorSZ') end
            if write_db.hasKey('textColorSZ') == 1 then textColorSZ = write_db.getStringValue('textColorSZ') end
            if write_db.hasKey('bottomHUDLineColorPVP') == 1 then bottomHUDLineColorPVP = write_db.getStringValue('bottomHUDLineColorPVP') end
            if write_db.hasKey('bottomHUDFillColorPVP') == 1 then bottomHUDFillColorPVP = write_db.getStringValue('bottomHUDFillColorPVP') end
            if write_db.hasKey('textColorPVP') == 1 then textColorPVP = write_db.getStringValue('textColorPVP') end
            if write_db.hasKey('neutralLineColor') == 1 then neutralLineColor = write_db.getStringValue('neutralLineColor') end
            if write_db.hasKey('neutralFontColor') == 1 then neutralFontColor = write_db.getStringValue('neutralFontColor') end
            if write_db.hasKey('L_Shield_HP') == 1 then L_Shield_HP = write_db.getIntValue('L_Shield_HP') end
            if write_db.hasKey('M_Shield_HP') == 1 then M_Shield_HP = write_db.getIntValue('M_Shield_HP') end
            if write_db.hasKey('S_Shield_HP') == 1 then S_Shield_HP = write_db.getIntValue('S_Shield_HP') end
            if write_db.hasKey('XS_Shield_HP') == 1 then XS_Shield_HP = write_db.getIntValue('XS_Shield_HP') end
            if write_db.hasKey('max_radar_load') == 1 then max_radar_load = write_db.getIntValue('max_radar_load') end
            if write_db.hasKey('warning_size') == 1 then warning_size = write_db.getFloatValue('warning_size') end
            if write_db.hasKey('warning_outline_color') == 1 then warning_outline_color = write_db.getStringValue('warning_outline_color') end
            if write_db.hasKey('warning_fill_color') == 1 then warning_fill_color = write_db.getStringValue('warning_fill_color') end

            if write_db.hasKey('antiMatterColor') == 1 then antiMatterColor = write_db.getStringValue('antiMatterColor') end
            if write_db.hasKey('electroMagneticColor') == 1 then electroMagneticColor = write_db.getStringValue('electroMagneticColor') end
            if write_db.hasKey('kineticColor') == 1 then kineticColor = write_db.getStringValue('kineticColor') end
            if write_db.hasKey('thermicColor') == 1 then thermicColor = write_db.getStringValue('thermicColor') end

            if write_db.hasKey('radarInfoWidgetX') == 1 then radarInfoWidgetX = write_db.getFloatValue('radarInfoWidgetX') end
            if write_db.hasKey('radarInfoWidgetY') == 1 then radarInfoWidgetY = write_db.getFloatValue('radarInfoWidgetY') end
            if write_db.hasKey('radarInfoWidgetScale') == 1 then radarInfoWidgetScale = write_db.getFloatValue('radarInfoWidgetScale') end
            if write_db.hasKey('radarInfoWidgetXmin') == 1 then radarInfoWidgetXmin = write_db.getFloatValue('radarInfoWidgetXmin') end
            if write_db.hasKey('radarInfoWidgetYmin') == 1 then radarInfoWidgetYmin = write_db.getFloatValue('radarInfoWidgetYmin') end
            if write_db.hasKey('radarInfoWidgetScalemin') == 1 then radarInfoWidgetScalemin = write_db.getFloatValue('radarInfoWidgetScalemin') end

            if write_db.hasKey('minimalWidgets') == 1 then minimalWidgets = write_db.getIntValue('minimalWidgets') == 1 end

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
            write_db.setStringValue('bottomHUDLineColorSZ',bottomHUDLineColorSZ)
            write_db.setStringValue('bottomHUDFillColorSZ',bottomHUDFillColorSZ)
            write_db.setStringValue('textColorSZ',textColorSZ)
            write_db.setStringValue('bottomHUDLineColorPVP',bottomHUDLineColorPVP)
            write_db.setStringValue('bottomHUDFillColorPVP',bottomHUDFillColorPVP)
            write_db.setStringValue('textColorPVP',textColorPVP)
            write_db.setStringValue('neutralLineColor',neutralLineColor)
            write_db.setStringValue('neutralFontColor',neutralFontColor)
            write_db.setIntValue('L_Shield_HP',L_Shield_HP)
            write_db.setIntValue('M_Shield_HP',M_Shield_HP)
            write_db.setIntValue('S_Shield_HP',S_Shield_HP)
            write_db.setIntValue('XS_Shield_HP',XS_Shield_HP)
            write_db.setIntValue('max_radar_load',max_radar_load)
            write_db.setFloatValue('warning_size',warning_size)
            write_db.setStringValue('warning_outline_color',warning_outline_color)
            write_db.setStringValue('warning_fill_color',warning_fill_color)
            if showCode then write_db.setIntValue('showCode',1) else write_db.setIntValue('showCode',0) end

            write_db.setStringValue('antiMatterColor',antiMatterColor)
            write_db.setStringValue('electroMagneticColor',electroMagneticColor)
            write_db.setStringValue('kineticColor',kineticColor)
            write_db.setStringValue('thermicColor',thermicColor)

            write_db.setFloatValue('radarInfoWidgetX',radarInfoWidgetX)
            write_db.setFloatValue('radarInfoWidgetY',radarInfoWidgetY)
            write_db.setFloatValue('radarInfoWidgetScale',radarInfoWidgetScale)
            write_db.setFloatValue('radarInfoWidgetXmin',radarInfoWidgetXmin)
            write_db.setFloatValue('radarInfoWidgetYmin',radarInfoWidgetYmin)
            write_db.setFloatValue('radarInfoWidgetScalemin',radarInfoWidgetScalemin)

            if minimalWidgets then write_db.setIntValue('minimalWidgets',1) else write_db.setIntValue('minimalWidgets',0) end

        end
    end
end

function weaponsWidget()
    local ww = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    local wtext = ''
    if weapon_size > 0 then
        local wStatus = {[1] = 'Idle', [2] = 'Firing', [4] = 'Reloading', [5] = 'Unloading'}
        ww = ww .. [[
            <line x1="]].. 0.02*screenWidth ..[[" y1="]].. 0.665*screenHeight ..[[" x2="]].. 0.15*screenWidth ..[[" y2="]].. 0.665*screenHeight ..[[" style="stroke:]]..neutralLineColor..[[;stroke-width:0.25;opacity:]].. 1 ..[[;" />
            ]]
        local offset = 1
        for i,w in pairs(weapon) do
            local textColor = neutralFontColor
            local ammoColor = neutralFontColor
            local probColor = warning_outline_color
            if w.isOutOfAmmo() == 1 then ammoColor = warning_outline_color end

            local probs = w.getHitProbability()
            if probs > .7 then probColor = friendlyTextColor elseif probs > .5 then probColor = 'yellow' end
            
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

            local ammoType = system.getItem(w.getAmmo())
            ammoType = tostring(ammoType['name']):lower()
            ammoTypeColor = neutralFontColor
            if string.find(ammoType,'antimatter') then ammoTypeColor = antiMatterColor ammoType = 'Antimatter'
            elseif string.find(ammoType,'electromagnetic') then ammoTypeColor = electroMagneticColor ammoType = 'ElectroMagnetic'
            elseif string.find(ammoType,'kinetic') then ammoTypeColor = kineticColor ammoType = 'Kinetic'
            elseif string.find(ammoType,'thermic') then ammoTypeColor = thermicColor ammoType = 'Thermic'
            end
            local weaponStr = string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring((0.66 - 0.015*i) * screenHeight) ..'px;left: '.. tostring(0.02* screenWidth) ..'px;"><div style="float: left;color: %s;">%s |&nbsp;</div><div style="float: left;color:%s;"> %.2f%% </div><div style="float: left;color: %s;"> | %s |&nbsp;</div><div style="float: left;color: %s;"> '..ammoType..'&nbsp;</div><div style="float: left;color: %s;">(%s) </div></div>',neutralFontColor,weaponName,probColor,probs*100,textColor,wStatus[w.getStatus()],ammoTypeColor,ammoColor,w.getAmmoCount())
            wtext = wtext .. weaponStr
            offset = i
        end
        offset = offset + 1
        ww = ww .. [[
            <line x1="]].. 0.02*screenWidth ..[[" y1="]].. (0.675-offset*0.015)*screenHeight ..[[" x2="]].. 0.15*screenWidth ..[[" y2="]].. (0.675-offset*0.015)*screenHeight ..[[" style="stroke:]]..neutralLineColor..[[;stroke-width:0.25;opacity:]].. 1 ..[[;" />
            ]]
    end
    ww = ww .. '</svg>' .. wtext
    return ww
end

function radarWidget()
    local rw = ''
    local friendlyShipNum = radarStats['friendly']['L'] + radarStats['friendly']['M'] + radarStats['friendly']['S'] + radarStats['friendly']['XS']
    local enemyShipNum = radarStats['enemy']['L'] + radarStats['enemy']['M'] + radarStats['enemy']['S'] + radarStats['enemy']['XS']
    local radarRangeString = formatNumber(radarRange,'distance')

    local x, y, s
    if minimalWidgets then 
        y = radarInfoWidgetYmin
        x = radarInfoWidgetXmin
        s = radarInfoWidgetScalemin
    else
        y = radarInfoWidgetY
        x = radarInfoWidgetX
        s = radarInfoWidgetScale
    end

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.185 * screenHeight) ..'px;left: '.. tostring(.875 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Identification Range:&nbsp;</div><div style="float: left;color: rgb(25, 247, 255);">%s&nbsp;</div></div>]],radarRangeString)
  

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.15 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">Identified By:&nbsp;</div><div style="float: left;color: orange;">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],identifiedBy)

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.165 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Attacked By:&nbsp;</div><div style="float: left;color: ]]..warning_outline_color..[[;">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],attackedBy)

    rw = rw .. [[
        <svg style="position: absolute; top: ]]..y..[[vh; left: ]]..x..[[vw;" viewBox="0 0 286 240" width="]]..s..[[vw">
            <rect x="6%" y="6%" width="87%" height="52%" rx="1%" ry="1%" fill="rgba(100,100,100,.9)" />
            <polygon style="stroke-width: 2px; stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="22 15 266 15 266 32 252 46 22 46"/>
            <polygon style="stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="18 17 12 22 12 62 15 66 15 135 18 138"/>
            <text style="fill: ]]..fontColor..[[; font-size: 17px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="37" y="35">Radar Information (]]..tostring(radarContactNumber)..[[)</text>
        ]]
    rw = rw .. [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="54" x2="22" y2="77"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="73">Enemy Ships:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="137" y="73">]]..enemyShipNum..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="81" x2="22" y2="104"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="30" y="100">L:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="50" y="100">]]..radarStats['enemy']['L']..[[</text>

            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="68" y="100">M:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="95" y="100">]]..radarStats['enemy']['M']..[[</text>

            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="115" y="100">S:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="135" y="100">]]..radarStats['enemy']['S']..[[</text>

            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="155" y="100">XS:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="185" y="100">]]..radarStats['enemy']['XS']..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="108" x2="22" y2="131"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="127">Friendly Ships:</text>
            <text style="fill: ]]..friendlyTextColor..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="150" y="127">]]..friendlyShipNum..[[</text>

        ]]

    rw = rw .. '</svg>'

    if attackedBy >= dangerWarning or showAlerts then
        warnings['attackedBy'] = 'svgWarning'
    else
        warnings['attackedBy'] = nil
    end

    if radarOverload or showAlerts then 
        warnings['radarOverload'] = 'svgCritical'
    else
        warnings['radarOverload'] = nil
    end
    return rw
end

function identifiedWidget()
    local id = radar_1.getTargetId()
    local iw = ''
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

        local tMatch = radar_1.hasMatchingTransponder(id) == 1
        local shipIDMatch = false
        if useShipID then for k,v in pairs(friendlySIDs) do if id == k then shipIDMatch = true end end end
        local friendly = tMatch or shipIDMatch

        local abandonded = radar_1.isConstructAbandoned(id) == 1
        local cardFill = warning_outline_color
        local cardText = textColorPVP
        if friendly then cardFill = bottomHUDFillColorSZ cardText = textColorSZ
        elseif abandonded then cardFill = 'darkgrey' cardText = 'black'
        end

        local distance = radar_1.getConstructDistance(id)
        local distString = formatNumber(distance,'distance')

        local name = radar_1.getConstructName(id)
        local uniqueCode = string.sub(tostring(id),-3)
        local shortName = name:sub(0,17)

        local lineColor = 'lightgrey'
        local targetIdentified = radar_1.isConstructIdentified(id) == 1


        if abandonded or showAlerts then warnings['cored'] = 'svgTarget' else warnings['cored'] = nil end
        if friendly or showAlerts then warnings['friendly'] = 'svgGroup' else warnings['friendly'] = nil end

        local speedVec = vec3(construct.getWorldVelocity())
        local mySpeed = speedVec:len() * 3.6
        local myMass = construct.getMass()

        local targetSpeedString = 'Not Identified'
        if targetIdentified then targetSpeed = radar_1.getConstructSpeed(id) * 3.6 targetSpeedString = formatNumber(targetSpeed,'speed') end
        local speedDiff = 0
        if targetIdentified then speedDiff = mySpeed-targetSpeed end
        
        local targetSpeedColor = neutralFontColor
        if targetIdentified then
            if speedDiff < -1000 then targetSpeedColor = warning_outline_color
            elseif speedDiff > 1000 then targetSpeedColor = 'rgb(56, 255, 56)'
            end
        end
        targetSpeedSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="54" x2="22" y2="77"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="73">Speed:</text>
            <text style="fill: ]]..targetSpeedColor..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="80" y="73">]]..targetSpeedString..[[</text>
        ]]

        local updateTimer = false
        if system.getArkTime() - lastUpdateTime > 0.5 and lastUpdateTime ~= 0 then 
            lastUpdateTime = system.getArkTime()
            updateTimer = true
        elseif lastUpdateTime == 0 then
            lastUpdateTime = system.getArkTime()
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
        local gapColor = neutralFontColor
        if gapCompare == 'Closing' then gapColor = 'rgb(56, 255, 56)' elseif gapCompare == 'Parting' then gapColor = warning_outline_color end
        local distanceCompareSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="81" x2="22" y2="104"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="100">Gap:</text>
            <text style="fill: ]]..gapColor..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="65" y="100">]]..tostring(gapCompare)..[[</text>
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
        local speedCompareColor = neutralFontColor
        if speedCompare == 'Braking' then speedCompareColor = warning_outline_color elseif speedCompare == 'Accelerating' then speedCompareColor = 'rgb(56, 255, 56)' end
        local speedCompareSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="108" x2="22" y2="131"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="127">&#8796;Speed:</text>
            <text style="fill: ]]..speedCompareColor..[[; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="95" y="127">]]..tostring(speedCompare)..[[</text>
        ]]

        local dmgSVG = [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="135" x2="22" y2="158"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="154">Damage:</text>
            <text style="fill: orange; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="95" y="154">]]..string.format('%s (%.2f%%)',dmg,(1-dmgRatio)*100)..[[</text>
        ]]

        local mass = radar_1.getConstructMass(id)
        local topSpeed = (50000/3.6-10713*(mass-10000)/(853926+(mass-10000)))*3.6
        if targetIdentified then
            topSpeed = clamp(topSpeed,20000,50000)
        else
            topSpeed = 0
        end
        local topSpeedSVG = ''
        if topSpeed > 0 then
            topSpeedSVG = [[
                <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="162" x2="22" y2="185"/>
                <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="181">Top Speed:</text>
                <text style="fill: orange; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="110" y="181">]]..formatNumber(topSpeed,'speed')..[[</text>
            ]]
        end

        local info = radar_1.getConstructInfos(id)
        local weapons = 'False'
        if info['weapons'] ~= 0 then weapons = 'True' end
        local dataSVG = ''
        if targetIdentified then
            dataSVG = [[
                <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="189" x2="22" y2="212"/>
                <text style="fill: ]]..neutralFontColor..[[; font-size: 20px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="208">Armed:</text>
                <text style="fill: orange; font-size: 19px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="95" y="208">]]..weapons..[[</text>
            ]]
        end

        local owner = ''
        if radar_1.hasMatchingTransponder(id) == 1 then
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
        y = 11.25
        x = 1.75
        s = 11.25
        iw = iw .. [[
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

        if targetIdentified then
            iw = iw .. topSpeedSVG .. dataSVG
        end

        iw = iw.. [[
            </svg>
        ]]

        if targetIndicators or showAlerts then
            iw = iw .. [[
                <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
                    <svg width="]].. tostring(.03 * screenWidth) ..[[" height="]].. tostring(.03 * screenHeight) ..[[" x="]].. tostring(.30 * screenWidth) ..[[" y="]].. tostring(.50 * screenHeight) ..[[" style="fill: ]]..speedCompareColor..[[;">
                        ]]..warningSymbols['svgTarget']..[[
                    </svg>
                    <text x="]].. tostring(.327 * screenWidth) ..[[" y="]].. tostring(.51 * screenHeight) .. [[" style="fill: ]]..neutralFontColor..[[;" font-size="1.7vh" font-weight="bold">Speed Change:</text>
                    <text x="]].. tostring(.390 * screenWidth) ..[[" y="]].. tostring(.51 * screenHeight) .. [[" style="fill: ]]..speedCompareColor..[[;" font-size="1.7vh" font-weight="bold">]]..speedCompare..[[</text>
                    <text x="]].. tostring(.359 * screenWidth) ..[[" y="]].. tostring(.53 * screenHeight) .. [[" style="fill: ]]..neutralFontColor..[[;" font-size="1.7vh" font-weight="bold">Speed: </text>
                    <text x="]].. tostring(.390 * screenWidth) ..[[" y="]].. tostring(.53 * screenHeight) .. [[" style="fill: ]]..speedCompareColor..[[;" font-size="1.7vh" font-weight="bold">]]..targetSpeedString..[[</text>
                </svg>
            ]]
        end
    end
    return iw
end

function warningsWidget()
    local ww = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    local warningText = {}
    warningText['attackedBy'] = string.format('%.0f ships attacking',attackedBy)
    warningText['radarOverload'] = 'Radar Overloaded'
    warningText['cored'] = 'Target is Destroyed'
    warningText['friendly'] = 'Target is Friendly'
    warningText['noRadar'] = 'No Radar Linked'
    warningText['venting'] = 'Shield Venting'
    warningText['radar_delta'] = string.format('Radar Delay %.2fs',cr_delta)

    local warningColor = {}
    warningColor['attackedBy'] = 'red'
    warningColor['radarOverload'] = 'orange'
    warningColor['cored'] = 'orange'
    warningColor['friendly'] = 'green'
    warningColor['noRadar'] = 'red'
    warningColor['venting'] = shieldHPColor
    warningColor['radar_delta'] = 'orange'

    local count = 0
    local y = .06
    if minimalWidgets then y = .14 end
    for k,v in pairs(warnings) do
        if v ~= nil then
            ww = ww .. string.format([[
                <svg width="]].. tostring(.03 * screenWidth) ..[[" height="]].. tostring(.03 * screenHeight) ..[[" x="]].. tostring(.65 * screenWidth) ..[[" y="]].. tostring(y * screenHeight + .032 * screenHeight * count) ..[[" style="fill: ]]..warningColor[k]..[[;">
                    ]]..warningSymbols[v]..[[
                </svg>
                <text x="]].. tostring(.677 * screenWidth) ..[[" y="]].. tostring((y+.02) * screenHeight + .032 * screenHeight * count) .. [[" style="fill: ]]..warningColor[k]..[[;" font-size="1.7vh" font-weight="bold">]]..warningText[k]..[[</text>
                ]])
            count = count + 1
        end
    end
    ww = ww .. '</svg>'
    return ww
end

function generateHTML()
    if write_db and write_db.hasKey('minimalWidgets') then
        minimalWidgets = write_db.getIntValue('minimalWidgets') == 1
    end 
    html = [[ <html> <body style="font-family: Calibri;"> ]]
    html = html .. ARWidget()
    if showScreen then
        if weapon_1 then html = html .. weaponsWidget() end
        if radar_1 then html = html .. radarWidget() end
        if radar_1 then html = html .. identifiedWidget() end
    end
    
    html = html .. warningsWidget()
    html = html .. [[ </body> </html> ]]
    system.setScreen(html)
end
