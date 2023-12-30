-- Damage
if not dmgTick then dmgTick = arkTime end

if not dpsChart[arkTime] then
    dpsChart[arkTime] = damage
else
    dpsChart[arkTime] = dpsChart[arkTime] + damage
end