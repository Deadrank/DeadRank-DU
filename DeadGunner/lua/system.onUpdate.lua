arkTime = system.getArkTime()

-- SZ Boundary --
inSZ = construct.isInPvPZone() == 0
SZD = construct.getDistanceToSafeZone()
bgColor = bottomHUDFillColorSZ 
fontColor = textColorSZ
lineColor = bottomHUDLineColorSZ
if not inSZ then 
    lineColor = bottomHUDLineColorPVP
    bgColor = bottomHUDFillColorPVP
    fontColor = textColorPVP
end
---------------------

if bootTimer >= 2 then
    generateHTML()
end

constructPosition = vec3(construct.getWorldPosition())

-- Generate on screen combat points for Augmented Reality view --
AR_Generate = {}
local tID = radar_1.getTargetId()
if AR_Mode == 'ALL' then
    if write_db then
        for _,key in pairs(write_db.getKeyList()) do
            if string.starts(key,'abnd-') and not string.starts(key,'abnd-name-') then
                abndPos = write_db.getStringValue(key)
                local abndVec = convertWaypoint(abndPos)
                local dist = vec3(abndVec - constructPosition):len()*0.000005
                if radar_1 and dist < 1.95 then
                    if radar_1.getConstructDistance(string.sub(key,6)) ~= 0 then
                        AR_Generate['[CORED] '..write_db.getStringValue(string.gsub(key,'-','-name-'))] = abndVec
                    elseif not inSZ then
                        system.print('-- Removing '.. write_db.getStringValue(string.gsub(key,'-','-name-')) ..' ('.. write_db.getStringValue(key) ..')')
                        write_db.clearValue(string.gsub(key,'-','-name-'))
                        write_db.clearValue(key)
                    end
                else
                    AR_Generate['[CORED] '..write_db.getStringValue(string.gsub(key,'-','-name-'))] = abndVec
                end
            end
        end
    end
    if FC then
        if radar_1.hasMatchingTransponder(FC) == 1 then
            local temp = radar_1.getConstructWorldPos(FC)
            fc_pos = string.format('::pos{0,0,%.2f,%.2f,%.2f}',temp[1],temp[2],temp[3])
            AR_Generate['Fleet Commander'] = convertWaypoint(fc_pos)
        elseif fc_pos then
            AR_Generate['Fleet Commander [LAST KNOWN]'] = convertWaypoint(fc_pos)
        end
    end
    if SL then
        if radar_1.hasMatchingTransponder(SL) == 1 then
            local temp = radar_1.getConstructWorldPos(SL)
            sl_pos = string.format('::pos{0,0,%.2f,%.2f,%.2f}',temp[1],temp[2],temp[3])
            AR_Generate['Squad Leader'] = convertWaypoint(sl_pos)
        elseif sl_pos then
            AR_Generate['Squad Leader [LAST KNOWN]'] = convertWaypoint(sl_pos)
        end
    end
    if manual_trajectory then
        local rem = {}
        for tID,tbl in pairs(manual_trajectory) do
            for i,v in pairs(manual_trajectory[tostring(tID)]) do
                local tDelta = arkTime-v['ts']
                if tDelta > 5*60 then 
                    table.insert(rem,i,1)
                else
                    AR_Generate[string.format('T-%.0f [%s]',tDelta,string.sub(tostring(tID),-3))] = v['pos']
                end
            end
            if #rem > 0 then
                for _,i in pairs(rem) do 
                    table.remove(manual_trajectory[tostring(tID)],i)
                end
            end
        end
        for id,v in pairs(trajectory_calc) do
            local dist = v['speed']*(arkTime-v['ts'])
            AR_Generate[string.format('Location [%s]',string.sub(tostring(id),-3))] = v['p1'] + dist*(v['p2']-v['p1'] )/vec3(v['p2']-v['p1'] ):len()
        end
    end
elseif AR_Mode == 'FLEET' then
    if FC then
        if radar_1.hasMatchingTransponder(FC) == 1 then
            local temp = radar_1.getConstructWorldPos(FC)
            fc_pos = string.format('::pos{0,0,%.2f,%.2f,%.2f}',temp[1],temp[2],temp[3])
            AR_Generate['Fleet Commander'] = convertWaypoint(fc_pos)
        elseif fc_pos then
            AR_Generate['Fleet Commander [LAST KNOWN]'] = convertWaypoint(fc_pos)
        end
    end
    if SL then
        if radar_1.hasMatchingTransponder(SL) == 1 then
            local temp = radar_1.getConstructWorldPos(SL)
            sl_pos = string.format('::pos{0,0,%.2f,%.2f,%.2f}',temp[1],temp[2],temp[3])
            AR_Generate['Squad Leader'] = convertWaypoint(sl_pos)
        elseif sl_pos then
            AR_Generate['Squad Leader [LAST KNOWN]'] = convertWaypoint(sl_pos)
        end
    end
