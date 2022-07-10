if bootTimer == 2 then
    radarData = RadarWidgetCreate()
    if transponder_1 ~= nil then unit.setTimer('code',.25) end
    radarStart = true
    unit.setTimer('radar',.75)
    unit.stopTimer('booting')
else
    system.print('System booting: '..tostring(bootTimer))
end
bootTimer = bootTimer + 1