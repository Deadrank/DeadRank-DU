if lShift and homeBaseLocation then
    autopilot_dest = homeBaseVec
    autopilot_dest_pos = homeBaseLocation
    system.print('-- Autopilot set to home --')
else
    autopilot = not autopilot
    if autopilot and autopilot_dest == nil then
        autopilot = false
        system.print('-- No autopilot destination entered --')
        system.print('-- Autopilot disabled --')
        db_1.setIntValue('record',0)
    elseif not autopilot then
        system.print('-- Autopilot disabled --')
        db_1.setIntValue('record',0)
    end
    if autopilot then
        if route then
            db_1.setIntValue('record',1)
            system.print('-- Routepilot engaged --')
        else
            system.print('-- Autopilot engaged --')
        end
        system.setWaypoint(autopilot_dest_pos)
        brakesOn = false
        enginesOn = true
    end
end