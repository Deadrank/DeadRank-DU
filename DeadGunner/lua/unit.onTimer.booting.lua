if bootTimer == 2 then
    if radar_1 then radarData = RadarWidgetCreate() end
    if transponder_1 ~= nil then unit.setTimer('code',.25) end
    radarStart = true
    if radar_1 then unit.setTimer('radar',.75) end
    WeaponWidgetCreate()
    unit.stopTimer('booting')
else
    system.print('System booting: '..tostring(bootTimer))
end
bootTimer = bootTimer + 1