json = require("dkjson")
Atlas = require('atlas')

function commas(number)
    return tostring(number) -- Make sure the "number" is a string
       :reverse() -- Reverse the string
       :gsub('%d%d%d', '%0,') -- insert one comma after every 3 numbers
       :gsub(',$', '') -- Remove a trailing comma if present
       :reverse() -- Reverse the string again
       :sub(1) -- a little hack to get rid of the second return value 😜
end

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

function brakeWidget()
    local brakeON = brakeInput > 0
    local bw = ''
    if brakeON then
        warnings['brakes'] = 'svgBrakes'
    else
        warnings['brakes'] = nil
    end
    return bw
end

function flightWidget()
    local sw = string.format([[
            <path d="
            M 595.2 1.08
            L  1324.8 1.08
            L 1171.2 59.4
            L 748.8 59.4
            L 595.2 1.08"
            stroke="%s" stroke-width="2" fill="%s" />
            <path d="
            M 1273.92 30.24
            L 1326.72 41.796
            L 1536 1.08
            L 1324.8 1.08
            L 1273.92 19.98
            L 1273.92 30.24"
            stroke="%s" stroke-width="1" fill="%s" />
            <path d="
            M 960 1.08
            L 960 69.66"
            stroke="%s" stroke-width="1" fill="none" />

            <path d="
            M 1171.2 1.08
            L 1171.2 69.66"
            stroke="%s" stroke-width="1" fill="none" />

            <path d="
            M 748.8 1.08 
            L 748.8 69.66"
            stroke="%s" stroke-width="1" fill="none" />

            <text x="768" y="16.2" style="fill: %s" font-size="1.42vh" font-weight="bold">Speed: %s</text>
            <text x="768" y="35.1" style="fill: %s" font-size="1.42vh" font-weight="bold">Current Accel: %.2f G</text>
            <text x="768" y="54" style="fill: %s" font-size="1.42vh" font-weight="bold">Brake Dist: %s</text>
            
            <text x="963.84" y="16.2" style="fill: %s" font-size="1.42vh" font-weight="bold">Max Speed: %s</text>
            <text x="963.84" y="35.1" style="fill: %s" font-size="1.42vh" font-weight="bold">Max Accel: %.2f G</text>
            <text x="963.84" y="54" style="fill: %s" font-size="1.42vh" font-weight="bold">Max Brake: %.2f G</text>

            <text x="1313.28" y="30.24" style="fill: %s" font-size="1.42vh" font-weight="bold" transform="rotate(-10,1313.28,30.24)">%s</text>

            ]],lineColor,bgColor,lineColor,modeBG,lineColor,lineColor,lineColor,fontColor,formatNumber(speed,'speed'),fontColor,accel/9.81,
            fontColor,formatNumber(brakeDist,'distance'),fontColor,formatNumber(maxSpeed,'speed'),fontColor,maxSpaceThrust/mass/9.81,
            fontColor,maxBrake/mass/9.81,
            fontColor,mode)

            sw = sw.. [[
                <text x="]].. tostring(.37 * screenWidth) ..[[" y="]].. tostring(.015 * screenHeight) ..[[" style="fill: ]]..fontColor..[[" font-size="1.42vh" font-weight="bold">Mass </text>
                <text x="]].. tostring(.355 * screenWidth) ..[[" y="]].. tostring(.028 * screenHeight) ..[[" style="fill: ]]..fontColor..[[" font-size="1.42vh" font-weight="bold">]]..formatNumber(mass,'mass')..[[</text>
            ]]
    return sw
end

