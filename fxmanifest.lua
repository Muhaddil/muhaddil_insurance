fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Muhaddil'
description 'Medical Insurance Script'
version 'v2.0.2'

shared_script 'config.lua'
client_script 'client/*'
server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/*'
}

shared_script '@ox_lib/init.lua'

files {
    'locales/*.json',
    'web/build/index.html',
    'web/build/**/*'
}

ui_page 'web/build/index.html'

dependencies {
    'ox_lib',
    'oxmysql'
}
