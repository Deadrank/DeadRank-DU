for id,pos in pairs(unknownRadar) do
    system.print()
    system.print('------ New Contact -------')
    system.print(string.format('%s',id))
    system.print('First contact:')
    system.print(string.format('::pos{0,0,%s,%s,%s}',pos['x'],pos['y'],pos['z']))
    local cored = ''
    if radar_1.isConstructAbandoned(id) == 1 then
        cored = '[CORED] '
    end
    system.print(string.format('Name: %s%s',cored,radar_1.getConstructName(id)))
    system.print(string.format('Size: %s',radar_1.getConstructCoreSize(id)))
    system.print('---------------------------')
end
unknownRadar = {}