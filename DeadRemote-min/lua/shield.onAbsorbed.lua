-- Damage
if not dmgTick then dmgTick = arkTime end

local dmgTime = tonumber(string.format('%.0f',arkTime/1000))

if not dpsChart[dmgTime] then
    dpsChart[dmgTime] = damage
else
    dpsChart[dmgTime] = dpsChart[dmgTime] + damage
end