arkTime = system.getArkTime()

FPS = string.format('%.1f',FPS_COUNTER/(arkTime - FPS_INTERVAL))
FPS_COUNTER = 0
FPS_INTERVAL = arkTime

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
            <text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (i-2)*.008) * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-weight="bold" font-size=".8vw">]]..tag.. ',' ..tempTag..[[</text>    
        ]]
        tempTag = nil
        offset = offset + 1
    else
        tempTag = tag
    end
end
if tempTag ~= nil then 
    engTable[#engTable+1] = [[<text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (offset)*.016) * screenHeight) ..[[" style="fill: rgb(60, 255, 60);" font-weight="bold" font-size=".8vw">]]..tempTag..[[</text>]]
end
if #engTable == 0 then
    engTable[#engTable+1] = [[<text x="]].. tostring(.001 * screenWidth) ..[[" y="]].. tostring((.060 + (offset)*.008) * screenHeight) ..[[" style="fill: rgba(200, 225, 235, 1)" font-size=".8vw">ALL</text>]]
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
        <text x="894" y="691.2" style="fill: red" font-size="3.42vh" font-weight="bold">SHIELD CRITICAL</text>
    ]],warningSymbols['svgCritical'])
elseif shieldPercent < 30 then
    shieldWarningHTML = string.format([[
        <svg width="115.2" height="64.8" x="792" y="648" style="fill: orange;">
            %s
        </svg>
        <text x="894" y="691.2" style="fill: orange" font-size="3.42vh" font-weight="bold">SHIELD LOW</text>
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



fuelHTML = fuelWidget()
shipNameHTML = shipNameWidget()
dpsHTML = dpsWidget()