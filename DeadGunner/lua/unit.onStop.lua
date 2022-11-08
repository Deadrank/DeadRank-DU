if transponder_1 ~= nil then
    local keep = {}
    if codeSeed ~= nil then
        for i,v in ipairs(tags) do
            if not string.starts(v,'AGC') then
                table.insert(keep,v)
            end
        end
        transponder_1.setTags(keep)
        transponder_1.deactivate()
    end
end

if write_db ~= nil then write_db.clearValue('targetSpeed') write_db.clearValue('targetFollowDist') write_db.clearValue('targetID') globalDB('save') end