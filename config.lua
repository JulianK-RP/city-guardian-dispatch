
Config = {}

-- General Settings
Config.PoliceJob = 'police' -- Set to false if standalone
Config.UseOxTarget = true
Config.Debug = false

-- Callout System
Config.CalloutFrequency = {
    min = 120000, -- 2 minutes minimum
    max = 300000  -- 5 minutes maximum
}

Config.MaxActiveCallouts = 3
Config.CalloutRadius = 2000.0 -- Distance from player to spawn callouts

-- Crime Types and Their Probabilities
Config.CrimeTypes = {
    robbery = {
        weight = 25,
        label = 'Armed Robbery',
        priority = 'High',
        color = 1, -- Red blip
        description = 'Armed suspect robbing a store'
    },
    pursuit = {
        weight = 20,
        label = 'Vehicle Pursuit',
        priority = 'High', 
        color = 1,
        description = 'Suspect fleeing in a vehicle'
    },
    shots_fired = {
        weight = 15,
        label = 'Shots Fired',
        priority = 'Critical',
        color = 59, -- Dark red
        description = 'Reports of gunshots in the area'
    },
    assault = {
        weight = 20,
        label = 'Assault in Progress',
        priority = 'Medium',
        color = 5, -- Yellow
        description = 'Physical altercation reported'
    },
    domestic = {
        weight = 15,
        label = 'Domestic Dispute',
        priority = 'Medium',
        color = 5,
        description = 'Domestic violence call'
    },
    theft = {
        weight = 5,
        label = 'Grand Theft Auto',
        priority = 'Low',
        color = 3, -- Blue
        description = 'Vehicle theft in progress'
    }
}

-- AI Behavior Probabilities
Config.AIBehavior = {
    flee_chance = 40,
    surrender_chance = 30,
    fight_chance = 30,
    backup_flee_chance = 60, -- Higher chance to flee when backup arrives
}

-- Suspect Models
Config.SuspectModels = {
    'a_m_m_beach_01',
    'a_m_m_bevhills_01',
    'a_m_m_business_01',
    'a_m_m_downtown_01',
    'a_m_m_eastsa_01',
    'a_m_m_fatlatin_01',
    'a_m_m_genfat_01',
    'a_m_m_golfer_01',
    'a_m_m_hasjew_01',
    'a_m_m_hillbilly_01',
    'a_m_y_business_01',
    'a_m_y_cyclist_01',
    'a_m_y_downtown_01',
    'a_m_y_epsilon_01',
    'a_m_y_gay_01'
}

-- Weapons for suspects
Config.SuspectWeapons = {
    'WEAPON_PISTOL',
    'WEAPON_MICROSMG',
    'WEAPON_KNIFE',
    'WEAPON_BAT',
    'WEAPON_CROWBAR'
}

-- Vehicle models for pursuits
Config.PursuitVehicles = {
    'adder',
    'banshee',
    'carbonizzare',
    'comet2',
    'coquette',
    'entityxf',
    'feltzer2',
    'monroe',
    'ninef',
    'rapidgt',
    'stinger',
    'vacca',
    'voltic'
}

-- Jail Settings
Config.JailCoords = vector3(1641.0, 2571.0, 46.0) -- Bolingbroke Penitentiary
Config.JailTime = 300 -- 5 minutes default

-- Interaction Settings
Config.InteractionDistance = 3.0
Config.BackupRadius = 500.0

-- Penalties/Fines
Config.Fines = {
    assault = 500,
    robbery = 1500,
    theft = 800,
    weapons = 1000,
    fleeing = 300,
    resisting = 200
}
