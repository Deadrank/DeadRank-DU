json = require("dkjson")
Atlas = require('atlas')

function profile(func, name, ...)
    local start_time = system.getArkTime()
    local result = {func(...)}
    local end_time = system.getArkTime()
    if debug then
        if profiling_data[name] == nil or profiling_data[name] < end_time - start_time then
            profiling_data[name] = end_time - start_time
        end
    end
    return table.unpack(result)
end

function commas(number)
    return tostring(number) -- Make sure the "number" is a string
       :reverse() -- Reverse the string
       :gsub('%d%d%d', '%0,') -- insert one comma after every 3 numbers
       :gsub(',$', '') -- Remove a trailing comma if present
       :reverse() -- Reverse the string again
       :sub(1) -- a little hack to get rid of the second return value
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
            <path class="widget" d="
            M 595.2 1.08
            L  1324.8 1.08
            L 1171.2 59.4
            L 748.8 59.4
            L 595.2 1.08"
            stroke="%s" stroke-width="2" fill="%s" />
            <path class="widget" d="
            M 1273.92 30.24
            L 1326.72 41.796
            L 1536 1.08
            L 1324.8 1.08
            L 1273.92 19.98
            L 1273.92 30.24"
            stroke="%s" stroke-width="1" fill="%s" />
            <path class="widget" d="
            M 960 1.08
            L 960 69.66"
            stroke="%s" stroke-width="1" fill="none" />

            <path class="widget" d="
            M 1171.2 1.08
            L 1171.2 69.66"
            stroke="%s" stroke-width="1" fill="none" />

            <path class="widget" d="
            M 748.8 1.08 
            L 748.8 69.66"
            stroke="%s" stroke-width="1" fill="none" />

            <text class="text" x="768" y="16.2" style="fill: %s" font-size="%svh" font-weight="bold">Speed: %s</text>
            <text class="text" x="768" y="35.1" style="fill: %s" font-size="%svh" font-weight="bold">Current Accel: %.2f G</text>
            <text class="text" x="768" y="54" style="fill: %s" font-size="%svh" font-weight="bold">Brake Dist: %s</text>
            
            <text class="text" x="963.84" y="16.2" style="fill: %s" font-size="%svh" font-weight="bold">Max Speed: %s</text>
            <text class="text" x="963.84" y="35.1" style="fill: %s" font-size="%svh" font-weight="bold">Max Accel: %.2f G</text>
            <text class="text" x="963.84" y="54" style="fill: %s" font-size="%svh" font-weight="bold">Max Brake: %.2f G</text>

            <text class="text" x="1313.28" y="30.24" style="fill: %s" font-size="%svh" font-weight="bold" transform="rotate(-10,1313.28,30.24)">%s</text>

            ]],lineColor,bgColor,lineColor,modeBG,lineColor,lineColor,lineColor,
            fontColor,font_size_ratio+0.42,formatNumber(speed,'speed'),
            fontColor,font_size_ratio+0.42,accel/9.81,
            fontColor,font_size_ratio+0.42,formatNumber(brakeDist,'distance'),
            fontColor,font_size_ratio+0.42,formatNumber(maxSpeed,'speed'),
            fontColor,font_size_ratio+0.42,maxSpaceThrust/mass/9.81,
            fontColor,font_size_ratio+0.42,maxBrake/mass/9.81,
            fontColor,font_size_ratio+0.42,mode)

            sw = sw.. [[
                <text x="]].. tostring(.37 * screenWidth) ..[[" y="]].. tostring(.015 * screenHeight) ..[[" style="fill: ]]..fontColor..[[" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Mass </text>
                <text x="]].. tostring(.355 * screenWidth) ..[[" y="]].. tostring(.028 * screenHeight) ..[[" style="fill: ]]..fontColor..[[" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">]]..formatNumber(mass,'mass')..[[</text>
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

    <text class="text" x="748.8" y="86.4" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Fuel: %s</text>

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
        <path class="widget" d="
            M 646.08 30.24
            L 593.28 41.796
            L 384 1.08
            L 595.2 1.08
            L 646.08 19.98
            L 646.08 30.24"
            stroke="%s" stroke-width="1" fill="%s" />
        
        <text class="text" x="480" y="12.96" style="fill: %s" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold" transform="rotate(10,480,12.96)">%s: %s</text>
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
            <path class="widget" d="
                M 0 16.74
                L 220.8 16.74
                L 238.08 27
                L 480 37.8
                L 528 29.16
                L 384 1.08
                L 0 1.08
                L 0 16.74"
                stroke="%s" stroke-width="1" fill="%s"/>
        <path class="widget" d="
            M 1980 16.74
            L 1699.2 16.74
            L 1681.92 27
            L 1440 37.8
            L 1392 29.16
            L 1536 1.08
            L 1920 1.08
            L 1920 16.74"
            stroke="%s" stroke-width="1" fill="%s" />
        <text class="text" x="1.92" y="14" style="fill: %s" font-size="]].. font_size_ratio ..[[vh">Remote Version: %s</text>
        <text class="text" x="1728" y="15" style="fill: %s" font-size="]].. font_size_ratio ..[[vh" font-weight="bold">Safe Zone Distance: %s</text>
        
        <text class="text" x="240" y="15" style="fill: %s" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Nearest Planet</text>
        <text class="text" x="288" y="26" style="fill: %s" font-size="]].. font_size_ratio ..[[vh" >%s</text>

        <text class="text" x="1574.4" y="15" style="fill: %s" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Nearest Pipe</text>
        <text class="text" x="1497.6" y="26" style="fill: %s" font-size="]].. font_size_ratio ..[[vh" >%s</text>
        ]],
        lineColor,bgColor,lineColor,bgColor,fontColor,hudVersion,fontColor,SZDStr,fontColor,fontColor,closestPlanetStr,fontColor,fontColor,closestPipeStr
    )
    return piw
