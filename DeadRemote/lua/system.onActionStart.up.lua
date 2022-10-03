if player.isFrozen() == 1 or seated == 1 then
    Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0)
end

