if orbit_active and orbit_center:len() > 0 then
    orbit_active = false
    autopilot = false  -- Exit autopilot mode
    system.print('Orbit disabled')
elseif orbit_center:len() > 0 then  -- Only re-enable if params were set previously
    orbit_active = true
    autopilot = true
    system.print('Orbit re-enabled')
else
    system.print('Set orbit params first with "orbit <pos> <speed>"')
end