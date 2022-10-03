if player.isFrozen() == 1 or seated == 1 then
    Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, 1.0)
    Nav.axisCommandManager:activateGroundEngineAltitudeStabilization(currentGroundAltitudeStabilization)
end