end

function shipNameWidget()
    local snw = string.format([[
            <text class="text" x="1728" y="35" font-size="]].. font_size_ratio+0.42 ..[[vh">Ship Name: %s</text>
            <text class="text" x="1728" y="50" font-size="]].. font_size_ratio+0.42 ..[[vh">Ship Code: %s</text>
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
                <svg class="widget" width="57.6" height="32.4" x="460.8" y="%s" style="fill: %s;" viewBox="0 0 1920 1080">
                    %s
                </svg>
                <text x="512.64" y="%s" style="fill: %s;" font-size="]].. font_size_ratio+0.7 ..[[vh" font-weight="bold">%s</text>
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
            <polyline class="widget" style="fill-opacity: 0; stroke-linejoin: round; stroke-linecap: round; stroke-width: 2px; stroke: lightgrey; fill: none;" points="2 78.902 250 78.902 276 50" bx:origin="0.564202 0.377551"/>
            <polyline class="widget" style="stroke-width: 2px; stroke: lightgrey; fill: none;" points="225 85.853 253.049 85.853 271 67.902" bx:origin="-1.23913 -1.086291"/>
            %s
            <text style="fill: rgb(25, 247, 255); font-size: 11.8px; white-space: pre;" x="15" y="28.824" bx:origin="-2.698544 2.296589">Shield:</text>
            <text style="fill: rgb(25, 247, 255); font-size: 11.8px; white-space: pre;" x="53.45" y="28.824" bx:origin="-2.698544 2.296589">%.2f%%</text>
            <text style="fill: rgb(60, 255, 60); font-size: 11.8px; white-space: pre;" x="153" y="28.824" bx:origin="-2.698544 2.296589">CCS:</text>
            <text style="fill: rgb(60, 255, 60); font-size: 11.8px; white-space: pre;" x="182.576" y="28.824" bx:origin="-2.698544 2.296589">%.2f%%</text>
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
                <text x="1.92" y="99" style="fill: red;" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Damage: %.1fk</text>
                <text x="1.92" y="120" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">AM: %.0f%% | %.0f%%</text>
                <text x="2.08" y="135" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">EM: %.0f%% | %.0f%%</text>
                <text x="2.32" y="150" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">KN: %.0f%% | %.0f%%</text>
                <text x="2.48" y="165" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">TH: %.0f%% | %.0f%%</text>
                <text x="2.48" y="180" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Resist cooldown: %.0f seconds</text>
    ]],cDPS/1000,100*amR,100*amS,100*emR,100*emS,100*knR,100*knS,100*thR,100*thS,shield_resist_cd)
    return dw
end

