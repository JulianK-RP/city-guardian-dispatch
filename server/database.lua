
-- Simple arrest/citation logging system
local arrestLog = {}
local citationLog = {}

-- Log arrest
RegisterNetEvent('lspd:logArrest', function(suspectData, charges, officer)
    local arrestId = #arrestLog + 1
    local arrest = {
        id = arrestId,
        suspect = suspectData,
        charges = charges,
        officer = officer,
        timestamp = os.date('%Y-%m-%d %H:%M:%S'),
        fine_amount = 0
    }
    
    -- Calculate total fine
    for _, charge in ipairs(charges) do
        if Config.Fines[charge] then
            arrest.fine_amount = arrest.fine_amount + Config.Fines[charge]
        end
    end
    
    arrestLog[arrestId] = arrest
    
    if Config.Debug then
        print(('Arrest logged: ID %d, Suspect: %s, Officer: %s'):format(
            arrestId, suspectData.name or 'Unknown', officer
        ))
    end
    
    return arrestId
end)

-- Log citation
RegisterNetEvent('lspd:logCitation', function(suspectData, violations, officer, amount)
    local citationId = #citationLog + 1
    local citation = {
        id = citationId,
        suspect = suspectData,
        violations = violations,
        officer = officer,
        amount = amount,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    citationLog[citationId] = citation
    
    if Config.Debug then
        print(('Citation logged: ID %d, Amount: $%d'):format(citationId, amount))
    end
    
    return citationId
end)

-- Get arrest history (for MDT integration)
lib.callback.register('lspd:getArrestHistory', function(source, limit)
    local history = {}
    local count = 0
    
    -- Get most recent arrests
    for i = #arrestLog, math.max(1, #arrestLog - (limit or 50) + 1), -1 do
        if arrestLog[i] then
            table.insert(history, arrestLog[i])
            count = count + 1
        end
    end
    
    return history
end)

-- Get citation history
lib.callback.register('lspd:getCitationHistory', function(source, limit)
    local history = {}
    local count = 0
    
    for i = #citationLog, math.max(1, #citationLog - (limit or 50) + 1), -1 do
        if citationLog[i] then
            table.insert(history, citationLog[i])
            count = count + 1
        end
    end
    
    return history
end)

-- Jail suspect
RegisterNetEvent('lspd:jailSuspect', function(suspectId, time)
    local src = source
    
    -- This would integrate with your jail system
    -- For now, we'll just teleport and notify
    TriggerClientEvent('lspd:sendToJail', src, suspectId, time or Config.JailTime)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'LSPD',
        description = 'Suspect sent to Bolingbroke Penitentiary',
        type = 'success'
    })
end)
