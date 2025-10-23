if player.isFrozen() or seated then
    Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0)
end
spaceBar = true
if spaceBar and lAlt and hoverLocked then
    hoverLocked = false
    Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0)
    Nav.axisCommandManager:setTargetGroundAltitude(1)
    Nav.axisCommandManager:activateGroundEngineAltitudeStabilization(1)
    system.print("Hover mode unlocked")
elseif spaceBar and lAlt and not hoverLocked then
    system.print("Hover mode locked")
    hoverLocked = true
    Nav.axisCommandManager:activateGroundEngineAltitudeStabilization(500)
    system.print("Hover mode locked")
    Nav.axisCommandManager:setTargetGroundAltitude(500)
    system.print("Hover mode locked")
end