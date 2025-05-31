
fx_version 'cerulean'
game 'gta5'

author 'Lovable'
description 'LSPD AI Callouts - LSPDFR Style Police System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/interactions.lua',
    'client/crimes.lua',
    'client/ui.lua'
}

server_scripts {
    'server/main.lua',
    'server/callouts.lua',
    'server/database.lua'
}

dependencies {
    'ox_lib',
    'qb-target'
}

lua54 'yes'
