if player.isFrozen() == 1 or seated == 1 then
    if lAlt then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 1.0)
    else
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 5.0)
    end
end
if auto_follow then
    system.print('Raising speed: ' .. tostring(followSpeedMod))
    if lAlt then
        followSpeedMod = followSpeedMod + 250
    else
        followSpeedMod = followSpeedMod + 500
    end
    system.print('Raised speed to: ' .. tostring(followSpeedMod))
end