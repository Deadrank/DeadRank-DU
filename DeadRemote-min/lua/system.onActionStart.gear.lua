gearExtended = not gearExtended
if gearExtended then
    Nav.control.deployLandingGears()
    Nav.axisCommandManager:setTargetGroundAltitude(0)
    player.freeze(false)
else
    Nav.control.retractLandingGears()
    Nav.axisCommandManager:setTargetGroundAltitude(defaultHoverHeight)
    player.freeze(true)
end

