-----------------------------------
showRemotePanel = false --export
showDockingPanel = false --export
showFuelPanel = false --export
showHelper = false --export
defaultHoverHeight = 42 --export
defautlFollowDistance = 40 --export
topHUDLineColorSZ = 'white' --export
topHUDFillColorSZ = 'rgba(29, 63, 255, 0.75)' --export
textColorSZ = 'white' --export
topHUDLineColorPVP = 'lightgrey' --export
topHUDFillColorPVP = 'rgba(255, 0, 0, 0.75)' --export
textColorPVP = 'black' --export
fuelTextColor = 'white' --export
Direction_Indicator_Size = 5 --export
Direction_Indicator_Color = 'white' --export
Prograde_Indicator_Size = 7.5 --export
Prograde_Indicator_Color = 'gold' --export
AP_Brake_Buffer = 5000 --export
AP_Max_Rotation_Factor = 8 --export
AR_Mode = 'NONE' --export
AR_Range = 3 --export
AR_Size = 15 --export
AR_Fill = 'rgb(29, 63, 255)' --export
AR_Outline = 'white' --export
AR_Opacity = '0.5'
AR_Exclude_Moons = true --export
------------------------------------
followID = nil
AR_Custom_Points = {}
AR_Custom = false
AR_Temp = false
AR_Temp_Points = {}
if pcall(require,'autoconf/custom/AR_Waypoints') then 
    waypoints = require('autoconf/custom/AR_Waypoints') 
    for name,pos in pairs(waypoints) do
        AR_Custom_Points[name] = pos
        AR_Custom = true
    end
end
screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
maxFuel = 0
for i,v in pairs(spacefueltank) do maxFuel = maxFuel + v.getMaxVolume() end
currentSystem = Atlas[0]
planets = {}
constructPosition = vec3(construct.getWorldPosition())
warp_beacons = {}
if pcall(require,'autoconf/custom/beacons') then 
    beacons = require('autoconf/custom/beacons') 
    for name,pos in pairs(beacons) do
        warp_beacons[name] = convertWaypoint(pos)
    end
end
for k,v in pairs(currentSystem) do 
    warp_beacons[currentSystem[k]['name'][1]] = vec3(currentSystem[k]['center']) 
    planets[currentSystem[k]['name'][1]] = vec3(currentSystem[k]['center']) 
end
pipes = {}
SZ = vec3(13771471, 7435803, -128971)
inSZ = true
enabledEngineTags = {}
------------------------------------

pitchInput = 0
rollInput = 0
yawInput = 0
brakeInput = 0

Nav = Navigator.new(system, core, unit)
Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, {1000, 5000, 10000, 20000, 30000})
Nav.axisCommandManager:setTargetGroundAltitude(0)

-- Parenting widget
if showDockingPanel then
    parentingPanelId = system.createWidgetPanel("Docking")
    parentingWidgetId = system.createWidget(parentingPanelId,"parenting")
    system.addDataToWidget(unit.getDataId(),parentingWidgetId)
end


-- element widgets
-- For now we have to alternate between PVP and non-PVP widgets to have them on the same side.
if not showRemotePanel then
    unit.hideWidget()
    core.hideWidget()
else
    unit.showWidget()
    core.showWidget()
end

placeRadar = true
if atmofueltank_size > 0 and showFuelPanel then
    _autoconf.displayCategoryPanel(atmofueltank, atmofueltank_size, "Atmo Fuel", "fuel_container")
    if placeRadar then
        _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
        placeRadar = false
    end
end
if spacefueltank_size > 0 and showFuelPanel then
    _autoconf.displayCategoryPanel(spacefueltank, spacefueltank_size, "Space Fuel", "fuel_container")
    if placeRadar then
        _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
        placeRadar = false
    end
end
_autoconf.displayCategoryPanel(rocketfueltank, rocketfueltank_size, "Rocket Fuel", "fuel_container")
if placeRadar then -- We either have only rockets or no fuel tanks at all, uncommon for usual vessels
    _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
    placeRadar = false
end
if antigrav ~= nil then antigrav.show() end
if warpdrive ~= nil then warpdrive.show() end
if gyro ~= nil then gyro.show() end
if shield ~= nil then shield.show() end

-- freeze the player in he is remote controlling the construct
seated = player.isSeated()
if seated == 1 then
    player.freeze(1)
end

if not showHelper then
    system.showHelper(0)
end

-- landing gear
-- make sure every gears are synchonized with the first
gearExtended = (Nav.control.isAnyLandingGearDeployed() == 1) -- make sure it's a lua boolean
if gearExtended then
    Nav.control.deployLandingGears()
else
    Nav.control.retractLandingGears()
end

if vec3(construct.getWorldVelocity()):len() * 3.6 < 500 then
    brakeInput = brakeInput + 1
end

system.showScreen(1)