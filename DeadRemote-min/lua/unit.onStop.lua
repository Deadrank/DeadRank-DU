_autoconf.hideCategoryPanels()
db_1.setIntValue('record',0)
if antigrav ~= nil then antigrav.hideWidget() end
if warpdrive ~= nil then warpdrive.hideWidget() end
if gyro ~= nil then gyro.hideWidget() end
core.hideWidget()
Nav.control.switchOffHeadlights()
globalDB('save')