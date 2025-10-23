--profile(runFlush,'runFlush')
status, err = pcall(runFlush)
if status then
    --system.print("runFlush() success")
else
    system.print("runFlush() error: " .. err)
end