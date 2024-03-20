Nav:update()
FPS_COUNTER = FPS_COUNTER + 1
ticker = ticker + 1

speedVec = vec3(constructVelocity)
speed = speedVec:len() * 3.6
if speed < 50 then speedVec = vec3(constructForward) end
maxSpeed = construct.getMaxSpeed() * 3.6
gravity = core.getGravityIntensity()
mass = construct.getMass()
constructPosition = vec3(construct.getWorldPosition())
maxBrake = json.decode(unit.getWidgetData()).maxBrake
maxThrustTags = 'thrust'
if #enabledEngineTags > 0 then
    maxThrustTags = maxThrustTags .. ' disengaged'
    for i,tag in pairs(enabledEngineTags) do
        maxThrustTags = maxThrustTags .. ',thrust '.. tag
    end
end
maxThrust = construct.getMaxThrustAlongAxis(maxThrustTags,construct.getOrientationForward())
maxSpaceThrust = math.abs(maxThrust[3])

dockedMass = 0
for _,id in pairs(construct.getDockedConstructs()) do 
    dockedMass = dockedMass + construct.getDockedConstructMass(id)
end
for _,id in pairs(construct.getPlayersOnBoard()) do 
    dockedMass = dockedMass + construct.getBoardedPlayerMass(id)
end
brakeDist,brakeTime = Kinematic.computeDistanceAndTime(speedVec:len(),0,mass + dockedMass,0,0,maxBrake)
accel = vec3(construct.getWorldAcceleration()):len()

-- SCREEN UPDATES --
if autopilot_dest and speed > 1000 then
    local balance = vec3(autopilot_dest - constructPosition):len()/(speed/3.6) --meters/(meter/second) == seconds
    local seconds = balance % 60
    balance = balance // 60
    local minutes = balance % 60
    balance = balance // 60
    local hours = balance % 60
    apHTML = [[
        <text x="537.6" y="59.4" style="fill: rgba(200, 225, 235, 1)" font-size="1.42vh" font-weight="bold">ETA: ]]..string.format('%.0f:%.0f.%.0f',hours,minutes,seconds)..[[</text>
    ]]
end

apBG = bgColor
if autopilot then apBG = 'rgba(99, 250, 79, 0.5)' apStatus = 'Engaged' if route and routes[route][route_pos] == autopilot_dest_pos then apStatus = route end end
if not autopilot and autopilot_dest ~= nil then apStatus = 'Set' if route and routes[route][route_pos] == autopilot_dest_pos then apStatus = route end end

if route_pos and route_pos ~= db_1.getIntValue('route_pos',route_pos) then db_1.setIntValue('route_pos',route_pos) end
-- END SCREEN UPDATES --

-- Generate Screen overlay --
if speed ~= nil and ticker % 3 == 0 then
    ticker = 0 generateScreen()
end
-----------------------------