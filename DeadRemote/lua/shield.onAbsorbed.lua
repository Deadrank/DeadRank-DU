local ts = system.getArkTime()
if not dmgTick then
    dmgTick = ts
end
if dpsTracker[string.format('%.0f',ts/10)] then
    dpsTracker[string.format('%.0f',ts/10)] = dpsTracker[string.format('%.0f',ts/10)] + damage
    dpsChart[1] = dpsTracker[string.format('%.0f',ts/10)]
else
    dpsTracker[string.format('%.0f',(ts-10)/10)] = nil
    dpsTracker[string.format('%.0f',ts/10)] = damage
    table.insert(dpsChart,1,damage)
end