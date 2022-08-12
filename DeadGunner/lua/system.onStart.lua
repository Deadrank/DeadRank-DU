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
            local ammoColor = 'rgb(60, 255, 60)'
            local probColor = warning_outline_color
            if w.isOutOfAmmo() == 1 then ammoColor = warning_outline_color end

            local probs = w.getHitProbability()
            if probs > .7 then probColor = 'rgb(60, 255, 60);' elseif probs > .5 then probColor = 'yellow' end
            
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
        if transponder_1.isActive() == 1 then transponderColor = 'rgb(25, 247, 255)' transponderStatus = 'Active' end
        tw = tw .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.932 * screenHeight) ..'px;left: '.. tostring(.505 * screenWidth) ..'px;"><div style="float: left;color: rgba(0,0,0,1);">Transponder Status:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>',transponderColor,transponderStatus)
        
        local tags = transponder_1.getTags()
        tw = tw .. '<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.98 * screenHeight) ..'px;left: '.. tostring(.40 * screenWidth) ..'px;"><div style="float: left;color: rgba(255,255,255,1);">Transponder Tags: '
        for i,tag in pairs(tags) do 
            tw = tw .. tag .. ' '
        end
        tw = tw .. '</div></div>'
    end

    return tw
end

function hpWidget()
    local hw = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    --Center Bottom Base
    hw = hw .. [[
            <path d="
            M ]] .. tostring(.38*screenWidth) .. ' ' .. tostring(.999*screenHeight) ..[[ 
            L ]] .. tostring(.62*screenWidth) .. ' ' .. tostring(.999*screenHeight) .. [[
            L ]] .. tostring(.60*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
            L ]] .. tostring(.40*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
            L ]] .. tostring(.38*screenWidth) .. ' ' .. tostring(.999*screenHeight) .. [["
            stroke="]]..lineColor..[[" stroke-width="2" fill="]]..bgColor..[[" />]]

    --Center Bottom Shield
    if shield_1 then 
        local shieldPercent = shield_1.getShieldHitpoints()/shield_1.getMaxShieldHitpoints()*100
        if shieldPercent < 15 or showAlerts then
            hw = hw .. string.format([[
            <svg width="]].. tostring(.06 * screenWidth) ..[[" height="]].. tostring(.06 * screenHeight) ..[[" x="]].. tostring(.40 * screenWidth) ..[[" y="]].. tostring(.76 * screenHeight) ..[[" style="fill: red;">
                ]]..warningSymbols['svgCritical']..[[
            </svg>
            <text x="]].. tostring(.45 * screenWidth) ..[[" y="]].. tostring(.80 * screenHeight) ..[[" style="fill: red" font-size="3.42vh" font-weight="bold">SHIELD CRITICAL</text>
            ]])
        elseif shieldPercent < 30 or showAlerts then
            hw = hw .. string.format([[
            <svg width="]].. tostring(.06 * screenWidth) ..[[" height="]].. tostring(.06 * screenHeight) ..[[" x="]].. tostring(.40 * screenWidth) ..[[" y="]].. tostring(.76 * screenHeight) ..[[" style="fill: orange;">
                ]]..warningSymbols['svgWarning']..[[
            </svg>
            <text x="]].. tostring(.45 * screenWidth) ..[[" y="]].. tostring(.80 * screenHeight) ..[[" style="fill: orange" font-size="3.42vh" font-weight="bold">SHIELD LOW</text>
            ]])
        end
        hw = hw .. string.format([[<linearGradient id="shield" x1="100%%" y1="0%%" x2="0%%" y2="0%%">
        <stop offset="%.1f%%" style="stop-color:rgb(25, 247, 255);stop-opacity:1" />
        <stop offset="%.1f%%" style="stop-color:rgba(255, 60, 60, 1);stop-opacity:1" />
        </linearGradient>]],shieldPercent,shieldPercent)
        hw = hw ..[[
                <path d="
                M ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.9755*screenHeight) ..[[ 
                L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.9755*screenHeight) .. [[
                L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
                L ]] .. tostring(.40*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
                L ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.9755*screenHeight) .. [["
                stroke="]]..bottomHUDLineColorPVP..[[" stroke-width="1" fill="url(#shield)" />]]
        if shield_1.isVenting() == 0 then
            hw = hw .. [[
                <text x="]].. tostring(.42 * screenWidth) ..[[" y="]].. tostring(.968 * screenHeight) ..[[" style="fill: black" font-size="1.42vh" font-weight="bold">Shield: ]] .. string.format('%.2f%%',shieldPercent) .. [[</text>
            ]]
        else 
            hw = hw .. [[
                <text x="]].. tostring(.42 * screenWidth) ..[[" y="]].. tostring(.968 * screenHeight) ..[[" style="fill: black" font-size="1.42vh" font-weight="bold">Shield: VENTING</text>
            ]]
        end
    end

    --Center Bottom CCS
    local CCSPercent = 100*(core_1.getMaxCoreStress()-core_1.getCoreStress())/core_1.getMaxCoreStress()
    hw = hw .. string.format([[<linearGradient id="CCS" x1="0%%" y1="0%%" x2="100%%" y2="0%%">
    <stop offset="%.1f%%" style="stop-color:rgb(60, 255, 60);stop-opacity:1" />
    <stop offset="%.1f%%" style="stop-color:rgba(255, 60, 60, 1);stop-opacity:1" />
    </linearGradient>]],CCSPercent,CCSPercent)
    hw = hw ..[[
            <path d="
            M ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.9755*screenHeight) ..[[ 
            L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.9755*screenHeight) .. [[
            L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
            L ]] .. tostring(.6*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
            L ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.9755*screenHeight) .. [["
            stroke="]]..bottomHUDLineColorPVP..[[" stroke-width="1" fill="url(#CCS)" />]]
    hw = hw .. [[
        <text x="]].. tostring(.51 * screenWidth) ..[[" y="]].. tostring(.968 * screenHeight) ..[[" style="fill: black" font-size="1.42vh" font-weight="bold">CCS: ]] .. string.format('%.2f%%',CCSPercent) .. [[</text>
    ]]

    hw = hw .. '</svg>'

    return hw
end

function resistWidget()
    local rw = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    rw = rw .. [[
        <path d="
        M ]] .. tostring(.4*screenWidth) .. ' ' .. tostring(.95*screenHeight) ..[[ 
        L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
        L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.85*screenHeight) .. [[
        L ]] .. tostring(.4*screenWidth) .. ' ' .. tostring(.85*screenHeight) .. [[
        L ]] .. tostring(.4*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [["
        stroke="]]..neutralLineColor..[[" stroke-width="2" fill="rgba(211,211,211,.1)" />]]

    local stress = shield_1.getStressRatioRaw()
    local am = stress[1]
    local em = stress[2]
    local kn = stress[3]
    local th = stress[4]

    rw = rw .. [[
        <line x1="]]..tostring(.45*screenWidth)..[[" y1="]]..tostring(.95*screenHeight)..[[" x2="]]..tostring(.45*screenWidth)..[[" y2="]]..tostring(.85*screenHeight)..[[" stroke="]]..neutralLineColor..[[" stroke-width=".5" opacity=1 />
        <line x1="]]..tostring(.40*screenWidth)..[[" y1="]]..tostring(.90*screenHeight)..[[" x2="]]..tostring(.50*screenWidth)..[[" y2="]]..tostring(.90*screenHeight)..[[" stroke="]]..neutralLineColor..[[" stroke-width=".5" opacity=1 />
        ]]

    rw = rw .. [[
        <path d="
        M ]] .. tostring(.45*screenWidth) .. ' ' .. tostring(.90*screenHeight - (.04*am + .01)*screenHeight) ..[[ 
        L ]] .. tostring(.45*screenWidth + (.04*em + .01)*screenHeight) .. ' ' .. tostring(.90*screenHeight) .. [[
        L ]] .. tostring(.45*screenWidth) .. ' ' .. tostring(.90*screenHeight + (.04*kn + .01)*screenHeight) .. [[
        L ]] .. tostring(.45*screenWidth - (.04*th + .01)*screenHeight) .. ' ' .. tostring(.90*screenHeight) .. [[
        L ]] .. tostring(.45*screenWidth) .. ' ' .. tostring(.90*screenHeight - (.04*am + .01)*screenHeight) .. [["
        stroke="]]..neutralLineColor..[[" stroke-width="1" fill="rgba(255, 240, 25, 0.4)" />
        
        <text x="]].. tostring(.452 * screenWidth) ..[[" y="]].. tostring(.86 * screenHeight) ..[[" style="fill: white" font-size=".6vw">AM</text>
        <text x="]].. tostring(.49 * screenWidth) ..[[" y="]].. tostring(.91 * screenHeight) ..[[" style="fill: white" font-size=".6vw">EM</text>
        <text x="]].. tostring(.44 * screenWidth) ..[[" y="]].. tostring(.945 * screenHeight) ..[[" style="fill: white" font-size=".6vw">KN</text>
        <text x="]].. tostring(.401 * screenWidth) ..[[" y="]].. tostring(.89 * screenHeight) ..[[" style="fill: white" font-size=".6vw">TH</text>
        <text x="]].. tostring(.40 * screenWidth) ..[[" y="]].. tostring(.841 * screenHeight) ..[[" style="fill: rgba(255, 240, 25, 1);" font-size=".7vw" font-weight="bold">Incoming Damage</text>
        ]]

    local srp = shield_1.getResistancesPool()
    local csr = shield_1.getResistances()
    am = csr[1]/srp
    em = csr[2]/srp
    kn = csr[3]/srp
    th = csr[4]/srp
    rw = rw .. [[
        <path d="
        M ]] .. tostring(.45*screenWidth) .. ' ' .. tostring(.90*screenHeight - (.04*am + .01)*screenHeight) ..[[ 
        L ]] .. tostring(.45*screenWidth + (.04*em + .01)*screenHeight) .. ' ' .. tostring(.90*screenHeight) .. [[
        L ]] .. tostring(.45*screenWidth) .. ' ' .. tostring(.90*screenHeight + (.04*kn + .01)*screenHeight) .. [[
        L ]] .. tostring(.45*screenWidth - (.04*th + .01)*screenHeight) .. ' ' .. tostring(.90*screenHeight) .. [[
        L ]] .. tostring(.45*screenWidth) .. ' ' .. tostring(.90*screenHeight - (.04*am + .01)*screenHeight) .. [["
        stroke="black" stroke-width="1" fill="rgba(25, 247, 255, 0.4)" />
        
        <text x="]].. tostring(.452 * screenWidth) ..[[" y="]].. tostring(.841 * screenHeight) ..[[" style="fill: rgb(25, 247, 255);" font-size=".7vw" font-weight="bold">Shield Resistance</text>
        ]]


    rw = rw .. [[
        <path d="
        M ]] .. tostring(.6*screenWidth) .. ' ' .. tostring(.95*screenHeight) ..[[ 
        L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [[
        L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.85*screenHeight) .. [[
        L ]] .. tostring(.6*screenWidth) .. ' ' .. tostring(.85*screenHeight) .. [[
        L ]] .. tostring(.6*screenWidth) .. ' ' .. tostring(.95*screenHeight) .. [["
        stroke="]]..neutralLineColor..[[" stroke-width="2" fill="rgba(211,211,211,.3)" />
        
        
    ]]

    rw = rw .. '</svg>'
    local ventTimer = shield_1.getVentingCooldown()
    local ventTimerColor = 'rgb(25, 247, 255)'
    if ventTimer > 0 then ventTimerColor = warning_outline_color end
    rw = rw .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.855 * screenHeight) ..'px;left: '.. tostring(.505 * screenWidth) ..'px;"><div style="float: left;color: rgba(0,0,0,1);">Vent Timer:&nbsp;</div><div style="float: left;color: %s;"> %.2fs </div></div>',ventTimerColor,ventTimer)

    local resistTimer = shield_1.getResistancesCooldown()
    local resistTimerColor = 'rgb(25, 247, 255)'
    if resistTimer > 0 then resistTimerColor = warning_outline_color end 
    rw = rw .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.87 * screenHeight) ..'px;left: '.. tostring(.505 * screenWidth) ..'px;"><div style="float: left;color: rgba(0,0,0,1);">Resist Timer:&nbsp;</div><div style="float: left;color: %s;"> %.2fs </div></div>',resistTimerColor,resistTimer)
    return rw
end

function radarWidget()
    local rw = ''
    local friendlyShipNum = radarStats['friendly']['L'] + radarStats['friendly']['M'] + radarStats['friendly']['S'] + radarStats['friendly']['XS']
    local enemyShipNum = radarStats['enemy']['L'] + radarStats['enemy']['M'] + radarStats['enemy']['S'] + radarStats['enemy']['XS']
    rw = rw .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.885 * screenHeight) ..'px;left: '.. tostring(.505 * screenWidth) ..'px;"><div style="float: left;color: rgba(0,0,0,1);">Allied Ships:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>','rgb(25, 247, 255)',friendlyShipNum)
    rw = rw .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.9 * screenHeight) ..'px;left: '.. tostring(.505 * screenWidth) ..'px;"><div style="float: left;color: rgba(0,0,0,1);">Enemy Ships:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>',warning_outline_color,enemyShipNum)
    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.915 * screenHeight) ..'px;left: '.. tostring(.505 * screenWidth) ..[[px;">
    <div style="float: left;color: rgba(0,0,0,1);">L:&nbsp;</div><div style="float: left;color: ]]..warning_outline_color..[[;">%s&nbsp;&nbsp;&nbsp;</div>
    <div style="float: left;color: rgba(0,0,0,1);">M:&nbsp;</div><div style="float: left;color: ]]..warning_outline_color..[[;">%s&nbsp;&nbsp;&nbsp;</div>
    <div style="float: left;color: rgba(0,0,0,1);">S:&nbsp;</div><div style="float: left;color: ]]..warning_outline_color..[[;">%s&nbsp;&nbsp;&nbsp;</div>
    <div style="float: left;color: rgba(0,0,0,1);">XS:&nbsp;</div><div style="float: left;color: ]]..warning_outline_color..[[;">%s&nbsp;&nbsp;&nbsp;</div>
    </div>]],radarStats['enemy']['L'],radarStats['enemy']['M'],radarStats['enemy']['S'],radarStats['enemy']['XS'])

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

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.15 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">Identified By:&nbsp;</div><div style="float: left;color: orange;">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],identifiedBy)

    rw = rw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.165 * screenHeight) ..'px;left: '.. tostring(.90 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Attacked By:&nbsp;</div><div style="float: left;color: ]]..warning_outline_color..[[;">%.0f&nbsp;</div><div style="float: left;color: ]]..'white'..[[;">ships</div></div>]],attackedBy)

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

                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.495 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. tostring(uniqueName) .. [[</text>
                <text x="]].. tostring(.100 * screenWidth) ..[[" y="]].. tostring(.495 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">Ship Size: ]] .. tostring(size) .. [[</text>
                
                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.510 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. string.format('Speed: %s',speedString) .. [[</text>
                <text x="]].. tostring(.100 * screenWidth) ..[[" y="]].. tostring(.510 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. string.format('%s: %.0fkm/h',speedCompare,speedDiff) .. [[</text>
                
                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.525 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. string.format('Mass: %s',massStr) .. [[</text>
                <text x="]].. tostring(.090 * screenWidth) ..[[" y="]].. tostring(.525 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. 'Top Speed: '.. topSpeedStr .. [[</text>
                
                <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.540 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. string.format('%s',distString) .. [[</text>
                <text x="]].. tostring(.066 * screenWidth) ..[[" y="]].. tostring(.540 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. string.format('Radars: %.0f',info['radars']) .. [[</text>
                <text x="]].. tostring(.103 * screenWidth) ..[[" y="]].. tostring(.540 * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-size="1.42vh" font-weight="bold">]] .. string.format('Weapons: %s',weapons) .. [[</text>
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
            if speedDiff > 0 and math.abs(speedDiff) > 5 then targetSpeedString = string.format('%s &#8593;',speedString) targetSpeedColor = 'rgb(60, 255, 60);'
            elseif speedDiff < 0 and math.abs(speedDiff) > 5 then targetSpeedString = string.format('%s &#8595;',speedString) targetSpeedColor = warning_outline_color
            elseif not targetIdentified then targetSpeedString = 'Not Identified'
            end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.420 * screenHeight) ..'px;left: '.. tostring(.30 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Speed:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>]],targetSpeedColor,targetSpeedString)

            -- Target Acceleration
            local accelString = 'Stable'
            local accelColor = neutralFontColor
            if accelCompare == 'Accelerating' then accelString = 'Speeding Up &#8593;' accelColor = 'rgb(60, 255, 60);'
            elseif accelCompare == 'Braking' then accelString = 'Slowing Down&#8595;' accelColor = warning_outline_color
            elseif not targetIdentified then accelString = 'Not Identified'
            end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.440 * screenHeight) ..'px;left: '.. tostring(.30 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Change:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>]],accelColor,accelString)

            -- Target Gap
            local speedColor = neutralFontColor
            if not targetIdentified then speedDiff = 0 end
            if speedCompare == 'Closing' and math.abs(speedDiff) > 5 then speedColor = 'rgb(60, 255, 60);'
            elseif speedCompare == 'Parting' and math.abs(speedDiff) > 5 then speedColor = warning_outline_color
            end
            local fontColor = 'white'
            if speedColor == 'white' then fontColor = neutralFontColor end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.460 * screenHeight) ..'px;left: '.. tostring(.30 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Gap:&nbsp;</div><div style="float: left;color: %s;"> %s (%.2fkm/h) </div></div>]],speedColor,speedCompare,speedDiff)

            -- Target Distance
            local inRange = radarRange >= distance
            local distanceColor = 'orange'
            if inRange then distanceColor = 'rgb(60, 255, 60);' end
            targetString = targetString .. string.format('<div style="position: absolute;font-weight: bold;font-size: .8vw;top: '.. tostring(.400 * screenHeight) ..'px;left: '.. tostring(.60 * screenWidth) ..[[px;">
            <div style="float: left;color: white;">Target Dist:&nbsp;</div><div style="float: left;color: %s;"> %s </div></div>]],distanceColor,distString)

            -- Target Top Speed
            local outrunColor = neutralFontColor
            if not targetIdentified then topSpeedStr = 'Not identified' end
            if outrun then outrunColor = 'rgb(60, 255, 60);'
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

    local radarRangeString = ''
    if radarRange < 1000 then radarRangeString = string.format('%.2fm',radarRange)
    elseif radarRange < 100000 then radarRangeString = string.format('%.2fkm',radarRange/1000)
    else radarRangeString = string.format('%.2fsu',radarRange*.000005)
    end
    iw = iw .. string.format([[<div style="position: absolute;font-weight: bold;font-size: .8vw;top: ]].. tostring(.185 * screenHeight) ..'px;left: '.. tostring(.875 * screenWidth) ..[[px;">
    <div style="float: left;color: ]]..'white'..[[;">&nbsp;&nbsp;Identification Range:&nbsp;</div><div style="float: left;color: rgb(25, 247, 255);">%s&nbsp;</div></div>]],radarRangeString)
    
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

    local warningColor = {}
    warningColor['attackedBy'] = 'red'
    warningColor['radarOverload'] = 'orange'
    warningColor['cored'] = 'orange'
    warningColor['friendly'] = 'green'
    warningColor['noRadar'] = 'red'

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
