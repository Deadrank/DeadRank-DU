autopilot = not autopilot
if autopilot and autopilot_dest == nil then
    autopilot = false
    system.print('-- No autopilot destination entered --')
    system.print('-- Autopilot disabled --')
elseif not autopilot then
    system.print('-- Autopilot disabled --')
end
if autopilot then
    system.print('-- Autopilot engaged --')
    system.setWaypoint(autopilot_dest_pos)
    brakesOn = false
    enginesOn = true
end