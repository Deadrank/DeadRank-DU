if bootTimer == 2 then
    WeaponWidgetCreate(true)
    if radar_1 then 
        radarDataID,panel = RadarWidgetCreate('RADAR')
        if targetRadar or slave then primaryRadarID,primaryRadarPanelID = RadarWidgetCreate('PRIMARY TARGETS') end
    end
    
    radarStart = true
    if radar_1 then unit.setTimer('radar',0.15) end
    unit.stopTimer('booting')
else
    system.print('System booting: '..tostring(bootTimer))
end
bootTimer = bootTimer + 1