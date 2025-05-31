
local activeCrimeScenes = {}

-- Spawn crime scene based on callout type
RegisterNetEvent('lspd:spawnCrimeScene', function(callout)
    if activeCrimeScenes[callout.id] then return end
    
    Citizen.CreateThread(function()
        local crimeScene = {
            id = callout.id,
            type = callout.type,
            coords = callout.coords,
            suspects = {},
            vehicles = {},
            resolved = false
        }
        
        activeCrimeScenes[callout.id] = crimeScene
        
        -- Spawn crime scene based on type
        if callout.type == 'robbery' then
            SpawnRobberyScene(crimeScene)
        elseif callout.type == 'pursuit' then
            SpawnPursuitScene(crimeScene)
        elseif callout.type == 'shots_fired' then
            SpawnShotsScene(crimeScene)
        elseif callout.type == 'assault' then
            SpawnAssaultScene(crimeScene)
        elseif callout.type == 'domestic' then
            SpawnDomesticScene(crimeScene)
        elseif callout.type == 'theft' then
            SpawnTheftScene(crimeScene)
        end
        
        -- Monitor scene until resolved
        MonitorCrimeScene(crimeScene)
    end)
end)

function SpawnRobberyScene(scene)
    local coords = scene.coords
    
    -- Spawn suspect with weapon
    local suspectModel = Config.SuspectModels[math.random(#Config.SuspectModels)]
    local suspectHash = GetHashKey(suspectModel)
    
    RequestModel(suspectHash)
    while not HasModelLoaded(suspectHash) do
        Citizen.Wait(10)
    end
    
    local suspect = CreatePed(4, suspectHash, coords.x, coords.y, coords.z, 0.0, true, true)
    SetPedRandomComponentVariation(suspect, false)
    SetPedRandomProps(suspect)
    
    -- Give weapon
    local weapon = Config.SuspectWeapons[math.random(#Config.SuspectWeapons)]
    GiveWeaponToPed(suspect, GetHashKey(weapon), 100, false, true)
    
    -- Set up AI behavior
    SetupSuspectAI(suspect, scene.id, 'robbery')
    
    table.insert(scene.suspects, suspect)
    SetModelAsNoLongerNeeded(suspectHash)
end

function SpawnPursuitScene(scene)
    local coords = scene.coords
    
    -- Spawn pursuit vehicle
    local vehicleModel = Config.PursuitVehicles[math.random(#Config.PursuitVehicles)]
    local vehicleHash = GetHashKey(vehicleModel)
    
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Citizen.Wait(10)
    end
    
    local vehicle = CreateVehicle(vehicleHash, coords.x, coords.y, coords.z, 0.0, true, true)
    
    -- Spawn driver
    local driverModel = Config.SuspectModels[math.random(#Config.SuspectModels)]
    local driverHash = GetHashKey(driverModel)
    
    RequestModel(driverHash)
    while not HasModelLoaded(driverHash) do
        Citizen.Wait(10)
    end
    
    local driver = CreatePed(4, driverHash, coords.x, coords.y, coords.z, 0.0, true, true)
    SetPedIntoVehicle(driver, vehicle, -1)
    
    -- Start pursuit behavior
    TaskVehicleDriveWander(driver, vehicle, 80.0, 786603)
    SetDriverAggressiveness(driver, 1.0)
    SetDriverRacingModifier(driver, 1.0)
    
    SetupSuspectAI(driver, scene.id, 'pursuit')
    
    table.insert(scene.suspects, driver)
    table.insert(scene.vehicles, vehicle)
    
    SetModelAsNoLongerNeeded(vehicleHash)
    SetModelAsNoLongerNeeded(driverHash)
end

function SpawnShotsScene(scene)
    local coords = scene.coords
    local numSuspects = math.random(1, 2)
    
    for i = 1, numSuspects do
        local offset = vector3(
            math.random(-10, 10),
            math.random(-10, 10),
            0
        )
        
        local suspectCoords = coords + offset
        local suspectModel = Config.SuspectModels[math.random(#Config.SuspectModels)]
        local suspectHash = GetHashKey(suspectModel)
        
        RequestModel(suspectHash)
        while not HasModelLoaded(suspectHash) do
            Citizen.Wait(10)
        end
        
        local suspect = CreatePed(4, suspectHash, suspectCoords.x, suspectCoords.y, suspectCoords.z, 0.0, true, true)
        
        -- Always armed for shots fired
        GiveWeaponToPed(suspect, GetHashKey('WEAPON_PISTOL'), 100, false, true)
        SetCurrentPedWeapon(suspect, GetHashKey('WEAPON_PISTOL'), true)
        
        -- More aggressive behavior
        SetPedCombatAttributes(suspect, 46, true)
        SetPedCombatAttributes(suspect, 0, false)
        
        SetupSuspectAI(suspect, scene.id, 'shots_fired')
        table.insert(scene.suspects, suspect)
        
        SetModelAsNoLongerNeeded(suspectHash)
    end
end

function SpawnAssaultScene(scene)
    local coords = scene.coords
    
    -- Spawn aggressor
    local aggressorModel = Config.SuspectModels[math.random(#Config.SuspectModels)]
    local aggressorHash = GetHashKey(aggressorModel)
    
    RequestModel(aggressorHash)
    while not HasModelLoaded(aggressorHash) do
        Citizen.Wait(10)
    end
    
    local aggressor = CreatePed(4, aggressorHash, coords.x, coords.y, coords.z, 0.0, true, true)
    
    -- Sometimes give melee weapon
    if math.random(100) < 30 then
        local meleeWeapons = {'WEAPON_KNIFE', 'WEAPON_BAT', 'WEAPON_CROWBAR'}
        local weapon = meleeWeapons[math.random(#meleeWeapons)]
        GiveWeaponToPed(aggressor, GetHashKey(weapon), 1, false, true)
    end
    
    SetupSuspectAI(aggressor, scene.id, 'assault')
    table.insert(scene.suspects, aggressor)
    
    SetModelAsNoLongerNeeded(aggressorHash)
end

function SpawnDomesticScene(scene)
    -- Similar to assault but with multiple peds
    SpawnAssaultScene(scene)
end

function SpawnTheftScene(scene)
    local coords = scene.coords
    
    -- Find nearby vehicle to "steal"
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 50.0, 0, 71)
    
    if not DoesEntityExist(vehicle) then
        -- Spawn a vehicle to steal
        local vehicleModel = 'blista'
        local vehicleHash = GetHashKey(vehicleModel)
        
        RequestModel(vehicleHash)
        while not HasModelLoaded(vehicleHash) do
            Citizen.Wait(10)
        end
        
        vehicle = CreateVehicle(vehicleHash, coords.x, coords.y, coords.z, 0.0, true, true)
        table.insert(scene.vehicles, vehicle)
        SetModelAsNoLongerNeeded(vehicleHash)
    end
    
    -- Spawn thief
    local thiefModel = Config.SuspectModels[math.random(#Config.SuspectModels)]
    local thiefHash = GetHashKey(thiefModel)
    
    RequestModel(thiefHash)
    while not HasModelLoaded(thiefHash) do
        Citizen.Wait(10)
    end
    
    local thief = CreatePed(4, thiefHash, coords.x, coords.y, coords.z, 0.0, true, true)
    
    -- Task thief to enter vehicle
    TaskEnterVehicle(thief, vehicle, -1, -1, 1.0, 1, 0)
    
    SetupSuspectAI(thief, scene.id, 'theft')
    table.insert(scene.suspects, thief)
    
    SetModelAsNoLongerNeeded(thiefHash)
end

function SetupSuspectAI(suspect, sceneId, crimeType)
    -- Mark as suspect for targeting
    Entity(suspect).state:set('isSuspect', true, true)
    Entity(suspect).state:set('sceneId', sceneId, true)
    Entity(suspect).state:set('crimeType', crimeType, true)
    Entity(suspect).state:set('arrested', false, true)
    
    -- Set up basic AI behavior
    SetPedCanRagdoll(suspect, false)
    SetPedCanBeTargetted(suspect, true)
    SetEntityInvincible(suspect, false)
    
    -- Random behavior based on crime type
    Citizen.CreateThread(function()
        Citizen.Wait(math.random(5000, 15000)) -- Wait before reacting
        
        if not DoesEntityExist(suspect) or Entity(suspect).state.arrested then
            return
        end
        
        -- Check if police are nearby
        local policeNearby = IsPoliceNearby(suspect, 50.0)
        
        if policeNearby then
            local behavior = DetermineSuspectBehavior(crimeType)
            ExecuteSuspectBehavior(suspect, behavior, sceneId)
        end
    end)
end

function DetermineSuspectBehavior(crimeType)
    local rand = math.random(100)
    
    if crimeType == 'shots_fired' then
        -- More likely to fight
        if rand <= 60 then return 'fight'
        elseif rand <= 85 then return 'flee'
        else return 'surrender' end
    else
        -- Normal behavior probabilities
        if rand <= Config.AIBehavior.flee_chance then return 'flee'
        elseif rand <= Config.AIBehavior.flee_chance + Config.AIBehavior.surrender_chance then return 'surrender'
        else return 'fight' end
    end
end

function ExecuteSuspectBehavior(suspect, behavior, sceneId)
    if behavior == 'flee' then
        -- Run away
        TaskSmartFleePed(suspect, PlayerPedId(), 500.0, -1, false, false)
        SetPedKeepTask(suspect, true)
        
        -- Cleanup after 2 minutes if not caught
        SetTimeout(120000, function()
            if DoesEntityExist(suspect) and not Entity(suspect).state.arrested then
                DeleteEntity(suspect)
            end
        end)
        
    elseif behavior == 'fight' then
        -- Attack player
        TaskCombatPed(suspect, PlayerPedId(), 0, 16)
        SetPedCombatAttributes(suspect, 46, true)
        
    elseif behavior == 'surrender' then
        -- Put hands up
        TaskHandsUp(suspect, -1, PlayerPedId(), -1, false)
        SetPedKeepTask(suspect, true)
    end
end

function IsPoliceNearby(suspect, radius)
    local playerPed = PlayerPedId()
    local suspectCoords = GetEntityCoords(suspect)
    local playerCoords = GetEntityCoords(playerPed)
    
    return isOnDuty and #(suspectCoords - playerCoords) <= radius
end

function MonitorCrimeScene(scene)
    Citizen.CreateThread(function()
        while activeCrimeScenes[scene.id] and not scene.resolved do
            Citizen.Wait(5000)
            
            -- Check if all suspects are arrested/dead
            local allResolved = true
            for _, suspect in ipairs(scene.suspects) do
                if DoesEntityExist(suspect) and not Entity(suspect).state.arrested and not IsEntityDead(suspect) then
                    allResolved = false
                    break
                end
            end
            
            if allResolved then
                CompleteCallout(scene.id, 'Suspects apprehended')
                scene.resolved = true
                
                -- Cleanup after 5 minutes
                SetTimeout(300000, function()
                    CleanupCrimeScene(scene)
                end)
            end
        end
    end)
end

function CleanupCrimeScene(scene)
    -- Remove suspects
    for _, suspect in ipairs(scene.suspects) do
        if DoesEntityExist(suspect) then
            DeleteEntity(suspect)
        end
    end
    
    -- Remove vehicles
    for _, vehicle in ipairs(scene.vehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    
    activeCrimeScenes[scene.id] = nil
end
