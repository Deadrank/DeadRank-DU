json = require("dkjson")
Atlas = require('atlas')


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
        -- somewhere along the warp pipe. Let's calculate
        -- that distance
        else
            dist = vec3(AE:cross(BE)):len()/vec3(AB):len()
            distType = 'PIPE'
        end
        return dist,distType
    end
    return nil,nil
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

function closestPipe()
    pipes = {}
    for name,center in pairs(planets) do
            pipes[string.format('%s - %s',closestPlanetName,name)] = {}
            table.insert(pipes[string.format('%s - %s',closestPlanetName,name)],planets[closestPlanetName])
            table.insert(pipes[string.format('%s - %s',closestPlanetName,name)],center)
    end
    local cPipe = 'None'
    local cDist = 9999999999
    local cLoc = vec3(construct.getWorldPosition())
    for pName,vecs in pairs(pipes) do
        local tempDist,tempType = pipeDist(vecs[1],vecs[2],cLoc,false)
        if tempDist ~= nil then
            if cDist > tempDist then
                cDist = tempDist
                cPipe = pName
            end
        end
    end
    return cPipe,cDist
end

function contains(tablelist, val)
    for i=1,#tablelist do
       if tablelist[i] == val then 
          return true
       end
    end
    return false
 end


 function WeaponWidgetCreate()
    if type(weapon) == 'table' and #weapon > 0 then
        local WeaponPanaelIdList = {}
        for i = 1, #weapon do
            if i%2 ~= 0 then
            table.insert(WeaponPanaelIdList, system.createWidgetPanel(''))
            end
                local WeaponWidgetDataId = weapon[i].getDataId()
                local WeaponWidgetType = weapon[i].getWidgetType()
                system.addDataToWidget(WeaponWidgetDataId, system.createWidget(WeaponPanaelIdList[#WeaponPanaelIdList], WeaponWidgetType))
        end
    end
end

function brakeWidget()
    local brakeON = brakeInput > 0
    local bw = ''
    if brakeON then
        bw = [[
            <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
                <rect x="46vw" y="28vh" rx="10" ry="10" width="7vw" height="3vh" style="fill:rgba(29, 63, 255, 0.9);stroke:rgba(255, 60, 60, 0.9);stroke-width:5;" />
                <text x="]].. tostring(.47 * screenWidth) ..[[" y="]].. tostring(.30 * screenHeight) ..[[" style="fill: rgb(255, 60, 60)" font-size=".8vw" font-weight="bold">Brakes Engaged</text>
            </svg>
        ]]
    end
    return bw
end

function flightWidget()
    if Nav.axisCommandManager:getMasterMode() == controlMasterModeId.travel then mode = 'Throttle ' .. tostring(Nav.axisCommandManager:getThrottleCommand(0) * 100) .. '%' modeBG = bgColor
    else mode = 'Cruise '  .. string.format('%.2f',Nav.axisCommandManager:getTargetSpeed(0)) .. ' km/h' modeBG = 'rgba(99, 250, 79, 0.5)'
    end
    local sw = ''
    if maxBrakeStr ~= nil then
        --Center Top
        sw = [[
            <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
                <path d="
                M ]] .. tostring(.31*screenWidth) .. ' ' .. tostring(.001*screenHeight) ..[[ 
                L ]] .. tostring(.69*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
                L ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[
                L ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[
                L ]] .. tostring(.31*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [["
                stroke="]]..lineColor..[[" stroke-width="2" fill="]]..bgColor..[[" />]]
        

        -- Right Side
        sw = sw .. [[<path d="
                M ]] .. tostring(.6635*screenWidth) .. ' ' .. tostring(.028*screenHeight) .. [[ 
                L ]] .. tostring(.691*screenWidth) .. ' ' .. tostring(.0387*screenHeight) .. [[
                L ]] .. tostring(.80*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
                L ]] .. tostring(.69*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
                L ]] .. tostring(.6635*screenWidth) .. ' ' .. tostring(.0185*screenHeight) .. [[
                L ]] .. tostring(.6635*screenWidth) .. ' ' .. tostring(.028*screenHeight) .. [["
                stroke="]]..lineColor..[[" stroke-width="1" fill="]].. modeBG ..[[" />]]
                
        sw = sw .. [[<path d="
                M ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[ 
                L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.0645*screenHeight) .. [["
                stroke="]]..lineColor..[[" stroke-width="1" fill="none" />

                <path d="
                M ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[ 
                L ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.0645*screenHeight) .. [["
                stroke="]]..lineColor..[[" stroke-width="1" fill="none" />

                <path d="
                M ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[ 
                L ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.0645*screenHeight) .. [["
                stroke="]]..lineColor..[[" stroke-width="1" fill="none" />

                <text x="]].. tostring(.4 * screenWidth) ..[[" y="]].. tostring(.015 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Speed: ]] .. speedStr .. [[</text>
                <text x="]].. tostring(.4 * screenWidth) ..[[" y="]].. tostring(.0325 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Current Accel: ]] .. accelStr .. [[</text>
                <text x="]].. tostring(.4 * screenWidth) ..[[" y="]].. tostring(.05 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Brake Dist: ]] .. brakeDistStr .. [[</text>
                
                <text x="]].. tostring(.502 * screenWidth) ..[[" y="]].. tostring(.015 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Max Speed: ]] .. maxSpeedStr .. [[</text>
                <text x="]].. tostring(.502 * screenWidth) ..[[" y="]].. tostring(.0325 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Max Accel: ]] .. maxThrustStr ..[[</text>
                <text x="]].. tostring(.502 * screenWidth) ..[[" y="]].. tostring(.05 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Max Brake: ]] .. maxBrakeStr .. [[</text>

                <text x="]].. tostring(.37 * screenWidth) ..[[" y="]].. tostring(.015 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Mass </text>
                <text x="]].. tostring(.355 * screenWidth) ..[[" y="]].. tostring(.028 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">]]..massStr..[[</text>

                <text x="]].. tostring(.612 * screenWidth) ..[[" y="]].. tostring(.015 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Gravity </text>
                <text x="]].. tostring(.612 * screenWidth) ..[[" y="]].. tostring(.028 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">]].. gravityStr ..[[</text>

                <text x="]].. tostring(.684 * screenWidth) ..[[" y="]].. tostring(.028 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold" transform="rotate(-10,]].. tostring(.684 * screenWidth) ..",".. tostring(.028 * screenHeight) ..[[)">]].. mode ..[[</text>

                

            </svg>
            ]]
    else
        sw = ''
    end
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
        <svg width="100%%" height="100%%" style="position: absolute;left:0%%;top:0%%;font-family: Calibri;">
            <linearGradient id="sFuel" x1="0%%" y1="0%%" x2="100%%" y2="0%%">
            <stop offset="%.1f%%" style="stop-color:rgba(99, 250, 79, 0.95);stop-opacity:.95" />
            <stop offset="%.1f%%" style="stop-color:rgba(255, 10, 10, 0.5);stop-opacity:.5" />
            </linearGradient>]],sFuelPercent,sFuelPercent)
        
    fw = fw .. [[
        <path d="
        M ]] .. tostring(.336*screenWidth) .. ' ' .. tostring(.0185*screenHeight) .. [[ 
        L ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[
        L ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[
        L ]] .. tostring(.6635*screenWidth) .. ' ' .. tostring(.0185*screenHeight) .. [[
        L ]] .. tostring(.6635*screenWidth) .. ' ' .. tostring(.028*screenHeight) .. [[
        L ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.0645*screenHeight) .. [[
        L ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.0645*screenHeight) .. [[
        L ]] .. tostring(.3365*screenWidth) .. ' ' .. tostring(.028*screenHeight) .. [[
        L ]] .. tostring(.336*screenWidth) .. ' ' .. tostring(.0185*screenHeight) .. [["
    stroke="]]..lineColor..[[" stroke-width="2" fill="]]..bgColor..[[" />

    <path d="
        M ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[
        L ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[
        L ]] .. tostring(.61*screenWidth) .. ' ' .. tostring(.0645*screenHeight) .. [[
        L ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.0645*screenHeight) .. [[
        L ]] .. tostring(.39*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [["
    stroke="]]..lineColor..[[" stroke-width="1" fill="url(#sFuel)" />

    <path d="
        M ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[ 
        L ]] .. tostring(.5*screenWidth) .. ' ' .. tostring(.070*screenHeight) .. [["
    stroke="black" stroke-width="1.5" fill="none" />

    <path d="
        M ]] .. tostring(.555*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[ 
        L ]] .. tostring(.555*screenWidth) .. ' ' .. tostring(.070*screenHeight) .. [["
    stroke="black" stroke-width="1.5" fill="none" />

    <path d="
        M ]] .. tostring(.445*screenWidth) .. ' ' .. tostring(.055*screenHeight) .. [[ 
        L ]] .. tostring(.445*screenWidth) .. ' ' .. tostring(.070*screenHeight) .. [["
    stroke="black" stroke-width="1.5" fill="none" />

    <text x="]].. tostring(.39 * screenWidth) ..[[" y="]].. tostring(.08 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">Fuel: ]] .. curFuelStr .. [[</text>
    <!--text x="]].. tostring(.445 * screenWidth) ..[[" y="]].. tostring(.08 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">25%</text>
    <text x="]].. tostring(.5 * screenWidth) ..[[" y="]].. tostring(.08 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">50%</text>
    <text x="]].. tostring(.555 * screenWidth) ..[[" y="]].. tostring(.08 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">75%</text-->


    ]]

    if fuelTankWarning or fuelWarning then
        local warningText = 'Fuel level below 20%'
        if not fuelWarning then warningText = 'Fuel tank is below 20%' end
        fw = fw .. [[
                <rect x="45vw" y="9vh" rx="10" ry="10" width="9vw" height="2.25vh" style="fill:rgba(50, 50, 50, 0.5);stroke:rgba(255, 60, 60, 0.9);stroke-width:5;opacity:0.95;" />
                <text x="]].. tostring(.455 * screenWidth) ..[[" y="]].. tostring(.105 * screenHeight) ..[[" style="fill: rgb(255, 60, 60);" font-size=".8vw" font-weight="bold">]]..warningText..[[</text>
        ]]
    end

    fw = fw .. '</svg>'

    return fw
end

function apStatusWidget()
    local bg = bgColor
    local apStatus = 'inactive'
    if auto_follow then bg = 'rgba(99, 250, 79, 0.5)' apStatus = 'following' end
    if autopilot then bg = 'rgba(99, 250, 79, 0.5)' apStatus = 'Engaged' end
    if not autopilot and autopilot_dest ~= nil then apStatus = 'Set' end
    local apw = [[
            <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
            -- Left Top Side]]
    apw = apw .. [[<path d="
        M ]] .. tostring(.3365*screenWidth) .. ' ' .. tostring(.028*screenHeight) .. [[ 
        L ]] .. tostring(.309*screenWidth) .. ' ' .. tostring(.0387*screenHeight) .. [[
        L ]] .. tostring(.2*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
        L ]] .. tostring(.31*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
        L ]] .. tostring(.3365*screenWidth) .. ' ' .. tostring(.0185*screenHeight) .. [[
        L ]] .. tostring(.3365*screenWidth) .. ' ' .. tostring(.028*screenHeight) .. [["
        stroke="]]..lineColor..[[" stroke-width="1" fill="]]..bg..[[" />
        
        <text x="]].. tostring(.25 * screenWidth) ..[[" y="]].. tostring(.012 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold" transform="rotate(10,]].. tostring(.25 * screenWidth) ..",".. tostring(.012 * screenHeight) ..[[)">AutoPilot: ]]..apStatus..[[</text>

        
        </svg>]]
    return apw
end

function positionInfoWidget()
    local piw = [[
            <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
            -- Far Left Top Side]]
    piw = piw .. [[<path d="
        M ]] .. tostring(.0*screenWidth) .. ' ' .. tostring(.0155*screenHeight) .. [[ 
        L ]] .. tostring(.115*screenWidth) .. ' ' .. tostring(.0155*screenHeight) .. [[
        L ]] .. tostring(.124*screenWidth) .. ' ' .. tostring(.025*screenHeight) .. [[
        L ]] .. tostring(.25*screenWidth) .. ' ' .. tostring(.035*screenHeight) .. [[
        L ]] .. tostring(.275*screenWidth) .. ' ' .. tostring(.027*screenHeight) .. [[
        L ]] .. tostring(.2*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
        L ]] .. tostring(.0*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
        L ]] .. tostring(.0*screenWidth) .. ' ' .. tostring(.0155*screenHeight) .. [[ 
        "
        stroke="]]..lineColor..[[" stroke-width="1" fill="]]..bgColor..[[" />

        <path d="
        M ]] .. tostring(1.0*screenWidth) .. ' ' .. tostring(.0155*screenHeight) .. [[ 
        L ]] .. tostring(.885*screenWidth) .. ' ' .. tostring(.0155*screenHeight) .. [[
        L ]] .. tostring(.876*screenWidth) .. ' ' .. tostring(.025*screenHeight) .. [[
        L ]] .. tostring(.75*screenWidth) .. ' ' .. tostring(.035*screenHeight) .. [[
        L ]] .. tostring(.725*screenWidth) .. ' ' .. tostring(.027*screenHeight) .. [[
        L ]] .. tostring(.8*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
        L ]] .. tostring(1.0*screenWidth) .. ' ' .. tostring(.001*screenHeight) .. [[
        L ]] .. tostring(1.0*screenWidth) .. ' ' .. tostring(.0155*screenHeight) .. [[ 
        "
        stroke="]]..lineColor..[[" stroke-width="1" fill="]]..bgColor..[[" />
        
        <text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring(.01 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".6vw">Remote Version: ]]..hudVersion..[[</text>
        <text x="]].. tostring(.125 * screenWidth) ..[[" y="]].. tostring(.011 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Nearest Planet</text>
        <text x="]].. tostring(.15 * screenWidth) ..[[" y="]].. tostring(.022 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".7vw" >]]..closestPlanetStr..[[</text>
        
        <text x="]].. tostring(.82 * screenWidth) ..[[" y="]].. tostring(.011 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw" font-weight="bold">Nearest Pipe</text>
        <text x="]].. tostring(.78 * screenWidth) ..[[" y="]].. tostring(.022 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".7vw" >]]..closestPipeStr..[[</text>

        <text x="]].. tostring(.90 * screenWidth) ..[[" y="]].. tostring(.011 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".7vw" font-weight="bold">Safe Zone Distance: ]]..SZDStr..[[</text>

        </svg>]]
    return piw
end

function engineWidget()
    local ew = [[
        <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
            <text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring(.045 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">Controlling Engine tags</text>
            ]]..enabledEngineTagsStr..[[
        </svg>
    ]]
    return ew
end

function planetARWidget()
    local arw = planetAR
    arw = arw .. [[
        <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
            <text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring(.03 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">Augmented Reality Mode: ]]..AR_Mode..[[</text>
        </svg>
    ]]

    return arw
end

function helpWidget()
    local hw = ''
    if showHelp then
        hw = [[
            <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
            <rect x="]].. tostring(.125 * screenWidth) ..[[" y="]].. tostring(.125 * screenHeight) ..[[" rx="15" ry="15" width="60vw" height="22vh" style="fill:rgba(50, 50, 50, 0.9);stroke:white;stroke-width:5;opacity:0.9;" />
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.15 * screenHeight) ..[[" style="fill: ]]..'orange'..[[" font-size=".8vw" font-weight="bold">
                OPTION KEY BINDINGS</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.17 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+1: Toggle help screen</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.19 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+2: Toggle Augmented reality view mode (NONE, ALL, PLANETS, CUSTOM) HUD Loads custom waypoints for AR from "autoconf/custom/AR_Waypoints.lua"</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.21 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+3: Clear all engine tag filters (i.e. all engines controlled by throttle) (Alt+shift+3 toggles through predefined tags)</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.23 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+4: Engage AutoPilot to current AP destination (shown in VR)</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.25 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+5: Engage Follow Mode. Ship will attempt to mirror the speed of the target construct (or close the gap if to far away). REQUIRES an identified and targeted construct in radar</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.27 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+6: Set AutoPilot destination to the nearest safe zone</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.29 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+7: Toggles radar widget filtering mode (Show all, Show Enemy, Show Identified, Show Friendly)</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.31 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+8: Toggle Shield vent. Start venting if available. Stop venting if currently venting</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.33 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                Alt+9: Toggle between Cruise and Throttle control modes</text>
            </rect>
            
            <rect x="]].. tostring(.125 * screenWidth) ..[[" y="]].. tostring(.365 * screenHeight) ..[[" rx="15" ry="15" width="60vw" height="22vh" style="fill:rgba(50, 50, 50, 0.9);stroke:white;stroke-width:5;opacity:0.9;" />
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.39 * screenHeight) ..[[" style="fill: ]]..'orange'..[[" font-size=".8vw" font-weight="bold">
                Lua Commands</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.41 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                disable &lt;tag&gt;: Disables control of engines tagged with the <tag> parameter</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.43 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                enable &lt;tag&gt;: Enables control of engines tagged with <tag></text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.45 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                warpFrom &lt;start position&gt; &lt;destination position&gt;: Calculates best warp bath from the <start position> (positions are in ::pos{} format)</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.47 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                warp &lt;destination position&gt;: Calculates best warp path from current postion to destination (position is in ::pos{} format)</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.49 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                addWaypoint &lt;waypoint1&gt; &lt;Name&gt;: Adds temporary AR points when enabled. Requires a position tag. Optionally, you can also optionally add a custom name as well</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.51 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                delWaypoint &lt;name&gt;: Removes the specified temporary AR point</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.53 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                addShips db: Adds all ships currently on radar to the friendly construct list</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.55 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                code &lt;transponder code&gt;: Adds the transponder tag to the transponder. "delcode &lt;code&gt;" removes the tag</text>
            <text x="]].. tostring(.13 * screenWidth) ..[[" y="]].. tostring(.57 * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw" font-weight="bold">
                &lt;Primary Target ID&gt;: Filters radar widget to only show the construct with the specified ID</text>
            </rect>

            </svg>
        ]]
    else
        hw = ''
    end

    return hw
end

function travelIndicatorWidget()
    local p = constructPosition + 2/.000005 * vec3(construct.getWorldOrientationForward())
    local pInfo = library.getPointOnScreen({p['x'],p['y'],p['z']})

    local tiw = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
    if pInfo[3] ~= 0 then
        if pInfo[1] < .01 then pInfo[1] = .01 end
        if pInfo[2] < .01 then pInfo[2] = .01 end
        local fill = AR_Fill
        local translate = '(0,0)'
        local depth = '8'           
        if pInfo[1] < 1 and pInfo[2] < 1 then
            translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight*pInfo[2])
        elseif pInfo[1] > 1 and pInfo[1] < AR_Range and pInfo[2] < 1 then
            translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight*pInfo[2])
        elseif pInfo[2] > 1 and pInfo[2] < AR_Range and pInfo[1] < 1 then
            translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight)
        else
            translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight)
        end
        tiw = tiw .. [[<g transform="translate]]..translate..[[">
                <circle cx="0" cy="0" r="]].. Direction_Indicator_Size ..[[px" style="fill:lightgrey;stroke:]]..Direction_Indicator_Color..[[;stroke-width:]]..tostring(Indicator_Width)..[[;opacity:]].. 0.5 ..[[;" />
                <line x1="]].. Direction_Indicator_Size*1.5 ..[[" y1="0" x2="]].. -Direction_Indicator_Size*1.5 ..[[" y2="0" style="stroke:]]..Direction_Indicator_Color..[[;stroke-width:]]..tostring(Indicator_Width/5)..[[;opacity:]].. 0.85 ..[[;" />
                <line y1="]].. Direction_Indicator_Size*1.5 ..[[" x1="0" y2="]].. -Direction_Indicator_Size*1.5 ..[[" x2="0" style="stroke:]]..Direction_Indicator_Color..[[;stroke-width:]]..tostring(Indicator_Width/5)..[[;opacity:]].. 0.85 ..[[;" />
                </g>]]
    end
    if speed > 20 then
        local a = constructPosition + 2/.000005 * vec3(construct.getWorldVelocity())
        local aInfo = library.getPointOnScreen({a['x'],a['y'],a['z']})
        if aInfo[3] ~= 0 then
            if aInfo[1] < .01 then aInfo[1] = .01 end
            if aInfo[2] < .01 then aInfo[2] = .01 end
            local fill = AR_Fill
            local translate = '(0,0)'
            local depth = '8'           
            if aInfo[1] < 1 and aInfo[2] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth*aInfo[1],screenHeight*aInfo[2])
            elseif aInfo[1] > 1 and aInfo[1] < AR_Range and aInfo[2] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight*aInfo[2])
            elseif aInfo[2] > 1 and aInfo[2] < AR_Range and aInfo[1] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth*aInfo[1],screenHeight)
            else
                translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight)
            end
            tiw = tiw .. [[<g transform="translate]]..translate..[[">
                    <circle cx="0" cy="0" r="]].. Prograde_Indicator_Size ..[[px" style="fill:none;stroke:]]..Prograde_Indicator_Color..[[;stroke-width:]]..tostring(Indicator_Width)..[[;opacity:]].. 0.5 ..[[;" />
                    <line x1="]].. Prograde_Indicator_Size*1.4 ..[[" y1="]].. Prograde_Indicator_Size*1.4 ..[[" x2="]].. -Prograde_Indicator_Size*1.4 ..[[" y2="]].. -Prograde_Indicator_Size*1.4 ..[[" style="stroke:]]..Prograde_Indicator_Color..[[;stroke-width:]]..tostring(Indicator_Width/5)..[[;opacity:]].. 0.85 ..[[;" />
                    <line x1="]].. -Prograde_Indicator_Size*1.4 ..[[" y1="]].. Prograde_Indicator_Size*1.4 ..[[" x2="]].. Prograde_Indicator_Size*1.4 ..[[" y2="]].. -Prograde_Indicator_Size*1.4 ..[[" style="stroke:]]..Prograde_Indicator_Color..[[;stroke-width:]]..tostring(Indicator_Width/5)..[[;opacity:]].. 0.85 ..[[;" />
                    </g>]]
        end
        local r = constructPosition - 2/.000005 * vec3(construct.getWorldVelocity())
        local aInfo = library.getPointOnScreen({r['x'],r['y'],r['z']})
        if aInfo[3] ~= 0 then
            if aInfo[1] < .01 then aInfo[1] = .01 end
            if aInfo[2] < .01 then aInfo[2] = .01 end
            local fill = AR_Fill
            local translate = '(0,0)'
            local depth = '8'           
            if aInfo[1] < 1 and aInfo[2] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth*aInfo[1],screenHeight*aInfo[2])
            elseif aInfo[1] > 1 and aInfo[1] < AR_Range and aInfo[2] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight*aInfo[2])
            elseif aInfo[2] > 1 and aInfo[2] < AR_Range and aInfo[1] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth*aInfo[1],screenHeight)
            else
                translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight)
            end
            tiw = tiw .. [[<g transform="translate]]..translate..[[">
                    <circle cx="0" cy="0" r="]].. Prograde_Indicator_Size ..[[px" style="fill:none;stroke:rgb(255, 60, 60);stroke-width:]]..tostring(Indicator_Width)..[[;opacity:]].. 0.5 ..[[;" />
                    <line x1="]].. Prograde_Indicator_Size*1.4 ..[[" y1="]].. Prograde_Indicator_Size*1.4 ..[[" x2="]].. -Prograde_Indicator_Size*1.4 ..[[" y2="]].. -Prograde_Indicator_Size*1.4 ..[[" style="stroke:rgb(255, 60, 60);stroke-width:]]..tostring(Indicator_Width/5)..[[;opacity:]].. 0.85 ..[[;" />
                    <line x1="]].. -Prograde_Indicator_Size*1.4 ..[[" y1="]].. Prograde_Indicator_Size*1.4 ..[[" x2="]].. Prograde_Indicator_Size*1.4 ..[[" y2="]].. -Prograde_Indicator_Size*1.4 ..[[" style="stroke:rgb(255, 60, 60);stroke-width:]]..tostring(Indicator_Width/5)..[[;opacity:]].. 0.85 ..[[;" />
                    </g>]]
        end
    end
    tiw = tiw .. '</svg>'
    return tiw
end



function generateScreen()
    html = [[ <html> <body style="font-family: Calibri;"> ]]
    html = html .. brakeWidget()
    html = html .. flightWidget()
    html = html .. fuelWidget()
    html = html .. apStatusWidget()
    html = html .. positionInfoWidget()
    html = html .. engineWidget()
    html = html .. planetARWidget()
    html = html .. helpWidget()
    html = html .. travelIndicatorWidget()

    html = html .. [[ </body> </html> ]]
    system.setScreen(html)
end

function globalDB(action)
    if db_1 ~= nil then
        if action == 'get' then
            if db_1.hasKey('showRemotePanel') == 1 then showRemotePanel = db_1.getIntValue('showRemotePanel') == 1 end
            if db_1.hasKey('showDockingPanel') == 1 then showDockingPanel = db_1.getIntValue('showDockingPanel') == 1 end
            if db_1.hasKey('showFuelPanel') == 1 then showFuelPanel = db_1.getIntValue('showFuelPanel') == 1 end
            if db_1.hasKey('showHelper') == 1 then showHelper = db_1.getIntValue('showHelper') == 1 end
            if db_1.hasKey('defaultHoverHeight') == 1 then defaultHoverHeight = db_1.getIntValue('defaultHoverHeight') end
            if db_1.hasKey('defautlFollowDistance') == 1 then defautlFollowDistance = db_1.getIntValue('defautlFollowDistance') end
            if db_1.hasKey('topHUDLineColorSZ') == 1 then topHUDLineColorSZ = db_1.getStringValue('topHUDLineColorSZ') end
            if db_1.hasKey('topHUDFillColorSZ') == 1 then topHUDFillColorSZ = db_1.getStringValue('topHUDFillColorSZ') end
            if db_1.hasKey('textColorSZ') == 1 then textColorSZ = db_1.getStringValue('textColorSZ') end
            if db_1.hasKey('topHUDLineColorPVP') == 1 then topHUDLineColorPVP = db_1.getStringValue('topHUDLineColorPVP') end
            if db_1.hasKey('topHUDFillColorPVP') == 1 then topHUDFillColorPVP = db_1.getStringValue('topHUDFillColorPVP') end
            if db_1.hasKey('textColorPVP') == 1 then textColorPVP = db_1.getStringValue('textColorPVP') end
            if db_1.hasKey('fuelTextColor') == 1 then fuelTextColor = db_1.getStringValue('fuelTextColor') end
            if db_1.hasKey('Direction_Indicator_Size') == 1 then Direction_Indicator_Size = db_1.getFloatValue('Direction_Indicator_Size') end
            if db_1.hasKey('Direction_Indicator_Color') == 1 then Direction_Indicator_Color = db_1.getStringValue('Direction_Indicator_Color') end
            if db_1.hasKey('Prograde_Indicator_Size') == 1 then Prograde_Indicator_Size = db_1.getFloatValue('Prograde_Indicator_Size') end
            if db_1.hasKey('Prograde_Indicator_Color') == 1 then Prograde_Indicator_Color = db_1.getStringValue('Prograde_Indicator_Color') end
            if db_1.hasKey('AP_Brake_Buffer') == 1 then AP_Brake_Buffer = db_1.getFloatValue('AP_Brake_Buffer') end
            if db_1.hasKey('AP_Max_Rotation_Factor') == 1 then AP_Max_Rotation_Factor = db_1.getFloatValue('AP_Max_Rotation_Factor') end
            if db_1.hasKey('AR_Mode') == 1 then AR_Mode = db_1.getStringValue('AR_Mode') end
            if db_1.hasKey('AR_Range') == 1 then AR_Range = db_1.getFloatValue('AR_Range') end
            if db_1.hasKey('AR_Size') == 1 then AR_Size = db_1.getFloatValue('AR_Size') end
            if db_1.hasKey('AR_Fill') == 1 then AR_Fill = db_1.getStringValue('AR_Fill') end
            if db_1.hasKey('AR_Outline') == 1 then AR_Outline = db_1.getStringValue('AR_Outline') end
            if db_1.hasKey('AR_Opacity') == 1 then AR_Opacity = db_1.getStringValue('AR_Opacity') end
            if db_1.hasKey('AR_Exclude_Moons') == 1 then AR_Exclude_Moons = db_1.getIntValue('AR_Exclude_Moons') == 1 end
            if db_1.hasKey('EngineTagColor') == 1 then EngineTagColor = db_1.getStringValue('EngineTagColor') end
            if db_1.hasKey('Indicator_Width') == 1 then Indicator_Width = db_1.getFloatValue('Indicator_Width') end
        elseif action == 'save' then
            if showRemotePanel then db_1.setIntValue('showRemotePanel',1) else db_1.setIntValue('showRemotePanel',0) end
            if showDockingPanel then db_1.setIntValue('showDockingPanel',1) elsedb_1.setIntValue('showDockingPanel',0) end
            if showFuelPanel then db_1.setIntValue('showFuelPanel',1) else db_1.setIntValue('showFuelPanel',0) end
            if showHelper then db_1.setIntValue('showHelper',1) else db_1.setIntValue('showHelper',0) end
            db_1.setIntValue('defaultHoverHeight',defaultHoverHeight)
            db_1.setIntValue('defautlFollowDistance',defautlFollowDistance)
            db_1.setStringValue('topHUDLineColorSZ',topHUDLineColorSZ)
            db_1.setStringValue('topHUDFillColorSZ',topHUDFillColorSZ)
            db_1.setStringValue('textColorSZ',textColorSZ)
            db_1.setStringValue('topHUDLineColorPVP',topHUDLineColorPVP)
            db_1.setStringValue('topHUDFillColorPVP',topHUDFillColorPVP)
            db_1.setStringValue('textColorPVP',textColorPVP)
            db_1.setStringValue('fuelTextColor',fuelTextColor)
            db_1.setFloatValue('Direction_Indicator_Size',Direction_Indicator_Size)
            db_1.setStringValue('Direction_Indicator_Color',Direction_Indicator_Color)
            db_1.setFloatValue('Prograde_Indicator_Size',Prograde_Indicator_Size) 
            db_1.setStringValue('Prograde_Indicator_Color',Prograde_Indicator_Color) 
            db_1.setFloatValue('AP_Brake_Buffer',AP_Brake_Buffer)
            db_1.setFloatValue('AP_Max_Rotation_Factor',AP_Max_Rotation_Factor)
            db_1.setStringValue('AR_Mode',AR_Mode)
            db_1.setFloatValue('AR_Range',AR_Range)
            db_1.setFloatValue('AR_Size',AR_Size)
            db_1.setStringValue('AR_Fill',AR_Fill)
            db_1.setStringValue('AR_Outline',AR_Outline)
            db_1.setStringValue('AR_Opacity',AR_Opacity)
            db_1.setStringValue('EngineTagColor',EngineTagColor)
            db_1.setFloatValue('Indicator_Width',Indicator_Width)
            if AR_Exclude_Moons then db_1.setIntValue('AR_Exclude_Moons',1) else db_1.setIntValue('AR_Exclude_Moons',0) end
        end
    end
end

Kinematic = {} -- just a namespace
local C = 100000000 / 3600
local C2 = C * C
local ITERATIONS = 100 -- iterations over engine "warm-up" period

function Kinematic.computeDistanceAndTime(initial, final, restMass, thrust, t50, brakeThrust)

    t50 = t50 or 0
    brakeThrust = brakeThrust or 0 -- usually zero when accelerating
    local speedUp = initial <= final
    local a0 = thrust * (speedUp and 1 or -1) / restMass
    local b0 = -brakeThrust / restMass
    local totA = a0 + b0
    if speedUp and totA <= 0 or not speedUp and totA >= 0 then
        return -1, -1 -- no solution
    end
    local distanceToMax, timeToMax = 0, 0

    if a0 ~= 0 and t50 > 0 then

        local k1 = math.asin(initial / C)
        local c1 = math.pi * (a0 / 2 + b0)
        local c2 = a0 * t50
        local c3 = C * math.pi
        local v = function(t)
            local w = (c1 * t - c2 * math.sin(math.pi * t / 2 / t50) + c3 * k1) / c3
            local tan = math.tan(w)
            return C * tan / msqrt(tan * tan + 1)
        end
        local speedchk = speedUp and function(s)
            return s >= final
        end or function(s)
            return s <= final
        end
        timeToMax = 2 * t50
        if speedchk(v(timeToMax)) then
            local lasttime = 0
            while mabs(timeToMax - lasttime) > 0.5 do
                local t = (timeToMax + lasttime) / 2
                if speedchk(v(t)) then
                    timeToMax = t
                else
                    lasttime = t
                end
            end
        end
        -- There is no closed form solution for distance in this case.
        -- Numerically integrate for time t=0 to t=2*T50 (or less)
        local lastv = initial
        local tinc = timeToMax / ITERATIONS
        for step = 1, ITERATIONS do
            local speed = v(step * tinc)
            distanceToMax = distanceToMax + (speed + lastv) * tinc / 2
            lastv = speed
        end
        if timeToMax < 2 * t50 then
            return distanceToMax, timeToMax
        end
        initial = lastv
    end

    local k1 = C * math.asin(initial / C)
    local time = (C * math.asin(final / C) - k1) / totA
    local k2 = C2 * math.cos(k1 / C) / totA
    local distance = k2 - C2 * math.cos((totA * time + k1) / C) / totA
    return distance + distanceToMax, time + timeToMax
end

function Kinematic.lorentz(v) return lorentz(v) end

function isNumber(n)  return type(n)           == 'number' end
function isSNumber(n) return type(tonumber(n)) == 'number' end
function isTable(t)   return type(t)           == 'table'  end
function isString(s)  return type(s)           == 'string' end
function isVector(v)  return isTable(v) and isNumber(v.x and v.y and v.z) end



---------------------- TRANSFORM -------------------------
clamp = utils.clamp

Transform = {}

--
-- computeHeading - compute compass heading corresponding to a direction.
-- planetCenter[in]: planet's center in world coordinates.
-- position    [in]: construct's position in world coordinates.
-- direction   [in]: the direction in world coordinates of the heading.
-- return: the heading in radians where 0 is North, PI is South.
-- 
function Transform.computeHeading(planetCenter, position, direction)
    planetCenter   = vec3(planetCenter)
    position       = vec3(position)
    direction      = vec3(direction)
    local radius   = position - planetCenter
    if radius.x == 0 and radius.y == 0 then -- at north or south pole
        return radius.z >=0 and math.pi or 0
    end
    local chord    = planetCenter + vec3(0,0,radius:len()) - position
    local north    = chord:project_on_plane(radius):normalize_inplace()
    -- facing north, east is to the right
    local east     = north:cross(radius):normalize_inplace()
    local dir_prj  = direction:project_on_plane(radius):normalize_inplace()
    local adjacent = north:dot(dir_prj)
    local opposite = east:dot(dir_prj)
    local heading  = math.atan(opposite, adjacent) -- North==0

    if heading < 0 then heading = heading + 2*math.pi end
    if math.abs(heading - 2*math.pi) < .001 then heading = 0 end
    return heading
end

function Transform.computePRYangles(yaxis, zaxis, faxis, uaxis)
    yaxis = yaxis.x and yaxis or vec3(yaxis)
    zaxis = zaxis.x and zaxis or vec3(zaxis)
    faxis = faxis.x and faxis or vec3(faxis)
    uaxis = uaxis.x and uaxis or vec3(uaxis)
    local zproject = zaxis:project_on_plane(faxis):normalize_inplace()
    local adjacent = uaxis:dot(zproject)
    local opposite = faxis:cross(zproject):dot(uaxis)
    local roll     = math.atan(opposite, adjacent) -- rotate 'up' around 'fwd'
    local pitch    = math.asin(clamp(faxis:dot(zaxis), -1, 1))
    local fproject = faxis:project_on_plane(zaxis):normalize_inplace()
    local yaw      = math.asin(clamp(yaxis:cross(fproject):dot(zaxis), -1, 1))
    return pitch, roll, yaw
end