
if toggleBrakes then
    if brakeInput > 0 then
        brakeInput = 0
        brakesOn = false
    else
        brakeInput = brakeInput + 1
        brakesOn = true
    end
else
    brakeInput = brakeInput + 1
    brakesOn = true
end

local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
if (longitudinalCommandType == axisCommandType.byTargetSpeed) then
    local targetSpeed = Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal)
    if (math.abs(targetSpeed) > constants.epsilon) then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, - utils.sign(targetSpeed))
    end
end
