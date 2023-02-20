if lAlt then
    boosterOn = not boosterOn
    if boosterOn then 
        unit.setTimer('booster',.75)
    else
        boosterCount = 0
        unit.stopTimer('booster')
        if Nav.boosterState == 1 then 
            Nav:toggleBoosters()
            system.print('Boosters Off (end)')
        end
    end
else
    if player.isFrozen() == 1 or seated == 1 then
        Nav:toggleBoosters()
    end
end