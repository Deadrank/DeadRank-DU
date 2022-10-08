auto_follow = not auto_follow
if auto_follow and tostring(radar_1.getTargetId()) == "0" then auto_follow = false end
system.print(string.format('-- Gunner Chair Auto Follow "%s"',auto_follow))