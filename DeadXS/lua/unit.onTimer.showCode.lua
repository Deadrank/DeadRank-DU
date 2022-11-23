if codeCount >= codeTimer then
    codeCount = 0
    unit.stopTimer('showCode')
else
    codeCount = codeCount + 1
end
