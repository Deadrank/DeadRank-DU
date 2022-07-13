Nav:update()

-- Check player seated status --
seated = player.isSeated()
if seated == 1 and player.isFrozen() == 0 then
    player.freeze(1)
elseif seated == 0 and player.isFrozen() == 1 then
    player.freeze(0)
end
----------------------------------

-- Closest Planet/Pipe info --
closestPlanetName,closestPlanetDist = closestPlanet()
closestPipeName,closestPipeDistance = closestPipe()
closestPipeStr = ''
if closestPipeDistance < 1000 then closestPipeStr = string.format('%s (%.2f m)',closestPipeName,closestPipeDistance)
elseif closestPipeDistance < 100000 then closestPipeStr = string.format('%s (%.2f km)',closestPipeName,closestPipeDistance/1000)
else closestPipeStr = string.format('%s (%.2f SU)',closestPipeName,closestPipeDistance*.000005)
end
closestPlanetStr = ''
if closestPlanetDist < 1000 then closestPlanetStr = string.format('%s (%.2f m)',closestPlanetName,closestPlanetDist)
elseif closestPlanetDist < 100000 then closestPlanetStr = string.format('%s (%.2f km)',closestPlanetName,closestPlanetDist/1000)
else closestPlanetStr = string.format('%s (%.2f SU)',closestPlanetName,closestPlanetDist*.000005)
end

-- Disable AutoPilot if to close to planet --
if closestPlanetDist < 40000 and autopilot then 
    autopilot = false 
    brakeInput = 1
    brakesOn = true
    system.print('-- autopilot canceled due to planet proximity --')
end

-- Safe Zone Distance --
inSZ = construct.isInPvPZone() == 0
SZD = math.abs(construct.getDistanceToSafeZone())
local tempSZD = vec3(constructPosition - SZ):len()
nearestSZPOS = system.getWaypointFromPlayerPos()
if closestPlanetDist < math.abs(tempSZD - 18000000) then
    local cPlanet = planets[closestPlanetName]
    nearestSZPOS = string.format('::pos{0,0,%.4f,%.4f,%.4f}',cPlanet['x'],cPlanet['y'],cPlanet['z'])
else
    nearestSZPOS = '::pos{0,0,13771471,7435803,-128971}'
end

SZDStr = ''
if SZD < 1000 then SZDStr = string.format('%.2f m',SZD)
elseif SZD < 100000 then SZDStr = string.format('%.2f km',SZD/1000)
else SZDStr = string.format('%.2f su',SZD*.000005)
end
---------------------------

-- Engine Tag Filtering --
enabledEngineTagsStr = ''
local tempTag = nil
local offset = 0
for i,tag in pairs(enabledEngineTags) do
    if i % 2 == 0 then 
        enabledEngineTagsStr = enabledEngineTagsStr .. [[
            <text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (i-2)*.008) * screenHeight) ..[[" style="fill: ]]..EngineTagColor..[[;" font-weight="bold" font-size=".8vw">]]..tag.. ',' ..tempTag..[[</text>    
        ]]
        tempTag = nil
        offset = offset + 1
    else
        tempTag = tag
    end
