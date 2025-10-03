fx_version 'cerulean'
game 'gta5'

name 'qb-playtime'
author 'devtakkekar'
description 'Playtime tracker with /time UI and leaderboard for QBCore'
version '1.0.0'

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/style.css',
	'html/app.js'
}

shared_scripts {
	'@qb-core/shared/locale.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/server.lua'
}

client_scripts {
	'client/client.lua'
}

lua54 'yes'