function fuelWidget()
    curFuel = 0
    local fuelWarning = false
    local fuelTankWarning = false
    for i,v in pairs(spacefueltank) do 
        curFuel = curFuel + v.getItemsVolume()
        if v.getItemsVolume()/v.getMaxVolume() < .2 then fuelTankWarning = true end
    end
    sFuelPercent = curFuel/maxFuel * 100
    if sFuelPercent < 20 then fuelWarning = true end
    curFuelStr = string.format('%.2f%%',sFuelPercent)

    --Center bottom ribbon
    local fw = string.format([[
            <linearGradient id="sFuel" x1="0%%" y1="0%%" x2="100%%" y2="0%%">
            <stop offset="%.1f%%" style="stop-color:rgba(99, 250, 79, 0.95);stop-opacity:.95" />
            <stop offset="%.1f%%" style="stop-color:rgba(255, 10, 10, 0.5);stop-opacity:.5" />
            </linearGradient>

        <path d="
        M 645.12 19.98 
        L 748.8 59.4
        L 1171.2 59.4
        L 1273.92 19.98
        L 1273.92 30.24
        L 1171.2 69.66
        L 748.8 69.66
        L 646.08 30.24
        L 645.12 19.98"
    stroke="%s" stroke-width="2" fill="%s" />

    <path d="
        M 748.8 59.4
        L 1171.2 59.4
        L 1171.2 69.66
        L 748.8 69.66
        L 748.8 59.4"
    stroke="%s" stroke-width="1" fill="url(#sFuel)" />

    <path d="
        M 960 59.4 
        L 960 75.6"
    stroke="black" stroke-width="1.5" fill="none" />

    <path d="
        M 1065.6 59.4 
        L 1065.6 75.6"
    stroke="black" stroke-width="1.5" fill="none" />

    <path d="
        M 854.4 59.4 
        L 854.4 75.6"
    stroke="black" stroke-width="1.5" fill="none" />

    <text x="748.8" y="86.4" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">Fuel: %s</text>

    ]],sFuelPercent,sFuelPercent,lineColor,bgColor,lineColor,curFuelStr)

    if fuelTankWarning or fuelWarning or showAlerts then
        fuelWarningText = 'Fuel level &lt; 20%'
        if not fuelWarning then fuelWarningText = 'A Fuel tank &lt; 20%%' end
        warnings['lowFuel'] = 'svgWarning'
    else
        warnings['lowFuel'] = nil
    end

    return fw
end

function apStatusWidget()
    local ap_type = 'Autopilot'
    if route and routes[route][route_pos] == autopilot_dest_pos then ap_type = 'Routepilot' end
    local apw = string.format([[
        <path d="
            M 646.08 30.24
            L 593.28 41.796
            L 384 1.08
            L 595.2 1.08
            L 646.08 19.98
            L 646.08 30.24"
            stroke="%s" stroke-width="1" fill="%s" />
        
        <text x="480" y="12.96" style="fill: %s" font-size="1.42vh" font-weight="bold" transform="rotate(10,480,12.96)">%s: %s</text>
        %s
    ]],lineColor,apBG,fontColor,ap_type,apStatus,apHTML)

    return apw
end

function closestPlanet()
    local cName = nil
    local cDist = nil
    for pname,pvec in pairs(planets) do
        local tempDist = vec3(constructPosition-pvec):len()
        if cDist == nil or cDist > tempDist then
            cDist = tempDist
            cName = pname
        end
    end
    return cName,cDist
end

function pipeDist(A,B,loc,reachable)
    local AB = vec3.new(B['x']-A['x'],B['y']-A['y'],B['z']-A['z'])
    local BE = vec3.new(loc['x']-B['x'],loc['y']-B['y'],loc['z']-B['z'])
    local AE = vec3.new(loc['x']-A['x'],loc['y']-A['y'],loc['z']-A['z'])

    -- Is the point within warp distance and do we care?
    if AB:len() <= 500/0.000005 or not reachable then
        AB_BE = AB:dot(BE)
        AB_AE = AB:dot(AE)

        -- Is the point past the warp destination?
        -- If so, then the warp destination is closest
        if (AB_BE > 0) then
            dist = BE:len()
            distType = 'POINT'

        -- Is the point before the start point?
        -- If so, then the start point is the closest
        elseif (AB_AE < 0) then
            dist = AE:len()
            distType = 'POINT'

        -- If neither above condition was met, then the
        -- destination point must have be directly out from
        -- somewhere along the warp pipe. Lets calculate
        -- that distance
        else
            dist = vec3(AE:cross(BE)):len()/vec3(AB):len()
            distType = 'PIPE'
        end
        return dist,distType
    end
    return nil,nil
end

function closestPipe()
    pipes = {}
    local i = 0
    for name,center in pairs(planets) do
        if not string.starts(name,'Thades A') then
            for name2,center2 in pairs(planets) do
                if name ~= name2 and pipes[string.format('%s - %s',name2,name)] == nil and not string.starts(name,'Thades A') then
                    pipes[string.format('%s - %s',name,name2)] = {}
                    table.insert(pipes[string.format('%s - %s',name,name2)],center)
                    table.insert(pipes[string.format('%s - %s',name,name2)],center2)
                    if i % 100 == 0 then
                        coroutine.yield()
                    end
                    i = i + 1
                end
            end
        end
    end

    local cPipe = 'None'
    local cDist = 9999999999
    local cLoc = vec3(construct.getWorldPosition())
    i = 0
    for pName,vecs in pairs(pipes) do
        local tempDist,tempType = pipeDist(vecs[1],vecs[2],cLoc,false)
        if tempDist ~= nil then
            if cDist > tempDist then
                cDist = tempDist
                cPipe = pName
            end
        end
        if i % 200 == 0 then
            coroutine.yield()
        end
        i = i + 1
    end
    closestPipeName = cPipe
    closestPipeDistance = cDist
    return cPipe,cDist
