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
hudVersion = 'v2.0.4'
validatePilot = false --export
useDB = true --export
showRemotePanel = false --export
showDockingPanel = false --export
showFuelPanel = false --export
showHelper = false --export
showShieldWidget = false --export
defaultHoverHeight = 42 --export
defautlFollowDistance = 40 --export
followMaxSpeedGain = 4000 --export
topHUDLineColorSZ = 'rgba(125, 150, 160, 1)' --export
topHUDFillColorSZ = 'rgba(20, 114, 209, 0.75)' --export
textColorSZ = 'rgba(200, 225, 235, 1)' --export
topHUDLineColorPVP = 'lightgrey' --export
topHUDFillColorPVP = 'rgba(255, 0, 0, 0.75)' --export
textColorPVP = 'black' --export
fuelTextColor = 'rgba(200, 225, 235, 1)' --export
Indicator_Width = 1.5
Direction_Indicator_Size = 5 --export
Direction_Indicator_Color = 'rgba(200, 225, 235, 1)' --export
Prograde_Indicator_Size = 7.5 --export
Prograde_Indicator_Color = 'rgb(60, 255, 60)' --export
AP_Brake_Buffer = 5000 --export
AP_Max_Rotation_Factor = 20 --export
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
logoSVG = '<svg viewBox="100 0 200 500" width="400" height="500"> 	  <polygon style="paint-order: fill; stroke: rgb(191, 166, 95); stroke-width: 1.5px; stroke-linecap: round; stroke-miterlimit: 1; fill: rgb(14, 3, 27); stroke-linejoin: round;" points="0 135.706 61.665 51.467 224.57 51.299 287 135.581 143.921 492.818"/> 	  <polygon style="stroke-width: 0.5px; fill: rgb(191, 166, 95); stroke: rgb(191, 166, 95); stroke-linecap: round; stroke-linejoin: round;" points="19.464 141.252 92.171 169.799 89.762 190.81 118.569 237.883 81.34 295.081"/> 	  <polygon style="stroke-width: 0.5px; fill: rgb(191, 166, 95); stroke: rgb(191, 166, 95); stroke-linecap: round; stroke-linejoin: round;" points="94.088 166.745 18.487 137.186 71.808 64.673 140.04 139.503"/> 	  <polygon style="stroke-width: 0.5px; fill: rgb(191, 166, 95); stroke: rgb(191, 166, 95); stroke-linecap: round; stroke-linejoin: round;" points="82.857 298.873 120.362 241.689 120.227 220.611 95.445 193.609 125.12 219.307 125.142 252.811 143.672 276.36 161.82 252.425 161.851 218.589 191.413 194.022 166.914 220.994 166.575 240.41 204.615 298.826 144.742 448.602 144.861 284.752 178.001 269.382 165.761 255.903 143.642 282.037 121.43 255.717 107.87 269.269 141.945 284.668 142.287 448.443"/> 	  <polygon style="stroke-width: 0.5px; fill: rgb(191, 166, 95); stroke: rgb(191, 166, 95); stroke-linecap: round; stroke-linejoin: round;" points="221.951 64.868 146.688 94.764 200.119 166.941 268.131 92.223" transform="matrix(-1, 0, 0, -1, 414.819031, 231.80899)"/> 	  <polygon style="stroke-width: 0.5px; fill: rgb(191, 166, 95); stroke: rgb(191, 166, 95); stroke-linecap: round; stroke-linejoin: round;" points="142.453 64.685 75.919 137.818 210.604 137.697 144.206 64.724" transform="matrix(-1, 0, 0, -1, 286.52298, 202.502991)"/> 	  <polygon style="stroke-width: 0.5px; fill: rgb(191, 166, 95); stroke: rgb(191, 166, 95); stroke-linecap: round; stroke-linejoin: round;" points="168.836 294.998 241.703 266.291 239.538 244.634 268.022 197.642 231.035 140.523" transform="matrix(-1, 0, 0, -1, 436.858002, 435.520996)"/> 	  <path d="M 84.617 39.914 Q 75.887 47.433 68.7 47.433 Q 62.834 47.433 58.166 42.958 Q 53.498 38.482 53.498 30.634 Q 53.498 25.154 55.921 20.83 Q 58.345 16.506 62.792 13.56 Q 67.24 10.613 73.491 10.613 Q 78.944 10.613 83.791 12.32 L 83.791 20.637 L 81.836 20.637 Q 81.478 16.727 78.393 14.537 Q 75.309 12.348 71.04 12.348 Q 65.064 12.348 61.65 16.727 Q 58.235 21.105 58.235 27.467 Q 58.235 34.352 62.118 38.896 Q 66.001 43.439 72.087 43.439 Q 78.173 43.439 84.617 38.235 Z M 101.097 20.692 Q 106.302 20.692 109.427 23.956 Q 112.553 27.219 112.553 32.644 Q 112.553 39.088 108.202 43.26 Q 103.851 47.433 98.618 47.433 Q 93.386 47.433 90.357 44.114 Q 87.327 40.796 87.327 35.481 Q 87.327 29.147 91.637 24.919 Q 95.947 20.692 101.097 20.692 Z M 98.756 22.84 Q 95.011 22.84 93.028 25.512 Q 91.045 28.183 91.045 32.204 Q 91.045 37.161 94.171 41.057 Q 97.296 44.954 101.455 44.954 Q 104.539 44.954 106.673 42.393 Q 108.808 39.832 108.808 35.701 Q 108.808 31.873 107.1 28.83 Q 105.393 25.787 103.19 24.314 Q 100.987 22.84 98.756 22.84 Z M 115.294 23.584 L 122.537 20.637 L 123.748 20.637 L 123.748 29.587 Q 126.585 24.74 128.816 22.716 Q 131.046 20.692 133.387 20.692 Q 134.296 20.692 135.563 21.105 L 135.563 29.587 L 133.607 29.587 Q 133.58 24.603 130.716 24.603 Q 127.879 24.603 125.662 29.243 Q 123.445 33.883 123.445 39.749 Q 123.445 43.219 124.726 44.266 Q 126.007 45.312 129.614 45.312 L 129.614 46.634 L 115.294 46.634 L 115.294 45.312 Q 117.552 45.257 118.543 44.334 Q 119.535 43.412 119.535 41.016 L 119.535 26.723 Q 119.535 24.3 117.745 24.3 Q 117.001 24.3 115.294 24.906 Z M 138.075 23.584 L 145.318 20.637 L 146.53 20.637 L 146.53 29.587 Q 149.366 24.74 151.597 22.716 Q 153.827 20.692 156.168 20.692 Q 157.077 20.692 158.344 21.105 L 158.344 29.587 L 156.389 29.587 Q 156.361 24.603 153.497 24.603 Q 150.66 24.603 148.444 29.243 Q 146.227 33.883 146.227 39.749 Q 146.227 43.219 147.507 44.266 Q 148.788 45.312 152.395 45.312 L 152.395 46.634 L 138.075 46.634 L 138.075 45.312 Q 140.333 45.257 141.325 44.334 Q 142.316 43.412 142.316 41.016 L 142.316 26.723 Q 142.316 24.3 140.526 24.3 Q 139.783 24.3 138.075 24.906 Z M 167.328 9.181 Q 168.512 9.181 169.27 9.966 Q 170.027 10.751 170.027 11.825 Q 170.027 12.899 169.256 13.67 Q 168.485 14.441 167.383 14.441 Q 166.309 14.441 165.538 13.684 Q 164.767 12.926 164.767 11.825 Q 164.767 10.668 165.566 9.924 Q 166.364 9.181 167.328 9.181 Z M 161.077 45.312 Q 163.197 45.257 164.244 44.39 Q 165.29 43.522 165.29 41.016 L 165.29 25.952 Q 165.29 24.217 163.307 24.217 Q 162.591 24.217 161.738 24.575 Q 161.297 24.768 161.077 24.823 L 161.077 23.419 L 168.127 20.637 L 169.476 20.637 L 169.476 41.016 Q 169.476 43.467 170.495 44.362 Q 171.514 45.257 173.69 45.312 L 173.69 46.634 L 161.077 46.634 Z M 176.259 23.529 L 183.419 20.61 L 184.576 20.61 L 184.576 29.67 Q 188.541 24.382 191.102 22.496 Q 193.664 20.61 195.949 20.61 Q 200.603 20.61 200.603 26.586 L 200.603 41.016 Q 200.603 43.467 201.609 44.362 Q 202.614 45.257 204.817 45.312 L 204.817 46.634 L 195.233 46.634 L 195.233 45.312 Q 196.39 45.257 196.39 43.963 L 196.39 26.944 Q 196.39 25.512 195.646 24.644 Q 194.903 23.777 193.719 23.777 Q 190.249 23.777 187.261 28.692 Q 184.273 33.608 184.273 39.97 Q 184.273 43.192 185.264 44.224 Q 186.256 45.257 188.789 45.312 L 188.789 46.634 L 176.259 46.634 L 176.259 45.312 Q 178.49 45.257 179.467 44.348 Q 180.445 43.439 180.445 41.016 L 180.445 26.944 Q 180.445 24.217 178.627 24.217 Q 177.966 24.217 176.259 24.906 Z M 221.003 20.692 Q 226.208 20.692 229.334 23.956 Q 232.459 27.219 232.459 32.644 Q 232.459 39.088 228.108 43.26 Q 223.757 47.433 218.525 47.433 Q 213.292 47.433 210.263 44.114 Q 207.234 40.796 207.234 35.481 Q 207.234 29.147 211.543 24.919 Q 215.853 20.692 221.003 20.692 Z M 218.662 22.84 Q 214.917 22.84 212.934 25.512 Q 210.951 28.183 210.951 32.204 Q 210.951 37.161 214.077 41.057 Q 217.203 44.954 221.361 44.954 Q 224.445 44.954 226.58 42.393 Q 228.714 39.832 228.714 35.701 Q 228.714 31.873 227.007 28.83 Q 225.299 25.787 223.096 24.314 Q 220.893 22.84 218.662 22.84 Z" style="fill: rgb(14, 3, 27); white-space: pre;"/> 	</svg>' --export SVG Logo that will be placed in the top left of the HUD (automatically scaled)
------------------------------------

userCode = {}
userCode[validPilotCode] = pilotName
if db_1 ~= nil and useDB then
    globalDB('get')
end

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
gearExtended = (Nav.control.isAnyLandingGearDeployed() == 1) -- make sure it's a lua boolean
if gearExtended then
    Nav.control.deployLandingGears()
else
    Nav.control.retractLandingGears()
end

if vec3(construct.getWorldVelocity()):len() * 3.6 < 500 then
    brakeInput = brakeInput + 1
end

lShift = false

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

system.showScreen(1)