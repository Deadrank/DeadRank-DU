---------- Global Values ----------
local clamp  = utils.clamp
local function signedRotationAngle(normal, vecA, vecB)
    vecA = vecA:project_on_plane(normal)
    vecB = vecB:project_on_plane(normal)
    return math.atan(vecA:cross(vecB):dot(normal), vecA:dot(vecB))
end

if (pitchPID == nil) then
    pitchPID = pid.new(0.1, 0, 11)
    rollPID = pid.new(0.1, 0, 11)
    yawPID = pid.new(0.1, 0, 11)
end
------------------------------------

apBrakeDist,brakeTime = Kinematic.computeDistanceAndTime(speedVec:len(),0,mass + dockedMass,0,0,maxBrake)

local pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local yawSpeedFactor =  1 --export: This factor will increase/decrease the player input along the yaw axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

local brakeSpeedFactor = 3 --export: When braking, this factor will increase the brake force by brakeSpeedFactor * velocity<br>Valid values: Superior or equal to 0.01
local brakeFlatFactor = 1 --export: When braking, this factor will increase the brake force by a flat brakeFlatFactor * velocity direction><br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

local autoRoll = false --export: [Only in atmosphere]<br>When the pilot stops rolling,  flight model will try to get back to horizontal (no roll)
local autoRollFactor = 2 --export: [Only in atmosphere]<br>When autoRoll is engaged, this factor will increase to strength of the roll back to 0<br>Valid values: Superior or equal to 0.01

local turnAssist = true --export: [Only in atmosphere]<br>When the pilot is rolling, the flight model will try to add yaw and pitch to make the construct turn better<br>The flight model will start by adding more yaw the more horizontal the construct is and more pitch the more vertical it is
local turnAssistFactor = 2 --export: [Only in atmosphere]<br>This factor will increase/decrease the turnAssist effect<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

local torqueFactor = 2 -- Force factor applied to reach rotationSpeed<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

-- validate params
pitchSpeedFactor = math.max(pitchSpeedFactor, 0.01)
yawSpeedFactor = math.max(yawSpeedFactor, 0.01)
rollSpeedFactor = math.max(rollSpeedFactor, 0.01)
torqueFactor = math.max(torqueFactor, 0.01)
brakeSpeedFactor = math.max(brakeSpeedFactor, 0.01)
brakeFlatFactor = math.max(brakeFlatFactor, 0.01)
autoRollFactor = math.max(autoRollFactor, 0.01)
turnAssistFactor = math.max(turnAssistFactor, 0.01)

-- final inputs
local finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
local finalRollInput = rollInput + system.getControlDeviceYawInput()
local finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
local finalBrakeInput = brakeInput

-- Axis
local worldVertical = vec3(core.getWorldVertical()) -- along gravity
local constructUp = vec3(construct.getWorldOrientationUp())
constructForward = vec3(construct.getWorldOrientationForward())
constructRight = vec3(construct.getWorldOrientationRight())
constructVelocity = vec3(construct.getWorldVelocity())
local constructVelocityDir = vec3(constructVelocity):normalize()
local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
local currentRollDegAbs = math.abs(currentRollDeg)
local currentRollDegSign = utils.sign(currentRollDeg)

-- Rotation
local constructAngularVelocity = vec3(construct.getWorldAngularVelocity())
-- SETUP AUTOPILOT ROTATIONS --
local targetAngularVelocity = vec3()

local destVec = vec3()
local currentYaw = 0
local currentPitch = 0
local targetYaw = 0
local targetPitch = 0
local yawChange = 0
local pitchChange = 0
local total_align = 0
--local totalAngularChange = nil
if autopilot_dest then
    destVec = vec3(autopilot_dest - constructPosition):normalize()
    local dirYaw = -math.deg(signedRotationAngle(constructUp:normalize(), destVec:normalize(), constructForward:normalize()))
    local dirPitch = math.deg(signedRotationAngle(constructRight:normalize(), destVec:normalize(), constructForward:normalize()))

    local speedYaw = -math.deg(signedRotationAngle(constructUp:normalize(), destVec:normalize(), constructVelocity))
    local speedPitch = math.deg(signedRotationAngle(constructRight:normalize(), destVec:normalize(), constructVelocity))

    local yawDiff = -math.deg(signedRotationAngle(constructUp:normalize(), constructVelocity:normalize(), constructForward:normalize()))
    local pitchDiff = math.deg(signedRotationAngle(constructRight:normalize(), constructVelocity:normalize(), constructForward:normalize()))

    if speed < 40 then
        yawChange = dirYaw
        pitchChange = dirPitch
    else
        yawChange = speedYaw
        pitchChange = speedPitch

        if math.abs(yawDiff) > 30 then yawChange = dirYaw end
        if math.abs(pitchDiff) > 30 then pitchChange = dirPitch end
    end
    total_align = math.abs(yawChange) + math.abs(pitchChange)
