if lShift then
    if AR_Mode == 'ALL' then AR_Mode = 'FLEET' system.print('-- AR Mode: FLEET --')
    elseif AR_Mode == 'FLEET' then AR_Mode = 'ABANDONDED' system.print('-- AR Mode: ABANDONDED --')
    elseif AR_Mode == 'ABANDONDED' then AR_Mode = 'TRAJECTORY' system.print('-- AR Mode: TRAJECTORY --')
    elseif AR_Mode == 'TRAJECTORY' then AR_Mode = 'NONE' system.print('-- AR Mode: NONE --')
    elseif AR_Mode == 'NONE' then AR_Mode = 'ALL' system.print('-- AR Mode: ALL --')
    end
end