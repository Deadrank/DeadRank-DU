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
    local enemyLShips = 0
    local friendlyLShips = 0
    local constructList = {}
    local shipsBySize = {}
    shipsBySize['XS'] = {}
    shipsBySize['S'] = {}
    shipsBySize['M'] = {}
    shipsBySize['L'] = {}

    identifiedBy = 0
    attackedBy = 0
    radarStats = {
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
    if #radarList > max_radar_load then radarOverload = true return data end
    radarOverload = false
    for _,id in pairs(radarList) do
        local threatLevel = radar_1.getThreatRateFrom(id)
        if threatLevel == 2 then identifiedBy = identifiedBy + 1
        elseif threatLevel == 5 then attackedBy = attackedBy + 1
        end
        local tMatch = radar_1.hasMatchingTransponder(id) == 1
        local abandonded = radar_1.isConstructAbandoned(id) == 1
        local nameOrig = radar_1.getConstructName(id)
        local name = nameOrig--:gsub('%[',''):gsub('%]','')
        nameOrig = nameOrig:gsub('%]','%%]'):gsub('%[','%%[')
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
        local shipSize = radar_1.getConstructCoreSize(id)
        local shipType = radar_1.getConstructKind(id)
        local identified = radar_1.isConstructIdentified(id) == 1

        if shipType == 5 then
            if friendly then radarStats['friendly'][shipSize] = radarStats['friendly'][shipSize] + 1
            else radarStats['enemy'][shipSize] = radarStats['enemy'][shipSize] + 1
            end
        end

        if contains(filterSize,shipSize) then
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
                    if identified then
                        table.insert(constructList,1,replacedData)
                    elseif radarSort == 'Size' then
                        table.insert(shipsBySize[shipSize],replacedData)
                    else
                        table.insert(constructList,replacedData)
                    end
                end
            end
        end
    end
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
    return data
end

function RadarWidgetCreate()
    local _data = updateRadar(radarFilter)
    local _panel = system.createWidgetPanel("RADAR")
    local _widget = system.createWidget(_panel, "radar")
    radarDataID = system.createData(_data)
    system.addDataToWidget(radarDataID, _widget)
    return radarDataID
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
            if write_db.hasKey('generateAutoCode') == 1 then generateAutoCode = write_db.getIntValue('generateAutoCode') == 1 end
            if write_db.hasKey('autoVent') == 1 then autoVent = write_db.getIntValue('autoVent') == 1 end
            if write_db.hasKey('L_Shield_HP') == 1 then L_Shield_HP = write_db.getIntValue('L_Shield_HP') end
            if write_db.hasKey('M_Shield_HP') == 1 then M_Shield_HP = write_db.getIntValue('M_Shield_HP') end
            if write_db.hasKey('S_Shield_HP') == 1 then S_Shield_HP = write_db.getIntValue('S_Shield_HP') end
            if write_db.hasKey('XS_Shield_HP') == 1 then XS_Shield_HP = write_db.getIntValue('XS_Shield_HP') end
            if write_db.hasKey('max_radar_load') == 1 then max_radar_load = write_db.getIntValue('max_radar_load') end
            if write_db.hasKey('warning_size') == 1 then warning_size = write_db.getFloatValue('warning_size') end
            if write_db.hasKey('warning_outline_color') == 1 then warning_outline_color = write_db.getStringValue('warning_outline_color') end
            if write_db.hasKey('warning_fill_color') == 1 then warning_fill_color = write_db.getStringValue('warning_fill_color') end

            if write_db.hasKey('hpWidgetX') == 1 then hpWidgetX = write_db.getFloatValue('hpWidgetX') end
            if write_db.hasKey('hpWidgetY') == 1 then hpWidgetY = write_db.getFloatValue('hpWidgetY') end
            if write_db.hasKey('hpWidgetScale') == 1 then hpWidgetScale = write_db.getFloatValue('hpWidgetScale') end
            if write_db.hasKey('shieldHPColor') == 1 then shieldHPColor = write_db.getStringValue('shieldHPColor') end
            if write_db.hasKey('ccsHPColor') == 1 then ccsHPColor = write_db.getStringValue('ccsHPColor') end

            if write_db.hasKey('resistWidgetX') == 1 then resistWidgetX = write_db.getFloatValue('resistWidgetX') end
            if write_db.hasKey('resistWidgetY') == 1 then resistWidgetY = write_db.getFloatValue('resistWidgetY') end
            if write_db.hasKey('resistWidgetScale') == 1 then resistWidgetScale = write_db.getFloatValue('resistWidgetScale') end
            if write_db.hasKey('antiMatterColor') == 1 then antiMatterColor = write_db.getStringValue('antiMatterColor') end
            if write_db.hasKey('electroMagneticColor') == 1 then electroMagneticColor = write_db.getStringValue('electroMagneticColor') end
            if write_db.hasKey('kineticColor') == 1 then kineticColor = write_db.getStringValue('kineticColor') end
            if write_db.hasKey('thermicColor') == 1 then thermicColor = write_db.getStringValue('thermicColor') end

            if write_db.hasKey('transponderWidgetX') == 1 then transponderWidgetX = write_db.getFloatValue('transponderWidgetX') end
            if write_db.hasKey('transponderWidgetY') == 1 then transponderWidgetY = write_db.getFloatValue('transponderWidgetY') end
            if write_db.hasKey('transponderWidgetScale') == 1 then transponderWidgetScale = write_db.getFloatValue('transponderWidgetScale') end

            if write_db.hasKey('radarInfoWidgetX') == 1 then radarInfoWidgetX = write_db.getFloatValue('radarInfoWidgetX') end
            if write_db.hasKey('radarInfoWidgetY') == 1 then radarInfoWidgetY = write_db.getFloatValue('radarInfoWidgetY') end
            if write_db.hasKey('radarInfoWidgetScale') == 1 then radarInfoWidgetScale = write_db.getFloatValue('radarInfoWidgetScale') end

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
            if generateAutoCode then write_db.setIntValue('generateAutoCode',1) else write_db.setIntValue('generateAutoCode',0) end
            if autoVent then write_db.setIntValue('autoVent',1) else write_db.setIntValue('autoVent',0) end
            write_db.setIntValue('L_Shield_HP',L_Shield_HP)
            write_db.setIntValue('M_Shield_HP',M_Shield_HP)
            write_db.setIntValue('S_Shield_HP',S_Shield_HP)
            write_db.setIntValue('XS_Shield_HP',XS_Shield_HP)
            write_db.setIntValue('max_radar_load',max_radar_load)
            write_db.setFloatValue('warning_size',warning_size)
            write_db.setStringValue('warning_outline_color',warning_outline_color)
            write_db.setStringValue('warning_fill_color',warning_fill_color)

            write_db.setFloatValue('hpWidgetX',hpWidgetX)
            write_db.setFloatValue('hpWidgetY',hpWidgetY)
            write_db.setFloatValue('hpWidgetScale',hpWidgetScale)
            write_db.setStringValue('shieldHPColor',shieldHPColor)
            write_db.setStringValue('ccsHPColor',ccsHPColor)

            write_db.setFloatValue('resistWidgetX',resistWidgetX)
            write_db.setFloatValue('resistWidgetY',resistWidgetY)
            write_db.setFloatValue('resistWidgetScale',resistWidgetScale)
            write_db.setStringValue('antiMatterColor',antiMatterColor)
            write_db.setStringValue('electroMagneticColor',electroMagneticColor)
            write_db.setStringValue('kineticColor',kineticColor)
            write_db.setStringValue('thermicColor',thermicColor)

            write_db.setFloatValue('transponderWidgetX',transponderWidgetX)
            write_db.setFloatValue('transponderWidgetY',transponderWidgetY)
            write_db.setFloatValue('transponderWidgetScale',transponderWidgetScale)

            write_db.setFloatValue('radarInfoWidgetX',radarInfoWidgetX)
            write_db.setFloatValue('radarInfoWidgetY',radarInfoWidgetY)
            write_db.setFloatValue('radarInfoWidgetScale',radarInfoWidgetScale)
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
            if probs > .7 then probColor = ccsHPColor elseif probs > .5 then probColor = 'yellow' end
            
            local weaponName = w.getName():lower()

            local matches = {}
            for w in weaponName:gmatch("([^ ]+) ?") do table.insert(matches,w) end
            local prefix = matches[1]:sub(1,1) .. matches[2]:sub(1,1)
            local wtype = ''
            if string.find(weaponName,'cannon') then wType = 'Cannon'
            elseif string.find(weaponName,'railgun') then wType = 'Railgun'
            elseif string.find(weaponName,'missile') then wType = 'Missile'
            elseif string.find(weaponName,'laser') then wType = 'Laser'
            end
            weaponName = prefix .. wType

            local ammoType = system.getItem(w.getAmmo())
            ammoType = tostring(ammoType['name']):lower()
            ammoTypeColor = neutralFontColor
            if string.find(ammoType,'antimatter') then ammoTypeColor = antiMatterColor ammoType = 'Antimatter'
            elseif string.find(ammoType,'electromagnetic') then ammoTypeColor = electroMagneticColor ammoType = 'ElectroMagnetic'
            elseif string.find(ammoType,'kinetic') then ammoTypeColor = kineticColor ammoType = 'Kinetic'
            elseif string.find(ammoType,'thermic') then ammoTypeColor = thermicColor ammoType = 'Thermic'
            end
            local weaponStr = string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring((0.66 - 0.015*i) * screenHeight) ..'px;left: '.. tostring(0.02* screenWidth) ..'px;"><div style="float: left;color: %s;">%s |&nbsp;</div><div style="float: left;color:%s;"> %.2f%% </div><div style="float: left;color: %s;"> | %s |&nbsp;</div><div style="float: left;color: %s;"> '..ammoType..'&nbsp;</div><div style="float: left;color: %s;">(%s) </div></div>',fontColor,weaponName,probColor,probs*100,textColor,wStatus[w.getStatus()],ammoTypeColor,ammoColor,w.getAmmoCount())
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

