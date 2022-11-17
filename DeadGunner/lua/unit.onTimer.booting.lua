if bootTimer == 2 then
    if radar_1 then radarData = RadarWidgetCreate() end
    
    radarStart = true
    if radar_1 then unit.setTimer('radar',0.15) end
    WeaponWidgetCreate()
    unit.stopTimer('booting')
else
    system.print('System booting: '..tostring(bootTimer))
end
bootTimer = bootTimer + 1