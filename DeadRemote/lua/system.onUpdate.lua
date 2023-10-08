Nav:update()
if screenCount % 4 == 0 then
    screenCount = 1
    -- Generate Screen overlay --
    if speed ~= nil then generateScreen() end
    -----------------------------
else
    screenCount = screenCount + 1
end