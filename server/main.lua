
local onDutyOfficers = {}
local activeCallouts = {}
local calloutId = 0

-- Police duty management
RegisterNetEvent('lspd:toggleDuty', function()
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]
    
    if onDutyOfficers[identifier] then
        onDutyOfficers[identifier] = nil
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'LSPD',
            description = 'You are now off duty',
            type = 'inform'
        })
        TriggerClientEvent('lspd:dutyStatus', src, false)
    else
        onDutyOfficers[identifier] = {
            source = src,
            name = GetPlayerName(src)
        }
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'LSPD',
            description = 'You are now on duty',
            type = 'success'
        })
        TriggerClientEvent('lspd:dutyStatus', src, true)
    end
end)

-- Get on-duty officers
lib.callback.register('lspd:getOnDutyOfficers', function(source)
    return onDutyOfficers
end)

-- Check if player is on duty
lib.callback.register('lspd:isOnDuty', function(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    return onDutyOfficers[identifier] ~= nil
end)

-- Send dispatch to all on-duty officers
function SendDispatch(callout)
    for identifier, officer in pairs(onDutyOfficers) do
        if GetPlayerPing(officer.source) > 0 then -- Check if player is still connected
            TriggerClientEvent('lspd:receiveDispatch', officer.source, callout)
        else
            onDutyOfficers[identifier] = nil -- Remove disconnected officers
        end
    end
end

-- Create new callout
RegisterNetEvent('lspd:createCallout', function(crimeType, coords)
    calloutId = calloutId + 1
    
    local callout = {
        id = calloutId,
        type = crimeType,
        coords = coords,
        timestamp = os.time(),
        active = true,
        responding = {}
    }
    
    activeCallouts[calloutId] = callout
    SendDispatch(callout)
    
    if Config.Debug then
        print(('Callout created: ID %d, Type: %s'):format(calloutId, crimeType))
    end
end)

-- Officer responding to callout
RegisterNetEvent('lspd:respondToCallout', function(calloutId)
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]
    
    if not onDutyOfficers[identifier] then return end
    
    if activeCallouts[calloutId] then
        table.insert(activeCallouts[calloutId].responding, {
            source = src,
            name = GetPlayerName(src)
        })
        
        -- Notify other officers
        for id, officer in pairs(onDutyOfficers) do
            if officer.source ~= src then
                TriggerClientEvent('ox_lib:notify', officer.source, {
                    title = 'Dispatch',
                    description = GetPlayerName(src) .. ' is responding to callout #' .. calloutId,
                    type = 'inform'
                })
            end
        end
    end
end)

-- Complete callout
RegisterNetEvent('lspd:completeCallout', function(calloutId, outcome)
    if activeCallouts[calloutId] then
        activeCallouts[calloutId].active = false
        activeCallouts[calloutId].outcome = outcome
        
        -- Notify all officers
        for identifier, officer in pairs(onDutyOfficers) do
            TriggerClientEvent('lspd:calloutCompleted', officer.source, calloutId, outcome)
        end
        
        -- Clean up after 5 minutes
        SetTimeout(300000, function()
            activeCallouts[calloutId] = nil
        end)
    end
end)

-- Request backup
RegisterNetEvent('lspd:requestBackup', function(coords, reason)
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]
    
    if not onDutyOfficers[identifier] then return end
    
    for id, officer in pairs(onDutyOfficers) do
        if officer.source ~= src then
            TriggerClientEvent('lspd:backupRequested', officer.source, {
                requester = GetPlayerName(src),
                coords = coords,
                reason = reason or 'Officer needs assistance'
            })
        end
    end
end)

-- Admin commands
RegisterCommand('callout', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, 'lspd.admin') then
        local crimeType = args[1]
        if crimeType and Config.CrimeTypes[crimeType] then
            local player = GetPlayerPed(source == 0 and 1 or source)
            local coords = GetEntityCoords(player)
            TriggerEvent('lspd:createCallout', crimeType, coords)
            
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Callout created: ' .. crimeType,
                    type = 'success'
                })
            else
                print('Callout created: ' .. crimeType)
            end
        else
            local msg = 'Available crime types: ' .. table.concat(table.keys(Config.CrimeTypes), ', ')
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = msg,
                    type = 'error'
                })
            else
                print(msg)
            end
        end
    end
end, false)

-- Utility function to get table keys
function table.keys(t)
    local keys = {}
    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end
