
-- Automatic callout generation system
local lastCalloutTime = 0
local activeCalloutCount = 0

-- Generate random callouts
Citizen.CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        
        -- Check if we should create a new callout
        if activeCalloutCount < Config.MaxActiveCallouts then
            local timeSinceLastCallout = currentTime - lastCalloutTime
            local nextCalloutTime = math.random(Config.CalloutFrequency.min, Config.CalloutFrequency.max)
            
            if timeSinceLastCallout >= nextCalloutTime then
                CreateRandomCallout()
                lastCalloutTime = currentTime
            end
        end
        
        Citizen.Wait(10000) -- Check every 10 seconds
    end
end)

function CreateRandomCallout()
    -- Get all on-duty officers
    local officers = {}
    for identifier, officer in pairs(onDutyOfficers or {}) do
        table.insert(officers, officer.source)
    end
    
    -- Only create callouts if there are officers on duty
    if #officers == 0 then return end
    
    -- Select random officer to base location on
    local randomOfficer = officers[math.random(#officers)]
    local officerPed = GetPlayerPed(randomOfficer)
    local officerCoords = GetEntityCoords(officerPed)
    
    -- Generate random location within radius
    local angle = math.random() * 2 * math.pi
    local distance = math.random(500, Config.CalloutRadius)
    local coords = vector3(
        officerCoords.x + math.cos(angle) * distance,
        officerCoords.y + math.sin(angle) * distance,
        officerCoords.z
    )
    
    -- Select random crime type based on weights
    local crimeType = SelectWeightedCrime()
    
    -- Create the callout
    TriggerEvent('lspd:createCallout', crimeType, coords)
    activeCalloutCount = activeCalloutCount + 1
    
    -- Decrease count when callout is completed (with cleanup)
    SetTimeout(600000, function() -- 10 minutes max callout time
        activeCalloutCount = math.max(0, activeCalloutCount - 1)
    end)
end

function SelectWeightedCrime()
    local totalWeight = 0
    local crimes = {}
    
    -- Calculate total weight and build crimes table
    for crimeType, config in pairs(Config.CrimeTypes) do
        totalWeight = totalWeight + config.weight
        table.insert(crimes, {type = crimeType, weight = config.weight})
    end
    
    -- Select random crime based on weight
    local randomWeight = math.random() * totalWeight
    local currentWeight = 0
    
    for _, crime in ipairs(crimes) do
        currentWeight = currentWeight + crime.weight
        if randomWeight <= currentWeight then
            return crime.type
        end
    end
    
    -- Fallback
    return 'assault'
end

-- Callout completion tracking
RegisterNetEvent('lspd:calloutResolved', function()
    activeCalloutCount = math.max(0, activeCalloutCount - 1)
end)
