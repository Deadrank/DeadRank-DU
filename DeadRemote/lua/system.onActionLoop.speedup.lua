if player.isFrozen() == 1 or seated == 1 then
    Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 1.0)
end