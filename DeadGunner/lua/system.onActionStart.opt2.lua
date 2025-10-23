if lShift then
    if ar_mode == 'ALL' then ar_mode = 'FLEET' system.print('-- AR Mode: FLEET --')
    elseif ar_mode == 'FLEET' then ar_mode = 'ABANDONDED' system.print('-- AR Mode: ABANDONDED --')
    elseif ar_mode == 'ABANDONDED' then ar_mode = 'TRAJECTORY' system.print('-- AR Mode: TRAJECTORY --')
    elseif ar_mode == 'TRAJECTORY' then ar_mode = 'NONE' system.print('-- AR Mode: NONE --')
    elseif ar_mode == 'NONE' then ar_mode = 'ALL' system.print('-- AR Mode: ALL --')
    end
end