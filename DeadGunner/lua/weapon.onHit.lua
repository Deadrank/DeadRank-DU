if printCombatLog then 
    system.print(string.format('Hit %s for %.0f damage',radar_1.getConstructName(targetId),damage))
end

if db_1 then
    if db_1.hasKey('damage - ' .. tostring(targetId)) == 1 then
        local totalDamage = db_1.getFloatValue('damage - ' .. tostring(targetId)) + damage
        db_1.setFloatValue('damage - ' .. tostring(targetId),totalDamage)
        dmgTracker[tostring(targetId)] = db_1.getFloatValue('damage - ' .. tostring(targetId))
    else
        db_1.setFloatValue('damage - ' .. tostring(targetId),damage)
        dmgTracker[tostring(targetId)] = db_1.getFloatValue('damage - ' .. tostring(targetId))
    end
else
    if dmgTracker[tostring(targetId)] then 
        dmgTracker[tostring(targetId)] = dmgTracker[tostring(targetId)] + damage
    else
        dmgTracker[tostring(targetId)] = damage
    end
end