function transponderWidget()
    local tw = ''
    if transponder_1 ~= nil then
        local transponderColor = warning_outline_color
        local transponderStatus = 'offline'
        if transponder_1.isActive() == 1 then transponderColor = shieldHPColor transponderStatus = 'Active' end
        local tags = transponder_1.getTags()

        tw = [[
            <svg style="position: absolute; top: ]]..transponderWidgetY..[[vh; left: ]]..transponderWidgetX..[[vw;" viewBox="0 0 286 ]]..tostring(101+#tags*24)..[[" width="]]..transponderWidgetScale..[[vw">
                <polygon style="stroke-width: 2px; stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="22 15 266 15 266 32 252 46 22 46"/>
                <polygon style="stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="18 17 12 22 12 62 15 66 15 ]]..tostring(81+#tags*24)..[[ 18 ]]..tostring(83+#tags*24)..[["/>
                <text style="fill: ]]..fontColor..[[; font-size: 17px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="37" y="35">Transponder Status:</text>
                <text style="fill: ]]..transponderColor..[[; font-size: 17px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="190" y="35">]]..transponderStatus..[[</text>
            ]]


        for i,tag in pairs(tags) do
            local code = 'redacted'
            if showCode then code = tag end
            tw = tw .. [[<line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="]]..tostring(54+(i-1)*27)..[[" x2="22" y2="]]..tostring(80.7+(i-1)*27)..[["/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="]]..tostring(73+(i-1)*27)..[[">]]..code..[[</text>]]
        end    
        tw = tw .. '</svg>'
    end

    return tw