elseif AR_Mode == 'ABANDONDED' then
    if write_db then
        for _,key in pairs(write_db.getKeyList()) do
            if string.starts(key,'abnd-') and not string.starts(key,'abnd-name-') then
                abndPos = write_db.getStringValue(key)
                AR_Generate['[CORED] '..write_db.getStringValue(string.gsub(key,'-','-name-'))] = convertWaypoint(abndPos)
            end
        end
    end
elseif AR_Mode == 'TRAJECTORY' then
    local rem = {}
    for id,tbl in pairs(manual_trajectory) do
        for i,v in pairs(manual_trajectory[tostring(id)]) do
            local tDelta = arkTime-v['ts']
            if tDelta > 5*60 then 
                table.insert(rem,i,1)
            else
                AR_Generate[string.format('T-%.0f [%s]',tDelta,string.sub(tostring(id),-3))] = v['pos']
            end
        end
        if #rem > 0 then
            for _,i in pairs(rem) do 
                table.remove(manual_trajectory[tostring(id)],i)
            end
        end
    end
    for id,v in pairs(trajectory_calc) do
        local dist = v['speed']*(arkTime-v['ts'])
        AR_Generate[string.format('Location [%s]',string.sub(tostring(id),-3))] = v['p1'] + dist*(v['p2']-v['p1'] )/vec3(v['p2']-v['p1'] ):len()
    end
