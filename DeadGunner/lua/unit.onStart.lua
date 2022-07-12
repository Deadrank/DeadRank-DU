
-- Add Valid User ID --
masterPlayerID = player.getId()
pilotName = system.getPlayerName(masterPlayerID)
validPilotCode = '123456' --Your player ID
----------------------

-- SETTINGS --
useDB = true --export use connected DB for config options
printCombatLog = true --export Print weapon hits/misses to lua
dangerWarning = 4 --export
validatePilot = false --export
bottomHUDLineColorSZ = 'white' --export
bottomHUDFillColorSZ = 'rgba(29, 63, 255, 0.75)' --export
textColorSZ = 'white' --export
bottomHUDLineColorPVP = 'lightgrey' --export
bottomHUDFillColorPVP = 'rgba(255, 0, 0, 0.75)' --export
textColorPVP = 'black' --export
neutralLineColor = 'lightgrey' --export
neutralFontColor = 'darkgrey' --export
generateAutoCode = false --export
autoVent = true --export Autovent shield at 0 hp
L_Shield_HP = 11500000 --export
M_Shield_HP = 8625000 --export
S_Shield_HP = 8625000 --export
XS_Shield_HP = 500000 --export
max_radar_load = 250 --export
----------------

userCode = {}
userCode[validPilotCode] = pilotName
if useDB and db_1 ~= nil then
    globalDB('get')
end

-- Shield Initialize --
dmgTick = 0
--------

--- Radar Initial Values ---
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
radarToggles = {}
table.insert(radarToggles,'All')
table.insert(radarToggles,'enemy')
table.insert(radarToggles,'identified')
table.insert(radarToggles,'friendly')
table.insert(radarToggles,'primary')
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
lastDistance = {}
lastSpeed = {}
identifiedBy = 0
attackedBy = 0
warpScan = {}
unknownRadar = {}
------------------------------

--- Screen Resolution ---
screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
--------------------------

if db_1 ~= nil then
    for _,key in pairs(db_1.getKeyList()) do
        if db_1.getStringValue(key) ~= nil and db_1.getStringValue(key) ~= '' and string.starts(key,'uc-') then 
            userCode[string.sub(key,4)] = db_1.getStringValue(key)
        end
    end
end

inSZ = construct.isInPvPZone() == 0
SZD = construct.getDistanceToSafeZone()

--- Weapons --
initialResistWait = 15 --export
weaponDataList = {}
WeaponWidgetCreate()
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
showCode = true
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

warningHTML = ''
if radar_1 == nil then
    system.print('ERROR: NO RADAR LINKED')
    warningHTML = [[ 
        <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
        <rect x="]].. tostring(.02 * screenWidth) ..[[" y="]].. tostring(.04 * screenHeight) ..[[" rx="15" ry="15" width="7vw" height="4vh" style="fill:rgba(50, 50, 50, 0.9);stroke:red;stroke-width:5;opacity:0.9;" />
        <text x="]].. tostring(.025 * screenWidth) ..[[" y="]].. tostring(.065 * screenHeight) ..[[" style="fill: ]]..'red'..[[" font-size=".8vw" font-weight="bold">
            NO RADAR LINKED</text>
        </rect></svg>]]
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
html = html .. instructionHTML .. warningHTML .. [[</body></html>]]
system.setScreen(html)
system.showScreen(1)

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
