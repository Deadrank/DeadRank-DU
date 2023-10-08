if player.isFrozen() or seated then
    Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, 1.0)
    Nav.axisCommandManager:activateGroundEngineAltitudeStabilization(currentGroundAltitudeStabilization)
end

