gearExtended = not gearExtended
if gearExtended then
    Nav.control.deployLandingGears()
    Nav.axisCommandManager:setTargetGroundAltitude(0)
    system.freeze(0)
else
    Nav.control.retractLandingGears()
    Nav.axisCommandManager:setTargetGroundAltitude(defaultHoverHeight)
    system.freeze(1)
end

