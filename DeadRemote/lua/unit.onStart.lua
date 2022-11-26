-- Add Valid User ID --
masterPlayerID = player.getId()
pilotName = system.getPlayerName(masterPlayerID)
validPilotCode = '123456' --Your player ID
----------------------

------- Predifined Engine Tags -------
predefinedTags = {}
table.insert(predefinedTags,'military')
table.insert(predefinedTags,'maneuver')
table.insert(predefinedTags,'freight')
--------------------------------------

showAlerts = false

---------------------------------------
hudVersion = 'v4.0.9'
system.print('-- '..hudVersion..' --')
useDB = true --export
caerusOption = false --export
validatePilot = false --export
toggleBrakes = true --export
autoVent = true --export Autovent shield at 0 hp
homeBaseLocation = '' --export Location of home base (to turn off shield)
homeBaseDistance = 5 --export Distance from home base to turn off shield (km)
defaultHoverHeight = 42 --export
topHUDLineColorSZ = 'rgba(150, 175, 185, 1)' --export
topHUDFillColorSZ = 'rgba(25, 25, 50, 0.35)' --export
textColorSZ = 'rgba(225, 250, 265, 1)' --export
topHUDLineColorPVP = 'lightgrey' --export
topHUDFillColorPVP = 'rgba(255, 0, 0, 0.75)' --export
textColorPVP = 'black' --export
fuelTextColor = 'rgba(200, 225, 235, 1)' --export
neutralFontColor = 'white' --export
neutralLineColor = 'lightgrey' --export
Indicator_Width = 1.5
Direction_Indicator_Size = 5 --export
Direction_Indicator_Color = 'rgba(200, 225, 235, 1)' --export
Prograde_Indicator_Size = 7.5 --export
Prograde_Indicator_Color = 'rgb(60, 255, 60)' --export
AP_Brake_Buffer = 5000 --export
AP_Max_Rotation_Factor = 10 --export
AR_Mode = 'NONE' --export
AR_Range = 3 --export
AR_Size = 15 --export
AR_Fill = 'rgb(29, 63, 255)' --export
AR_Outline = 'rgba(125, 150, 160, 1)' --export
AR_Opacity = '0.5' --export
AR_Exclude_Moons = true --export
EngineTagColor = 'rgb(60, 255, 60)' --export
initialResistWait = 15
autoVent = true
warning_size = 0.75 --export How large the warning indicators should be.
warning_outline_color = 'rgb(255, 60, 60)' --export
warning_fill_color = 'rgba(50, 50, 50, 0.9)' --export
useLogo = false --export Enable the logo to be shown on the HUD. Must use the logo variable in unit.onStart and logo must be in SVG format.
logoSVG = '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0" y="0" viewBox="0 0 1024 612" xml:space="preserve" enable-background="new 0 0 1024 612"> 	<defs> 		<filter id="glow"> 			<feGaussianBlur result="coloredBlur" stdDeviation="10"/> 		</filter> 	</defs> 	<style> 		.blue{ 			fill: rgb(255, 65, 65) 		} 		.animationBlur{ 			filter:url(#glow) 		} 		.animationBlur, .animationSolid{ 			fill:rgb(255, 65, 65); 			stroke:rgb(255, 65, 65); 			stroke-width:14; 			stroke-miterlimit:18.6667; 			stroke-dasharray:4000; 		} 	</style> 	 	<path class="animationBlur" d="M313.3 138.1c26.4-2.1 50.1 9.8 64.6 29.1 11.2 14.9 32.4 17.8 47.2 6.3 2.5-2 22.5-17.6 25-19.6 14.2-11.1 16.7-31.6 5.9-46-34-45.1-89.9-72.7-152-67.3-82.9 7.3-149.2 75.1-155 158-6.9 99.9 72.1 183.2 170.5 183.2 43.4-1.8 73.5-14.2 103.8-35.1 43.5-30.1 87.6-77.7 171.6-137.5-28.3 5.8-66.6 20-107.7 34.6-57.1 20.2-119.5 41-167.8 40.1-41.4 0-74.9-34.5-73-76.4 1.7-36.3 30.8-66.5 66.9-69.4z"/> 	<path class="animationSolid" d="M313.3 138.1c26.4-2.1 50.1 9.8 64.6 29.1 11.2 14.9 32.4 17.8 47.2 6.3 2.5-2 22.5-17.6 25-19.6 14.2-11.1 16.7-31.6 5.9-46-34-45.1-89.9-72.7-152-67.3-82.9 7.3-149.2 75.1-155 158-6.9 99.9 72.1 183.2 170.5 183.2 43.4-1.8 73.5-14.2 103.8-35.1 43.5-30.1 87.6-77.7 171.6-137.5-28.3 5.8-66.6 20-107.7 34.6-57.1 20.2-119.5 41-167.8 40.1-41.4 0-74.9-34.5-73-76.4 1.7-36.3 30.8-66.5 66.9-69.4z"/> 	<path class="animationBlur" d="M707 283.9c-26.4 2.1-50.1-9.8-64.6-29.1-11.2-14.9-32.5-17.8-47.2-6.3-2.5 2-22.5 17.6-25 19.5-14.2 11.1-16.7 31.6-5.9 46 34 45.1 89.9 72.7 152 67.3 82.9-7.3 149.1-75 154.9-158 7-99.8-72-183.1-170.5-183.1-43.3 1.8-73.4 14.2-103.8 35.1-43.5 30.1-87.6 77.7-171.6 137.5 28.3-5.8 66.6-20 107.7-34.6 57.1-20.2 119.5-41 167.8-40.1 41.5 0 74.9 34.5 73 76.4-1.6 36.3-30.7 66.5-66.8 69.4z"/> 	<path class="animationSolid" d="M707 283.9c-26.4 2.1-50.1-9.8-64.6-29.1-11.2-14.9-32.5-17.8-47.2-6.3-2.5 2-22.5 17.6-25 19.5-14.2 11.1-16.7 31.6-5.9 46 34 45.1 89.9 72.7 152 67.3 82.9-7.3 149.1-75 154.9-158 7-99.8-72-183.1-170.5-183.1-43.3 1.8-73.4 14.2-103.8 35.1-43.5 30.1-87.6 77.7-171.6 137.5 28.3-5.8 66.6-20 107.7-34.6 57.1-20.2 119.5-41 167.8-40.1 41.5 0 74.9 34.5 73 76.4-1.6 36.3-30.7 66.5-66.8 69.4z"/> 	<g id="g3848"> 		<path id="path83" class="blue" d="M149.6 500.4h13.7v-68.5h-13.7v68.5z"/> 		<path id="path85" class="blue" d="M212.2 500.4h13.7v-47.5l41.1 47.5h13.7v-68.5H267v47.5l-41.1-47.5h-13.7v68.5z"/> 		<path id="path87" class="blue" d="M329.5 500.4h13.7V473h41.1v-13.7h-41.1v-13.7H398v-13.7h-68.5v68.5z"/> 		<path id="path89" class="blue" d="M446.8 500.4h13.7v-68.5h-13.7v68.5z"/> 		<path id="path91" class="blue" d="M509.3 500.4H523v-47.5l41.1 47.5h13.7v-68.5h-13.7v47.5L523 431.9h-13.7v68.5z"/> 		<path id="path93" class="blue" d="M626.7 500.4h13.7v-68.5h-13.7v68.5z"/> 		<path id="path95" class="blue" d="M689.2 431.9v13.7h27.4v54.8h13.7v-54.8h27.4v-13.7h-68.5z"/> 		<path id="path97" class="blue" d="M806.5 431.9v10.3c0 5.7 2.8 10.4 6.1 13.1l21.3 17.7v27.4h13.7V473l21.3-17.7c3.3-2.7 6.1-7.5 6.1-13.1v-10.3h-13.7v10.3c0 .9-.4 2-1.2 2.6L840.7 461l-19.4-16.2c-.8-.6-1.2-1.6-1.2-2.6v-10.3h-13.6z"/> 	</g> 	<g id="g3838"><path id="path60" class="blue" d="M206.4 534.3h-44.5c-8.2 0-14.8 6.7-14.8 14.8v29.7c0 8.2 6.7 14.8 14.8 14.8h44.5v-9.7h-44.5c-2.8 0-5.2-2.4-5.2-5.2V549c0-2.8 2.4-5.2 5.2-5.2h44.5v-9.5z"/> 		<path id="path62" class="blue" d="M218.3 578.9c0 8.2 6.7 14.8 14.8 14.8h29.7c8.2 0 14.8-6.7 14.8-14.8v-29.7c0-8.2-6.7-14.8-14.8-14.8h-29.7c-8.2 0-14.8 6.7-14.8 14.8v29.7zm14.9 5.2c-2.8 0-5.2-2.4-5.2-5.2v-29.7c0-2.8 2.4-5.2 5.2-5.2h29.7c2.8 0 5.2 2.4 5.2 5.2v29.7c0 2.8-2.4 5.2-5.2 5.2h-29.7z"/> 		<path id="path64" class="blue" d="M289.7 593.7h9.7v-24.9h20.3l17.5 24.9h11.9l-17.5-24.9h2.7c8.2 0 14.8-6.7 14.8-14.8v-4.8c0-8.2-6.7-14.8-14.8-14.8h-44.5v59.3zm9.6-34.5V544h34.9c2.8 0 5.2 2.4 5.2 5.2v4.8c0 2.8-2.4 5.2-5.2 5.2h-34.9z"/> 		<path id="path66" class="blue" d="M361 593.7h9.7v-24.9h34.9c8.2 0 14.8-6.7 14.8-14.8v-4.8c0-8.2-6.7-14.8-14.8-14.8H361v59.3zm9.7-34.5V544h34.9c2.8 0 5.2 2.4 5.2 5.2v4.8c0 2.8-2.4 5.2-5.2 5.2h-34.9z"/> 		<path id="path68" class="blue" d="M432.4 578.9c0 8.2 6.7 14.8 14.8 14.8h29.7c8.2 0 14.8-6.7 14.8-14.8v-29.7c0-8.2-6.7-14.8-14.8-14.8h-29.7c-8.2 0-14.8 6.7-14.8 14.8v29.7zm14.8 5.2c-2.8 0-5.2-2.4-5.2-5.2v-29.7c0-2.8 2.4-5.2 5.2-5.2h29.7c2.8 0 5.2 2.4 5.2 5.2v29.7c0 2.8-2.4 5.2-5.2 5.2h-29.7z"/> 		<path id="path70" class="blue" d="M503.7 593.7h9.7v-24.9h20.3l17.5 24.9h11.9l-17.5-24.9h2.7c8.2 0 14.8-6.7 14.8-14.8v-4.8c0-8.2-6.7-14.8-14.8-14.8h-44.5v59.3zm9.7-34.5V544h34.9c2.8 0 5.2 2.4 5.2 5.2v4.8c0 2.8-2.4 5.2-5.2 5.2h-34.9z"/> 		<path id="path72" class="blue" d="M575.1 593.7h9.7v-24.9h40.1v24.9h9.7v-44.5c0-8.2-6.7-14.8-14.8-14.8h-29.7c-8.2 0-14.8 6.7-14.8 14.8l-.2 44.5zm9.6-34.5v-10c0-2.8 2.4-5.2 5.2-5.2h29.7c2.8 0 5.2 2.4 5.2 5.2v10h-40.1z"/> 		<path id="path74" class="blue" d="M646.4 534.3v9.7h24.9v49.7h9.7V544h24.9v-9.7h-59.5z"/> 		<path id="path76" class="blue" d="M718.9 593.7h9.7v-59.4h-9.7v59.4z"/><path id="path78" class="blue" d="M741.6 578.9c0 8.2 6.7 14.8 14.8 14.8h29.7c8.2 0 14.8-6.7 14.8-14.8v-29.7c0-8.2-6.7-14.8-14.8-14.8h-29.7c-8.2 0-14.8 6.7-14.8 14.8v29.7zm14.8 5.2c-2.8 0-5.2-2.4-5.2-5.2v-29.7c0-2.8 2.4-5.2 5.2-5.2h29.7c2.8 0 5.2 2.4 5.2 5.2v29.7c0 2.8-2.4 5.2-5.2 5.2h-29.7z"/> 		<path id="path80" class="blue" d="M812.9 593.7h9.7v-44.6l40.1 44.6h9.7v-59.4h-9.7V579l-40.1-44.6h-9.7v59.3z"/> 	</g> </svg>' --export SVG Logo that will be placed in the top left of the HUD (automatically scaled)
showRemotePanel = false --export
showDockingPanel = false --export
showFuelPanel = false --export
showHelper = false --export
showShieldWidget = false --export

