if player.isFrozen() or seated then
    if lAlt then
        Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 0.5)
    else
        Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 1.0)
    end
end