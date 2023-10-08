if Nav.axisCommandManager:getThrottleCommand(0) == 0 then
    Nav.axisCommandManager:setThrottleCommand(0,1)
    enginesOn = true
else
    Nav.axisCommandManager:resetCommand(axisCommandId.longitudinal)
    enginesOn = false
end