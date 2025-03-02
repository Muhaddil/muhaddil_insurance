fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Muhaddil'
description 'Simple Medical Insurance Script'
version 'v1.0.121'

shared_script 'config.lua'
client_script 'client.lua'
server_script {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

shared_script '@ox_lib/init.lua'

files {
    'locales/*.json'
}