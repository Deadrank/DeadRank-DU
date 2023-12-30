if write_db ~= nil then
    write_db.clearValue('primaryTarget')
    globalDB('save')
end