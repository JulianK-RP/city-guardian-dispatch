
local dutyUIVisible = false

function ShowPoliceUI()
    dutyUIVisible = true
    
    lib.notify({
        title = 'LSPD',
        description = 'Police UI activated\nF6: Toggle Duty\nF9: Request Backup',
        type = 'inform',
        duration = 5000
    })
    
    -- Could add more UI elements here like:
    -- - Active callouts display
    -- - Officer status
    -- - Quick action buttons
end

function HidePoliceUI()
    dutyUIVisible = false
end

-- Show callout menu
RegisterCommand('callouts', function()
    if not isOnDuty then
        lib.notify({
            title = 'LSPD',
            description = 'You must be on duty to view callouts',
            type = 'error'
        })
        return
    end
    
    local options = {}
    
    for id, callout in pairs(currentCallouts) do
        local crimeConfig = Config.CrimeTypes[callout.type]
        local distance = #(GetEntityCoords(PlayerPedId()) - callout.coords)
        
        table.insert(options, {
            title = 'Callout #' .. id,
            description = string.format('%s - %.0fm away\n%s', 
                crimeConfig.label, 
                distance, 
                crimeConfig.description
            ),
            icon = 'bell',
            onSelect = function()
                RespondToCallout(id)
            end
        })
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'No Active Callouts',
            description = 'All quiet on the streets',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'callouts_menu',
        title = 'Active Callouts',
        options = options
    })
    
    lib.showContext('callouts_menu')
end, false)

-- Show police tools menu
RegisterCommand('policetools', function()
    if not isOnDuty then
        lib.notify({
            title = 'LSPD',
            description = 'You must be on duty to access police tools',
            type = 'error'
        })
        return
    end
    
    local options = {
        {
            title = 'Request Backup',
            description = 'Call for officer assistance',
            icon = 'shield',
            onSelect = function()
                RequestBackupMenu()
            end
        },
        {
            title = 'View Active Callouts',
            description = 'See all ongoing incidents',
            icon = 'bell',
            onSelect = function()
                ExecuteCommand('callouts')
            end
        },
        {
            title = 'Check Records',
            description = 'Access arrest and citation history',
            icon = 'file-text',
            onSelect = function()
                ShowRecordsMenu()
            end
        }
    }
    
    lib.registerContext({
        id = 'police_tools',
        title = 'Police Tools',
        options = options
    })
    
    lib.showContext('police_tools')
end, false)

function RequestBackupMenu()
    local input = lib.inputDialog('Request Backup', {
        {type = 'select', label = 'Priority', options = {
            {value = 'low', label = 'Low Priority'},
            {value = 'medium', label = 'Medium Priority'},
            {value = 'high', label = 'High Priority'},
            {value = 'emergency', label = 'Emergency'}
        }},
        {type = 'input', label = 'Reason', placeholder = 'Describe the situation'}
    })
    
    if not input then return end
    
    local priority = input[1]
    local reason = input[2] or 'Officer needs assistance'
    
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('lspd:requestBackup', coords, priority .. ': ' .. reason)
    
    lib.notify({
        title = 'LSPD',
        description = 'Backup requested',
        type = 'inform'
    })
end

function ShowRecordsMenu()
    -- Get recent arrest and citation history
    lib.callback.await('lspd:getArrestHistory', false, 10):next(function(arrests)
        lib.callback.await('lspd:getCitationHistory', false, 10):next(function(citations)
            local options = {}
            
            -- Add recent arrests
            if #arrests > 0 then
                table.insert(options, {
                    title = 'Recent Arrests (' .. #arrests .. ')',
                    disabled = true
                })
                
                for _, arrest in ipairs(arrests) do
                    table.insert(options, {
                        title = 'Arrest #' .. arrest.id,
                        description = string.format('Officer: %s\nCharges: %s\nFine: $%d', 
                            arrest.officer, 
                            table.concat(arrest.charges, ', '),
                            arrest.fine_amount
                        ),
                        icon = 'handcuffs'
                    })
                end
            end
            
            -- Add recent citations
            if #citations > 0 then
                table.insert(options, {
                    title = 'Recent Citations (' .. #citations .. ')',
                    disabled = true
                })
                
                for _, citation in ipairs(citations) do
                    table.insert(options, {
                        title = 'Citation #' .. citation.id,
                        description = string.format('Officer: %s\nViolation: %s\nAmount: $%d',
                            citation.officer,
                            table.concat(citation.violations, ', '),
                            citation.amount
                        ),
                        icon = 'file-text'
                    })
                end
            end
            
            if #options == 0 then
                table.insert(options, {
                    title = 'No Records Found',
                    description = 'No recent activity',
                    disabled = true
                })
            end
            
            lib.registerContext({
                id = 'records_menu',
                title = 'Department Records',
                options = options
            })
            
            lib.showContext('records_menu')
        end)
    end)
end

-- Key bindings for menus
RegisterKeyMapping('callouts', 'View Active Callouts', 'keyboard', 'F7')
RegisterKeyMapping('policetools', 'Police Tools Menu', 'keyboard', 'F8')
