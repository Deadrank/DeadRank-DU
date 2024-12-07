local baseDamage = weapon_8.getBaseDamage()
local AT = system.getItem(weapon_8.getAmmo())
AT = tostring(AT['name']):lower()
if string.find(AT,'antimatter') then AT = 'Antimatter'
elseif string.find(AT,'electromagnetic') then AT = 'ElectroMagnetic'
elseif string.find(AT,'kinetic') then AT = 'Kinetic'
elseif string.find(AT,'thermic') then AT = 'Thermic'
end

if printCombatLog then 
    system.print(string.format('Hit %s for %.0f damage (%.0f%% %s)',radar_1.getConstructName(targetId),damage,(1-damage/baseDamage)*100,AT))
end

if dmgTracker[tostring(targetId)] then 
    dmgTracker[tostring(targetId)] = dmgTracker[tostring(targetId)] + damage
else
    dmgTracker[tostring(targetId)] = damage
end

local dmgTime = tonumber(string.format('%.0f',arkTime))
if not dpsChart[dmgTime] then
    dpsChart[dmgTime] = damage
else
    dpsChart[dmgTime] = dpsChart[dmgTime] + damage
end