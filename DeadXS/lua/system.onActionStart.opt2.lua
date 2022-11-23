if not lShift then
    if AR_Mode == 'ALL' then AR_Mode = 'PLANETS' system.print('-- AR Mode: Planets --')
    elseif AR_Mode == 'PLANETS' and AR_Temp then AR_Mode = 'TEMPORARY' system.print('-- AR Mode: TEMPORARY --')
    elseif AR_Mode == 'PLANETS' and AR_Custom then AR_Mode = 'FROM_FILE' system.print('-- AR Mode: FROM_FILE --')
    elseif AR_Mode == 'PLANETS' then AR_Mode = 'NONE' system.print('-- AR Mode: NONE --')
    elseif AR_Mode == 'TEMPORARY' and AR_Custom then AR_Mode = 'FROM_FILE' system.print('-- AR Mode: FROM_FILE --')
    elseif AR_Mode == 'TEMPORARY' then AR_Mode = 'NONE' system.print('-- AR Mode: NONE --')
    elseif AR_Mode == 'FROM_FILE' then AR_Mode = 'NONE' system.print('-- AR Mode: None --')
    elseif AR_Mode == 'NONE' then AR_Mode = 'ALL' system.print('-- AR Mode: All --')
    end
end