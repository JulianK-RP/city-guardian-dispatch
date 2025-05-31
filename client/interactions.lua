
-- Suspect interaction system

function InteractWithSuspect(suspect)
    if not isOnDuty then return end
    if not DoesEntityExist(suspect) then return end
    if not Entity(suspect).state.isSuspect then return end
    
    interactingSuspect = suspect
    
    local options = {}
    
    -- Check suspect state
    local isArrested = Entity(suspect).state.arrested
    local isDead = IsEntityDead(suspect)
    local isArmed = IsPedArmed(suspect, 7) -- Any weapon type
    
    if isDead then
        table.insert(options, {
            title = 'Check Body',
            description = 'Examine the deceased suspect',
            icon = 'skull',
            onSelect = function()
                CheckDeadSuspect(suspect)
            end
        })
    elseif isArrested then
        table.insert(options, {
            title = 'Transport to Jail',
            description = 'Send suspect to Bolingbroke Penitentiary',
            icon = 'car',
            onSelect = function()
                TransportToJail(suspect)
            end
        })
        
        table.insert(options, {
            title = 'Issue Citation',
            description = 'Give suspect a fine',
            icon = 'file-text',
            onSelect = function()
                IssueCitation(suspect)
            end
        })
    else
        -- Active suspect
        if isArmed then
            table.insert(options, {
                title = 'Order to Drop Weapon',
                description = 'Command suspect to disarm',
                icon = 'shield',
                onSelect = function()
                    OrderDropWeapon(suspect)
                end
            })
        end
        
        table.insert(options, {
            title = 'Arrest Suspect',
            description = 'Place suspect under arrest',
            icon = 'handcuffs',
            onSelect = function()
                ArrestSuspect(suspect)
            end
        })
        
        table.insert(options, {
            title = 'Search Suspect',
            description = 'Perform a pat-down search',
            icon = 'search',
            onSelect = function()
                SearchSuspect(suspect)
            end
        })
        
        table.insert(options, {
            title = 'Negotiate',
            description = 'Try to get suspect to surrender',
            icon = 'message-square',
            onSelect = function()
                NegotiateWithSuspect(suspect)
            end
        })
    end
    
    -- Show context menu
    lib.registerContext({
        id = 'suspect_interaction',
        title = 'Suspect Interaction',
        options = options
    })
    
    lib.showContext('suspect_interaction')
end

function ArrestSuspect(suspect)
    if not DoesEntityExist(suspect) then return end
    if Entity(suspect).state.arrested then return end
    
    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(suspect))
    
    if distance > Config.InteractionDistance then
        lib.notify({
            title = 'LSPD',
            description = 'You are too far from the suspect',
            type = 'error'
        })
        return
    end
    
    -- Check if suspect is resisting
    local isResisting = IsPedInCombat(suspect, playerPed) or IsPedFleeing(suspect)
    
    if isResisting then
        lib.notify({
            title = 'LSPD',
            description = 'Suspect is resisting arrest',
            type = 'error'
        })
        return
    end
    
    -- Perform arrest animation
    lib.progressBar({
        duration = 3000,
        label = 'Arresting suspect...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
        anim = {
            dict = 'mp_arrest_paired',
            clip = 'cop_p2_back_right'
        }
    })
    
    -- Set suspect as arrested
    Entity(suspect).state:set('arrested', true, true)
    SetPedCanRagdoll(suspect, false)
    TaskHandsUp(suspect, -1, playerPed, -1, false)
    SetPedKeepTask(suspect, true)
    
    -- Remove weapons
    RemoveAllPedWeapons(suspect, true)
    
    lib.notify({
        title = 'LSPD',
        description = 'Suspect arrested',
        type = 'success'
    })
    
    -- Log arrest
    local charges = DetermineCharges(suspect)
    TriggerServerEvent('lspd:logArrest', {
        name = 'Suspect #' .. GetPlayerServerId(PlayerId()),
        model = GetEntityModel(suspect)
    }, charges, GetPlayerName(PlayerId()))
end

function SearchSuspect(suspect)
    if not DoesEntityExist(suspect) then return end
    
    lib.progressBar({
        duration = 2000,
        label = 'Searching suspect...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        }
    })
    
    -- Random search results
    local contraband = {}
    local money = math.random(0, 500)
    
    if math.random(100) <= 30 then
        table.insert(contraband, 'Illegal weapon')
    end
    if math.random(100) <= 20 then
        table.insert(contraband, 'Drugs')
    end
    if math.random(100) <= 15 then
        table.insert(contraband, 'Stolen goods')
    end
    
    local searchResults = {}
    if money > 0 then
        table.insert(searchResults, '$' .. money .. ' cash')
    end
    
    for _, item in ipairs(contraband) do
        table.insert(searchResults, item)
    end
    
    if #searchResults == 0 then
        table.insert(searchResults, 'Nothing found')
    end
    
    lib.notify({
        title = 'Search Results',
        description = table.concat(searchResults, '\n'),
        type = 'inform',
        duration = 5000
    })
end

