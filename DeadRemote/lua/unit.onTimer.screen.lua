Nav:update()

-- Check player seated status --
seated = player.isSeated()
if seated == 1 and player.isFrozen() == 0 then
    player.freeze(1)
elseif seated == 0 and player.isFrozen() == 1 then
    player.freeze(0)
end
----------------------------------



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
            targetSpeed = db_1.getFloatValue('targetSpeed') + followSpeedMod
            targetDist = db_1.getFloatValue('targetDistance')

            -- Set cruise speed to targets speed
            brakeInput = 0
            Nav.axisCommandManager:resetCommand(axisCommandId.longitudinal)
            if (Nav.axisCommandManager:getAxisCommandType(0) ~= axisCommandType.byTargetSpeed) then
                Nav.control.cancelCurrentControlMasterMode()
            end
            Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal,targetSpeed)
        elseif followID ~= targetID then
            if (Nav.axisCommandManager:getAxisCommandType(0) ~= axisCommandType.byThrottle) then
                Nav.control.cancelCurrentControlMasterMode()
            end
            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
            system.print('-- Auto follow cancelled due to target change --')
            followID = nil
            auto_follow = false
        end
    else
        auto_follow = false
        system.print('-- No target found for following --')
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
    if not (name:find('Moon') or name:find('Haven') or name:find('Sanctuary') or name:find('Asteroid')) or not AR_Exclude_Moons then
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
                if name == 'AutoPilot' then
                    planetAR = planetAR .. [[<g transform="translate]]..translate..[[">
                            <circle cx="0" cy="0" r="]].. depth ..[[px" style="fill:]]..fill..[[;stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                            <line x1="0" y1="0" x2="]].. depth*1.2 ..[[" y2="]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                            <line x1="]].. depth*1.2 ..[[" y1="]].. depth*1.2 ..[[" x2="]]..tostring(depth*1.2 + 30)..[[" y2="]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                            <text x="]]..tostring(depth*1.2)..[[" y="]].. depth*1.2+screenHeight*0.008 ..[[" style="fill: ]]..AR_Outline..[[" font-size="]]..tostring(.04*AR_Size)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                            </g>]]
                else
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
end
planetAR = planetAR .. '</svg>'
-----------------------------------------------------------

-- Shield Updates --
if shield_1 then
    local srp = shield_1.getResistancesPool()
    local csr = shield_1.getResistances()
    local rcd = shield_1.getResistancesCooldown()
    if shield_1.getStressRatioRaw()[1] == 0 and shield_1.getStressRatioRaw()[2] == 0 and shield_1.getStressRatioRaw()[3] == 0 and shield_1.getStressRatioRaw()[4] == 0 then
        dmgTick = 0
        srp = srp / 4
        if (csr[1] == srp and csr[2] == srp and csr[3] == srp and csr[4] == srp) or rcd ~= 0 then
            --No change
        else
            shield_1.setResistances(srp,srp,srp,srp)
        end
    elseif math.abs(arkTime - dmgTick) >= initialResistWait then
        local srr = shield_1.getStressRatioRaw()
        if (csr[1] == (srp*srr[1]) and csr[2] == (srp*srr[2]) and csr[3] == (srp*srr[3]) and csr[4] == (srp*srr[4])) or rcd ~= 0 then -- If ratio hasn't change, or timer is not up, don't waste the resistance change timer.
            --No change
        else
            shield_1.setResistances(srp*srr[1],srp*srr[2],srp*srr[3],srp*srr[4])
        end
    elseif dmgTick == 0 then
        dmgTick = arkTime
    end

    local hp = shield_1.getShieldHitpoints()
    if shield_1.isVenting() == 0 and hp == 0 and autoVent then
        shield_1.startVenting()
    elseif shield_1.isActive() == 0 and shield_1.isVenting() == 0 or vec3(homeBaseVec - constructPosition):len() < homeBaseDistance*1000 then
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

    local coreHP = 0
    if core_1 then coreHP = (core_1.getMaxCoreStress()-core_1.getCoreStress())/core_1.getMaxCoreStress() end
end
-- End Shield Updates --

-- Choose background color scheme based on PVP --
bgColor = ''
lineColor = ''
fontColor = ''
if inSZ then bgColor=topHUDFillColorSZ lineColor=topHUDLineColorSZ fontColor=textColorSZ 
else bgColor=topHUDFillColorPVP lineColor=topHUDLineColorPVP fontColor=textColorPVP
end
--------------------------------------------------

------- Warp Drive Brake activation ------
if construct.isWarping() == 1 then
    brakeInput = 1
    brakesOn = true
end
-----------------------------------------


-- Generate Screen overlay --
if speed ~= nil then generateScreen() end
-----------------------------