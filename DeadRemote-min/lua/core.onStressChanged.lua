if not dmgTick then dmgTick = arkTime end

local dmgTime = tonumber(string.format('%.0f',arkTime))

if not dpsChart[dmgTime] then
    dpsChart[dmgTime] = stress
else
    dpsChart[dmgTime] = dpsChart[dmgTime] + stress
end