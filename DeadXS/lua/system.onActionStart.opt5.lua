auto_follow = not auto_follow
if not auto_follow then 
    followID = nil
    if (Nav.axisCommandManager:getAxisCommandType(0) ~= axisCommandType.byThrottle) then
        Nav.control.cancelCurrentControlMasterMode()
    end
    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
end
system.print(string.format('-- Auto Follow "%s"',auto_follow))