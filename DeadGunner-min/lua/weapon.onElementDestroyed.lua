if printCombatLog then 
    local element = system.getItem(elementId)
    local name = element['displayName']
    system.print(string.format('Destroyed %s on %s',name,radar_1.getConstructName(targetId)))
    if string.find(name:lower(),'core') then write_db.setStringValue(string.format('kill-%s',targetId),string.format('%s Destroyed by %s',radar_1.getConstructName(targetId),pilotName))
end