function generateScreen()
    local i = 0
    local htmlTable = {}
    htmlTable[i+1] = [[ <html>
        <style>
            body {
                font-family: 'Roboto', sans-serif;
                color: #e6e6e6;
                margin: 0;
                overflow: hidden;
            }
            svg {
                filter: drop-shadow(0px 0px 5px rgba(0, 255, 255, 0.5));
            }
            .widget {
                stroke-width: 2;
            }
            .text {
                fill: #e6e6e6;
            }
        </style>
            <body>
            <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;" viewBox="0 0 1920 1080">]]
    i = i + 1
    htmlTable[i+1] = brakeWidget()
    i = i + 1
    
    if showScreen then 
        if showHelp then
            htmlTable[i+1] = systemCheckHTML
            i = i + 1
        end
        htmlTable[i+1] = profile(flightWidget,'flightWidget')
        i = i + 1
        htmlTable[i+1] = fuelHTML
        i = i + 1
        htmlTable[i+1] = profile(apStatusWidget,'apStatusWidget')
        i = i + 1
        htmlTable[i+1] = profile(positionInfoWidget,'positionInfoWidget')
        i = i + 1
        htmlTable[i+1] = shipNameHTML
        i = i + 1
        if shield_1 then 
            htmlTable[i+1] = profile(hpWidget,'hpWidget')
            i = i + 1
        end
        htmlTable[i+1] = dpsHTML
        i = i + 1
    end
    
    htmlTable[i+1] = profile(ARWidget,'ARWidget')
    i = i + 1
    htmlTable[i+1] = profile(travelIndicatorWidget,'travelIndicatorWidget')
    i = i + 1
    htmlTable[i+1] = profile(warningsWidget,'warningsWidget')
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
            if db_1.hasKey('font_size_ratio') then font_size_ratio = db_1.getFloatValue('font_size_ratio') end

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
            db_1.setFloatValue('font_size_ratio',font_size_ratio)
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
                <text x="1.92" y="32.4" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Augmented Reality Mode: %s</text>
                <text x="1.92" y="68" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">FPS: %s</text>
            ]],AR_Mode,FPS)
    else
        if string.find(AR_Mode,"FILE") ~= nil then
            i, j = string.find(AR_Mode,"FILE")
            fileNumber = tonumber(string.sub(AR_Mode,j+1))
            --Catch if they reduced the number of custom files
            if fileNumber > #validWaypointFiles then AR_Mode = "NONE" end
            arw[#arw+1] = string.format([[
                    <text x="1.92" y="32.4" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Augmented Reality Mode: %s</text>
                    <text x="1.92" y="68" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">FPS: %s</text>
                ]],validWaypointFiles[fileNumber].DisplayName,FPS)
        else
            arw[#arw+1] = string.format([[
                <text x="1.92" y="32.4" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">Augmented Reality Mode: %s</text>
                <text x="1.92" y="68" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">FPS: %s</text>
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
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">Engines:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">%.1f%% (%.1fM)</text>
    ]],x_offset,197+y_offset,x_offset+120,197+y_offset,100*DamageGroupMap['Engine']['Current']/DamageGroupMap['Engine']['Total'],.000001*DamageGroupMap['Engine']['Current'])
    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(250, 150, 150, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" >%s</text>
    ]],x_offset+240,197+y_offset,string.sub(brokenDisplay['Engine'],1,-2))


    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">System Controls:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">%.1f%% (%.1fM)</text>
    ]],x_offset,217+y_offset,x_offset+120,217+y_offset,100*DamageGroupMap['Control']['Current']/DamageGroupMap['Control']['Total'],.000001*DamageGroupMap['Control']['Current'])
    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(250, 150, 150, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" >%s</text>
    ]],x_offset+240,217+y_offset,string.sub(brokenDisplay['Control'],1,-2))

    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">Weapons:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">%.1f%% (%.1fM)</text>
    ]],x_offset,237+y_offset,x_offset+120,237+y_offset,100*DamageGroupMap['Weapons']['Current']/DamageGroupMap['Weapons']['Total'],.000001*DamageGroupMap['Weapons']['Current'])
    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(250, 150, 150, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" >%s</text>
    ]],x_offset+240,237+y_offset,string.sub(brokenDisplay['Weapons'],1,-2))

    dw[#dw+1] = string.format([[
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">Other:</text>
        <text x="%s" y="%s" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.5 ..[[vh" font-weight="bold">%.1f%% (%.1fM)</text>
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

function runFlush()
    ---------- Global Values ----------
    local clamp  = utils.clamp
    local function signedRotationAngle(normal, vecA, vecB)
        vecA = vecA:project_on_plane(normal)
        vecB = vecB:project_on_plane(normal)
        return math.atan(vecA:cross(vecB):dot(normal), vecA:dot(vecB))
    end

    if (pitchPID == nil) then
        pitchPID = pid.new(0.1, 0, 11)
        rollPID = pid.new(0.1, 0, 11)
        yawPID = pid.new(0.1, 0, 11)
    end
    ------------------------------------

    apBrakeDist,brakeTime = Kinematic.computeDistanceAndTime(speedVec:len(),0,mass + dockedMass,0,0,maxBrake)

    local pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
    local yawSpeedFactor =  1 --export: This factor will increase/decrease the player input along the yaw axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
    local rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

    local brakeSpeedFactor = 3 --export: When braking, this factor will increase the brake force by brakeSpeedFactor * velocity<br>Valid values: Superior or equal to 0.01
    local brakeFlatFactor = 1 --export: When braking, this factor will increase the brake force by a flat brakeFlatFactor * velocity direction><br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

    local autoRoll = false --export: [Only in atmosphere]<br>When the pilot stops rolling,  flight model will try to get back to horizontal (no roll)
    local autoRollFactor = 2 --export: [Only in atmosphere]<br>When autoRoll is engaged, this factor will increase to strength of the roll back to 0<br>Valid values: Superior or equal to 0.01

    local turnAssist = true --export: [Only in atmosphere]<br>When the pilot is rolling, the flight model will try to add yaw and pitch to make the construct turn better<br>The flight model will start by adding more yaw the more horizontal the construct is and more pitch the more vertical it is
    local turnAssistFactor = 2 --export: [Only in atmosphere]<br>This factor will increase/decrease the turnAssist effect<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

    local torqueFactor = 2 -- Force factor applied to reach rotationSpeed<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

    -- validate params
    pitchSpeedFactor = math.max(pitchSpeedFactor, 0.01)
    yawSpeedFactor = math.max(yawSpeedFactor, 0.01)
    rollSpeedFactor = math.max(rollSpeedFactor, 0.01)
    torqueFactor = math.max(torqueFactor, 0.01)
    brakeSpeedFactor = math.max(brakeSpeedFactor, 0.01)
    brakeFlatFactor = math.max(brakeFlatFactor, 0.01)
    autoRollFactor = math.max(autoRollFactor, 0.01)
    turnAssistFactor = math.max(turnAssistFactor, 0.01)

    -- final inputs
    local finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
    local finalRollInput = rollInput + system.getControlDeviceYawInput()
    local finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
    local finalBrakeInput = brakeInput

    -- Axis
    local worldVertical = vec3(core.getWorldVertical()) -- along gravity
    local constructUp = vec3(construct.getWorldOrientationUp())
    constructForward = vec3(construct.getWorldOrientationForward())
    constructRight = vec3(construct.getWorldOrientationRight())
    constructVelocity = vec3(construct.getWorldVelocity())
    local constructVelocityDir = vec3(constructVelocity):normalize()
    local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
    local currentRollDegAbs = math.abs(currentRollDeg)
    local currentRollDegSign = utils.sign(currentRollDeg)

    -- Rotation
    local constructAngularVelocity = vec3(construct.getWorldAngularVelocity())
    -- SETUP AUTOPILOT ROTATIONS --
    local targetAngularVelocity = vec3()

    local destVec = vec3()
    local currentYaw = 0
    local currentPitch = 0
    local targetYaw = 0
    local targetPitch = 0
    local yawChange = 0
    local pitchChange = 0
    local total_align = 0
    --local totalAngularChange = nil
    if autopilot_dest then
        destVec = vec3(autopilot_dest - constructPosition):normalize()
        local dirYaw = -math.deg(signedRotationAngle(constructUp:normalize(), destVec:normalize(), constructForward:normalize()))
        local dirPitch = math.deg(signedRotationAngle(constructRight:normalize(), destVec:normalize(), constructForward:normalize()))

        local speedYaw = -math.deg(signedRotationAngle(constructUp:normalize(), destVec:normalize(), constructVelocity))
        local speedPitch = math.deg(signedRotationAngle(constructRight:normalize(), destVec:normalize(), constructVelocity))

        local yawDiff = -math.deg(signedRotationAngle(constructUp:normalize(), constructVelocity:normalize(), constructForward:normalize()))
        local pitchDiff = math.deg(signedRotationAngle(constructRight:normalize(), constructVelocity:normalize(), constructForward:normalize()))

        if speed < 40 then
            yawChange = dirYaw
            pitchChange = dirPitch
        else
            yawChange = speedYaw
            pitchChange = speedPitch

            if math.abs(yawDiff) > 30 then yawChange = dirYaw end
            if math.abs(pitchDiff) > 30 then pitchChange = dirPitch end
        end
        total_align = math.abs(yawChange) + math.abs(pitchChange)
    end

    if autopilot and autopilot_dest ~= nil and Nav.axisCommandManager:getThrottleCommand(0) ~= 0 then
        yawPID:inject(yawChange)
        local apYawInput = yawPID:get()
        if apYawInput > AP_Max_Rotation_Factor then apYawInput = AP_Max_Rotation_Factor
        elseif apYawInput < -AP_Max_Rotation_Factor then apYawInput = -AP_Max_Rotation_Factor
        end

        pitchPID:inject(pitchChange)
        local apPitchInput = -pitchPID:get()
        if apPitchInput > AP_Max_Rotation_Factor then apPitchInput = AP_Max_Rotation_Factor
        elseif apPitchInput < -AP_Max_Rotation_Factor then apPitchInput = -AP_Max_Rotation_Factor
        end
        targetAngularVelocity = apYawInput * 2 * constructUp
                                + apPitchInput * 2 * constructRight
                                + finalPitchInput * pitchSpeedFactor * constructRight
                                + finalRollInput * rollSpeedFactor * constructForward
                                + finalYawInput * yawSpeedFactor * constructUp
    else
        targetAngularVelocity = finalPitchInput * pitchSpeedFactor * constructRight
            + finalRollInput * rollSpeedFactor * constructForward
            + finalYawInput * yawSpeedFactor * constructUp
    end

    ---------------------------------

    -- In atmosphere?
    if worldVertical:len() > 0.01 and unit.getAtmosphereDensity() > 0.0 then
        local autoRollRollThreshold = 1.0
        -- autoRoll on AND currentRollDeg is big enough AND player is not rolling
        if autoRoll == true and currentRollDegAbs > autoRollRollThreshold and finalRollInput == 0 then
            local targetRollDeg = utils.clamp(0,currentRollDegAbs-30, currentRollDegAbs+30);  -- we go back to 0 within a certain limit
            if (rollPID == nil) then
                rollPID = pid.new(autoRollFactor * 0.01, 0, autoRollFactor * 0.1) -- magic number tweaked to have a default factor in the 1-10 range
            end
            rollPID:inject(targetRollDeg - currentRollDeg)
            local autoRollInput = rollPID:get()

            targetAngularVelocity = targetAngularVelocity + autoRollInput * constructForward
        end
        local turnAssistRollThreshold = 20.0
        -- turnAssist AND currentRollDeg is big enough AND player is not pitching or yawing
        if turnAssist == true and currentRollDegAbs > turnAssistRollThreshold and finalPitchInput == 0 and finalYawInput == 0 then
            local rollToPitchFactor = turnAssistFactor * 0.1 -- magic number tweaked to have a default factor in the 1-10 range
            local rollToYawFactor = turnAssistFactor * 0.025 -- magic number tweaked to have a default factor in the 1-10 range

            -- rescale (turnAssistRollThreshold -> 180) to (0 -> 180)
            local rescaleRollDegAbs = ((currentRollDegAbs - turnAssistRollThreshold) / (180 - turnAssistRollThreshold)) * 180
            local rollVerticalRatio = 0
            if rescaleRollDegAbs < 90 then
                rollVerticalRatio = rescaleRollDegAbs / 90
            elseif rescaleRollDegAbs < 180 then
                rollVerticalRatio = (180 - rescaleRollDegAbs) / 90
            end

            rollVerticalRatio = rollVerticalRatio * rollVerticalRatio

            local turnAssistYawInput = - currentRollDegSign * rollToYawFactor * (1.0 - rollVerticalRatio)
            local turnAssistPitchInput = rollToPitchFactor * rollVerticalRatio

            targetAngularVelocity = targetAngularVelocity
                                + turnAssistPitchInput * constructRight
                                + turnAssistYawInput * constructUp
        end
    end

    -- Engine commands
    local keepCollinearity = 1 -- for easier reading
    local dontKeepCollinearity = 0 -- for easier reading
    local tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we do not go to the next priorities

    -- Rotation
    if not dampening and not autopilot then
        constructAngularVelocity = vec3(construct.getWorldAngularVelocity())*.1
    end

    local angularAcceleration = torqueFactor * (targetAngularVelocity - constructAngularVelocity)
    if not dampening then
        angularAcceleration = angularAcceleration*dampenerTorqueReduction
    end

    local airAcceleration = vec3(construct.getWorldAirFrictionAngularAcceleration())
    angularAcceleration = angularAcceleration - airAcceleration -- Try to compensate air friction
    Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)

    -- Brakes
    local brakeAcceleration = vec3()
    if autopilot then
        if autopilot_dest ~= nil and vec3(constructPosition - autopilot_dest):len() <= apBrakeDist + AP_Brake_Buffer or brakesOn or (total_align > 5 and speed < 40) then
            brakeAcceleration = -maxBrake * constructVelocityDir
            brakeInput = 1
        elseif autopilot_dest ~= nil and not brakesOn then
            brakeAcceleration = vec3()
            brakeInput = 0
        end
    else
        brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructVelocity + brakeFlatFactor * constructVelocityDir)
    end
    Nav:setEngineForceCommand('brake', brakeAcceleration)

    -- AutoNavigation regroups all the axis command by 'TargetSpeed'
    local autoNavigationEngineTags = ''
    local autoNavigationAcceleration = vec3()
    local autoNavigationUseBrake = false

    -- Longitudinal Translation
    local longitudinalEngineTags = 'thrust analog longitudinal'
    if #enabledEngineTags > 0 then
        longitudinalEngineTags = longitudinalEngineTags .. ' disengaged'
        for i,tag in pairs(enabledEngineTags) do
            longitudinalEngineTags = longitudinalEngineTags .. ',thrust analog longitudinal '.. tag
        end
    end
    local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
    local longitudinalAcceleration = vec3()

    if autopilot and autopilot_dest ~= nil and vec3(constructPosition - autopilot_dest):len() <= apBrakeDist + AP_Brake_Buffer + speed then
        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
        longitudinalAcceleration = vec3()
        Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
    elseif autopilot and autopilot_dest ~= nil and speed < maxSpeed and enginesOn then
        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,1)
        longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
        Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
    elseif autopilot and autopilot_dest ~= nil and speed >= maxSpeed - 10 then
        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
        longitudinalAcceleration = vec3()
        Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
        enginesOn = false
    else
        if (longitudinalCommandType == axisCommandType.byThrottle) then
            longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
            Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
        elseif  (longitudinalCommandType == axisCommandType.byTargetSpeed) then
            local longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal)
            autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
            autoNavigationAcceleration = autoNavigationAcceleration + longitudinalAcceleration
            if (Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) == 0 or -- we want to stop
                Nav.axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - Nav.axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) -- if the longitudinal velocity would need some braking
            then
                autoNavigationUseBrake = true
            end

        end
    end

    -- Lateral Translation
    local lateralStrafeEngineTags = 'thrust analog lateral'
    local lateralCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral)
    if (lateralCommandType == axisCommandType.byThrottle) then
        local lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
        Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
    elseif  (lateralCommandType == axisCommandType.byTargetSpeed) then
        local lateralAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
        autoNavigationAcceleration = autoNavigationAcceleration + lateralAcceleration
    end

    -- Vertical Translation
    local verticalStrafeEngineTags = 'thrust analog vertical'
    local verticalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical)
    if (verticalCommandType == axisCommandType.byThrottle) then
        local verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
        Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
    elseif  (verticalCommandType == axisCommandType.byTargetSpeed) then
        local verticalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags
        autoNavigationAcceleration = autoNavigationAcceleration + verticalAcceleration
    end

    -- Auto Navigation (Cruise Control)
    if (autoNavigationAcceleration:len() > constants.epsilon) then
        if (brakeInput ~= 0 or autoNavigationUseBrake or math.abs(constructVelocityDir:dot(constructForward)) < 0.95)  -- if the velocity is not properly aligned with the forward
        then
            autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
        end
        Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
    end

    -- Rockets
    Nav:setBoosterCommand('rocket_engine')

    -- Disable Auto-Pilot when destination is reached --
    if autopilot and autopilot_dest ~= nil and vec3(constructPosition - autopilot_dest):len() <= apBrakeDist + 1200 + AP_Brake_Buffer and speed < 1000 then
        brakeInput = brakeInput + 1
        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
        Nav:setEngineForceCommand(longitudinalEngineTags, vec3(), keepCollinearity)
        if not route then
            system.print('-- Autopilot complete --')
            autopilot_dest_pos = nil
            autopilot = false
        elseif route and speed < 40 and routes[route][route_pos+1] ~= nil and vec3(constructPosition - autopilot_dest):len() <= 1200+AP_Brake_Buffer then
            system.print('-- Route pilot point complete --')
            system.print('-- Starting next point --')
            route_pos = route_pos+1
            autopilot_dest = vec3(convertWaypoint(routes[route][route_pos]))
            autopilot_dest_pos = routes[route][route_pos]
            system.print('-- Route pilot destination set --')
            brakesOn = false
            enginesOn = true
            system.print(routes[route][route_pos])
        elseif route and route_pos == #routes[route] then
            system.print('-- Route pilot complete --')
            autopilot_dest_pos = nil
            autopilot = false
            route = nil
            route_pos = nil
            db_1.clearValue('route')
            db_1.clearValue('route_pos')
            db_1.setIntValue('record',0)
        end
    end
    ---------------------------------------------------
