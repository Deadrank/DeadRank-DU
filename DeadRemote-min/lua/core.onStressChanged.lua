-- Damage
if not dmgTick then dmgTick = arkTime end

local dmgTime = tonumber(string.format('%.0f',arkTime))

if not dpsChart[dmgTime] then
    dpsChart[dmgTime] = damage
else
    dpsChart[dmgTime] = dpsChart[dmgTime] + damage
end