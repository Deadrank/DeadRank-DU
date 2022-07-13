if lShift then
    local tag = nil
    for i,t in pairs(predefinedTags) do
        if contains(enabledEngineTags,t) then
            tag = i
        end
    end
    if tag then
        local rem = nil
        for k,v in pairs(enabledEngineTags) do
            if v == predefinedTags[tag] then
                rem = k
            end
        end
        if rem then
            table.remove(enabledEngineTags,rem)
        end
        if tag < #predefinedTags then
            table.insert(enabledEngineTags,predefinedTags[tag+1])
            system.print(string.format('-- Engine tag filter changed "%s" to "%s"',predefinedTags[tag],predefinedTags[tag+1]))
        else
            system.print(string.format('-- All Engines Enabled --'))
        end
    else
        table.insert(enabledEngineTags,predefinedTags[1])
        system.print(string.format('-- Engine tag filter added "%s"',predefinedTags[1]))
    end
else
    enabledEngineTags = {}
    system.print('-- All Engines Enabled --')
end