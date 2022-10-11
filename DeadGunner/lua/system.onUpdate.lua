arkTime = system.getArkTime()

if bootTimer >= 2 then
    generateHTML()
end

inSZ = construct.isInPvPZone() == 0
SZD = construct.getDistanceToSafeZone()
bgColor = bottomHUDFillColorSZ 
fontColor = textColorSZ
lineColor = bottomHUDLineColorSZ
if not inSZ then 
    lineColor = bottomHUDLineColorPVP
    bgColor = bottomHUDFillColorPVP
    fontColor = textColorPVP
end

-- Radar Updates --
if radar_1 and cr == nil then
    cr = coroutine.create(updateRadar)
elseif cr ~= nil then
    if coroutine.status(cr) ~= "dead" and coroutine.status(cr) == "suspended" then
        coroutine.resume(cr,radarFilter)
    elseif coroutine.status(cr) == "dead" then
        cr = nil
        system.updateData(radarDataID,radarWidgetData)
        if not cr_time then
            cr_time = system.getArkTime()
        else
            cr_delta = system.getArkTime() - cr_time
            cr_time = system.getArkTime()
            if (cr_delta > 1 and radarOverload) or showAlerts then
                warnings['radar_delta'] = 'svgCritical'
            else
                warnings['radar_delta'] = nil
            end
        end
    end
end
---- End Radar Updates ----

-- Shield Updates --
local cPos = vec3(construct.getWorldPosition())
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
    elseif shield_1.isActive() == 0 and shield_1.isVenting() == 0 or vec3(homeBaseVec - cPos):len() < homeBaseDistance*1000 then
        if homeBaseVec then
            if vec3(homeBaseVec - cPos):len() >= homeBaseDistance*1000 then
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

-- AutoFollow Updates --
local target = tostring(radar_1.getTargetId())
if auto_follow then
    if not followID then followID = target end
    if followID then
        local identified = radar_1.isConstructIdentified(followID) == 1
        if identified then
            local tSpeed = radar_1.getConstructSpeed(followID) * 3.6
            local tDist = radar_1.getConstructDistance(followID)
            write_db.setIntValue('targetID',tonumber(followID))
            write_db.setFloatValue('targetSpeed',tSpeed)
            write_db.setFloatValue('targetDistance',tDist)
        else
            write_db.clearValue('targetID')
            write_db.clearValue('targetSpeed')
            write_db.clearValue('targetDistance')
        end
    end
end
-- End autofollow --