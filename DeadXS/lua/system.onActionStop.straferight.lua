if player.isFrozen() == 1 or seated == 1 then
    Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, -1.0)
end