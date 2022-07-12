if transponder_1 ~= nil then
    local r = {}
    for i,v in ipairs(tags) do
        if string.starts(v,'AGC') then
            table.insert(r,i)
        end
    end
    for k,v in ipairs(r) do
        local rem = table.remove(tags,v)
        system.print('Removing dynamic code: '..rem)
    end
    transponder_1.setTags(tags)
end

if db_1 ~= nil then db_1.clearValue('targetSpeed') db_1.clearValue('targetFollowDist') db_1.clearValue('targetID') globalDB('save') end