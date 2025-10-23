-- SZ Boundary --
inSZ = not construct.isInPvPZone()
SZD = construct.getDistanceToSafeZone()
bgColor = 'rgba(25, 25, 50, 0.35)' 
fontColor = 'rgba(225, 250, 265, 1)'
lineColor = 'rgba(150, 175, 185, .75)'
if not inSZ then 
    lineColor = 'rgba(220, 50, 50, .75)'
    bgColor = 'rgba(175, 75, 75, 0.30)'
    fontColor = 'rgba(225, 250, 265, 1)'
end
---------------------

if weapon_1 then weaponHTML = weaponsWidget() end
if radar_1 then radarHTML = radarWidget() end
if radar_1 then identHTML = identifiedWidget() end
if weapon_1 then dpsHTML = dpsWidget() end
warningsHTML = warningsWidget()