end

function positionInfoWidget()
    local piw = string.format([[
            <path d="
                M 0 16.74
                L 220.8 16.74
                L 238.08 27
                L 480 37.8
                L 528 29.16
                L 384 1.08
                L 0 1.08
                L 0 16.74"
                stroke="%s" stroke-width="1" fill="%s"/>
        <path d="
            M 1980 16.74
            L 1699.2 16.74
            L 1681.92 27
            L 1440 37.8
            L 1392 29.16
            L 1536 1.08
            L 1920 1.08
            L 1920 16.74"
            stroke="%s" stroke-width="1" fill="%s" />
        <text x="1.92" y="10.8" style="fill: %s" font-size=".6vw">Remote Version: %s</text>
        <text x="1728" y="11.88" style="fill: %s" font-size=".7vw" font-weight="bold">Safe Zone Distance: %s</text>
        
        <text x="240" y="11.88" style="fill: %s" font-size="1.42vh" font-weight="bold">Nearest Planet</text>
        <text x="288" y="23.76" style="fill: %s" font-size=".7vw" >%s</text>

        <text x="1574.4" y="11.88" style="fill: %s" font-size="1.42vh" font-weight="bold">Nearest Pipe</text>
        <text x="1497.6" y="23.76" style="fill: %s" font-size=".7vw" >%s</text>
        ]],
        lineColor,bgColor,lineColor,bgColor,fontColor,hudVersion,fontColor,SZDStr,fontColor,fontColor,closestPlanetStr,fontColor,fontColor,closestPipeStr
    )
    return piw
end

function shipNameWidget()
    local snw = string.format([[
            <text x="1728" y="140.4" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">Ship Name: %s</text>
            <text x="1728" y="153.36" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">Ship Code: %s</text>
    ]],cName,cID)
    return snw
end

function arInfo(p,color,size,fill)
    local aInfo = library.getPointOnScreen({p['x'],p['y'],p['z']})
    if aInfo[3] ~= 0 then
        if aInfo[1] < .01 then aInfo[1] = .01 end
        if aInfo[2] < .01 then aInfo[2] = .01 end
        local translate = '(0,0)'
        if aInfo[1] < 1 and aInfo[2] < 1 then
            translate = string.format('(%.2f,%.2f)',screenWidth*aInfo[1],screenHeight*aInfo[2])
        elseif aInfo[1] > 1 and aInfo[1] < 3 and aInfo[2] < 1 then
            translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight*aInfo[2])
        elseif aInfo[2] > 1 and aInfo[2] < 3 and aInfo[1] < 1 then
            translate = string.format('(%.2f,%.2f)',screenWidth*aInfo[1],screenHeight)
        else
            translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight)
        end
        return string.format([[<g transform="translate%s">
                <circle cx="0" cy="0" r="%spx" style="fill:%s;stroke:%s;stroke-width:1.5;opacity:0.5;" />
                <line x1="%s" y1="%s" x2="-%s" y2="-%s" style="stroke:%s;stroke-width:.75;opacity:0.85;" />
                <line x1="-%s" y1="%s" x2="%s" y2="-%s" style="stroke:%s;stroke-width:.75;opacity:0.85;" />
                </g>]],translate,size,fill,color,size*1.4,size*1.4,size*1.4,size*1.4,color,size*1.4,size*1.4,size*1.4,size*1.4,color)
    else
        return ''
    end
end