end
ARSVG = '<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">'
for name,pos in pairs(AR_Generate) do
    local pDist = vec3(pos - constructPosition):len()
    if (pDist*0.000005 < abandonedCoreDist and (pDist*0.000005 > 1.95 or inSZ) ) or string.starts(name,'Fleet Commander') or string.starts(name,'Squad Leader') or string.starts(name,'T-') or string.starts(name,'Location ') then 
        local pInfo = library.getPointOnScreen({pos['x'],pos['y'],pos['z']})
        if pInfo[3] ~= 0 then
            if pInfo[1] < .01 then pInfo[1] = .01 end
            if pInfo[2] < .01 then pInfo[2] = .01 end
            local fill = AR_Fill
            if string.starts(name,'[CORED]') then fill = 'rgb(144,144,144)'
            elseif string.starts(name,'Fleet Commander') then fill = 'rgb(186,85,211)'
            elseif string.starts(name,'Squad Leader') then fill = 'rgb(30, 144, 255)'
            end
            local translate = '(0,0)'
            local depth = AR_Size * 1/(0.02*pDist*0.000005)
            local pDistStr = ''
            if pDist < 1000 then pDistStr = string.format('%.2fm',pDist)
            elseif pDist < 100000 then pDistStr = string.format('%.2fkm',pDist/1000)
            else pDistStr = string.format('%.2fsu',pDist*0.000005)
            end
            if depth > AR_Size then depth = tostring(AR_Size) elseif depth < 1 then depth = '1' else depth = tostring(depth) end
            if pInfo[1] < 1 and pInfo[2] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight*pInfo[2])
            elseif pInfo[1] > 1 and pInfo[1] < AR_Range and pInfo[2] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight*pInfo[2])
            elseif pInfo[2] > 1 and pInfo[2] < AR_Range and pInfo[1] < 1 then
                translate = string.format('(%.2f,%.2f)',screenWidth*pInfo[1],screenHeight)
            else
                translate = string.format('(%.2f,%.2f)',screenWidth,screenHeight)
            end
            if string.starts(name,'Squad Leader') or string.starts(name,'Fleet Commander') then
                ARSVG = ARSVG .. [[<g transform="translate]]..translate..[[">
                        <circle cx="0" cy="0" r="]].. depth ..[[px" style="fill:]]..fill..[[;stroke:]]..AR_Outline..[[;stroke-width:1;opacity:0.75;" />
                        <line x1="0" y1="0" x2="]].. depth*1.2 ..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:1;" />
                        <line x1="]].. depth*1.2 ..[[" y1="-]].. depth*1.2 ..[[" x2="]]..tostring(depth*1.2 + 30)..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:1;" />
                        <text x="]]..tostring(depth*1.2)..[[" y="-]].. depth*1.2+screenHeight*0.0035 ..[[" style="fill: ]]..AR_Outline..[[" font-size="]]..tostring(.075*AR_Size)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                        </g>]]
            elseif string.starts(name,'T-') then
                ARSVG = ARSVG .. [[<g transform="translate]]..translate..[[">
                        <circle cx="0" cy="0" r="]].. depth*0.80 ..[[px" style="fill: rgba(255,150,0,0); stroke:rgba(255, 130, 0, .5);stroke-width:2;" />
                        <line x1="0" y1="0" x2="-]].. depth*1.2 ..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <line x1="-]].. depth*1.2 ..[[" y1="-]].. depth*1.2 ..[[" x2="-]]..tostring(depth*1.2 + 30)..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <text x="-]]..tostring(6*#name+depth*1.2)..[[" y="-]].. depth*1.2+screenHeight*0.0035 ..[[" style="fill: ]]..AR_Outline..[[" font-size="]]..tostring(.075*AR_Size)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                        </g>]]
            elseif string.starts(name,'Location ') then
                ARSVG = ARSVG .. [[<g transform="translate]]..translate..[[">
                        <circle cx="0" cy="0" r="]].. depth*0.80 ..[[px" style="fill: rgba(255,150,0,0); stroke:rgba(255, 255, 0, .5);stroke-width:2;" />
                        <line x1="0" y1="0" x2="-]].. depth*1.2 ..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <line x1="-]].. depth*1.2 ..[[" y1="-]].. depth*1.2 ..[[" x2="-]]..tostring(depth*1.2 + 30)..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <text x="-]]..tostring(6*#name+depth*1.2)..[[" y="-]].. depth*1.2+screenHeight*0.0035 ..[[" style="fill: ]]..AR_Outline..[[" font-size="]]..tostring(.075*AR_Size)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                        </g>]]
            else
                ARSVG = ARSVG .. [[<g transform="translate]]..translate..[[">
                        <circle cx="0" cy="0" r="]].. depth ..[[px" style="fill:]]..fill..[[;stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <line x1="0" y1="0" x2="-]].. depth*1.2 ..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <line x1="-]].. depth*1.2 ..[[" y1="-]].. depth*1.2 ..[[" x2="-]]..tostring(depth*1.2 + 30)..[[" y2="-]].. depth*1.2 ..[[" style="stroke:]]..AR_Outline..[[;stroke-width:1;opacity:]]..AR_Opacity..[[;" />
                        <text x="-]]..tostring(6*#name+depth*1.2)..[[" y="-]].. depth*1.2+screenHeight*0.0035 ..[[" style="fill: ]]..AR_Outline..[[" font-size="]]..tostring(.075*AR_Size)..[[vw">]]..string.format('%s (%s)',name,pDistStr)..[[</text>
                        </g>]]
            end
        end
    end
end
ARSVG = ARSVG .. '</svg>'
-----------------------------------------------------------

-- Radar Updates --
if radar_1 and cr == nil then
    cr = coroutine.create(updateRadar)
elseif cr ~= nil then
    if coroutine.status(cr) ~= "dead" and coroutine.status(cr) == "suspended" then
        coroutine.resume(cr,radarFilter)
    elseif coroutine.status(cr) == "dead" then
        cr = nil
        system.updateData(radarDataID,radarWidgetData)
        if not cr_time then
            cr_time = system.getArkTime()
        else
            cr_delta = system.getArkTime() - cr_time
            cr_time = system.getArkTime()
            if (cr_delta > 1 and radarOverload) or showAlerts then
                warnings['radar_delta'] = 'svgCritical'
            else
                warnings['radar_delta'] = nil
            end
        end
    end
end
---- End Radar Updates ----

-- AutoFollow Updates --
local target = tostring(radar_1.getTargetId())
if auto_follow then
    if not followID then followID = target end
    if followID then
        local identified = radar_1.isConstructIdentified(followID) == 1
        if identified then
            local tSpeed = radar_1.getConstructSpeed(followID) * 3.6
            local tDist = radar_1.getConstructDistance(followID)
            write_db.setIntValue('targetID',tonumber(followID))
            write_db.setFloatValue('targetSpeed',tSpeed)
            write_db.setFloatValue('targetDistance',tDist)
        else
            write_db.clearValue('targetID')
            write_db.clearValue('targetSpeed')
            write_db.clearValue('targetDistance')
        end
    end
end
-- End autofollow --