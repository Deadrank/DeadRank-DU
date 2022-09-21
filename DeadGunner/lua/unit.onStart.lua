
-- Add Valid User ID --
masterPlayerID = player.getId()
pilotName = system.getPlayerName(masterPlayerID)
validPilotCode = '123456' --Your player ID
----------------------

chairID = tostring(player.getSeatId())
showAlerts = false

-- SETTINGS --
useDB = true --export use connected DB for config options
showCode = true --export True=plain text transponder codes, False=redacted codes
szAlerts = false --export
minimalWidgets = false --export
hideAbandonedCores = true --export
targetIndicators = true --export Show warnings when target is speeding up or slowing down
printCombatLog = true --export Print weapon hits/misses to lua
dangerWarning = 4 --export
validatePilot = false --export
bottomHUDLineColorSZ = 'rgba(125, 150, 160, 1)' --export
bottomHUDFillColorSZ = 'rgba(20, 114, 209, 0.75)' --export
textColorSZ = 'rgba(200, 225, 235, 1)' --export
bottomHUDLineColorPVP = 'lightgrey' --export
bottomHUDFillColorPVP = 'rgba(255, 0, 0, 0.75)' --export
textColorPVP = 'black' --export
neutralLineColor = 'lightgrey' --export
neutralFontColor = 'white' --export
generateAutoCode = false --export
autoVent = true --export Autovent shield at 0 hp
L_Shield_HP = 11500000 --export
M_Shield_HP = 8625000 --export
S_Shield_HP = 8625000 --export
XS_Shield_HP = 500000 --export
max_radar_load = 300 --export
maxWeaponsPerWidget = 3 --export How many weapons in each default weapon widget
radarBuffer = 0.00001
warning_size = 0.75 --export How large the warning indicators should be
warning_outline_color = 'rgb(255, 60, 60)' --export
warning_fill_color = 'rgba(50, 50, 50, 0.9)' --export

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
-- Radar Info Widget --
radarInfoWidgetX = 29 --export
radarInfoWidgetY = 67 --export
radarInfoWidgetScale = 11.25 --export

radarInfoWidgetXmin = 67.5 --export
radarInfoWidgetYmin = -0.9 --export
radarInfoWidgetScalemin = 10 --export
-----------------------------------------

-- Choose DB for seat --
write_db = nil
local found = false
for i,dbName in pairs(db) do
    if dbName.getStringValue('usedBy') == chairID then
        write_db = dbName
        found = true
        break
    end
end
if not found then
    for i,dbName in pairs(db) do
        if dbName.hasKey('usedBy') == 0 then
            write_db = dbName
            write_db.setStringValue('usedBy',chairID)
            found = true
        end
    end
end
if not found then system.print('-- No usable DB found --') end
------------------------

userCode = {}
userCode[validPilotCode] = pilotName
if useDB and write_db ~= nil then
    globalDB('get')
end

-- Shield Initialize --
dmgTick = 0
--------

--- Radar Initial Values ---
cr = nil
cr_time = nil
cr_delta = nil
constructListData = {}
radarWidgetData = nil
radarOverload = false
radarDataID = nil
radarStart = false
filterSize = {}
table.insert(filterSize,'L')
table.insert(filterSize,'M')
table.insert(filterSize,'S')
table.insert(filterSize,'XS')
friendlySIDs = {}
useShipID = true
radarFilter = 'All'
radarSort = 'Distance'
validSizes = {}
table.insert(validSizes,'L')
table.insert(validSizes,'M')
table.insert(validSizes,'S')
table.insert(validSizes,'XS')
radarStats = {
    ['enemy'] = {
        ['L'] = 0,
        ['M'] = 0,
        ['S'] = 0,
        ['XS'] = 0
    },
    ['friendly'] = {
        ['L'] = 0,
        ['M'] = 0,
        ['S'] = 0,
        ['XS'] = 0
    }
}
lastDistance = 0
lastUpdateTime = 0
speedCompare = 'Not Identified'
accelCompare = 'No Accel'
lastSpeed = 0
speedCompare = 0
gapCompare = 0
identifiedBy = 0
attackedBy = 0
warpScan = {}
unknownRadar = {}
radarContactNumber = 0
------------------------------