function travelIndicatorWidget()
    local tiw = {}
    tiw[#tiw+1] = arInfo(constructPosition + 1.5/.000005 * constructForward,'rgba(200, 225, 235, 1)',5,'lightgrey')
    if offset_points then
        tiw[#tiw+1] = arInfo(constructPosition + 1.5/.000005 * constructRight,'rgba(200, 225, 235, 1)',5,'aqua')
        tiw[#tiw+1] = arInfo(constructPosition + -1.5/.000005 * constructRight,'rgba(200, 225, 235, 1)',5,'aqua')
        tiw[#tiw+1] = arInfo(constructPosition + -1.5/.000005 * constructForward,'rgba(200, 225, 235, 1)',5,'red')
        tiw[#tiw+1] = arInfo(constructPosition + -1/.000005 * (constructForward+constructRight),'rgba(200, 225, 235, 1)',5,'yellow')
        tiw[#tiw+1] = arInfo(constructPosition + -1/.000005 * (constructForward-constructRight),'rgba(200, 225, 235, 1)',5,'yellow')
        tiw[#tiw+1] = arInfo(constructPosition + 1/.000005 * (constructForward+constructRight),'rgba(200, 225, 235, 1)',5,'green')
        tiw[#tiw+1] = arInfo(constructPosition + 1/.000005 * (constructForward-constructRight),'rgba(200, 225, 235, 1)',5,'green')
    end
    
    if speed > 20 then
        tiw[#tiw+1] = arInfo(constructPosition + 2/.000005 * constructVelocity,'rgb(60, 255, 60)',7.5,'none')
        tiw[#tiw+1] = arInfo(constructPosition - 2/.000005 * constructVelocity,'rgb(255, 60, 60)',7.5,'none')
    end
    return table.concat(tiw,'')
end

function warningsWidget()
    local warningText = {}
    warningText['lowFuel'] = fuelWarningText
    warningText['brakes'] = 'Brakes Locked'
    warningText['venting'] = 'Shield Venting'

    local warningColor = {}
    warningColor['lowFuel'] = 'red'
    warningColor['cored'] = 'orange'
    warningColor['friendly'] = 'green'
    warningColor['venting'] = 'rgb(25, 247, 255)'

    if math.floor(arkTime*5) % 2 == 0 then
        warningColor['brakes'] = 'orange'
    else
        warningColor['brakes'] = 'yellow'
    end

    local ww = {}
    ww[#ww+1] = ''
    local count = 0
    for k,v in pairs(warnings) do
        if v ~= nil then
            ww[#ww+1] = string.format([[
                <svg width="57.6" height="32.4" x="460.8" y="%s" style="fill: %s;" viewBox="0 0 1920 1080">
                    %s
                </svg>
                <text x="512.64" y="%s" style="fill: %s;" font-size="1.7vh" font-weight="bold">%s</text>
                ]],tostring(.20 * screenHeight + .032 * screenHeight * count),warningColor[k],warningSymbols[v],tostring(.22 * screenHeight + .032 * screenHeight * count),warningColor[k],warningText[k])
            count = count + 1
        end
    end
    return table.concat(ww,'')
end

function hpWidget()
    local hw = string.format([[

            %s
        <svg x="633.6" y="950.4" viewBox="0 0 1920 1080">
            <polyline style="fill-opacity: 0; stroke-linejoin: round; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey; fill: none;" points="2 78.902 250 78.902 276 50" bx:origin="0.564202 0.377551"/>
            <polyline style="stroke-width: 2px; stroke: lightgrey; fill: none;" points="225 85.853 253.049 85.853 271 67.902" bx:origin="-1.23913 -1.086291"/>
            %s
            <text style="fill: rgb(25, 247, 255); font-family: Arial; font-size: 11.8px; white-space: pre;" x="15" y="28.824" bx:origin="-2.698544 2.296589">Shield:</text>
            <text style="fill: rgb(25, 247, 255); font-family: Arial; font-size: 11.8px; white-space: pre;" x="53.45" y="28.824" bx:origin="-2.698544 2.296589">%.2f%%</text>
            <text style="fill: rgb(60, 255, 60); font-family: Arial; font-size: 11.8px; white-space: pre;" x="153" y="28.824" bx:origin="-2.698544 2.296589">CCS:</text>
            <text style="fill: rgb(60, 255, 60); font-family: Arial; font-size: 11.8px; white-space: pre;" x="182.576" y="28.824" bx:origin="-2.698544 2.296589">%.2f%%</text>
            %s
            %s
        </svg>]],
            shieldWarningHTML,ccsHTML,shieldPercent,CCSPercent,ventHTML,shieldHTML
        )

    return hw
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

    local dw = string.format([[
                <text x="1.92" y="99" style="fill: red;" font-size="1.42vh" font-weight="bold">Damage: %.1fk</text>
                <text x="1.92" y="113" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">AM: %.0f%% | %.0f%%</text>
                <text x="2.08" y="127" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">EM: %.0f%% | %.0f%%</text>
                <text x="2.32" y="141" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">KN: %.0f%% | %.0f%%</text>
                <text x="2.48" y="155" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">TH: %.0f%% | %.0f%%</text>
                <text x="2.48" y="169" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">Resist cooldown: %.0f seconds</text>
    ]],cDPS/1000,100*amR,100*amS,100*emR,100*emS,100*knR,100*knS,100*thR,100*thS,shield_resist_cd)
    return dw
end

function generateScreen()
    local i = 0
    local htmlTable = {}
    htmlTable[i+1] = [[ <html>
        <style>
            svg { filter: drop-shadow(0px 0px 1px rgba(255,255,255,.5));}
        </style>
            <body style="font-family: Calibri;">
            <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;" viewBox="0 0 1920 1080">]]
    i = i + 1
    htmlTable[i+1] = brakeWidget()
    i = i + 1
    
    if showScreen then 
        if showHelp then
            htmlTable[i+1] = systemCheckHTML
            i = i + 1
        end
        htmlTable[i+1] = flightWidget()
        i = i + 1
        htmlTable[i+1] = fuelHTML
        i = i + 1
        htmlTable[i+1] = apStatusWidget()
        i = i + 1
        htmlTable[i+1] = positionInfoWidget()
        i = i + 1
        htmlTable[i+1] = shipNameHTML
        i = i + 1
        if shield_1 then 
            htmlTable[i+1] = hpWidget()      -- 1fps
            i = i + 1
        end
        htmlTable[i+1] = dpsHTML             -- no impact
        i = i + 1
    end
    
    htmlTable[i+1] = ARWidget()                  -- 1fps
    i = i + 1
    htmlTable[i+1] = travelIndicatorWidget()   -- 1fps
    i = i + 1
    htmlTable[i+1] = warningsWidget()        -- no impact
    i = i + 1

    htmlTable[i+1] = [[ </svg></body> </html> ]]
    system.setScreen(table.concat(htmlTable, ''))
end

function globalDB(action)
    if db_1 ~= nil then
        if action == 'get' then
            if db_1.hasKey('generateAutoCode') then generateAutoCode = db_1.getIntValue('generateAutoCode') == 1 end
            if db_1.hasKey('toggleBrakes') then toggleBrakes = db_1.getIntValue('toggleBrakes') == 1 end
            if db_1.hasKey('validatePilot') then validatePilot = db_1.getIntValue('validatePilot') == 1 end
            if db_1.hasKey('AP_Brake_Buffer') then AP_Brake_Buffer = db_1.getFloatValue('AP_Brake_Buffer') end
            if db_1.hasKey('AP_Max_Rotation_Factor') then AP_Max_Rotation_Factor = db_1.getFloatValue('AP_Max_Rotation_Factor') end
            if db_1.hasKey('AR_Mode') then AR_Mode = db_1.getStringValue('AR_Mode') end
            if db_1.hasKey('AR_Exclude_Moons') then AR_Exclude_Moons = db_1.getIntValue('AR_Exclude_Moons') == 1 end
            if db_1.hasKey('homeBaseLocation') then homeBaseLocation = db_1.getStringValue('homeBaseLocation') end
            if db_1.hasKey('homeBaseDistance') then homeBaseDistance = db_1.getIntValue('homeBaseDistance') end
            if db_1.hasKey('autoVent') then autoVent = db_1.getIntValue('autoVent') == 1 end
            if db_1.hasKey('shieldProfile') then shieldProfile = db_1.getStringValue('shieldProfile') end
            if db_1.hasKey('dampenerTorqueReduction') then dampenerTorqueReduction = db_1.getFloatValue('dampenerTorqueReduction') end
            if db_1.hasKey('offset_points') then offset_points = db_1.getIntValue('offset_points') == 1 end
            if db_1.hasKey('dmgAvgDuration') then dmgAvgDuration = db_1.getIntValue('dmgAvgDuration') end

        elseif action == 'save' then
            if generateAutoCode then db_1.setIntValue('generateAutoCode',1) else db_1.setIntValue('generateAutoCode',0) end
            if validatePilot then db_1.setIntValue('validatePilot',1) else db_1.setIntValue('validatePilot',0) end
            db_1.setFloatValue('AP_Brake_Buffer',AP_Brake_Buffer)
            db_1.setFloatValue('AP_Max_Rotation_Factor',AP_Max_Rotation_Factor)
            db_1.setStringValue('AR_Mode',AR_Mode)
            if AR_Exclude_Moons then db_1.setIntValue('AR_Exclude_Moons',1) else db_1.setIntValue('AR_Exclude_Moons',0) end
            if homeBaseLocation then db_1.setStringValue('homeBaseLocation',homeBaseLocation) end
            db_1.setIntValue('homeBaseDistance',homeBaseDistance)
            if autoVent then db_1.setIntValue('autoVent',1) else db_1.setIntValue('autoVent',0) end
            db_1.setStringValue('shieldProfile',shieldProfile)
            db_1.setFloatValue('dampenerTorqueReduction',dampenerTorqueReduction)
            if offset_points then db_1.setIntValue('offset_points',1) else db_1.setIntValue('offset_points',0) end
            db_1.setIntValue('dmgAvgDuration',dmgAvgDuration)
        end
    end
end

function ARWidget()
    -- Generate on screen planets for Augmented Reality view --
    AR_Generate = {}
    if autopilot_dest_pos ~= nil then AR_Generate['AutoPilot'] = convertWaypoint(autopilot_dest_pos) end
    if route and routes[route][route_pos] == autopilot_dest_pos then
        for k,v in pairs(routes[route]) do
            AR_Generate[string.format('RP_%s',k)] = convertWaypoint(routes[route][k])
        end
    end

    --Correcting cases where the user was using the legacy FROM_FILE mode
    if AR_Mode == 'FROM_FILE' and not legacyFile then AR_Mode = "ALL" end

    if AR_Mode == 'ALL' then
        for k,v in pairs(AR_Custom_Points) do 
            AR_Generate[k] = convertWaypoint(v)
        end
        for k,v in pairs(planets) do
            AR_Generate[k] = v
        end
        for k,v in pairs(AR_Temp_Points) do 
            AR_Generate[k] = convertWaypoint(v)
        end
    elseif string.find(AR_Mode,"FILE") ~= nil and not legacyFile then
        i, j = string.find(AR_Mode,"FILE")
        fileNumber = tonumber(string.sub(AR_Mode,j+1))
        if fileNumber > #validWaypointFiles then 
            AR_Mode = "NONE"
        elseif not legacyFile then
            for k,v in pairs(AR_Array[fileNumber]) do 
                AR_Generate[k] = convertWaypoint(v)
            end
        end
    elseif AR_Mode == 'FROM_FILE' then
        for k,v in pairs(AR_Custom_Points) do 
            AR_Generate[k] = convertWaypoint(v)
        end
    elseif AR_Mode == 'TEMPORARY' then
        for k,v in pairs(AR_Temp_Points) do 
            AR_Generate[k] = convertWaypoint(v)
        end
    elseif AR_Mode == 'PLANETS' then
        for k,v in pairs(planets) do
            AR_Generate[k] = v
        end
    end
    local planetARTable = {}
    planetARTable[#planetARTable+1] = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    for name,pos in pairs(AR_Generate) do
        if not (name:find('Moon') or name:find('Haven') or name:find('Sanctuary') or name:find('Asteroid')) or vec3(pos - constructPosition):len()*0.000005 < 20 or not AR_Exclude_Moons then
            local pDist = vec3(pos - constructPosition):len()
            if pDist*0.000005 < 500  or planets[name] == nil then 
                local pInfo = library.getPointOnScreen({pos['x'],pos['y'],pos['z']})
                if pInfo[3] ~= 0 then
                    if pInfo[1] < .01 then pInfo[1] = .01 end
                    if pInfo[2] < .01 then pInfo[2] = .01 end
                    local fill = 'rgb(29, 63, 255)'
                    if planets[name] == nil  and name ~= 'AutoPilot' and not string.starts(name,'RP_') then fill = 'rgb(49, 182, 60)'
                    elseif name == 'AutoPilot' then fill = 'red'
                    elseif string.starts(name,'RP_') then fill = 'rgb(138, 43, 226)'
                    end
                    local translate = '(0,0)'
                    local depth = 15 * 1/( 0.02*pDist*0.000005)
                    local pDistStr = ''
                    if pDist < 1000 then pDistStr = string.format('%.2fm',pDist)
                    elseif pDist < 100000 then pDistStr = string.format('%.2fkm',pDist/1000)
                    else pDistStr = string.format('%.2fsu',pDist*0.000005)
                    end
                    if depth > 15 then depth = tostring(15) elseif depth < 1 then depth = '1' else depth = tostring(depth) end
                    if pInfo[1] < 1 and pInfo[2] < 1 then
                        translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight*pInfo[2])
                    elseif pInfo[1] > 1 and pInfo[1] < 3 and pInfo[2] < 1 then
                        translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight*pInfo[2])
                    elseif pInfo[2] > 1 and pInfo[2] < 3 and pInfo[1] < 1 then
                        translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight)
                    else
                        translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight)
                    end
                    if name == 'AutoPilot' then
                        planetARTable[#planetARTable+1] = [[<g transform="translate]]..translate..[[">
                                <circle cx="0" cy="0" r="]].. depth ..[[px" style="fill:]]..fill..[[;stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <line x1="0" y1="0" x2="]].. depth*1.2 ..[[" y2="]].. depth*1.2 ..[[" style="stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <line x1="]].. depth*1.2 ..[[" y1="]].. depth*1.2 ..[[" x2="]]..tostring(depth*1.2 + 30)..[[" y2="]].. depth*1.2 ..[[" style="stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <text x="]]..tostring(depth*1.2)..[[" y="]].. depth*1.2+screenHeight*0.008 ..[[" style="fill: rgba(125, 150, 160, 1)" font-size="]]..tostring(.04*15)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                                </g>]]
                    elseif string.starts(name,'RP_') then
                        local tDepth = depth*.5
                        planetARTable[#planetARTable+1] = [[<g transform="translate]]..translate..[[">
                                <circle cx="0" cy="0" r="]].. tDepth ..[[px" style="fill:]]..fill..[[;stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.75;" />
                                <line x1="0" y1="0" x2="-]].. tDepth*1.2 ..[[" y2="-]].. tDepth*1.2 ..[[" style="stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <line x1="-]].. tDepth*1.2 ..[[" y1="-]].. tDepth*1.2 ..[[" x2="-]]..tostring(tDepth*1.2 + 30)..[[" y2="-]].. tDepth*1.2 ..[[" style="stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <text x="-]]..tostring(6*#name+tDepth*1.2)..[[" y="-]].. tDepth*1.2+screenHeight*0.0035 ..[[" style="fill: rgba(125, 150, 160, 1)" font-size="]]..tostring(.04*15)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                                </g>]]
                    else
                        planetARTable[#planetARTable+1] = [[<g transform="translate]]..translate..[[">
                                <circle cx="0" cy="0" r="]].. depth ..[[px" style="fill:]]..fill..[[;stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <line x1="0" y1="0" x2="-]].. depth*1.2 ..[[" y2="-]].. depth*1.2 ..[[" style="stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <line x1="-]].. depth*1.2 ..[[" y1="-]].. depth*1.2 ..[[" x2="-]]..tostring(depth*1.2 + 30)..[[" y2="-]].. depth*1.2 ..[[" style="stroke:rgba(125, 150, 160, 1);stroke-width:1;opacity:0.5;" />
                                <text x="-]]..tostring(6*#name+depth*1.2)..[[" y="-]].. depth*1.2+screenHeight*0.0035 ..[[" style="fill: rgba(125, 150, 160, 1)" font-size="]]..tostring(.04*15)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                                </g>]]
                    end
                end
            end
        end
    end
    planetARTable[#planetARTable+1] = '</svg>'
    planetAR = table.concat(planetARTable, '')
    -- End planet updates --

    local arw = {}
    arw[#arw+1] = planetAR
    
    if legacyFile then
        arw[#arw+1] = string.format([[
                <text x="1.92" y="32.4" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">Augmented Reality Mode: %s</text>
                <text x="1.92" y="68" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">FPS: %s</text>
            ]],AR_Mode,FPS)
    else
        if string.find(AR_Mode,"FILE") ~= nil then
            i, j = string.find(AR_Mode,"FILE")
            fileNumber = tonumber(string.sub(AR_Mode,j+1))
            --Catch if they reduced the number of custom files
            if fileNumber > #validWaypointFiles then AR_Mode = "NONE" end
            arw[#arw+1] = string.format([[
                    <text x="1.92" y="32.4" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">Augmented Reality Mode: %s</text>
                    <text x="1.92" y="68" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">FPS: %s</text>
                ]],validWaypointFiles[fileNumber].DisplayName,FPS)
        else
            arw[#arw+1] = string.format([[
                <text x="1.92" y="32.4" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">Augmented Reality Mode: %s</text>
                <text x="1.92" y="68" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">FPS: %s</text>
            ]],AR_Mode,FPS)
        end
    end
    return table.concat(arw,'')
end

function systemCheckWidget()
    local dw = {}
    local y_offset = 175
    local x_offset = 50
    local r_width = 300
    if brokenDisplay['Weapons'] ~= "" or brokenDisplay['Engine'] ~= "" or brokenDisplay['Control'] ~= "" then
        r_width = 800
    end

    dw[#dw+1] = string.format([[
        <rect width="%s" height="100" x="%s" y="%s" rx="5" ry="5" style="fill: rgba(25,25,25,0.65); stroke-width: 1.5; stroke: rgba(175,25,25,0.80);" />
    ]],r_width,x_offset-20,y_offset+175)

    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">Engines:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">%.1f%% (%.1fM)</text>
    ]],x_offset,197+y_offset,x_offset+120,197+y_offset,100*DamageGroupMap['Engine']['Current']/DamageGroupMap['Engine']['Total'],.000001*DamageGroupMap['Engine']['Current'])
    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(250, 150, 150, 1)" font-size="1.5vh" >%s</text>
    ]],x_offset+240,197+y_offset,string.sub(brokenDisplay['Engine'],1,-2))


    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">System Controls:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">%.1f%% (%.1fM)</text>
    ]],x_offset,217+y_offset,x_offset+120,217+y_offset,100*DamageGroupMap['Control']['Current']/DamageGroupMap['Control']['Total'],.000001*DamageGroupMap['Control']['Current'])
    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(250, 150, 150, 1)" font-size="1.5vh" >%s</text>
    ]],x_offset+240,217+y_offset,string.sub(brokenDisplay['Control'],1,-2))

    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">Weapons:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">%.1f%% (%.1fM)</text>
    ]],x_offset,237+y_offset,x_offset+120,237+y_offset,100*DamageGroupMap['Weapons']['Current']/DamageGroupMap['Weapons']['Total'],.000001*DamageGroupMap['Weapons']['Current'])
    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(250, 150, 150, 1)" font-size="1.5vh" >%s</text>
    ]],x_offset+240,237+y_offset,string.sub(brokenDisplay['Weapons'],1,-2))

    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">Other:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="1.5vh" font-weight="bold">%.1f%% (%.1fM)</text>
    ]],x_offset,257+y_offset,x_offset+120,257+y_offset,100*DamageGroupMap['Misc']['Current']/DamageGroupMap['Misc']['Total'],.000001*DamageGroupMap['Misc']['Current'])
    return table.concat(dw,'')
