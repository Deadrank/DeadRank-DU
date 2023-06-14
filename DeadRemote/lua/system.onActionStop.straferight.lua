if player.isFrozen() or seated then
    Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, -1.0)
end