if printCombatLog then 
    system.print(string.format('Hit %s for %.0f damage',radar_1.getConstructName(targetId),damage))
end

if dmgTracker[tostring(targetId)] then 
    dmgTracker[tostring(targetId)] = dmgTracker[tostring(targetId)] + damage
else
    dmgTracker[tostring(targetId)] = damage
end

local dmgTime = tonumber(string.format('%.0f',arkTime/1000))
if not dpsChart[dmgTime] then
    dpsChart[dmgTime] = damage
else
    dpsChart[dmgTime] = dpsChart[dmgTime] + damage
end