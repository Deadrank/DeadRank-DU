if player.isFrozen() or seated then
    if lAlt then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 1.0)
    else
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 5.0)
    end
end