boosterCount = boosterCount + 1
local accelerating = false
if boosterSpeedThreshold > speed then
    accelerating = true
end
if accelerating then
    if boosterCount % 3 == 0 then
        if Nav.boosterState then 
            --system.print('Boosters off')
            Nav:toggleBoosters()
        end
    else
        if not Nav.boosterState then
            --system.print('Boosters on')
            Nav:toggleBoosters()
        end
    end
else
    system.print('Maintaining')
    if boosterCount % 3 == 0 then
        if not Nav.boosterState then 
            --system.print('Boosters on')
            Nav:toggleBoosters()
        end
    else
        if Nav.boosterState then 
            --system.print('Boosters off')
            Nav:toggleBoosters()
        end
    end
end