end

if autopilot and autopilot_dest ~= nil and Nav.axisCommandManager:getThrottleCommand(0) ~= 0 then
    yawPID:inject(yawChange)
    local apYawInput = yawPID:get()
    if apYawInput > AP_Max_Rotation_Factor then apYawInput = AP_Max_Rotation_Factor
    elseif apYawInput < -AP_Max_Rotation_Factor then apYawInput = -AP_Max_Rotation_Factor
    end

    pitchPID:inject(pitchChange)
    local apPitchInput = -pitchPID:get()
    if apPitchInput > AP_Max_Rotation_Factor then apPitchInput = AP_Max_Rotation_Factor
    elseif apPitchInput < -AP_Max_Rotation_Factor then apPitchInput = -AP_Max_Rotation_Factor
    end
    targetAngularVelocity = apYawInput * 2 * constructUp
                            + apPitchInput * 2 * constructRight
                            + finalPitchInput * pitchSpeedFactor * constructRight
                            + finalRollInput * rollSpeedFactor * constructForward
                            + finalYawInput * yawSpeedFactor * constructUp
else
    targetAngularVelocity = finalPitchInput * pitchSpeedFactor * constructRight
        + finalRollInput * rollSpeedFactor * constructForward
        + finalYawInput * yawSpeedFactor * constructUp
end

---------------------------------

-- In atmosphere?
if worldVertical:len() > 0.01 and unit.getAtmosphereDensity() > 0.0 then
    local autoRollRollThreshold = 1.0
    -- autoRoll on AND currentRollDeg is big enough AND player is not rolling
    if autoRoll == true and currentRollDegAbs > autoRollRollThreshold and finalRollInput == 0 then
        local targetRollDeg = utils.clamp(0,currentRollDegAbs-30, currentRollDegAbs+30);  -- we go back to 0 within a certain limit
        if (rollPID == nil) then
            rollPID = pid.new(autoRollFactor * 0.01, 0, autoRollFactor * 0.1) -- magic number tweaked to have a default factor in the 1-10 range
        end
        rollPID:inject(targetRollDeg - currentRollDeg)
        local autoRollInput = rollPID:get()

        targetAngularVelocity = targetAngularVelocity + autoRollInput * constructForward
    end
    local turnAssistRollThreshold = 20.0
    -- turnAssist AND currentRollDeg is big enough AND player is not pitching or yawing
    if turnAssist == true and currentRollDegAbs > turnAssistRollThreshold and finalPitchInput == 0 and finalYawInput == 0 then
        local rollToPitchFactor = turnAssistFactor * 0.1 -- magic number tweaked to have a default factor in the 1-10 range
        local rollToYawFactor = turnAssistFactor * 0.025 -- magic number tweaked to have a default factor in the 1-10 range

        -- rescale (turnAssistRollThreshold -> 180) to (0 -> 180)
        local rescaleRollDegAbs = ((currentRollDegAbs - turnAssistRollThreshold) / (180 - turnAssistRollThreshold)) * 180
        local rollVerticalRatio = 0
        if rescaleRollDegAbs < 90 then
            rollVerticalRatio = rescaleRollDegAbs / 90
        elseif rescaleRollDegAbs < 180 then
            rollVerticalRatio = (180 - rescaleRollDegAbs) / 90
        end

        rollVerticalRatio = rollVerticalRatio * rollVerticalRatio

        local turnAssistYawInput = - currentRollDegSign * rollToYawFactor * (1.0 - rollVerticalRatio)
        local turnAssistPitchInput = rollToPitchFactor * rollVerticalRatio

        targetAngularVelocity = targetAngularVelocity
                            + turnAssistPitchInput * constructRight
                            + turnAssistYawInput * constructUp
    end
end

-- Engine commands
local keepCollinearity = 1 -- for easier reading
local dontKeepCollinearity = 0 -- for easier reading
local tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we do not go to the next priorities

-- Rotation
if not dampening and not autopilot then
    constructAngularVelocity = vec3(construct.getWorldAngularVelocity())*.1
end

local angularAcceleration = torqueFactor * (targetAngularVelocity - constructAngularVelocity)
if not dampening then
    angularAcceleration = angularAcceleration*dampenerTorqueReduction
end

local airAcceleration = vec3(construct.getWorldAirFrictionAngularAcceleration())
angularAcceleration = angularAcceleration - airAcceleration -- Try to compensate air friction
Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)

