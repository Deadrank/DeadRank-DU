if printCombatLog then 
    system.print(string.format('Hit %s for %.0f damage',radar_1.getConstructName(targetId),damage))
end

if dmgTracker[tostring(targetId)] then 
    dmgTracker[tostring(targetId)] = dmgTracker[tostring(targetId)] + damage
else
    dmgTracker[tostring(targetId)] = damage
end

if db_1 then
    db_1.setFloatValue('damage - ' .. tostring(targetId) .. ' - ' .. pilotName,dmgTracker[tostring(targetId)])
end