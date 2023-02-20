boosterOn = not boosterOn

if boosterOn then 
    unit.setTimer('booster',0.33)
else
    boosterCount = 0
    unit.stopTimer('booster')
    if boosterPulseOn then Nav:toggleBoosters() end
end
--if player.isFrozen() == 1 or seated == 1 then
--    Nav:toggleBoosters()
--end