end

function hpWidget()
    local hw = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    --Shield/CCS Widget
    shieldPercent = 0
    if shield_1 then
        shieldPercent = shield_1.getShieldHitpoints()/shield_1.getMaxShieldHitpoints()*100
    end
    CCSPercent = 0
    if core_1.getMaxCoreStress() then
        CCSPercent = 100*(core_1.getMaxCoreStress()-core_1.getCoreStress())/core_1.getMaxCoreStress()
    end
    if (shield_1 and shieldPercent < 15) or showAlerts then
        hw = hw .. string.format([[
        <svg width="]].. tostring(.06 * screenWidth) ..[[" height="]].. tostring(.06 * screenHeight) ..[[" x="]].. tostring(.40 * screenWidth) ..[[" y="]].. tostring(.60 * screenHeight) ..[[" style="fill: red;">
            ]]..warningSymbols['svgCritical']..[[
        </svg>
        <text x="]].. tostring(.45 * screenWidth) ..[[" y="]].. tostring(.64 * screenHeight) ..[[" style="fill: red" font-size="3.42vh" font-weight="bold">SHIELD CRITICAL</text>
        ]])
    elseif (shield_1 and shieldPercent < 30) or showAlerts then
        hw = hw .. string.format([[
        <svg width="]].. tostring(.06 * screenWidth) ..[[" height="]].. tostring(.06 * screenHeight) ..[[" x="]].. tostring(.40 * screenWidth) ..[[" y="]].. tostring(.60 * screenHeight) ..[[" style="fill: orange;">
            ]]..warningSymbols['svgWarning']..[[
        </svg>
        <text x="]].. tostring(.45 * screenWidth) ..[[" y="]].. tostring(.64 * screenHeight) ..[[" style="fill: orange" font-size="3.42vh" font-weight="bold">SHIELD LOW</text>
        ]])
    end
    hw = hw .. '</svg>'
    hw = hw .. [[
        <svg style="position: absolute; top: ]]..hpWidgetY..[[vh; left: ]]..hpWidgetX..[[vw;" viewBox="0 0 355 97" width="]]..tostring(hpWidgetScale)..[[vw">
            <polyline style="fill-opacity: 0; stroke-linejoin: round; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" points="2 78.902 250 78.902 276 50" bx:origin="0.564202 0.377551"/>
            <polyline style="stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" points="225 85.853 253.049 85.853 271 67.902" bx:origin="-1.23913 -1.086291"/>
            <rect x="26.397" y="158.28" width="59" height="9" style="stroke-linecap: round; stroke-linejoin: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" transform="matrix(1, 0.000076, 0, 1, -24.396999, -79.380203)" bx:origin="2.813559 -3.390291"/>
            <rect x="4.921" y="123.131" width="11" height="7" style="stroke-linecap: round; stroke-linejoin: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" transform="matrix(1, 0.000076, 0, 1, -2.921, -35.229931)" bx:origin="15.090909 -5.644607"/>
            <rect x="4.921" y="123.111" width="11" height="6.999" style="stroke-linecap: round; stroke-linejoin: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" transform="matrix(1, 0.000106, 0, 1, 13.079, -35.20953)" bx:origin="13.636364 -5.645962"/>
            <rect x="4.921" y="123.111" width="11" height="6.999" style="stroke-linecap: round; stroke-linejoin: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" transform="matrix(1, 0.000106, 0, 1, 29.078999, -35.20953)" bx:origin="12.181818 -5.645719"/>
            <rect x="4.921" y="123.111" width="11" height="6.999" style="stroke-linecap: round; stroke-linejoin: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" transform="matrix(1, 0.000106, 0, 1, 45.078999, -35.20953)" bx:origin="10.727273 -5.645477"/>
            ]]
    local placement = 0
    for i = 4, CCSPercent, 4 do 
        hw = hw .. [[<line style="stroke-width: 5px; stroke-miterlimit: 1; stroke: ]]..ccsHPColor..[[; fill: none;" x1="]]..tostring(5+placement)..[["   y1="56" x2="]]..tostring(5+placement)..[["   y2="72" bx:origin="0 0.096154"/>]]  placement = placement + 10
    end
            
    hw = hw .. [[
            <line style="stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="5" y1="25.706" x2="5" y2="39.508" bx:origin="0 1.607143"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="14.859" y1="31.621" x2="14.859" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="24.718" y1="31.684" x2="24.718" y2="39.571" bx:origin="0 2.0545"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="34.576" y1="31.684" x2="34.576" y2="39.571" bx:origin="0 2.0545"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="44.435" y1="31.621" x2="44.435" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="54.294" y1="31.621" x2="54.294" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="64.153" y1="31.621" x2="64.153" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="74.012" y1="31.621" x2="74.012" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="83.871" y1="31.621" x2="83.871" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="93.729" y1="31.621" x2="93.729" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="103.588" y1="31.684" x2="103.588" y2="39.571" bx:origin="0 2.0545"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="113.447" y1="31.684" x2="113.447" y2="39.571" bx:origin="0 2.0545"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="123.306" y1="31.621" x2="123.306" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="133.165" y1="31.621" x2="133.165" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="143.023" y1="31.621" x2="143.023" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="152.882" y1="31.621" x2="152.882" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="162.741" y1="31.621" x2="162.741" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="172.6" y1="31.621" x2="172.6" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="182.459" y1="31.684" x2="182.459" y2="39.571" bx:origin="0 2.0545"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="192.318" y1="31.684" x2="192.318" y2="39.571" bx:origin="0 2.0545"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="202.176" y1="31.621" x2="202.176" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="212.035" y1="31.621" x2="212.035" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="221.894" y1="31.621" x2="221.894" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="231.753" y1="31.621" x2="231.753" y2="39.508" bx:origin="0 2.0625"/>
            <line style="paint-order: fill; stroke-miterlimit: 1; stroke-linecap: round; fill: none; stroke: ]]..neutralLineColor..[[;" x1="245" y1="25.706" x2="245" y2="39.508" bx:origin="0 1.535714"/>
            <text style="fill: ]]..shieldHPColor..[[; font-family: Arial; font-size: 11.8px; white-space: pre;" x="15" y="28.824" bx:origin="-2.698544 2.296589">Shield:</text>
            <text style="fill: rgb(255, 240, 25); font-family: Arial; font-size: 6.70451px; stroke-width: 0.25px; white-space: pre;" transform="matrix(1.017081, 0, 0, 0.89492, -12.273296, 5.679566)" x="16" y="89.114" bx:origin="3.495402 -4.692753">Incoming Damage</text>
            <text style="fill: rgb(255, 240, 25); font-family: Arial; font-size: 5.58709px; line-height: 8.93935px; stroke-width: 0.25px; white-space: pre;" transform="matrix(1.017081, 0, 0, 0.89492, 73.924286, 48.558426)" x="16" y="89.114" dx="-83.506" dy="-39.079" bx:origin="35.484825 -7.519482">A</text>
            <text style="fill: rgb(255, 240, 25); font-family: Arial; font-size: 5.58709px; line-height: 8.93935px; stroke-width: 0.25px; white-space: pre;" transform="matrix(1.017081, 0, 0, 0.89492, 98.152718, 71.789642)" x="16" y="89.114" dx="-91.857" dy="-65.038" bx:origin="38.374239 -7.519481">E</text>
            <text style="fill: rgb(255, 240, 25); font-family: Arial; font-size: 5.58709px; line-height: 8.93935px; stroke-width: 0.25px; white-space: pre;" transform="matrix(1.017081, 0, 0, 0.89492, 106.659058, 48.558426)" x="16" y="89.114" dx="-83.506" dy="-39.079" bx:origin="33.936403 -7.519482">T</text>
            <text style="fill: rgb(255, 240, 25); font-family: Arial; font-size: 5.58709px; line-height: 8.93935px; stroke-width: 0.25px; white-space: pre;" transform="matrix(1.017081, 0, 0, 0.89492, 121.659058, 48.558426)" x="16" y="89.114" dx="-83.506" dy="-39.079" bx:origin="27.291514 -7.519482">K</text>
            <text style="fill: ]]..shieldHPColor..[[; font-family: Arial; font-size: 11.8px; white-space: pre;" x="53.45" y="28.824" bx:origin="-2.698544 2.296589">]]..string.format('%.2f',shieldPercent)..[[%</text>
            <text style="fill: ]]..ccsHPColor..[[; font-family: Arial; font-size: 11.8px; white-space: pre;" x="153" y="28.824" bx:origin="-2.698544 2.296589">CCS:</text>
            <text style="fill: ]]..ccsHPColor..[[; font-family: Arial; font-size: 11.8px; white-space: pre;" x="182.576" y="28.824" bx:origin="-2.698544 2.296589">]]..string.format('%.2f',CCSPercent)..[[%</text>]]
    local placement = 0
    for i = 4, shieldPercent, 4 do 
        hw = hw .. [[<line style="stroke-width: 5px; stroke-miterlimit: 1; stroke: ]]..shieldHPColor..[[; fill: none;" x1="]]..tostring(5+placement)..[["   y1="42" x2="]]..tostring(5+placement)..[["   y2="55" bx:origin="0 0.096154"/>]]  placement = placement + 10
    end

    hw = hw .. '</svg>'

    return hw
