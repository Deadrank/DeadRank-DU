if radarFilter == 'All' then radarFilter = 'enemy' system.print('-- Radar: enemy --')
elseif radarFilter == 'enemy' then radarFilter = 'identified' system.print('-- Radar: identified --')
elseif radarFilter == 'identified' then radarFilter = 'friendly' system.print('-- Radar: friendly --')
elseif radarFilter == 'friendly' then radarFilter = 'primary' system.print('-- Radar: primary --')
elseif radarFilter == 'primary' then radarFilter = 'All' system.print('-- Radar: All --')
end