end

Kinematic = {} -- just a namespace
local ITERATIONS = 100 -- iterations over engine "warm-up" period

function Kinematic.computeAccelerationTime(initial, acceleration, final)
    -- ans: t = (vf - vi)/a
    return (final - initial)/acceleration
end

function Kinematic.computeDistanceAndTime(initial,final,mass,thrust,t50,brakeThrust)

    t50            = t50 or 0
    brakeThrust    = brakeThrust or 0 -- usually zero when accelerating

    local speedUp  = initial < final
    local a0       = thrust / (speedUp and mass or -mass)
    local b0       = -brakeThrust/mass
    local totA     = a0+b0

    if initial == final then
        return 0, 0   -- trivial
    elseif speedUp and totA <= 0 or not speedUp and totA >= 0 then
        return -1, -1 -- no solution
    end

    local distanceToMax, timeToMax = 0, 0

    if a0 ~= 0 and t50 > 0 then

        local c1  = math.pi/t50/2

        local v = function(t)
            return a0*(t/2 - t50*math.sin(c1*t)/math.pi) + b0*t + initial
        end

        local speedchk = speedUp and function(s) return s >= final end or
                                        function(s) return s <= final end
        timeToMax  = 2*t50

        if speedchk(v(timeToMax)) then
            local lasttime = 0

            while math.abs(timeToMax - lasttime) > 0.25 do
                local t = (timeToMax + lasttime)/2
                if speedchk(v(t)) then
                    timeToMax = t 
                else
                    lasttime = t
                end
            end
        end

        -- Closed form solution for distance exists (t <= 2*t50):
        local K       = 2*a0*t50^2/math.pi^2
        distanceToMax = K*(math.cos(c1*timeToMax) - 1) +
                        (a0+2*b0)*timeToMax^2/4 + initial*timeToMax

        if timeToMax < 2*t50 then
            return distanceToMax, timeToMax
        end
        initial = v(timeToMax)
    end
    -- At full thrust, motion follows Newtons formula:
    local a = a0+b0
    local t = Kinematic.computeAccelerationTime(initial, a, final)
    local d = initial*t + a*t*t/2
    return distanceToMax+d, timeToMax+t
end


function isNumber(n)  return type(n)           == 'number' end
function isSNumber(n) return type(tonumber(n)) == 'number' end
function isTable(t)   return type(t)           == 'table'  end
function isString(s)  return type(s)           == 'string' end
function isVector(v)  return isTable(v) and isNumber(v.x and v.y and v.z) end
