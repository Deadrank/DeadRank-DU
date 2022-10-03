if player.isFrozen() == 1 or seated == 1 then
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 5.0)
end