--- Screen Resolution/keys ---
screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
--------------------------

if write_db ~= nil then
    for _,key in pairs(write_db.getKeyList()) do
        if write_db.getStringValue(key) ~= nil and write_db.getStringValue(key) ~= '' and string.starts(key,'uc-') then 
            userCode[string.sub(key,4)] = write_db.getStringValue(key)
        end
    end
end

inSZ = construct.isInPvPZone() == 0
SZD = construct.getDistanceToSafeZone()

--- Weapons --
initialResistWait = 15 --export
weaponDataList = {}
shieldDmgTrack = {
    ['L'] = L_Shield_HP,
    ['M'] = M_Shield_HP,
    ['S'] = S_Shield_HP,
    ['XS'] = XS_Shield_HP
}
dmgTracker = {}
primary = nil
--------------

-- Transponder --
codeSeed = nil
tags = {}
transponderStatus = false
tCode = nil
cOverlap = false
cOverlapTick = 0
-----------------

bootTimer = 0
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



if radar_1 == nil then
    system.print('ERROR: NO RADAR LINKED')
    warnings['noRadar'] = 'svgWarning'
else
    warnings['noRadar'] = nil
end

instructionHTML = ''
if generateAutoCode then
    system.print('-- ENTER ACTIVATION CODE --')
    local textColor = 'white'
    instructionHTML = [[
    <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
            <rect x="]].. tostring(.25 * screenWidth) ..[[" y="]].. tostring(.125 * screenHeight) ..[[" rx="15" ry="15" width="50vw" height="22vh" style="fill:rgba(50, 50, 50, 0.9);stroke:white;stroke-width:5;opacity:0.9;" />
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.15 * screenHeight) ..[[" style="fill: ]]..'orange'..[[" font-size=".8vw" font-weight="bold">
                Gunner Chair Startup Instructions</text>
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.17 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                1) Press "enter" key and go to lua chat channel</text>
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.19 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                2) Enter the number you would like to use as your unique transponder seed</text>
            <text x="]].. tostring(.265 * screenWidth) ..[[" y="]].. tostring(.21 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                (or 0 if you do not want auto generated codes)</text>
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.23 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                3) After entering the code, the seat will start</text>
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.25 * screenHeight) ..[[" style="fill: ]]..'orange'..[[" font-size=".8vw" font-weight="bold">
                Notes:</text>
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.27 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                 - The code entered will create an auto-generated transponder code that changes every ~15 minutes.</text>
            <text x="]].. tostring(.27 * screenWidth) ..[[" y="]].. tostring(.29 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                Anyone using this HUD and entering the same startup code will have matching transponders</text>
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.31 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                 - Manually link a data bank to the seat to enable shared functions between the DeadGunner HUD and the DeadRemote HUD</text>
            <text x="]].. tostring(.255 * screenWidth) ..[[" y="]].. tostring(.33 * screenHeight) ..[[" style="fill: ]]..textColor..[[" font-size=".8vw">
                 - Make sure to run the seat config AFTER linking all radar and weapons to the seat</text>
            </rect>
            </svg>]]
else
    unit.setTimer('booting',1)
    codeSeed = 0
end


html = [[<html> <body style="font-family: Calibri;">]]
html = html .. instructionHTML .. [[</body></html>]]
system.setScreen(html)
system.showScreen(1)

showScreen = true
lShift = false

radarRange = 0
if radar_1 ~= nil then
    radarRange = radar_1.getIdentifyRanges()
    if #radarRange > 0 then
        radarRange = radarRange[1]
    else
        local radar_name = radar_1.getName()
        local radar_size = radar_name:match('Space Radar (%w)')
        local ranges = {}
        ranges['s'] = 90750*1.5
        ranges['m'] = 181500*1.5
        ranges['l'] = 400000
        radarRange = ranges[radar_size]
    end
end
