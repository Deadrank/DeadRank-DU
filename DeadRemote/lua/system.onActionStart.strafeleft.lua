if player.isFrozen() or seated then
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, -1.0)
end