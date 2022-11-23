arkTime = system.getArkTime()

-- SZ Boundary --
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
---------------------

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