end

function runTimerScreen()
    arkTime = system.getArkTime()

    local cFPS = FPS_COUNTER/(arkTime - FPS_INTERVAL)
    if fps_data['avg'] == nil then fps_data['avg'] = cFPS end
    FPS = string.format('%.1f | %.1f',cFPS,fps_data['avg'])
    FPS_COUNTER = 0
    FPS_INTERVAL = arkTime
    
    if debug then
        fps_data['count'] = fps_data['count'] + 1
        fps_data['sum'] = fps_data['sum'] + cFPS
        if cFPS > fps_data['max'] then fps_data['max'] = cFPS end
        if cFPS < fps_data['min'] and cFPS > 5 then fps_data['min'] = cFPS end
        if fps_data['avg'] ~= cFPS then
            fps_data['avg'] = (fps_data['sum'])/fps_data['count']
        end
    end
    bgColor = ''
    lineColor = ''
    fontColor = ''
    if inSZ then 
        bgColor='rgba(25, 25, 50, 0.35)'
        lineColor='rgba(150, 175, 185, .75)'
        fontColor='rgba(225, 250, 265, 1)' 
    else 
        bgColor='rgba(175, 75, 75, 0.30)'
        lineColor='rgba(220, 50, 50, .75)'
        fontColor='rgba(225, 250, 265, 1)'
    end
    
    -- Check player seated status --
    seated = player.isSeated()
    if seated and not player.isFrozen() then
        player.freeze(1)
    elseif not seated and player.isFrozen() then
        player.freeze(0)
    end
    ----------------------------------
    
    cName = construct.getName()
    if transponder_1 then tags = transponder_1.getTags() end
    
    ----------------------------------
    
    
    -- Shield Updates --
    if shield_1 then
        srp = shield_1.getResistancesPool()
        csr = shield_1.getResistances()
        rcd = shield_1.getResistancesCooldown()
        rem = shield_1.getResistancesRemaining()
        srr = shield_1.getStressRatioRaw()
        ventCD = shield_1.getVentingCooldown()
    
        if shieldProfile == 'auto' then
            if srr[1] == 0 and srr[2] == 0 and srr[3] == 0 and srr[4] == 0 then -- No stress
                dmgTick = nil
                if (csr[1] == srp/4 and csr[2] == srp/4 and csr[3] == srp/4 and csr[4] == srp/4) or rcd ~= 0 then
                    --No change
                else
                    shield_1.setResistances(srp/4,srp/4,srp/4,srp/4)
                end
            elseif dmgTick then
                if math.abs(arkTime - dmgTick) >= initialResistWait then
                    if not ((csr[1] == (srp*srr[1]) and csr[2] == (srp*srr[2]) and csr[3] == (srp*srr[3]) and csr[4] == (srp*srr[4])) or rcd ~= 0) then -- If ratio hasn't change, or timer is not up, don't waste the resistance change timer.
                        shield_1.setResistances(srp*srr[1],srp*srr[2],srp*srr[3],srp*srr[4])
                    end
                end
            end
        elseif not resistProfiles[shieldProfile] then
            system.print('-- Detected invalid shield profile --')
            shieldProfile = 'auto'
        else
            if not (csr[1] == srp*resistProfiles[shieldProfile]['am']
                and csr[2] == srp*resistProfiles[shieldProfile]['em']
                and csr[3] == srp*resistProfiles[shieldProfile]['kn']
                and csr[4] == srp*resistProfiles[shieldProfile]['th']) then
                if not rcd ~= 0 then
                    shield_1.setResistances(
                        srp*resistProfiles[shieldProfile]['am'],
                        srp*resistProfiles[shieldProfile]['em'],
                        srp*resistProfiles[shieldProfile]['kn'],
                        srp*resistProfiles[shieldProfile]['th']
                    )
                end
            end
        end
    
        shp = shield_1.getShieldHitpoints()
        venting = shield_1.isVenting()
        if not venting and shp == 0 and autoVent then
            shield_1.startVenting()
        elseif not shield_1.isActive() and not venting or vec3(homeBaseVec - constructPosition):len() < homeBaseDistance*1000 then
            if homeBaseVec then
                if vec3(homeBaseVec - constructPosition):len() >= homeBaseDistance*1000 then
                    shield_1.activate()
                else
                    shield_1.deactivate()
                end
            else
                shield_1.activate()
            end
        end
    
        if core then coreHP = (core.getMaxCoreStress()-core.getCoreStress())/core.getMaxCoreStress() end
    end
    -- End Shield Updates --
    
    
    -- Engine Tag Filtering --
    local engTable = {}
    local tempTag = nil
    local offset = 0
    for i,tag in pairs(enabledEngineTags) do
        if i % 2 == 0 then 
            engTable[#engTable+1] = [[
                <text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (i-2)*.008) * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-weight="bold" font-size="]].. font_size_ratio ..[[vh">]]..tag.. ',' ..tempTag..[[</text>    
            ]]
            tempTag = nil
            offset = offset + 1
        else
            tempTag = tag
        end
    end
    if tempTag ~= nil then 
        engTable[#engTable+1] = [[<text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (offset)*.016) * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-weight="bold" font-size="]].. font_size_ratio ..[[vh">]]..tempTag..[[</text>]]
    end
    if #engTable == 0 then
        engTable[#engTable+1] = [[<text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (offset)*.008) * screenHeight) ..[[" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio ..[[vh">ALL</text>]]
    end
    enabledEngineTagsStr = table.concat(engTable,'')
    ----------------------------
    
    -- Safe Zone Distance --
    inSZ = not construct.isInPvPZone()
    SZD = math.abs(construct.getDistanceToSafeZone())
    
    SZDStr = ''
    if SZD < 1000 then SZDStr = string.format('%.2f m',SZD)
    elseif SZD < 100000 then SZDStr = string.format('%.2f km',SZD/1000)
    else SZDStr = string.format('%.2f su',SZD*.000005)
    end
    ---------------------------
    
    -- Planet Location Updates --
    closestPlanetName,closestPlanetDist = closestPlanet()
    if cr == nil then
        cr = coroutine.create(closestPipe)
    elseif cr ~= nil then
        if coroutine.status(cr) == "suspended" then
            coroutine.resume(cr)
        elseif coroutine.status(cr) == "dead" then
            cr = nil
        end
    end
    closestPipeStr = string.format('%s (%s)',closestPipeName,formatNumber(closestPipeDistance,'distance'))
    closestPlanetStr = string.format('%s (%s)',closestPlanetName,formatNumber(closestPlanetDist,'distance'))
    ---- End Planet Updates ----
    
    ------- Warp Drive Brake activation ------
    if construct.isWarping() then
        brakeInput = 1
        brakesOn = true
    end
    -----------------------------------------
    -- Throttle Status --
    if Nav.axisCommandManager:getMasterMode() == controlMasterModeId.travel then mode = 'Throttle ' .. tostring(Nav.axisCommandManager:getThrottleCommand(0) * 100) .. '%' modeBG = bgColor
    else mode = 'Cruise '  .. string.format('%.2f',Nav.axisCommandManager:getTargetSpeed(0)) .. ' km/h' modeBG = 'rgba(99, 250, 79, 0.5)'
    end
    ---------------------
    
    CCSPercent = 0
    if coreHP ~= 0 then
        CCSPercent = 100*coreHP
    end
    
    if CCSPercent < 25 and CCSPercent > 1 then
        if db_1 then db_1.clearValue('homeBaseLocation') end
        if transponder_1 then transponder_1.setTags({}) end
    elseif CCSPercent == 0 and shieldPercent < 5 then
        if db_1 then db_1.clearValue('homeBaseLocation') end
        if transponder_1 then transponder_1.setTags({}) end
    end
    
    shieldPercent = 0
    shieldPercent = shp/maxSHP*100
    
    if shieldPercent < 15 then
        shieldWarningHTML = string.format([[
            <svg width="115.2" height="64.8" x="792" y="648" style="fill: red;">
                %s
            </svg>
            <text x="894" y="691.2" style="fill: red" font-size="]].. font_size_ratio+2.42 ..[[vh" font-weight="bold">SHIELD CRITICAL</text>
        ]],warningSymbols['svgCritical'])
    elseif shieldPercent < 30 then
        shieldWarningHTML = string.format([[
            <svg width="115.2" height="64.8" x="792" y="648" style="fill: orange;">
                %s
            </svg>
            <text x="894" y="691.2" style="fill: orange" font-size="]].. font_size_ratio+2.42 ..[[vh" font-weight="bold">SHIELD LOW</text>
        ]],warningSymbols['svgWarning'])
    else
        shieldWarningHTML = ''
    end
    
    local placement = 0
    local temp = {}
    for i = 4, CCSPercent, 4 do 
        temp[#temp+1] = string.format([[<line style="stroke-width: 5px; stroke-miterlimit: 1; stroke: rgb(60, 255, 60); fill: none;" x1="%s" y1="56" x2="%s" y2="72" bx:origin="0 0.096154"/>]],
        5+placement,5+placement)
        placement = placement + 10
    end
    ccsHTML = table.concat(temp,'')
    
    ventHTML = ''
    if shield_1 then
        if ventCD > 0 then
            ventHTML = string.format([[
                <text style="fill: rgb(255, 60, 60); font-family: Arial; font-size: 11.8px; paint-order: fill; white-space: pre;" x="66" y="91.01" bx:origin="-2.698544 2.296589">Vent Cooldown: </text>
                <text style="fill: rgb(255, 60, 60); font-family: Arial; font-size: 11.8px; paint-order: fill; white-space: pre;" x="151" y="91.01" bx:origin="-2.698544 2.296589">%.2fs</text>
            ]],ventCD)
        end
    end
    
    local placement = 0
    temp = {}
    for i = 4, shieldPercent, 4 do 
        temp[#temp+1] = string.format([[<line style="stroke-width: 5px; stroke-miterlimit: 1; stroke: rgb(25, 247, 255); fill: none;" x1="%s"   y1="42" x2="%s"   y2="55" bx:origin="0 0.096154"/>]],
        5+placement,5+placement)
        placement = placement + 10
    end
    shieldHTML = table.concat(temp,'')
    
    if not venting or not shield_1 then
        warnings['venting'] = nil
    else 
        warnings['venting'] = 'svgCritical'
    end
    
    if shield_1 then
        amS = srr[1]
        emS = srr[2]
        knS = srr[3]
        thS = srr[4]
        amR = csr[1]/srp
        emR = csr[2]/srp
        knR = csr[3]/srp
        thR = csr[4]/srp
        shield_resist_cd = shield_1.getResistancesCooldown()
    end
    
    if showHelp then
        DamageGroupMap = {}
        DamageGroupMap['Engine'] = {}
        DamageGroupMap['Engine']['Total'] = 0
        DamageGroupMap['Engine']['Current'] = 0
    
        DamageGroupMap['Control'] = {}
        DamageGroupMap['Control']['Total'] = 0
        DamageGroupMap['Control']['Current'] = 0
    
        DamageGroupMap['Weapons'] = {}
        DamageGroupMap['Weapons']['Total'] = 0
        DamageGroupMap['Weapons']['Current'] = 0
    
        DamageGroupMap['Misc'] = {}
        DamageGroupMap['Misc']['Total'] = 0
        DamageGroupMap['Misc']['Current'] = 0
    
        brokenElements = {}
        brokenElements['Engine'] = {}
        brokenElements['Control'] = {}
        brokenElements['Weapons'] = {}
    
        brokenDisplay = {}
        brokenDisplay['Engine'] = ''
        brokenDisplay['Control'] = ''
        brokenDisplay['Weapons'] = ''
    
        local itemClasses = {}
        for _,id in pairs(core.getElementIdList()) do
            local itemClass = core.getElementClassById(id)
            local itemDisplay = core.getElementDisplayNameById(id)
            if string.find(string.lower(itemClass),'engine')
                or string.find(string.lower(itemClass),'brake') then
                DamageGroupMap['Engine']['Total'] = DamageGroupMap['Engine']['Total'] + core.getElementMaxHitPointsById(id)
                DamageGroupMap['Engine']['Current'] = DamageGroupMap['Engine']['Current'] + core.getElementHitPointsById(id)
                if not (core.getElementHitPointsById(id) > 0) then
                    if brokenElements['Engine'][itemDisplay] == nil then
                        brokenElements['Engine'][itemDisplay] = 1
                    else
                        brokenElements['Engine'][itemDisplay] = brokenElements['Engine'][itemDisplay] + 1
                    end
                end
            elseif string.find(string.lower(itemClass),'control')
                or string.find(string.lower(itemClass),'pvpseat')
                or string.find(string.lower(itemClass),'fuel') then
                DamageGroupMap['Control']['Total'] = DamageGroupMap['Control']['Total'] + core.getElementMaxHitPointsById(id)
                DamageGroupMap['Control']['Current'] = DamageGroupMap['Control']['Current'] + core.getElementHitPointsById(id)
                if not (core.getElementHitPointsById(id) > 0) then
                    if brokenElements['Control'][itemDisplay] == nil then
                        brokenElements['Control'][itemDisplay] = 1
                    else
                        brokenElements['Control'][itemDisplay] = brokenElements['Control'][itemDisplay] + 1
                    end
                end
            elseif string.find(string.lower(itemClass),'ammocontainer')
                or string.find(string.lower(itemClass),'radar')
                or string.find(string.lower(itemClass),'weapon') then
                DamageGroupMap['Weapons']['Total'] = DamageGroupMap['Weapons']['Total'] + core.getElementMaxHitPointsById(id)
                DamageGroupMap['Weapons']['Current'] = DamageGroupMap['Weapons']['Current'] + core.getElementHitPointsById(id)
                if not (core.getElementHitPointsById(id) > 0 ) then
                    if brokenElements['Weapons'][itemDisplay] == nil then
                        brokenElements['Weapons'][itemDisplay] = 1
                    else
                        brokenElements['Weapons'][itemDisplay] = brokenElements['Weapons'][itemDisplay] + 1
                    end
                end
            else
                DamageGroupMap['Misc']['Total'] = DamageGroupMap['Misc']['Total'] + core.getElementMaxHitPointsById(id)
                DamageGroupMap['Misc']['Current'] = DamageGroupMap['Misc']['Current'] + core.getElementHitPointsById(id)
            end
        end
        for k,v in pairs(brokenElements) do
            for dk,dv in pairs(v) do
                if brokenDisplay[k] == nil then
                    brokenDisplay[k] = 'Broken: '
                end
                brokenDisplay[k] = brokenDisplay[k] .. string.format(' %sx %s,',dv,dk)
            end
        end
    end
    
    fuelHTML = profile(fuelWidget,'fuelWidget')
    shipNameHTML = profile(shipNameWidget,'shipNameWidget')
    dpsHTML = profile(dpsWidget,'dpsWidget')
    systemCheckHTML = profile(systemCheckWidget,'systemCheckWidget')
end

function runUpdate()
    Nav:update()
    FPS_COUNTER = FPS_COUNTER + 1
    ticker = ticker + 1

    speedVec = vec3(constructVelocity)
    speed = speedVec:len() * 3.6
    if speed < 50 then speedVec = vec3(constructForward) end
    if route and routes[route][route_pos] == autopilot_dest_pos then
        maxSpeed = route_speed
    else
        maxSpeed = construct.getMaxSpeed() * 3.6
    end
    gravity = core.getGravityIntensity()
    mass = construct.getMass()
    constructPosition = vec3(construct.getWorldPosition())
    maxBrake = json.decode(unit.getWidgetData()).maxBrake
    if maxBrake == nil then maxBrake = 0 end
    maxThrustTags = 'thrust'
    if #enabledEngineTags > 0 then
        maxThrustTags = maxThrustTags .. ' disengaged'
        for i,tag in pairs(enabledEngineTags) do
            maxThrustTags = maxThrustTags .. ',thrust '.. tag
        end
    end
    maxThrust = construct.getMaxThrustAlongAxis(maxThrustTags,construct.getOrientationForward())
    maxSpaceThrust = math.abs(maxThrust[3])

    dockedMass = 0
    for _,id in pairs(construct.getDockedConstructs()) do 
        dockedMass = dockedMass + construct.getDockedConstructMass(id)
    end
    for _,id in pairs(construct.getPlayersOnBoard()) do 
        dockedMass = dockedMass + construct.getBoardedPlayerMass(id)
    end
    brakeDist,brakeTime = Kinematic.computeDistanceAndTime(speedVec:len(),0,mass + dockedMass,0,0,maxBrake)
    accel = vec3(construct.getWorldAcceleration()):len()

    -- SCREEN UPDATES --
    if autopilot_dest and speed > 1000 then
        local balance = vec3(autopilot_dest - constructPosition):len()/(speed/3.6) --meters/(meter/second) == seconds
        local seconds = balance % 60
        balance = balance // 60
        local minutes = balance % 60
        balance = balance // 60
        local hours = balance % 60
        apHTML = [[
            <text x="537.6" y="59.4" style="fill: rgba(200, 225, 235, 1)" font-size="]].. font_size_ratio+0.42 ..[[vh" font-weight="bold">ETA: ]]..string.format('%.0f:%.0f.%.0f',hours,minutes,seconds)..[[</text>
        ]]
    end

    apBG = bgColor
    if autopilot then apBG = 'rgba(99, 250, 79, 0.5)' apStatus = 'Engaged' if route and routes[route][route_pos] == autopilot_dest_pos then apStatus = route end end
    if not autopilot and autopilot_dest ~= nil then apStatus = 'Set' if route and routes[route][route_pos] == autopilot_dest_pos then apStatus = route end end

    if route_pos and route_pos ~= db_1.getIntValue('route_pos',route_pos) then db_1.setIntValue('route_pos',route_pos) end
    -- END SCREEN UPDATES --

    -- Generate Screen overlay --
    if speed ~= nil and ticker % 3 == 0 then
        ticker = 0
        profile(generateScreen,'generateScreen')
    end
    -----------------------------
end