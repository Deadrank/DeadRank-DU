cPos = vec3(construct.getWorldPosition())
if SZD ~= nil and bootTimer > 0 then
    if not inSZ and SZD*0.000005 > radarBuffer or szAlerts or recordAll then
        system.stopSound()
        system.playSound('contact.mp3')
        if vec3(construct.getVelocity()):len() * 3.6 > 50000 then
            warpScan[id] = cPos
        else
            unknownRadar[id] = cPos
        end
    end
end