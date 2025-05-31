
# LSPD AI Callouts - FiveM Police Script

A comprehensive police roleplay script for FiveM servers running ox_core, providing dynamic AI-driven police callouts similar to LSPDFR.

## Features

### 🚓 Core Police System
- **Duty System**: Players can go on/off duty as police officers
- **Dynamic Callouts**: Automatic generation of various crime types across the map
- **AI Suspects**: Realistic NPC behavior with random responses (flee, fight, surrender)
- **Professional Dispatch**: Comprehensive notification and map blip system

### 🎯 Crime Types
- **Armed Robbery**: Store robberies with armed suspects
- **Vehicle Pursuits**: High-speed chases with fleeing suspects  
- **Shots Fired**: Active shooter scenarios
- **Assault**: Physical altercations and fights
- **Domestic Disputes**: Household disturbance calls
- **Grand Theft Auto**: Vehicle theft incidents

### 👮 Police Tools
- **Arrest System**: Full arrest mechanics with handcuffing
- **Search & Frisk**: Pat-down suspects for contraband
- **Citation System**: Issue fines and tickets
- **Backup Requests**: Call for officer assistance
- **Negotiation**: Attempt to peacefully resolve situations
- **Transport System**: Send suspects to jail

### 📱 User Interface
- **ox_lib Integration**: Modern UI with notifications and context menus
- **ox_target Support**: Interactive targeting system
- **Records System**: Track arrests and citations
- **Admin Controls**: Test callouts and manage system

## Installation

1. Ensure you have the required dependencies:
   - `ox_lib`
   - `ox_target` (optional but recommended)

2. Download and place the script in your resources folder

3. Add to your `server.cfg`:
   ```
   ensure lspd_ai_callouts
   ```

4. Configure the script by editing `config.lua`

## Configuration

### Basic Settings
```lua
Config.PoliceJob = 'police' -- Set to false for standalone
Config.UseOxTarget = true   -- Enable ox_target integration
Config.Debug = false        -- Enable debug logging
```

### Callout Frequency
```lua
Config.CalloutFrequency = {
    min = 120000, -- 2 minutes minimum
    max = 300000  -- 5 minutes maximum
}
```

### Crime Type Weights
Adjust the probability of different crime types:
```lua
Config.CrimeTypes = {
    robbery = { weight = 25, priority = 'High' },
    pursuit = { weight = 20, priority = 'High' },
    -- ... etc
}
```

## Commands

### Player Commands
- `/duty` - Toggle police duty status
- `/backup [reason]` - Request backup assistance
- `/callouts` - View active callouts menu
- `/policetools` - Access police tools menu

### Admin Commands
- `/callout [type]` - Manually create a test callout
  - Available types: robbery, pursuit, shots_fired, assault, domestic, theft

## Key Bindings

- **F6** - Toggle Police Duty
- **F7** - View Active Callouts
- **F8** - Police Tools Menu  
- **F9** - Request Backup

## How It Works

### Automatic Callout Generation
- System monitors on-duty officers
- Generates callouts within configurable radius of officers
- Weighs crime types based on configuration
- Limits maximum active callouts

### AI Suspect Behavior
- **40%** chance to flee when police arrive
- **30%** chance to surrender peacefully  
- **30%** chance to fight/resist arrest
- Behavior varies by crime type and situation

### Interaction System
When approaching suspects, officers can:
1. **Order Weapon Drop** - Command armed suspects to disarm
2. **Arrest** - Place suspect in custody
3. **Search** - Pat down for contraband
4. **Negotiate** - Attempt peaceful resolution
5. **Issue Citation** - Give fines instead of arrest
6. **Transport to Jail** - Send to Bolingbroke Penitentiary

## Advanced Features

### Records System
- Automatic logging of all arrests and citations
- Searchable history for investigations
- Fine calculation based on charges

### Backup System
- Real-time officer assistance requests
- Priority levels (Low, Medium, High, Emergency)
- Map blips for backup locations

### Jail Integration
- Automatic transport to Bolingbroke Penitentiary
- Configurable jail times
- Integration ready for advanced jail systems

## Compatibility

- **Framework**: ox_core (standalone compatible)
- **UI Library**: ox_lib
- **Targeting**: ox_target (optional)
- **Dependencies**: No ESX or QB required

## Support & Customization

The script is designed to be easily customizable:

- **Add New Crime Types**: Extend `Config.CrimeTypes`
- **Modify AI Behavior**: Adjust `Config.AIBehavior` percentages
- **Custom Suspect Models**: Edit `Config.SuspectModels`
- **Integration**: Easy integration with MDT systems

## Performance

- Optimized for minimal server impact
- Automatic cleanup of entities and blips
- Configurable limits to prevent resource overload
- Built-in debugging system for troubleshooting

## License

This script is provided as-is for educational and roleplay purposes. Feel free to modify and adapt for your server's needs.

---

*Created with ❤️ for the FiveM roleplay community*
