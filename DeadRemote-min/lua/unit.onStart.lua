-- Add Valid User ID --
masterPlayerID = player.getId()
pilotName = system.getPlayerName(masterPlayerID)
validPilotCode = '123456' --Your player ID
----------------------

hudVersion = 'v5.0.9-min'
system.print('-- '..hudVersion..' --')
offset_points = false --export Puts additional position markers around your ship
dampenerTorqueReduction = .01 --export 0 is no adjustors, 1 is full adjustors
screenRefreshRate = 0.25 --export
useDB = true --export
validatePilot = false --export
toggleBrakes = true --export
autoVent = true --export Autovent shield at 0 hp
dmgAvgDuration = 10 --export Duration to avg incoming damage over
trackerMode = false --export Use input position tags as location trackers instead of auto-pilot
trackerList = {}
homeBaseLocation = '' --export Location of home base (to turn off shield)
homeBaseDistance = 5 --export Distance from home base to turn off shield (km)
boosterSpeedThreshold = 55000 --export km/h
AP_Brake_Buffer = 5000 --export
AP_Max_Rotation_Factor = 10 --export
AR_Mode = 'NONE' --export
AR_Exclude_Moons = true --export
initialResistWait = 15
dampening = true --inertial dampening
route_speed = 20000 --export max speed to fly routes

-- HP (Shield/CCS) widget --
shieldProfile = 'auto'
resistProfiles = {}
resistProfiles['auto'] = {['am']=0, ['em']=0, ['kn']=0, ['th']=0}
resistProfiles['cannon'] = {['am']=0, ['em']=0, ['kn']=0.5, ['th']=0.5}
resistProfiles['railgun'] = {['am']=0.5, ['em']=0.5, ['kn']=0, ['th']=0}
resistProfiles['missile'] = {['am']=0.5, ['em']=0, ['kn']=0.5, ['th']=0}
resistProfiles['laser'] = {['am']=0, ['em']=0.5, ['kn']=0, ['th']=0.5}
resistProfiles['am'] = {['am']=1, ['em']=0, ['kn']=0, ['th']=0}
resistProfiles['em'] = {['am']=0, ['em']=1, ['kn']=0, ['th']=0}
resistProfiles['kn'] = {['am']=0, ['em']=0, ['kn']=1, ['th']=0}
resistProfiles['th'] = {['am']=0, ['em']=0, ['kn']=0, ['th']=1}

-- Element Damage Groups --
DamageGroupMap = {}
DamageGroupMap['Engine'] = {}
DamageGroupMap['Engine']['Total'] = 0
DamageGroupMap['Engine']['Current'] = 0

DamageGroupMap['Control'] = {}
DamageGroupMap['Control']['Total'] = 0
DamageGroupMap['Control']['Current'] = 0

DamageGroupMap['Weapons'] = {}
DamageGroupMap['Weapons']['Total'] = 0
DamageGroupMap['Weapons']['Current'] = 0

DamageGroupMap['Misc'] = {}
DamageGroupMap['Misc']['Total'] = 0
DamageGroupMap['Misc']['Current'] = 0

brokenElements = {}
brokenElements['Engine'] = {}
brokenElements['Control'] = {}
brokenElements['Weapons'] = {}

brokenDisplay = {}
brokenDisplay['Engine'] = ''
brokenDisplay['Control'] = ''
brokenDisplay['Weapons'] = ''

fontColor = 'Red;'

-- WayPoint File Info
validWaypointFiles = {}
------------------------------------
boosterOn = false
boosterPulseOn = false
boosterCount = 0


userCode = {}
userCode[validPilotCode] = pilotName
if db_1 ~= nil and useDB then
    globalDB('get')
end

if db_1 ~= nil then
    for _,key in pairs(db_1.getKeyList()) do
        if db_1.getStringValue(key) ~= nil and db_1.getStringValue(key) ~= '' and string.starts(key,'uc-') then 
            userCode[string.sub(key,4)] = db_1.getStringValue(key)
        end
    end
end

-----------------

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
ticker = 0
arkTime = system.getArkTime()
dpsChart = {}
CCSPercent = 0
ccsHTML = ''
shieldPercent = 0
shieldHTML = ''
shieldWarningHTML = ''
ventHTML = ''
shield_resist_cd = 0
amS = 0
emS = 0
knS = 0
thS = 0
amR = 0
emR = 0
knR = 0
thR = 0
constructPosition = vec3(construct.getWorldPosition())
constructForward = vec3(construct.getWorldOrientationForward())
constructVelocity = vec3(construct.getWorldVelocity())
speed = 0
apHTML = ''
apStatus = 'inactive'
apBG = ''
SZDStr = ''
cName = construct.getName()
cID = construct.getId()
cr = nil
cr_ar = nil

dockedMass = 0
maxThrustTags = 'thrust'
FPS = 0
FPS_COUNTER = 0
FPS_INTERVAL = arkTime

AR_Custom_Points = {}
AR_Custom = false
AR_Temp = false
AR_Temp_Points = {}
AR_Array = {}
dpsHTML = ''
fuelHTML = ''
shipNameHTML = shipNameWidget()
systemCheckHTML = ''

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

-- Import routes file --
routes = {}
route = nil
route_pos = nil
if db_1 then
    db_1.setIntValue('record',0)
end
if pcall(require,'autoconf/custom/routes') then
    routes = require('autoconf/custom/routes')
end

screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
maxFuel = 0
sFuelPercent = 0
maxBrake = 0
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
enabledEngineTagsStr = ''
closestPipeStr = ''
closestPlanetStr = ''
milEng = false
if shield_1 then
    srp = shield_1.getResistancesPool()
    csr = shield_1.getResistances()
    rcd = shield_1.getResistancesCooldown()
    rem = shield_1.getResistancesRemaining()
    srr = shield_1.getStressRatioRaw()
    maxCD = shield_1.getResistancesMaxCooldown()
    venting = shield_1.isVenting()
    shp = shield_1.getShieldHitpoints()
    maxSHP = shield_1.getMaxShieldHitpoints()
    ventCD = shield_1.getVentingCooldown()
else
    srp = {}
    csr = {}
    rcd = 0
    rem = 0
    srr = {}
    maxCD = 0
    venting = 0
    shp = 0
    maxSHP = 0
    ventCD = 0
end
coreHP = 0
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


-- element widgets
unit.hideWidget()
core.hideWidget()

placeRadar = true
_autoconf.displayCategoryPanel(rocketfueltank, rocketfueltank_size, "Rocket Fuel", "fuel_container")
if placeRadar then -- We either have only rockets or no fuel tanks at all, uncommon for usual vessels
    _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
    placeRadar = false
end
if antigrav ~= nil then antigrav.showWidget() end
if warpdrive ~= nil then warpdrive.showWidget() end
if gyro ~= nil then gyro.showWidget() end

-- freeze the player in he is remote controlling the construct
seated = player.isSeated()
if seated then
    player.freeze(1)
end

system.showHelper(0)

-- landing gear
-- make sure every gears are synchonized with the first
gearExtended = (Nav.control.isAnyLandingGearDeployed()) -- make sure it is a lua boolean
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
        if k == tostring(player.getId()) then 
            validPilot = true 
            system.print(string.format('-- Welcome %s --',pilotName)) 
            break
        end
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
unit.setTimer('screen',screenRefreshRate)
system.showScreen(1)