-- Brakes
local brakeAcceleration = vec3()
if autopilot then
    if autopilot_dest ~= nil and vec3(constructPosition - autopilot_dest):len() <= apBrakeDist + AP_Brake_Buffer or brakesOn or (total_align > 5 and speed < 40) then
        brakeAcceleration = -maxBrake * constructVelocityDir
        brakeInput = 1
    elseif autopilot_dest ~= nil and not brakesOn then
        brakeAcceleration = vec3()
        brakeInput = 0
    end
else
    brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructVelocity + brakeFlatFactor * constructVelocityDir)
end
Nav:setEngineForceCommand('brake', brakeAcceleration)

-- AutoNavigation regroups all the axis command by 'TargetSpeed'
local autoNavigationEngineTags = ''
local autoNavigationAcceleration = vec3()
local autoNavigationUseBrake = false

-- Longitudinal Translation
local longitudinalEngineTags = 'thrust analog longitudinal'
if #enabledEngineTags > 0 then
    longitudinalEngineTags = longitudinalEngineTags .. ' disengaged'
    for i,tag in pairs(enabledEngineTags) do
        longitudinalEngineTags = longitudinalEngineTags .. ',thrust analog longitudinal '.. tag
    end
end
local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
local longitudinalAcceleration = vec3()

if autopilot and autopilot_dest ~= nil and vec3(constructPosition - autopilot_dest):len() <= apBrakeDist + AP_Brake_Buffer + speed then
    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
    longitudinalAcceleration = vec3()
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
elseif autopilot and autopilot_dest ~= nil and speed < maxSpeed - 10 and enginesOn then
    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,1)
    longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
elseif autopilot and autopilot_dest ~= nil and speed >= maxSpeed - 10 then
    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
    longitudinalAcceleration = vec3()
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
    enginesOn = false
else
    if (longitudinalCommandType == axisCommandType.byThrottle) then
        longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
        Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
    elseif  (longitudinalCommandType == axisCommandType.byTargetSpeed) then
        local longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal)
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
        autoNavigationAcceleration = autoNavigationAcceleration + longitudinalAcceleration
        if (Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) == 0 or -- we want to stop
            Nav.axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - Nav.axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) -- if the longitudinal velocity would need some braking
        then
            autoNavigationUseBrake = true
        end

    end
end

-- Lateral Translation
local lateralStrafeEngineTags = 'thrust analog lateral'
local lateralCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral)
if (lateralCommandType == axisCommandType.byThrottle) then
    local lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
    Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
elseif  (lateralCommandType == axisCommandType.byTargetSpeed) then
    local lateralAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
    autoNavigationAcceleration = autoNavigationAcceleration + lateralAcceleration
end

-- Vertical Translation
local verticalStrafeEngineTags = 'thrust analog vertical'
local verticalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical)
if (verticalCommandType == axisCommandType.byThrottle) then
    local verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
    Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
elseif  (verticalCommandType == axisCommandType.byTargetSpeed) then
    local verticalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags
    autoNavigationAcceleration = autoNavigationAcceleration + verticalAcceleration
end

-- Auto Navigation (Cruise Control)
if (autoNavigationAcceleration:len() > constants.epsilon) then
    if (brakeInput ~= 0 or autoNavigationUseBrake or math.abs(constructVelocityDir:dot(constructForward)) < 0.95)  -- if the velocity is not properly aligned with the forward
    then
        autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
    end
    Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
end

-- Rockets
Nav:setBoosterCommand('rocket_engine')

-- Disable Auto-Pilot when destination is reached --
if autopilot and autopilot_dest ~= nil and vec3(constructPosition - autopilot_dest):len() <= apBrakeDist + 1000 + AP_Brake_Buffer and speed < 1000 then
    brakeInput = brakeInput + 1
    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal,0)
    Nav:setEngineForceCommand(longitudinalEngineTags, vec3(), keepCollinearity)
    if not route then
        system.print('-- Autopilot complete --')
        autopilot_dest_pos = nil
        autopilot = false
    elseif route and speed < 15 and routes[route][route_pos+1] ~= nil and vec3(constructPosition - autopilot_dest):len() <= 1000+AP_Brake_Buffer then
        system.print('-- Route pilot point complete --')
        system.print('-- Starting next point --')
        route_pos = route_pos+1
        autopilot_dest = vec3(convertWaypoint(routes[route][route_pos]))
        autopilot_dest_pos = routes[route][route_pos]
        system.print('-- Route pilot destination set --')
        system.print(routes[route][route_pos])
    elseif route and route_pos == #routes[route] then
        system.print('-- Route pilot complete --')
        autopilot_dest_pos = nil
        autopilot = false
        route = nil
        route_pos = nil
        db_1.clearValue('route')
        db_1.clearValue('route_pos')
        db_1.setIntValue('record',0)
    end
end
---------------------------------------------------