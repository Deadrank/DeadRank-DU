if player.isFrozen() == 1 or seated == 1 then
    if lAlt then
        Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, -0.5)
    else
        Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, -1.0)
    end
end