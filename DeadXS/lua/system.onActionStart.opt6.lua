if inSZ then system.print('-- Already in Safe Zone --') end
system.print(string.format('-- Nearest SZ Center: %s',nearestSZPOS))
system.setWaypoint(nearestSZPOS)
autopilot_dest = vec3(convertWaypoint(nearestSZPOS))
