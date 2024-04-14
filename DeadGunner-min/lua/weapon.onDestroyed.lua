if printCombatLog then
    system.print(string.format('<-- %s Cored by %s -->',radar_1.getConstructName(targetId),pilotName))
end
if write_db then
    write_db.setStringValue(string.format('kill-%s',targetId),string.format('%s Destroyed by %s',radar_1.getConstructName(targetId),pilotName))
end