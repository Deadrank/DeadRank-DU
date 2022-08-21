if not lShift then
    if showHelp then
        if not showHelper then
            system.showHelper(0)
        end
        showHelp = false
    else
        system.showHelper(1) showHelp = true
    end
else
    minimalWidgets = not minimalWidgets
end