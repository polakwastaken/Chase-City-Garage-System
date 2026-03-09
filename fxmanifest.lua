fx_version 'cerulean'
game 'gta5'

author 'Polak' -- https://github.com/polakwastaken
description 'Garagescript'
version '1'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    '@NativeUI/src/NativeUIReloaded.lua',
    'client.lua'
}
