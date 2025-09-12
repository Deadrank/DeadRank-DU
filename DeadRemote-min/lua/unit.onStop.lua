_autoconf.hideCategoryPanels()
db_1.setIntValue('record',0)
if antigrav ~= nil then antigrav.hideWidget() end
if warpdrive ~= nil then warpdrive.hideWidget() end
if gyro ~= nil then gyro.hideWidget() end
core.hideWidget()
Nav.control.switchOffHeadlights()
globalDB('save')


if debug then
    system.print('-- Profiling Data --')
    for k,v in pairs(profiling_data) do
        if v >= .0001 then
            system.print(string.format([[Function %s took %.4f sec to run]],k,v))
        end
    end
    system.print('FPS Data: ')
    system.print(string.format('  FPS Min: %.2f',fps_data['min']))
    system.print(string.format('  FPS Max: %.2f',fps_data['max']))
    system.print(string.format('  FPS Avg: %.2f',fps_data['avg']))
    system.print('-- End Profiling Data --')
end