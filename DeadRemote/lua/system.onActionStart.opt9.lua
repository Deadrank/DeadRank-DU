local masterMode = Nav.axisCommandManager:getMasterMode()
if (masterMode == controlMasterModeId.travel) then
    Nav.control.cancelCurrentControlMasterMode()
    Nav.axisCommandManager:setMasterMode(controlMasterModeId.cruise)
else
    Nav.control.cancelCurrentControlMasterMode()
    Nav.axisCommandManager:setMasterMode(controlMasterModeId.travel)
end