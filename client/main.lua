
local isOnDuty = false
local currentCallouts = {}
local interactingSuspect = nil

-- Initialize
Citizen.CreateThread(function()
    -- Register qb-target if enabled
    if Config.UseQBTarget then
        exports['qb-target']:AddGlobalPed({
            options = {
                {
                    type = "client",
                    event = "lspd:interactWithSuspect",
                    icon = "fas fa-handcuffs",
                    label = "Police Interaction",
                    canInteract = function(entity, distance, data)
                        return isOnDuty and distance < Config.InteractionDistance and 
                               Entity(entity).state.isSuspect
                    end,
                }
            },
            distance = Config.InteractionDistance
        })
    end
end)

-- Handle qb-target interaction event
RegisterNetEvent('lspd:interactWithSuspect', function(data)
    InteractWithSuspect(data.entity)
end)

-- Police duty toggle command
RegisterCommand('duty', function()
    TriggerServerEvent('lspd:toggleDuty')
end, false)

-- Backup command
RegisterCommand('backup', function(source, args)
    if not isOnDuty then
        lib.notify({
            title = 'LSPD',
            description = 'You must be on duty to request backup',
            type = 'error'
        })
        return
    end
    
    local coords = GetEntityCoords(PlayerPedId())
    local reason = table.concat(args, ' ')
    TriggerServerEvent('lspd:requestBackup', coords, reason)
    
    lib.notify({
        title = 'LSPD',
        description = 'Backup requested',
        type = 'inform'
    })
end, false)

-- Duty status update
RegisterNetEvent('lspd:dutyStatus', function(status)
    isOnDuty = status
    
    if status then
        -- Show police UI
        ShowPoliceUI()
    else
        -- Hide police UI
        HidePoliceUI()
        -- Clear all callout blips
        for _, callout in pairs(currentCallouts) do
            if callout.blip then
                RemoveBlip(callout.blip)
            end
        end
        currentCallouts = {}
    end
end)

-- Receive dispatch
RegisterNetEvent('lspd:receiveDispatch', function(callout)
    if not isOnDuty then return end
    
    local crimeConfig = Config.CrimeTypes[callout.type]
    if not crimeConfig then return end
    
    -- Create blip
    local blip = AddBlipForCoord(callout.coords.x, callout.coords.y, callout.coords.z)
    SetBlipSprite(blip, 161) -- Police car icon
    SetBlipColour(blip, crimeConfig.color)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(crimeConfig.label)
    EndTextCommandSetBlipName(blip)
    
    -- Flash blip
    SetBlipFlashes(blip, true)
    SetTimeout(10000, function()
        SetBlipFlashes(blip, false)
    end)
    
    callout.blip = blip
    currentCallouts[callout.id] = callout
    
    -- Show notification
    lib.notify({
        title = 'DISPATCH',
        description = string.format('%s\n%s\nCallout #%d', 
            crimeConfig.label, 
            crimeConfig.description, 
            callout.id
        ),
        type = 'inform',
        duration = 8000
    })
    
    -- Spawn crime scene
    TriggerEvent('lspd:spawnCrimeScene', callout)
end)

-- Callout completed
RegisterNetEvent('lspd:calloutCompleted', function(calloutId, outcome)
    if currentCallouts[calloutId] then
        if currentCallouts[calloutId].blip then
            RemoveBlip(currentCallouts[calloutId].blip)
        end
        currentCallouts[calloutId] = nil
        
        lib.notify({
            title = 'DISPATCH',
            description = 'Callout #' .. calloutId .. ' completed: ' .. outcome,
            type = 'success'
        })
    end
end)

-- Backup requested
RegisterNetEvent('lspd:backupRequested', function(backup)
    if not isOnDuty then return end
    
    -- Create temporary blip for backup location
    local blip = AddBlipForCoord(backup.coords.x, backup.coords.y, backup.coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 3) -- Blue
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Backup Request')
    EndTextCommandSetBlipName(blip)
    SetBlipFlashes(blip, true)
    
    -- Remove blip after 2 minutes
    SetTimeout(120000, function()
        RemoveBlip(blip)
    end)
    
    lib.notify({
        title = 'BACKUP REQUEST',
        description = backup.requester .. ' needs assistance\n' .. backup.reason,
        type = 'warning',
        duration = 10000
    })
end)

-- Respond to callout
function RespondToCallout(calloutId)
    TriggerServerEvent('lspd:respondToCallout', calloutId)
    
    lib.notify({
        title = 'LSPD',
        description = 'Responding to callout #' .. calloutId,
        type = 'inform'
    })
end

-- Complete callout
function CompleteCallout(calloutId, outcome)
    TriggerServerEvent('lspd:completeCallout', calloutId, outcome)
    TriggerServerEvent('lspd:calloutResolved')
end

-- Key bindings
RegisterKeyMapping('duty', 'Toggle Police Duty', 'keyboard', 'F6')
RegisterKeyMapping('backup', 'Request Backup', 'keyboard', 'F9')

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Remove all blips
        for _, callout in pairs(currentCallouts) do
            if callout.blip then
                RemoveBlip(callout.blip)
            end
        end
    end
end)
