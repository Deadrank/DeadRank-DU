for id,pos in pairs(unknownRadar) do
    local cored = ''
    if radar_1.isConstructAbandoned(id) then
        cored = '[CORED] '
    end
    if not recordAll or not write_db then
        system.print()
        system.print('------ New Contact -------')
        system.print(string.format('%s',id))
        system.print('First contact:')
        system.print(string.format('::pos{0,0,%s,%s,%s}',pos['x'],pos['y'],pos['z']))
        system.print(string.format('Name: %s%s',cored,radar_1.getConstructName(id)))
        system.print(string.format('Size: %s',radar_1.getConstructCoreSize(id)))
        system.print('---------------------------')
    end
    if recordAll and write_db then
        system.print('------ New Contact -------')
        system.print(string.format('::pos{0,0,%s,%s,%s}',pos['x'],pos['y'],pos['z']))
        system.print(string.format('[%s] %s (%s)',radar_1.getConstructCoreSize(id),radar_1.getConstructName(id),radarKind[radar_1.getConstructKind(id)]))
        system.print('---------------------------')
        if (not excludeXS and radar_1.getConstructCoreSize(id) == 'XS') or radar_1.getConstructCoreSize(id) ~= 'XS' then
            write_db.setStringValue(string.format('fnd-pos-%s',id),string.format('::pos{0,0,%s,%s,%s}',pos['x'],pos['y'],pos['z']))
            write_db.setStringValue(string.format('fnd-name-%s',id),string.format('[%s] %s (%s)',radar_1.getConstructCoreSize(id),radar_1.getConstructName(id),radarKind[radar_1.getConstructKind(id)]))
    
        end
    end
end
unknownRadar = {}