minimalWidgets = false
-- HP (Shield/CCS) widget --
hpWidgetX = 33 --export
hpWidgetY = 88 --export
hpWidgetScale = 17 --export
shieldHPColor = 'rgb(25, 247, 255)' --export
ccsHPColor = 'rgb(60, 255, 60)' --export
-- Resist Widget --
resistWidgetX = 45 --export
resistWidgetY = 82 --export
resistWidgetScale = 8.5 --export
antiMatterColor = 'rgb(56, 255, 56)' --export
electroMagneticColor = 'rgb(27, 255, 217)' --export
kineticColor = 'rgb(255, 75, 75)' --export
thermicColor = 'rgb(255, 234, 41)' --export

-- Transponder Widget --
transponderWidgetX = 40 --export
transponderWidgetY = 67 --export
transponderWidgetScale = 11.25 --export

transponderWidgetXmin = 58.5 --export
transponderWidgetYmin = -0.9 --export
transponderWidgetScalemin = 10 --export

-- Ship information Widget --
shipInfoWidgetX = 76.5
shipInfoWidgetY = -0.9
shipInfoWidgetScale = 10

-- WayPoint File Info
validWaypointFiles = {}
------------------------------------

userCode = {}
userCode[validPilotCode] = pilotName
if db_1 ~= nil and useDB then
    globalDB('get')