end

function resistWidget()
    local rw = ''

    local stress = shield_1.getStressRatioRaw()
    local amS = stress[1]
    local emS = stress[2]
    local knS = stress[3]
    local thS = stress[4]

    local srp = shield_1.getResistancesPool()
    local csr = shield_1.getResistances()
    local amR = csr[1]/srp
    local emR = csr[2]/srp
    local knR = csr[3]/srp
    local thR = csr[4]/srp

    local resistTimer = shield_1.getResistancesCooldown()
    local resistTimerPer = 1 - resistTimer/shield_1.getResistancesMaxCooldown()
    local resistTimerColor = shieldHPColor
    if resistTimer > 0 then resistTimerColor = warning_outline_color end 

    if shield_1.isVenting() == 0 then
        warnings['venting'] = nil
    else 
        warnings['venting'] = 'svgCritical'
    end

    rw = [[
        <svg style="position: absolute; top: ]]..resistWidgetY..[[vh; left: ]]..resistWidgetX..[[vw;" viewBox="0 0 143 127" width="]]..resistWidgetScale..[[vw">
            <defs>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="stress-am">
                    <stop offset="]]..tostring(amS*100)..[[%" style="stop-color: ]]..antiMatterColor..[[; stop-opacity: 1"/>
                    <stop offset="]]..tostring(amS*100)..[[%" style="stop-color: ]]..neutralLineColor..[[; stop-opacity:.5"/>
                </linearGradient>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="stress-th">
                    <stop offset="]]..tostring(thS*100)..[[%" style="stop-color: ]]..thermicColor..[[; stop-opacity: 1"/>
                    <stop offset="]]..tostring(thS*100)..[[%" style="stop-color: ]]..neutralLineColor..[[; stop-opacity:.5"/>
                </linearGradient>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="stress-em">
                    <stop offset="]]..tostring(emS*100)..[[%" style="stop-color: ]]..electroMagneticColor..[[; stop-opacity: 1"/>
                    <stop offset="]]..tostring(emS*100)..[[%" style="stop-color: ]]..neutralLineColor..[[; stop-opacity:.5"/>
                </linearGradient>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="stress-kn">
                    <stop offset="]]..tostring(knS*100)..[[%" style="stop-color: ]]..kineticColor..[[; stop-opacity: 1"/>
                    <stop offset="]]..tostring(knS*100)..[[%" style="stop-color: ]]..neutralLineColor..[[; stop-opacity:.5"/>
                </linearGradient>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="resist-am">
                    <stop offset="]]..tostring(amR*100)..[[%" style="stop-color: ]]..antiMatterColor..[["/>
                    <stop offset="]]..tostring(amR*100)..[[%" style="stop-color: ]]..neutralLineColor..[[;"/>
                </linearGradient>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="resist-em">
                    <stop offset="]]..tostring(emR*100)..[[%" style="stop-color: ]]..electroMagneticColor..[["/>
                    <stop offset="]]..tostring(emR*100)..[[%" style="stop-color: ]]..neutralLineColor..[[;"/>
                </linearGradient>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="resist-th">
                    <stop offset="]]..tostring(thR*100)..[[%" style="stop-color: ]]..thermicColor..[["/>
                    <stop offset="]]..tostring(thR*100)..[[%" style="stop-color: ]]..neutralLineColor..[[;"/>
                </linearGradient>
                <linearGradient x1="100%" y1="0%" x2="0%" y2="100%" id="resist-kn">
                    <stop offset="]]..tostring(knR*100)..[[%" style="stop-color: ]]..kineticColor..[[;"/>
                    <stop offset="]]..tostring(knR*100)..[[%" style="stop-color: ]]..neutralLineColor..[[;"/>
                </linearGradient>
                <linearGradient x1="0%" y1="50%" x2="100%" y2="50%" id="resist-timer-horizontal" gradientUnits="userSpaceOnUse">
                    <stop offset="]]..tostring(resistTimerPer*100)..[[%" style="stop-color: ]]..neutralLineColor..[[;"/>
                    <stop offset="]]..tostring(resistTimerPer*100)..[[%" style="stop-color: ]]..warning_outline_color..[[;"/>  
                </linearGradient>
                <linearGradient x1="50%" y1="0%" x2="50%" y2="80%" id="resist-timer-vertical" gradientUnits="userSpaceOnUse">
                    <stop offset="]]..tostring(resistTimerPer*100)..[[%" style="stop-color: ]]..neutralLineColor..[[;"/>
                    <stop offset="]]..tostring(resistTimerPer*100)..[[%" style="stop-color: ]]..warning_outline_color..[[;"/>  
                </linearGradient>
            </defs>
            <ellipse style="fill: none; stroke: ]]..neutralLineColor..[[;" cx="73" cy="61" rx="8" ry="8"/>
            <ellipse style="fill: ]]..neutralLineColor..[[; stroke: ]]..neutralLineColor..[[;" cx="73" cy="61" rx="2" ry="2"/>
            <polyline style="fill: none; stroke-linejoin: bevel; stroke-linecap: round; stroke: ]]..neutralLineColor..[[;" points="53 30 35 61 53 93"/>
            <polyline style="fill: none; stroke-linejoin: bevel; stroke-linecap: round; stroke: ]]..neutralLineColor..[[;" points="92 30 110 61 92 93"/>
            <polyline style="fill: none; stroke-linecap: round; stroke-linejoin: bevel; stroke: ]]..neutralLineColor..[[;" points="90 35 105 61 90 89"/>
            <polyline style="fill: none; stroke-linecap: round; stroke-linejoin: bevel; stroke: ]]..neutralLineColor..[[;" points="55 35 40 61 55 89"/>
            <line style="fill: none; stroke-width: 0.5px; stroke: url(#resist-timer-horizontal);" x1="17" y1="61" x2="128" y2="61"/>
            <line style="fill: none; stroke-width: 0.5px; stroke: url(#resist-timer-vertical);" x1="72.888" y1="-9.275" x2="72.888" y2="101.725" transform="matrix(1, 0, 0, 1, 0.112056, 14.27536)"/>
            <text style="fill: ]]..antiMatterColor..[[; font-size: 8px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="55.182" y="51.282">AM</text>
            <text style="fill: ]]..electroMagneticColor..[[; font-size: 8px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="78" y="51.282">EM</text>
            <text style="fill: ]]..thermicColor..[[; font-size: 8px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="78" y="77.282">TH</text>
            <text style="fill: ]]..kineticColor..[[; font-size: 8px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="55" y="77.282">KN</text>
            <path style="fill: none; stroke-width: 3px; stroke-linecap: round; stroke: url(#stress-am);" d="M 15 59 C 45.52 58.894 71.021 34.344 71 3" transform="matrix(-1, 0, 0, -1, 86.000015, 62)"/>
            <path style="fill: none; stroke-width: 3px; stroke-linecap: round; stroke: url(#stress-th);" d="M 75 119 C 105.52 118.894 131.021 94.344 131 63"/>
            <path style="fill: none; stroke-width: 3px; stroke-linecap: round; stroke: url(#stress-em);" d="M 75 59 C 105.52 58.894 131.021 34.344 131 3" transform="matrix(0, -1, 1, 0, 72.000008, 134.000008)"/>
            <path style="fill: none; stroke-width: 3px; stroke-linecap: round; stroke: url(#stress-kn);" d="M 15 119 C 45.52 118.894 71.021 94.344 71 63" transform="matrix(0, 1, -1, 0, 134.000008, 47.999992)"/>
            <path style="fill: none; stroke-linecap: round; stroke: url(#resist-am); stroke-width: 5px;" d="M 25 56 C 48.435 55.92 68.016 37.068 68 13" transform="matrix(-1, 0, 0, -1, 93.000015, 69)"/>
            <path style="fill: none; stroke-linecap: round; stroke: url(#resist-em); stroke-width: 5px;" d="M 78 56 C 101.435 55.919 121.016 37.068 121 13" transform="matrix(0, -1, 1, 0, 65.000004, 134.000004)"/>
            <path style="fill: none; stroke-linecap: round; stroke: url(#resist-th); stroke-width: 5px;" d="M 78 109 C 101.435 108.919 121.016 90.068 121 66"/>
            <path style="fill: none; stroke-linecap: round; stroke: url(#resist-kn); stroke-width: 5px;" d="M 24 109 C 47.435 108.919 67.016 90.068 67 66" transform="matrix(0, 1, -1, 0, 133.000008, 41.999992)"/>
            </svg>
    ]]
    return rw