end
if tempTag ~= nil then 
    enabledEngineTagsStr = enabledEngineTagsStr .. [[<text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (offset)*.016) * screenHeight) ..[[" style="fill: ]]..EngineTagColor..[[;" font-weight="bold" font-size=".8vw">]]..tempTag..[[</text>]]
end
if enabledEngineTagsStr == '' then
    enabledEngineTagsStr = [[<text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (offset)*.008) * screenHeight) ..[[" style="fill: ]]..fuelTextColor..[[" font-size=".8vw">ALL</text>]]
end
----------------------------

-- Auto Follow feature --
if auto_follow then 
    if not db_1 then
        auto_follow = false
        system.print('-- No databank attached --')
    elseif db_1.hasKey('targetID') == 1 then
        targetID = db_1.getIntValue('targetID')
        if followID == nil or targetID == followID then
            followID = targetID
            targetSpeed = db_1.getFloatValue('targetSpeed')
            targetDist = db_1.getFloatValue('targetDistance')
            local followBrakeDist = 0
            if math.abs(speed/3.6 - targetSpeed) > 5 then
                followBrakeDist,followBrakeTime = Kinematic.computeDistanceAndTime(speed/3.6,targetSpeed,mass,0,0,maxBrake)
            end
            if db_1.hasKey('followDistance') == 1 then followDistance = db_1.getFloatValue('followDistance') else followDistance = defautlFollowDistance end
            followDistance = followDistance + followBrakeDist
            if followDistance > targetDist and followDistance - followDistance*.1 < targetDist then 
                -- Set cruise speed to targets speed
                brakeInput = 0
                Nav.axisCommandManager:resetCommand(axisCommandId.longitudinal)
                if (Nav.axisCommandManager:getAxisCommandType(0) ~= axisCommandType.byTargetSpeed) then
                    Nav.control.cancelCurrentControlMasterMode()
                end
                Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal,targetSpeed)
            elseif followDistance < targetDist then
                -- Full throttle
                brakeInput = 0
                if (Nav.axisCommandManager:getAxisCommandType(0) ~= axisCommandType.byThrottle) then
                    Nav.control.cancelCurrentControlMasterMode()
                end
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,1)
            elseif followDistance - followDistance*.1 > targetDist then
                -- Full brake
                brakeInput = 1
                if (Nav.axisCommandManager:getAxisCommandType(0) ~= axisCommandType.byThrottle) then
                    Nav.control.cancelCurrentControlMasterMode()
                end
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
            end
        elseif followID ~= targetID then
            if (Nav.axisCommandManager:getAxisCommandType(0) ~= axisCommandType.byThrottle) then
                Nav.control.cancelCurrentControlMasterMode()
            end
            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
            system.print('-- Auto follow cancelled due to target change --')
            followID = nil
            auto_follow = false
            db_1.clearValue('followDistance')
            db_1.clearValue('targetDistance')
            db_1.clearValue('targetSpeed')
            db_1.clearValue('targetID')
        end
    else
        auto_follow = false
        system.print('-- No target found for following --')
    end
end
if db_1 then 
    if auto_follow then
        db_1.setIntValue('following',1)
        db_1.setIntValue('followingID',followID)
    else
        followID = nil
        db_1.setIntValue('following',0)
        db_1.setIntValue('followingID',0)
    end
end
---------------------------

-- Generate on screen planets for Augmented Reality view --
AR_Generate = {}
if autopilot_dest_pos ~= nil then AR_Generate['AutoPilot'] = convertWaypoint(autopilot_dest_pos) end
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
planetAR = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
for name,pos in pairs(AR_Generate) do
    if not (name:find('Moon') or name:find('Haven') or name:find('Sanctuary')) or not AR_Exclude_Moons then
        local pDist = vec3(pos - constructPosition):len()
        if pDist*0.000005 < 500  or planets[name] == nil then 
            local pInfo = library.getPointOnScreen({pos['x'],pos['y'],pos['z']})
            if pInfo[3] ~= 0 then
                if pInfo[1] < .01 then pInfo[1] = .01 end
                if pInfo[2] < .01 then pInfo[2] = .01 end
                local fill = AR_Fill
                if planets[name] == nil  and name ~= 'AutoPilot' then fill = 'rgb(49, 182, 60)'
                elseif name == 'AutoPilot' then fill = 'red'
                end
                local translate = '(0,0)'
                local depth = AR_Size * 1/( 0.02*pDist*0.000005)
                local pDistStr = ''
                if pDist < 1000 then pDistStr = string.format('%.2fm',pDist)
                elseif pDist < 100000 then pDistStr = string.format('%.2fkm',pDist/1000)
                else pDistStr = string.format('%.2fsu',pDist*0.000005)
                end
                if depth > AR_Size then depth = tostring(AR_Size) elseif depth < 1 then depth = '1' else depth = tostring(depth) end
                if pInfo[1] < 1 and pInfo[2] < 1 then
                    translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight*pInfo[2])
                elseif pInfo[1] > 1 and pInfo[1] < AR_Range and pInfo[2] < 1 then
                    translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight*pInfo[2])
                elseif pInfo[2] > 1 and pInfo[2] < AR_Range and pInfo[1] < 1 then
                    translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight)
                else
                    translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight)
                end
                planetAR = planetAR .. [[<g transform="translate]]..translate..[[">
                        <circle cx="0" cy="0" r="]].. depth ..[[px" style="fill:]]..fill..[[;stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <line x1="0" y1="0" x2="-]].. depth*1.2 ..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <line x1="-]].. depth*1.2 ..[[" y1="-]].. depth*1.2 ..[[" x2="-]]..tostring(depth*1.2 + 30)..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <text x="-]]..tostring(6*#name+depth*1.2)..[[" y="-]].. depth*1.2+screenHeight*0.0035 ..[[" style="fill: ]]..AR_Outline..[[" font-size="]]..tostring(.04*AR_Size)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                        </g>]]
            end
        end
    end
end
planetAR = planetAR .. '</svg>'
-----------------------------------------------------------


-- Choose background color scheme based on PVP --
bgColor = ''
lineColor = ''
if inSZ then bgColor=topHUDFillColorSZ lineColor=topHUDLineColorSZ textColor=textColorSZ 
else bgColor=topHUDFillColorPVP lineColor=topHUDLineColorPVP textColor=textColorPVP
end
--------------------------------------------------

-- Generate Screen overlay --
if maxBrakeStr ~= nil then generateScreen() end
-----------------------------