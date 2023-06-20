if lAlt then
    boosterOn = not boosterOn
    if boosterOn then 
        unit.setTimer('booster',.75)
    else
        boosterCount = 0
        unit.stopTimer('booster')
        if Nav.boosterState then 
            Nav:toggleBoosters()
            system.print('Boosters Off (end)')
        end
    end
else
    if player.isFrozen() or seated then
        Nav:toggleBoosters()
    end
end