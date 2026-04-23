fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TMG Manic'
description 'Allows players to grow weed plants in their house to harvest for items to sell'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@tmg-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua'
}

client_script 'client/main.lua'

server_scripts {
    'server/main.lua'
}
