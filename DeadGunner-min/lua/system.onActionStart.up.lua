
local id = radar_1.getTargetId()
local targetSelected = id ~= 0
if targetSelected then
    local tDist = radar_1.getConstructDistance(id)
    local cam_fwd = vec3(system.getCameraWorldForward())
    local cam_pos = vec3(system.getCameraWorldPos())
    local cam_vec = vec3(cam_pos+cam_fwd)
    local tLoc = cam_pos + tDist*(cam_vec-cam_pos)/vec3(cam_vec-cam_pos):len()
    if manual_trajectory[tostring(id)] == nil then
        manual_trajectory[tostring(id)] = {}
    end
    local temp = {['ts']=arkTime,['pos']=tLoc}
    table.insert(manual_trajectory[tostring(id)],temp)
    system.print(string.format('-- Position added = ::pos{0,0,%.4f,%.4f,%.4f}',tLoc.x,tLoc.y,tLoc.z))
    if #manual_trajectory[tostring(id)] > 1 then
        local length = #manual_trajectory[tostring(id)] + 1
        local p2 = manual_trajectory[tostring(id)][length-2]['pos']
        local p2Time = manual_trajectory[tostring(id)][length-2]['ts']
        local distCalc = vec3(p2-tLoc):len()
        local speed = distCalc/(arkTime - p2Time)*3.6
        if speed > 2000 then
            local trajectory = p2 + 20/.000005*(tLoc-p2 )/vec3(tLoc-p2 ):len()
            trajectory_calc[tostring(id)] = {
                ['p1'] = tLoc,
                ['ts'] = arkTime,
                ['speed'] = speed/3.6,
                ['p2'] = trajectory
            }
            system.print(string.format('-- Target Calculated speed: %.0f km/h',speed))
            system.setWaypoint(string.format('::pos{0,0,%.4f,%.4f,%.4f}',trajectory.x,trajectory.y,trajectory.z))
        else
            system.print('-- Target is close to stationary --')
        end
    end
else
    system.print('-- No target selected --')
end
    
