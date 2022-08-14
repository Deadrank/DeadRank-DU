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
                    else
                        table.insert(constructList,replacedData)
                    end
                end
            elseif filter == 'identified' and identified then
                local rawData = data:gmatch('{"constructId":"'..tostring(id)..'"[^}]*}[^}]*}') 
                for str in rawData do
                    local replacedData = str:gsub(nameOrig,uniqueName)
                    table.insert(constructList,replacedData)
                end
            elseif filter == 'friendly' and friendly then
                local rawData = data:gmatch('{"constructId":"'..tostring(id)..'"[^}]*}[^}]*}') 
                for str in rawData do
                    local replacedData = str:gsub(nameOrig,uniqueName)
                    if identified then
                        table.insert(constructList,1,replacedData)
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
                    else
                        table.insert(constructList,replacedData)
                    end
                end
            end
        end
    end
    data = data:gsub('{"constructId[^}]*}[^}]*},*', "")
    data = data:gsub('"errorMessage":""','"errorMessage":"'..radarFilter..'"')
    data = data:gsub('"constructsList":%[%]','"constructsList":['..table.concat(constructList,',')..']')
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
    if db_1 ~= nil then
        if action == 'get' then
            if db_1.hasKey('printCombatLog') == 1 then printCombatLog = db_1.getIntValue('printCombatLog') == 1 end
            if db_1.hasKey('dangerWarning') == 1 then dangerWarning = db_1.getIntValue('dangerWarning') end
            if db_1.hasKey('validatePilot') == 1 then validatePilot = db_1.getIntValue('validatePilot') == 1 end
            if db_1.hasKey('bottomHUDLineColorSZ') == 1 then bottomHUDLineColorSZ = db_1.getStringValue('bottomHUDLineColorSZ') end
            if db_1.hasKey('bottomHUDFillColorSZ') == 1 then bottomHUDFillColorSZ = db_1.getStringValue('bottomHUDFillColorSZ') end
            if db_1.hasKey('textColorSZ') == 1 then textColorSZ = db_1.getStringValue('textColorSZ') end
            if db_1.hasKey('bottomHUDLineColorPVP') == 1 then bottomHUDLineColorPVP = db_1.getStringValue('bottomHUDLineColorPVP') end
            if db_1.hasKey('bottomHUDFillColorPVP') == 1 then bottomHUDFillColorPVP = db_1.getStringValue('bottomHUDFillColorPVP') end
            if db_1.hasKey('textColorPVP') == 1 then textColorPVP = db_1.getStringValue('textColorPVP') end
            if db_1.hasKey('neutralLineColor') == 1 then neutralLineColor = db_1.getStringValue('neutralLineColor') end
            if db_1.hasKey('neutralFontColor') == 1 then neutralFontColor = db_1.getStringValue('neutralFontColor') end
            if db_1.hasKey('generateAutoCode') == 1 then generateAutoCode = db_1.getIntValue('generateAutoCode') == 1 end
            if db_1.hasKey('autoVent') == 1 then autoVent = db_1.getIntValue('autoVent') == 1 end
            if db_1.hasKey('L_Shield_HP') == 1 then L_Shield_HP = db_1.getIntValue('L_Shield_HP') end
            if db_1.hasKey('M_Shield_HP') == 1 then M_Shield_HP = db_1.getIntValue('M_Shield_HP') end
            if db_1.hasKey('S_Shield_HP') == 1 then S_Shield_HP = db_1.getIntValue('S_Shield_HP') end
            if db_1.hasKey('XS_Shield_HP') == 1 then XS_Shield_HP = db_1.getIntValue('XS_Shield_HP') end
            if db_1.hasKey('max_radar_load') == 1 then max_radar_load = db_1.getIntValue('max_radar_load') end
            if db_1.hasKey('warning_size') == 1 then warning_size = db_1.getFloatValue('warning_size') end
            if db_1.hasKey('warning_outline_color') == 1 then warning_outline_color = db_1.getStringValue('warning_outline_color') end
            if db_1.hasKey('warning_fill_color') == 1 then warning_fill_color = db_1.getStringValue('warning_fill_color') end

            if db_1.hasKey('hpWidgetX') == 1 then hpWidgetX = db_1.getIntValue('hpWidgetX') end
            if db_1.hasKey('hpWidgetY') == 1 then hpWidgetY = db_1.getIntValue('hpWidgetY') end
            if db_1.hasKey('hpWidgetScale') == 1 then hpWidgetScale = db_1.getIntValue('hpWidgetScale') end
            if db_1.hasKey('shieldHPColor') == 1 then shieldHPColor = db_1.getStringValue('shieldHPColor') end
            if db_1.hasKey('ccsHPColor') == 1 then ccsHPColor = db_1.getStringValue('ccsHPColor') end

            if db_1.hasKey('resistWidgetX') == 1 then resistWidgetX = db_1.getIntValue('resistWidgetX') end
            if db_1.hasKey('resistWidgetY') == 1 then resistWidgetY = db_1.getIntValue('resistWidgetY') end
            if db_1.hasKey('resistWidgetScale') == 1 then resistWidgetScale = db_1.getIntValue('resistWidgetScale') end
            if db_1.hasKey('antiMatterColor') == 1 then antiMatterColor = db_1.getStringValue('antiMatterColor') end
            if db_1.hasKey('electroMagneticColor') == 1 then electroMagneticColor = db_1.getStringValue('electroMagneticColor') end
            if db_1.hasKey('kineticColor') == 1 then kineticColor = db_1.getStringValue('kineticColor') end
            if db_1.hasKey('thermicColor') == 1 then thermicColor = db_1.getStringValue('thermicColor') end

            if db_1.hasKey('transponderWidgetX') == 1 then transponderWidgetX = db_1.getIntValue('transponderWidgetX') end
            if db_1.hasKey('transponderWidgetY') == 1 then transponderWidgetY = db_1.getIntValue('transponderWidgetY') end
            if db_1.hasKey('transponderWidgetScale') == 1 then transponderWidgetScale = db_1.getIntValue('transponderWidgetScale') end

            if db_1.hasKey('radarInfoWidgetX') == 1 then radarInfoWidgetX = db_1.getIntValue('radarInfoWidgetX') end
            if db_1.hasKey('radarInfoWidgetY') == 1 then radarInfoWidgetY = db_1.getIntValue('radarInfoWidgetY') end
            if db_1.hasKey('radarInfoWidgetScale') == 1 then radarInfoWidgetScale = db_1.getIntValue('radarInfoWidgetScale') end

        elseif action == 'save' then
            db_1.setStringValue('uc-'..validPilotCode,pilotName)
            if printCombatLog then db_1.setIntValue('printCombatLog',1) else db_1.setIntValue('printCombatLog',0) end
            db_1.setIntValue('dangerWarning',dangerWarning)
            if validatePilot then db_1.setIntValue('validatePilot',1) else db_1.setIntValue('validatePilot',0) end
            db_1.setStringValue('bottomHUDLineColorSZ',bottomHUDLineColorSZ)
            db_1.setStringValue('bottomHUDFillColorSZ',bottomHUDFillColorSZ)
            db_1.setStringValue('textColorSZ',textColorSZ)
            db_1.setStringValue('bottomHUDLineColorPVP',bottomHUDLineColorPVP)
            db_1.setStringValue('bottomHUDFillColorPVP',bottomHUDFillColorPVP)
            db_1.setStringValue('textColorPVP',textColorPVP)
            db_1.setStringValue('neutralLineColor',neutralLineColor)
            db_1.setStringValue('neutralFontColor',neutralFontColor)
            if generateAutoCode then db_1.setIntValue('generateAutoCode',1) else db_1.setIntValue('generateAutoCode',0) end
            if autoVent then db_1.setIntValue('autoVent',1) else db_1.setIntValue('autoVent',0) end
            db_1.setIntValue('L_Shield_HP',L_Shield_HP)
            db_1.setIntValue('M_Shield_HP',M_Shield_HP)
            db_1.setIntValue('S_Shield_HP',S_Shield_HP)
            db_1.setIntValue('XS_Shield_HP',XS_Shield_HP)
            db_1.setIntValue('max_radar_load',max_radar_load)
            db_1.setFloatValue('warning_size',warning_size)
            db_1.setStringValue('warning_outline_color',warning_outline_color)
            db_1.setStringValue('warning_fill_color',warning_fill_color)

            db_1.setIntValue('hpWidgetX',hpWidgetX)
            db_1.setIntValue('hpWidgetY',hpWidgetY)
            db_1.setIntValue('hpWidgetScale',hpWidgetScale)
            db_1.setStringValue('shieldHPColor',shieldHPColor)
            db_1.setStringValue('ccsHPColor',ccsHPColor)

            db_1.setIntValue('resistWidgetX',resistWidgetX)
            db_1.setIntValue('resistWidgetY',resistWidgetY)
            db_1.setIntValue('resistWidgetScale',resistWidgetScale)
            db_1.setStringValue('antiMatterColor',antiMatterColor)
            db_1.setStringValue('electroMagneticColor',electroMagneticColor)
            db_1.setStringValue('kineticColor',kineticColor)
            db_1.setStringValue('thermicColor',thermicColor)

            db_1.setIntValue('transponderWidgetX',transponderWidgetX)
            db_1.setIntValue('transponderWidgetY',transponderWidgetY)
            db_1.setIntValue('transponderWidgetScale',transponderWidgetScale)

            db_1.setIntValue('radarInfoWidgetX',radarInfoWidgetX)
            db_1.setIntValue('radarInfoWidgetY',radarInfoWidgetY)
            db_1.setIntValue('radarInfoWidgetScale',radarInfoWidgetScale)
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
            local ammoColor = ccsHPColor
            local probColor = warning_outline_color
            if w.isOutOfAmmo() == 1 then ammoColor = warning_outline_color end

            local probs = w.getHitProbability()
            if probs > .7 then probColor = ccsHPColor elseif probs > .5 then probColor = 'yellow' end
            
            local weaponStr = string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring((0.66 - 0.015*i) * screenHeight) ..'px;left: '.. tostring(0.02* screenWidth) ..'px;"><div style="float: left;color: %s;">%s |&nbsp;</div><div style="float: left;color:%s;"> %.2f%% </div><div style="float: left;color: %s;"> | %s |&nbsp;</div><div style="float: left;color: %s;"> Ammo Count: %s </div></div>',textColor,w.getName(),probColor,probs*100,textColor,wStatus[w.getStatus()],ammoColor,w.getAmmoCount())
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
                tw = tw .. [[<line style="fill: none; stroke-linecap: round; stroke-width: 2px; stroke: ]]..neutralLineColor..[[;" x1="22" y1="]]..tostring(54+(i-1)*27)..[[" x2="22" y2="]]..tostring(80.7+(i-1)*27)..[["/>
                <text style="fill: ]]..neutralFontColor..[[; font-size: 24px; paint-order: fill; stroke-width: 0.5px; white-space: pre;" x="27" y="]]..tostring(73+(i-1)*27)..[[">]]..tag..[[</text>]]
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
    if shieldPercent < 15 or showAlerts then
        hw = hw .. string.format([[
        <svg width="]].. tostring(.06 * screenWidth) ..[[" height="]].. tostring(.06 * screenHeight) ..[[" x="]].. tostring(.40 * screenWidth) ..[[" y="]].. tostring(.64 * screenHeight) ..[[" style="fill: red;">
            ]]..warningSymbols['svgCritical']..[[
        </svg>
        <text x="]].. tostring(.45 * screenWidth) ..[[" y="]].. tostring(.68 * screenHeight) ..[[" style="fill: red" font-size="3.42vh" font-weight="bold">SHIELD CRITICAL</text>
        ]])
    elseif shieldPercent < 30 or showAlerts then
        hw = hw .. string.format([[
        <svg width="]].. tostring(.06 * screenWidth) ..[[" height="]].. tostring(.06 * screenHeight) ..[[" x="]].. tostring(.40 * screenWidth) ..[[" y="]].. tostring(.64 * screenHeight) ..[[" style="fill: orange;">
            ]]..warningSymbols['svgWarning']..[[
        </svg>
        <text x="]].. tostring(.45 * screenWidth) ..[[" y="]].. tostring(.68 * screenHeight) ..[[" style="fill: orange" font-size="3.42vh" font-weight="bold">SHIELD LOW</text>
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

    local ventTimer = shield_1.getVentingCooldown()
    local ventTimerColor = shieldHPColor
    if ventTimer > 0 then ventTimerColor = warning_outline_color end
    hw = hw .. [[
        <text style="fill: ]]..neutralFontColor..[[; font-family: Arial; font-size: 11.8px; paint-order: fill; white-space: pre;" x="66" y="91.01" bx:origin="-2.698544 2.296589">Vent Cooldown: </text>
        <text style="fill: ]]..ventTimerColor..[[; font-family: Arial; font-size: 11.8px; paint-order: fill; white-space: pre;" x="151" y="91.01" bx:origin="-2.698544 2.296589">]]..string.format('%.2f',ventTimer)..[[s</text>
        <!--ellipse style="stroke-width: 2px; stroke: ]]..neutralLineColor..[[; fill: none;" cx="311" cy="15" rx="6" ry="6"/-->
        </svg>
    ]]

    if shield_1.isVenting() == 0 then
        warnings['venting'] = nil
    else 
        warnings['venting'] = 'svgCritical'
    end

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
    local resistTimerColor = shieldHPColor
    if resistTimer > 0 then resistTimerColor = warning_outline_color end 

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
            </defs>
            <ellipse style="fill: none; stroke: ]]..neutralLineColor..[[;" cx="73" cy="61" rx="8" ry="8"/>
            <ellipse style="fill: ]]..neutralLineColor..[[; stroke: ]]..neutralLineColor..[[;" cx="73" cy="61" rx="2" ry="2"/>
            <polyline style="fill: none; stroke-linejoin: bevel; stroke-linecap: round; stroke: ]]..neutralLineColor..[[;" points="53 30 35 61 53 93"/>
            <polyline style="fill: none; stroke-linejoin: bevel; stroke-linecap: round; stroke: ]]..neutralLineColor..[[;" points="92 30 110 61 92 93"/>
            <polyline style="fill: none; stroke-linecap: round; stroke-linejoin: bevel; stroke: ]]..neutralLineColor..[[;" points="90 35 105 61 90 89"/>
            <polyline style="fill: none; stroke-linecap: round; stroke-linejoin: bevel; stroke: ]]..neutralLineColor..[[;" points="55 35 40 61 55 89"/>
            <line style="fill: none; stroke-width: 0.5px; stroke: ]]..neutralLineColor..[[;" x1="17" y1="61" x2="128" y2="61"/>
            <line style="fill: none; stroke-width: 0.5px; stroke: ]]..neutralLineColor..[[;" x1="72.888" y1="-9.275" x2="72.888" y2="101.725" transform="matrix(1, 0, 0, 1, 0.112056, 14.27536)"/>
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
    if db_1 ~= nil then 
        if db_1.hasKey('followingID') then
            followingID = db_1.getIntValue('followingID')
        end
        if not contains(identList,followingID) then
            db_1.setIntValue('targetID',0) 
        else
            followingIdentified = true
        end
        if not followingIdentified then db_1.clearValue('targetID') end
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
        
        local dmgRatio = 0
        local dmg = 0
        if dmgTracker[tostring(id)] then
            dmgRatio = clamp(dmgTracker[tostring(id)]/shieldDmgTrack[size],0,1)
            dmg = dmgTracker[tostring(id)]
            if dmg < 1000 then dmg = string.format('%.2f',dmg)
            elseif dmg < 1000000 then dmg = string.format('%.2fk',dmg/1000)
            else dmg = string.format('%.2fm',dmg/1000000)
            end
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
        if db_1 ~= nil then
            if db_1.getIntValue('following') == 1 and id == followingID and followingIdentified then
                db_1.setIntValue('targetID',id)
                db_1.setFloatValue('targetSpeed',speed)
                db_1.setFloatValue('targetDistance',distance)
                local weaponMin = radarRange - 10000
                for _,w in pairs(weapon) do if w.getOptimalDistance() - 10000 < weaponMin then weaponMin = w.getOptimalDistance() - 10000 end end
                db_1.setFloatValue('followDistance',weaponMin)
            elseif followingID == 0 then
                db_1.setIntValue('targetID',id)
                db_1.setFloatValue('targetSpeed',speed)
                db_1.setFloatValue('targetDistance',distance)
                weaponMin = radarRange - 10000
                for _,w in pairs(weapon) do if w.getOptimalDistance() - 10000 < weaponMin then weaponMin = w.getOptimalDistance() - 10000 end end
                db_1.setFloatValue('followDistance',weaponMin)
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
