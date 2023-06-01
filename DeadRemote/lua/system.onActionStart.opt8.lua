if shield_1 and not shield_1.isVenting() then shield_1.startVenting()
elseif shield_1 and shield_1.isVenting() then shield_1.stopVenting() shield_1.activate()
end