end

function radarWidget()
    local rw = ''
    local friendlyShipNum = radarStats['friendly']['L'] + radarStats['friendly']['M'] + radarStats['friendly']['S'] + radarStats['friendly']['XS']
    local enemyShipNum = radarStats['enemy']['L'] + radarStats['enemy']['M'] + radarStats['enemy']['S'] + radarStats['enemy']['XS']
    local radarRangeString = formatNumber(radarRange,'distance')

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.185 * screenHeight) ..'px;left: '.. tostring(.875 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Identification Range:&nbsp;</div><div style="float: left;color: rgb(25, 247, 255);">%s&nbsp;</div></div>]],radarRangeString)
  

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.15 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">Identified By:&nbsp;</div><div style="float: left;color: orange;">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],identifiedBy)

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.165 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Attacked By:&nbsp;</div><div style="float: left;color: ]]..warning_outline_color..[[;">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],attackedBy)

    rw = rw .. [[
        <svg style="position: absolute; top: ]]..radarInfoWidgetY..[[vh; left: ]]..radarInfoWidgetX..[[vw;" viewBox="0 0 286 245" width="]]..radarInfoWidgetScale..[[vw">
            <polygon style="stroke-width: 2px; stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="22 15 266 15 266 32 252 46 22 46"/>
            <polygon style="stroke-linejoin: round; fill: ]]..bgColor..[[; stroke: ]]..lineColor..[[;" points="18 17 12 22 12 62 15 66 15 225 18 227"/>
            <text style="fill: ]]..fontColor..[[; font-size: 17px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="37" y="35">Radar Information:</text>
        ]]
    rw = rw .. [[
            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="54" x2="22" y2="77"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="73">Enemy Ships:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="157" y="73">]]..enemyShipNum..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="81" x2="22" y2="104"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="100">L:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="57" y="100">]]..radarStats['enemy']['L']..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="108" x2="22" y2="131"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="127">M:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="57" y="127">]]..radarStats['enemy']['M']..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="135" x2="22" y2="158"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="154">S:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="57" y="154">]]..radarStats['enemy']['S']..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="162" x2="22" y2="185"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="181">XS:</text>
            <text style="fill: ]]..warning_outline_color..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="57" y="181">]]..radarStats['enemy']['XS']..[[</text>

            <line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="189" x2="22" y2="212"/>
            <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="208">Friendly Ships:</text>
            <text style="fill: ]]..ccsHPColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="170" y="208">]]..friendlyShipNum..[[</text>

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
    local updateTimer = false
    if math.abs(lastDistanceTime - system.getArkTime()) > .5 then 
        lastDistanceTime = system.getArkTime()
        updateTimer = true
    end
    local identList = radar_1.getIdentifiedConstructIds()
    local targetID = radar_1.getTargetId()
    local followingIdentified = false
    local followingID = 0
    if write_db ~= nil then 
        if write_db.hasKey('followingID') then
            followingID = write_db.getIntValue('followingID')
        end
        if not contains(identList,followingID) then
            write_db.setIntValue('targetID',0) 
        else
            followingIdentified = true
        end
        if not followingIdentified then write_db.clearValue('targetID') end
    end
    if not contains(identList,targetID) and targetID ~= 0 then table.insert(identList,targetID) end
    if targetID == 0 then warnings['cored'] = nil warnings['friendly'] = nil end
    local targetIdentified = radar_1.isConstructIdentified(targetID) == 1
    local iw = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    local speedVec = vec3(construct.getWorldVelocity())
    local mySpeed = speedVec:len() * 3.6
    local myMass = construct.getMass()
    local count = 1
    local targetString = ''
    for i,id in pairs(identList) do
        local constructIdentified = radar_1.isConstructIdentified(id)
        local targeted = targetID == id
        local distance = radar_1.getConstructDistance(id)
        local distString = formatNumber(distance,'distance')

        local speed = radar_1.getConstructSpeed(id) * 3.6
        local speedDiff = mySpeed - speed

        if updateTimer then
            speedCompare = 'Stable'
            if lastDistance[id] then
                if (math.abs(speedDiff) > 1 or speed == 0) and updateTimer then 
                    if lastDistance[id] > distance then speedCompare = 'Closing'
                    elseif lastDistance[id] < distance then speedCompare = 'Parting'
                    end
                    if not constructIdentified then speed = 0 end
                end
            end
            lastDistance[id] = distance
        end

        if updateTimer then
            accelCompare = 'No Accel'
            if lastSpeed[id] and constructIdentified then
                if lastSpeed[id] > speed then accelCompare = 'Accelerating'
                elseif lastSpeed[id] < speed then accelCompare = 'Braking'
                end
            end
            if constructIdentified then lastSpeed[id] = speed end
        end
        local speedString = formatNumber(speed,'speed')

        local tMatch = radar_1.hasMatchingTransponder(id) == 1

        local mass = radar_1.getConstructMass(id)
        local outrun = false
        if mass > myMass then outrun = true end
        local topSpeed = 201460 - 11462.1*math.log(4171.81*mass/1000+492243)
        if constructIdentified then
            topSpeed = clamp(topSpeed,20000,50000)
        else
            topSpeed = 0
        end

        local topSpeedStr = formatNumber(topSpeed,'speed')
        local massStr = formatNumber(mass,'mass')

        local size = radar_1.getConstructCoreSize(id)
        local shipIDMatch = false
        if useShipID then for k,v in pairs(friendlySIDs) do if id == k then shipIDMatch = true end end end
        local friendly = tMatch or shipIDMatch
        local info = radar_1.getConstructInfos(id)
        local weapons = 'False'
        if info['weapons'] ~= 0 then weapons = 'True' end
        

        local abandonded = radar_1.isConstructAbandoned(id) == 1
        local nameOrig = radar_1.getConstructName(id)
        local name = nameOrig--:gsub('%[',''):gsub('%]','')
        nameOrig = nameOrig:gsub('%]','%%]'):gsub('%[','%%[')
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
        uniqueName = uniqueName:sub(0,21)
        
        local dmg = 0
        if write_db and dmgTracker[tostring(id)] then
            write_db.setFloatValue('damage - ' .. tostring(id) .. ' - ' .. pilotName,dmgTracker[tostring(id)])
        end
        if #db > 0 then
            for _,dbName in pairs(db) do
                for _,key in pairs(dbName.getKeyList()) do
                    if string.starts(key,'damage - ' .. tostring(id)) then
                        dmg = dmg + dbName.getFloatValue(key)
                    end
                end
            end
        end
        if (dmg == 0 or not write_db) and dmgTracker[tostring(id)] then
            dmg = dmgTracker[tostring(id)]
        end

        local dmgRatio = clamp(dmg/shieldDmgTrack[size],0,1)
        if dmg < 1000 then dmg = string.format('%.2f',dmg)
        elseif dmg < 1000000 then dmg = string.format('%.2fk',dmg/1000)
        else dmg = string.format('%.2fm',dmg/1000000)
        end


        local cardFill = 'rgba(211,211,211,.1)'
        if friendly then cardFill = 'rgba(49, 182, 60,.2)' end
        local lineColor = 'lightgrey'
        if i <= 5 and not targeted then
            iw = iw .. [[<g transform="translate(0,]]..tostring(.05*screenHeight - count*.07*screenHeight)..[[)">
            <path d="
                M ]] .. tostring(.02*screenWidth) .. ' ' .. tostring(.545*screenHeight) ..[[ 
                L ]] .. tostring(.17*screenWidth) .. ' ' .. tostring(.545*screenHeight) .. [[
                L ]] .. tostring(.17*screenWidth) .. ' ' .. tostring(.48*screenHeight) .. [[
                L ]] .. tostring(.02*screenWidth) .. ' ' .. tostring(.48*screenHeight) .. [[
                L ]] .. tostring(.02*screenWidth) .. ' ' .. tostring(.545*screenHeight) .. [["
                stroke="]]..lineColor..[[" stroke-width="2" fill="]]..cardFill..[[" />

                <line x1="]].. 0.02*screenWidth ..[[" y1="]].. 0.545*screenHeight ..[[" x2="]].. (0.17-0.15*(1-dmgRatio))*screenWidth ..[[" y2="]].. 0.545*screenHeight ..[[" style="stroke:]]..warning_outline_color..[[;stroke-width:1.5;opacity:]].. 1 ..[[;" />

                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.495 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. tostring(uniqueName) .. [[</text>
                <text x="]].. tostring(.100 * screenWidth) ..[[" y="]].. tostring(.495 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">Ship Size: ]] .. tostring(size) .. [[</text>
                
                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.510 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. string.format('Speed: %s',speedString) .. [[</text>
                <text x="]].. tostring(.100 * screenWidth) ..[[" y="]].. tostring(.510 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. string.format('%s: %.0fkm/h',speedCompare,speedDiff) .. [[</text>
                
                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.525 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. string.format('Mass: %s',massStr) .. [[</text>
                <text x="]].. tostring(.090 * screenWidth) ..[[" y="]].. tostring(.525 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. 'Top Speed: '.. topSpeedStr .. [[</text>
                
                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.540 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. string.format('%s',distString) .. [[</text>
                <text x="]].. tostring(.066 * screenWidth) ..[[" y="]].. tostring(.540 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. string.format('Radars: %.0f',info['radars']) .. [[</text>
                <text x="]].. tostring(.103 * screenWidth) ..[[" y="]].. tostring(.540 * screenHeight) ..[[" style="fill: ]]..ccsHPColor..[[;" font-size="1.42vh" font-weight="bold">]] .. string.format('Weapons: %s',weapons) .. [[</text>
                </g>
            ]]
            count = count + 1
        end

        -- update following data --
        if write_db ~= nil then
            if write_db.getIntValue('following') == 1 and id == followingID and followingIdentified then
                write_db.setIntValue('targetID',id)
                write_db.setFloatValue('targetSpeed',speed)
                write_db.setFloatValue('targetDistance',distance)
                local weaponMin = radarRange - 10000
                for _,w in pairs(weapon) do if w.getOptimalDistance() - 10000 < weaponMin then weaponMin = w.getOptimalDistance() - 10000 end end
                write_db.setFloatValue('followDistance',weaponMin)
            elseif followingID == 0 then
                write_db.setIntValue('targetID',id)
                write_db.setFloatValue('targetSpeed',speed)
                write_db.setFloatValue('targetDistance',distance)
                weaponMin = radarRange - 10000
                for _,w in pairs(weapon) do if w.getOptimalDistance() - 10000 < weaponMin then weaponMin = w.getOptimalDistance() - 10000 end end
                write_db.setFloatValue('followDistance',weaponMin)
            end
        end

        if targeted then

            -- Target Name
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.40 * screenHeight) ..'px;left: '.. tostring(.30 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Name:&nbsp;</div>
            <div style="float: left;color: orange;">%s</div></div>]],uniqueName)

            -- Target Speed
            local targetSpeedString = '0.00 km/h -'
            local targetSpeedColor = neutralFontColor
            if speedDiff > 0 and math.abs(speedDiff) > 5 then targetSpeedString = string.format('%s &#8593;',speedString) targetSpeedColor = ccsHPColor..';'
            elseif speedDiff < 0 and math.abs(speedDiff) > 5 then targetSpeedString = string.format('%s &#8595;',speedString) targetSpeedColor = warning_outline_color
            elseif not targetIdentified then targetSpeedString = 'Not Identified'
            end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.420 * screenHeight) ..'px;left: '.. tostring(.30 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Speed:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>]],targetSpeedColor,targetSpeedString)

            -- Target Acceleration
            local accelString = 'Stable'
            local accelColor = neutralFontColor
            if accelCompare == 'Accelerating' then accelString = 'Speeding Up &#8593;' accelColor = ccsHPColor..';'
            elseif accelCompare == 'Braking' then accelString = 'Slowing Down&#8595;' accelColor = warning_outline_color
            elseif not targetIdentified then accelString = 'Not Identified'
            end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.440 * screenHeight) ..'px;left: '.. tostring(.30 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Change:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>]],accelColor,accelString)

            -- Target Gap
            local speedColor = neutralFontColor
            if not targetIdentified then speedDiff = 0 end
            if speedCompare == 'Closing' and math.abs(speedDiff) > 5 then speedColor = ccsHPColor..';'
            elseif speedCompare == 'Parting' and math.abs(speedDiff) > 5 then speedColor = warning_outline_color
            end
            local fontColor = 'white'
            if speedColor == 'white' then fontColor = neutralFontColor end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.460 * screenHeight) ..'px;left: '.. tostring(.30 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Gap:&nbsp;</div><div style="float: left;color: %s;"> %s (%.2fkm/h) </div></div>]],speedColor,speedCompare,speedDiff)

            -- Target Distance
            local inRange = radarRange >= distance
            local distanceColor = 'orange'
            if inRange then distanceColor = ccsHPColor..';' end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.400 * screenHeight) ..'px;left: '.. tostring(.60 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Dist:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>]],distanceColor,distString)

            -- Target Top Speed
            local outrunColor = neutralFontColor
            if not targetIdentified then topSpeedStr = 'Not identified' end
            if outrun then outrunColor = ccsHPColor..';'
            else outrunColor = 'orange;'
            end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.420 * screenHeight) ..'px;left: '.. tostring(.60 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Top Speed:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>]],outrunColor,topSpeedStr)

            -- Target DMG
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.440 * screenHeight) ..'px;left: '.. tostring(.60 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Damage:&nbsp;</div><div style="float: left;color: %s;"> %s (%.2f%%) </div></div>]],'orange',dmg,(1-dmgRatio)*100)

            -- Target Data
            if targetIdentified then
                targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.460 * screenHeight) ..'px;left: '.. tostring(.60 * screenWidth) ..[[px;">
                <div style="float: left;color: white;">Target Data:&nbsp;</div><div style="float: left;color: %s;"> Weapons: %s &nbsp;&nbsp; Radars: %.0f</div></div>]],neutralFontColor,weapons,info['radars'])
            end
            
            if abandonded or showAlerts then
                warnings['cored'] = 'svgTarget'
            else
                warnings['cored'] = nil
            end
            if friendly or showAlerts then
                warnings['friendly'] = 'svgGroup'
            else
                warnings['friendly'] = nil
            end
        end
    end
    

    iw = iw .. '</svg>'
    iw = iw .. targetString
    
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

    local warningColor = {}
    warningColor['attackedBy'] = 'red'
    warningColor['radarOverload'] = 'orange'
    warningColor['cored'] = 'orange'
    warningColor['friendly'] = 'green'
    warningColor['noRadar'] = 'red'
    warningColor['venting'] = shieldHPColor

    local count = 0
    for k,v in pairs(warnings) do
        if v ~= nil then
            ww = ww .. string.format([[
                <svg width="]].. tostring(.03 * screenWidth) ..[[" height="]].. tostring(.03 * screenHeight) ..[[" x="]].. tostring(.65 * screenWidth) ..[[" y="]].. tostring(.06 * screenHeight + .032 * screenHeight * count) ..[[" style="fill: ]]..warningColor[k]..[[;">
                    ]]..warningSymbols[v]..[[
                </svg>
                <text x="]].. tostring(.677 * screenWidth) ..[[" y="]].. tostring(.08 * screenHeight + .032 * screenHeight * count) .. [[" style="fill: ]]..warningColor[k]..[[;" font-size="1.7vh" font-weight="bold">]]..warningText[k]..[[</text>
                ]])
            count = count + 1
        end
    end
    ww = ww .. '</svg>'
    return ww
end

function generateHTML()
    html = [[ <html> <body style="font-family: Calibri;"> ]]
    if showScreen then
    html = html .. hpWidget()
        if shield_1 then html = html .. resistWidget() end
        if weapon_1 then html = html .. weaponsWidget() end
        if transponder_1 then html = html .. transponderWidget() end
        if radar_1 then html = html .. radarWidget() end
    end
    if radar_1 then html = html .. identifiedWidget() end
    html = html .. warningsWidget()
    html = html .. [[ </body> </html> ]]
    system.setScreen(html)
end
