boosterCount = boosterCount + 1
local accelerating = false
if boosterSpeedThreshold > speed then
    accelerating = true
end
if accelerating then
    system.print('Accelerating')
    if boosterCount % 3 == 0 then
        if Nav.boosterState == 1 then 
            --system.print('Boosters off')
            Nav:toggleBoosters()
        end
    else
        if Nav.boosterState == 0 then
            --system.print('Boosters on')
            Nav:toggleBoosters()
        end
    end
else
    system.print('Maintaining')
    if boosterCount % 3 == 0 then
        if Nav.boosterState == 0 then 
            --system.print('Boosters on')
            Nav:toggleBoosters()
        end
    else
        if Nav.boosterState == 1 then 
            --system.print('Boosters off')
            Nav:toggleBoosters()
        end
    end
end