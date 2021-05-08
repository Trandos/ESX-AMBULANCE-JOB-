fx_version 'adamant'
games { 'gta5' };

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'config.lua',
	'server/main.lua',
	'server/medoc.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'config.lua',
	'client/main.lua',
	'client/appel.lua',
	'client/job.lua',
	'client/wheelchair.lua',
	'client/medoc.lua'
}
