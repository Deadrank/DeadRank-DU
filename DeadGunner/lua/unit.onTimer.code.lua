if transponder_1 ~= nil then
    tags = transponder_1.getTags()
    if transponder_1.isActive() ~= 1 then transponder_1.activate() end
    
end

local a = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
math.randomseed(tonumber(string.format('%.0f',codeSeed + system.getArkTime()/rollTimer)))
local genCode = 'AGC'
for i = 1,5 do
    local c = math.random(1,string.len(a))
    genCode = genCode .. string.sub(a,c,c)
end

if cOverlapTick > 5 then unit.stopTimer('overlap') end

local cApplied = contains(tags,genCode)
if genCode ~= tCode or not cApplied then

    if cOverlapTick == 0 or cOverlapTick > 3 then 
        local r = {}
        for i,v in ipairs(tags) do
            if string.starts(v,'AGC') then
                table.insert(r,i)
            end
        end
        for _,i in ipairs(r) do table.remove(tags,i) end

        if cOverlapTick == 0 and tCode ~= nil then
            cOverlapTick = 1
            unit.setTimer('overlap',2)
        end
        if cOverlapTick >= 3 or tCode == nil then
            unit.stopTimer('overlap')
            tCode = genCode
            cOverlapTick = 0
            local r = {}
            for i,v in ipairs(tags) do
                if string.starts(v,'AGC') then
                    table.insert(r,i)
                end
            end
            for _,i in ipairs(r) do table.remove(tags,i) end
            table.insert(tags,genCode)
            transponder_1.setTags(tags)
        else
            table.insert(tags,genCode)
            table.insert(tags,tCode)
            transponder_1.setTags(tags)
        end
    end
end