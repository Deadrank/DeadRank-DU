if player.isFrozen() or seated then
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, 1.0)
    
    dampening = not dampening

    if dampening then
        system.print("-- DAMPENING ON  --")
        system.playSound('damp_on.mp3')
    else
        system.print("-- DAMPENING OFF --")
        system.playSound('damp_off.mp3')
    end
end