end

if caerusOption then
    shipInfoWidgetX = 53
    shipInfoWidgetY = 80
    shipInfoWidgetScale = 12
end

if db_1 ~= nil then
    for _,key in pairs(db_1.getKeyList()) do
        if db_1.getStringValue(key) ~= nil and db_1.getStringValue(key) ~= '' and string.starts(key,'uc-') then 
            userCode[string.sub(key,4)] = db_1.getStringValue(key)
        end
    end
end

-- Transponder --
showCode = false
codeTimer = 5
codeCount = 0
codeSeed = nil
tags = {}
transponderStatus = false
tCode = nil
cOverlap = false
cOverlapTick = 0
codeSeed = nil
rollTimer = 120 --Roll code timer in seconds
if pcall(require,'autoconf/custom/transponder') then 
    codeSeed = tonumber(require('autoconf/custom/transponder'))
end
unit.setTimer('code',0.25)

-----------------

---- Initialization ---
arkTime = system.getArkTime()
constructPosition = vec3(construct.getWorldPosition())
cr = nil
followID = nil
followSpeedMod = 0
AR_Custom_Points = {}
AR_Custom = false
AR_Temp = false
AR_Temp_Points = {}

AR_Array = {}

legacyFile = false
if pcall(require,'autoconf/custom/DeadRemote_CustomFileIndex') then
    customFiles = require('autoconf/custom/DeadRemote_CustomFileIndex')
    if type(customFiles) == "table" then
        for waypointFileId,waypointFile in ipairs(customFiles) do
            system.print('Found waypointFileId: '..waypointFileId..' displayName='..waypointFile.DisplayName..' waypointFilePath='..waypointFile.FilePath)
            if pcall(require,waypointFile.FilePath) then
                waypoints = require(waypointFile.FilePath)
                if type(waypoints) == "table" then
                    table.insert(validWaypointFiles,waypointFile)
                    AR_Array[#validWaypointFiles] = {}
                    system.print('Adding waypoints from '..waypointFile.FilePath)
                    for name,pos in pairs(waypoints) do
                        AR_Custom_Points[name] = pos
                                        AR_Array[#validWaypointFiles][name]=pos
                        AR_Custom = true
                    end
                else
                    system.print('Failed to load waypoints from '..waypointFile.FilePath)
                end
            else
                system.print('Failed to load waypoints from '..waypointFile.FilePath)
            end
        end
    end
else
    legacyFile = true
    if pcall(require,'autoconf/custom/AR_Waypoints') then 
        waypoints = require('autoconf/custom/AR_Waypoints') 
        for name,pos in pairs(waypoints) do
            AR_Custom_Points[name] = pos
            AR_Custom = true
        end
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
milEng = false
------------------------------------

-- Shield Initialize --
dmgTick = 0
homeBaseVec = vec3()
if homeBaseLocation ~= '' then
    homeBaseVec = vec3(convertWaypoint(homeBaseLocation))
end
--------

pitchInput = 0
rollInput = 0
yawInput = 0
brakeInput = 0
spaceBar = false

Nav = Navigator.new(system, core, unit)
Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, {1000, 5000, 10000, 20000, 30000, 40000, 50000})
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
if antigrav ~= nil then antigrav.showWidget() end
if warpdrive ~= nil then warpdrive.showWidget() end
if gyro ~= nil then gyro.showWidget() end
if shield_1 ~= nil and showShieldWidget then shield_1.showWidget() end

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
gearExtended = (Nav.control.isAnyLandingGearDeployed() == 1) -- make sure it is a lua boolean
if gearExtended then
    Nav.control.deployLandingGears()
else
    Nav.control.retractLandingGears()
end

if vec3(construct.getWorldVelocity()):len() * 3.6 < 500 then
    brakeInput = brakeInput + 1
end

lShift = false
lAlt = false

-- Validate pilot mode --
if validatePilot then
    local validPilot = false
    for k,v in pairs(userCode) do 
        if k == tostring(player.getId()) then validPilot = true system.print(string.format('-- Welcome %s --',pilotName)) break end
    end
    if not validPilot then
        system.print(player.getId())
        unit.exit()
    end
end
----------------------------

showScreen = true
fuelWarningText = ''
warnings = {}
warningSymbols = {}
warningSymbols['svgCritical'] = [[
                <svg x="0px" y="0px" viewBox="0 0 414.205 414.205" style="enable-background:new 0 0 414.205 414.205;">
                    <g>
                        <g>
                            <polygon points="188.077,129.985 188.077,129.99 165.759,226.671 216.626,207.046 204.891,257.867 194.589,257.867 
                                206.99,293.641 235.908,257.867 225.606,257.867 244.561,175.773 193.693,195.398 208.797,129.985 		"/>
                            <path d="M39.11,207.103l167.992,167.992L375.09,207.103L207.103,39.116L39.11,207.103z M207.103,351.103l-143.995-144
                                L207.103,63.108l143.99,143.995L207.103,351.103z"/>
                            <path d="M405.093,185.102L229.103,9.112c-12.15-12.15-31.846-12.15-43.996,0L9.112,185.102c-12.15,12.15-12.15,31.846,0,43.996
                                l175.99,175.995c12.15,12.15,31.846,12.15,43.996,0l175.995-175.99C417.243,216.954,417.243,197.252,405.093,185.102z
                                M393.092,217.097l-175.985,176c-2.673,2.668-6.226,4.137-10.004,4.137s-7.327-1.469-9.999-4.137L21.108,217.102
                                c-5.514-5.514-5.514-14.484,0-19.999L197.103,21.108c2.673-2.667,6.221-4.137,9.999-4.137s7.332,1.469,10.004,4.142l175.99,175.99
                                c2.673,2.673,4.142,6.226,4.142,9.999S395.764,214.429,393.092,217.097z"/>
                        </g>
                    </g>
                </svg>
            ]]
warningSymbols['svgWarning'] = [[
                <svg x="0px" y="0px"
                    viewBox="0 0 192.146 192.146" style="enable-background:new 0 0 192.146 192.146;" >
                    <g>
                        <g>
                            <g>
                                <path d="M108.186,144.372c0,7.054-4.729,12.32-12.037,12.32h-0.254c-7.054,0-11.92-5.266-11.92-12.32
                                    c0-7.298,5.012-12.31,12.174-12.31C103.311,132.062,108.059,137.054,108.186,144.372z M88.44,125.301h15.447l2.951-61.298H85.46
                                    L88.44,125.301z M190.372,177.034c-2.237,3.664-6.214,5.921-10.493,5.921H12.282c-4.426,0-8.51-2.384-10.698-6.233
                                    c-2.159-3.849-2.11-8.549,0.147-12.349l84.111-149.22c2.208-3.722,6.204-5.96,10.522-5.96h0.332
                                    c4.445,0.107,8.441,2.618,10.513,6.546l83.515,149.229C192.717,168.768,192.629,173.331,190.372,177.034z M179.879,170.634
                                    L96.354,21.454L12.292,170.634H179.879z"/>
                            </g>
                        </g>
                    </g>
                </svg>
            ]]
warningSymbols['svgTarget'] = [[
                <svg x="0px" y="0px" viewBox="0 0 330 330" style="enable-background:new 0 0 330 330;">
                    <g id="XMLID_813_">
                        <path id="XMLID_814_" d="M15,130c8.284,0,15-6.716,15-15V30h85c8.284,0,15-6.716,15-15s-6.716-15-15-15H15C6.716,0,0,6.716,0,15
                            v100C0,123.284,6.716,130,15,130z"/>
                        <path id="XMLID_815_" d="M15,330h100c8.284,0,15-6.716,15-15s-6.716-15-15-15H30v-85c0-8.284-6.716-15-15-15s-15,6.716-15,15v100
                            C0,323.284,6.716,330,15,330z"/>
                        <path id="XMLID_816_" d="M315,200c-8.284,0-15,6.716-15,15v85h-85c-8.284,0-15,6.716-15,15s6.716,15,15,15h100
                            c8.284,0,15-6.716,15-15V215C330,206.716,323.284,200,315,200z"/>
                        <path id="XMLID_817_" d="M215,30h85v85c0,8.284,6.716,15,15,15s15-6.716,15-15V15c0-8.284-6.716-15-15-15H215
                            c-8.284,0-15,6.716-15,15S206.716,30,215,30z"/>
                        <path id="XMLID_818_" d="M75,165c0,8.284,6.716,15,15,15h60v60c0,8.284,6.716,15,15,15s15-6.716,15-15v-60h60
                            c8.284,0,15-6.716,15-15s-6.716-15-15-15h-60V90c0-8.284-6.716-15-15-15s-15,6.716-15,15v60H90C81.716,150,75,156.716,75,165z"/>
                    </g>
                </svg>
            ]]
warningSymbols['svgGroup'] = [[
                <svg x="0px" y="0px" viewBox="0 0 487.3 487.3" style="enable-background:new 0 0 487.3 487.3;" >
                    <g>
                        <g>
                            <g>
                                <path d="M362.1,326.05c-32.6-26.8-67.7-44.5-74.9-48c-0.8-0.4-1.3-1.2-1.3-2.1v-50.7c6.4-4.3,10.6-11.5,10.6-19.7v-52.6
                                    c0-26.2-21.2-47.4-47.4-47.4h-5.6h-5.7c-26.2,0-47.4,21.2-47.4,47.4v52.6c0,8.2,4.2,15.5,10.6,19.7v50.7c0,0.9-0.5,1.7-1.3,2.1
                                    c-7.2,3.5-42.3,21.3-74.9,48c-5.9,4.8-9.3,12.1-9.3,19.7v36h128h127.9v-36C371.4,338.15,368,330.85,362.1,326.05z"/>
                            </g>
                            <g>
                                <path d="M479.2,290.55c-27.3-22.5-56.8-37.4-62.8-40.3c-0.7-0.3-1.1-1-1.1-1.8v-42.5c5.3-3.6,8.9-9.6,8.9-16.6v-44.1
                                    c0-21.9-17.8-39.7-39.7-39.7h-4.7h-4.7c-21.9,0-39.7,17.8-39.7,39.7v44.1c0,6.9,3.5,13,8.9,16.6v42.5c0,0.8-0.4,1.4-1.1,1.8
                                    c-3.7,1.8-16.5,8.2-32.1,18.2c15.6,8.6,40.3,23.4,63.6,42.6c8.2,6.7,13.6,16,15.6,26.2h97v-30.2
                                    C487,300.65,484.2,294.55,479.2,290.55z"/>
                            </g>
                            <g>
                                <path d="M144,250.25c-0.7-0.3-1.1-1-1.1-1.8v-42.5c5.3-3.6,8.9-9.6,8.9-16.6v-44.1c0-21.9-17.8-39.7-39.7-39.7h-4.7h-4.9
                                    c-21.9,0-39.7,17.8-39.7,39.7v44.1c0,6.9,3.5,13,8.9,16.6v42.5c0,0.8-0.4,1.4-1.1,1.8c-6,2.9-35.5,17.8-62.8,40.3
                                    c-4.9,4.1-7.8,10.1-7.8,16.5v30.2h97c1.9-10.2,7.4-19.5,15.6-26.2c23.3-19.2,48-34,63.6-42.6
                                    C160.5,258.45,147.7,252.05,144,250.25z"/>
                            </g>
                        </g>
                    </g>
                </svg>
            ]]
warningSymbols['svgBrakes'] = [[
                <svg x="0px" y="0px" viewBox="0 0 234.409 234.409" style="enable-background:new 0 0 234.409 234.409;">
                    <g>
                        <path d="M117.204,30.677c-47.711,0-86.527,38.816-86.527,86.528c0,47.711,38.816,86.526,86.527,86.526s86.527-38.815,86.527-86.526
                            C203.732,69.494,164.915,30.677,117.204,30.677z M117.204,188.732c-39.44,0-71.527-32.086-71.527-71.526
                            c0-39.441,32.087-71.528,71.527-71.528s71.527,32.087,71.527,71.528C188.732,156.645,156.645,188.732,117.204,188.732z"/>
                        <path d="M44.896,44.897c2.929-2.929,2.929-7.678,0-10.607c-2.93-2.929-7.678-2.929-10.607,0
                            c-45.718,45.719-45.718,120.111,0,165.831c1.465,1.465,3.384,2.197,5.304,2.197c1.919,0,3.839-0.732,5.303-2.197
                            c2.93-2.929,2.93-7.677,0.001-10.606C5.026,149.643,5.026,84.768,44.896,44.897z"/>
                        <path d="M200.119,34.29c-2.93-2.929-7.678-2.929-10.607,0c-2.929,2.929-2.929,7.678,0,10.607
                            c39.872,39.871,39.872,104.746,0,144.618c-2.929,2.929-2.929,7.678,0,10.606c1.465,1.464,3.385,2.197,5.304,2.197
                            c1.919,0,3.839-0.732,5.304-2.197C245.839,154.4,245.839,80.009,200.119,34.29z"/>
                        <path d="M117.204,140.207c4.143,0,7.5-3.358,7.5-7.5v-63.88c0-4.142-3.357-7.5-7.5-7.5c-4.143,0-7.5,3.358-7.5,7.5v63.88
                            C109.704,136.849,113.062,140.207,117.204,140.207z"/>
                        <circle cx="117.204" cy="156.254" r="9.329"/>
                    </g>
                </svg>
            ]]


unit.setTimer('screen',0.025)
system.showScreen(1)