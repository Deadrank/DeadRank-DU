if player.isFrozen() or seated then
    Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, -1.0)
end