function OrderDropWeapon(suspect)
    if not DoesEntityExist(suspect) then return end
    
    -- Chance suspect complies
    if math.random(100) <= 60 then
        RemoveAllPedWeapons(suspect, true)
        TaskHandsUp(suspect, 5000, PlayerPedId(), -1, false)
        
        lib.notify({
            title = 'LSPD',
            description = 'Suspect dropped weapon',
            type = 'success'
        })
    else
        lib.notify({
            title = 'LSPD',
            description = 'Suspect refuses to comply',
            type = 'warning'
        })
        
        -- May become aggressive
        if math.random(100) <= 40 then
            TaskCombatPed(suspect, PlayerPedId(), 0, 16)
        end
    end
end

function NegotiateWithSuspect(suspect)
    if not DoesEntityExist(suspect) then return end
    
    lib.progressBar({
        duration = 3000,
        label = 'Negotiating...',
        useWhileDead = false,
        canCancel = true
    })
    
    -- Chance of success based on situation
    local successChance = 50
    
    -- Higher chance if suspect is surrounded or outnumbered
    local nearbyOfficers = GetNearbyOfficers(suspect, 50.0)
    if #nearbyOfficers > 1 then
        successChance = successChance + 20
    end
    
    -- Lower chance if suspect is armed
    if IsPedArmed(suspect, 7) then
        successChance = successChance - 15
    end
    
    if math.random(100) <= successChance then
        -- Success - suspect surrenders
        TaskHandsUp(suspect, -1, PlayerPedId(), -1, false)
        SetPedKeepTask(suspect, true)
        RemoveAllPedWeapons(suspect, true)
        
        lib.notify({
            title = 'LSPD',
            description = 'Suspect surrendered',
            type = 'success'
        })
    else
        -- Failure - suspect may become more aggressive
        lib.notify({
            title = 'LSPD',
            description = 'Negotiation failed',
            type = 'error'
        })
        
        if math.random(100) <= 30 then
            TaskSmartFleePed(suspect, PlayerPedId(), 200.0, -1, false, false)
        end
    end
end

function IssueCitation(suspect)
    if not DoesEntityExist(suspect) then return end
    if not Entity(suspect).state.arrested then return end
    
    local input = lib.inputDialog('Issue Citation', {
        {type = 'number', label = 'Fine Amount ($)', default = 500, min = 1, max = 5000},
        {type = 'input', label = 'Violation', placeholder = 'Enter violation description'}
    })
    
    if not input then return end
    
    local amount = input[1]
    local violation = input[2]
    
    if not amount or not violation or violation == '' then
        lib.notify({
            title = 'LSPD',
            description = 'Invalid citation details',
            type = 'error'
        })
        return
    end
    
    -- Log citation
    TriggerServerEvent('lspd:logCitation', {
        name = 'Suspect #' .. GetPlayerServerId(PlayerId()),
        model = GetEntityModel(suspect)
    }, {violation}, GetPlayerName(PlayerId()), amount)
    
    lib.notify({
        title = 'LSPD',
        description = 'Citation issued: $' .. amount,
        type = 'success'
    })
    
    -- Release suspect
    DeleteEntity(suspect)
end

function TransportToJail(suspect)
    if not DoesEntityExist(suspect) then return end
    if not Entity(suspect).state.arrested then return end
    
    TriggerServerEvent('lspd:jailSuspect', suspect, Config.JailTime)
    DeleteEntity(suspect)
end

function CheckDeadSuspect(suspect)
    lib.notify({
        title = 'Investigation',
        description = 'Suspect appears to have died from gunshot wounds',
        type = 'inform'
    })
    
    -- Could add more forensic details here
end

function DetermineCharges(suspect)
    local charges = {}
    local crimeType = Entity(suspect).state.crimeType
    
    -- Base charge for the crime
    if crimeType then
        table.insert(charges, crimeType)
    end
    
    -- Additional charges
    if IsPedArmed(suspect, 7) then
        table.insert(charges, 'weapons')
    end
    
    if Entity(suspect).state.hasResisted then
        table.insert(charges, 'resisting')
    end
    
    if Entity(suspect).state.hasFled then
        table.insert(charges, 'fleeing')
    end
    
    return charges
end

function GetNearbyOfficers(suspect, radius)
    local officers = {}
    local suspectCoords = GetEntityCoords(suspect)
    
    for _, player in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(player)
        local playerCoords = GetEntityCoords(playerPed)
        
        if #(suspectCoords - playerCoords) <= radius then
            table.insert(officers, player)
        end
    end
    
    return officers
end

-- Send to jail client-side handling
RegisterNetEvent('lspd:sendToJail', function(suspectId, time)
    if DoesEntityExist(suspectId) then
        -- Teleport to jail (in a real scenario, this might be handled differently)
        SetEntityCoords(suspectId, Config.JailCoords.x, Config.JailCoords.y, Config.JailCoords.z)
        
        -- Delete after jail time
        SetTimeout(time * 1000, function()
            if DoesEntityExist(suspectId) then
                DeleteEntity(suspectId)
            end
        end)
    end
end)
