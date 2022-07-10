if printCombatLog then 
    local element = system.getItem(elementId)
    local name = element['displayName']
    system.print(string.format('Destroyed %s on %s',name,radar_1.getConstructName(targetId)))
end