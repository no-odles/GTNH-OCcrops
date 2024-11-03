local shell = require('shell')

local scripts = {
    'actions.lua',
    'config.lua',
    'database.lua',
    'geolyse.lua',
    'inventory.lua',
    -- 'events.lua',
    'navigation.lua',
    'propagate.lua',
    'utils.lua',
    'uninstall.lua'
}

for i=1, #scripts do
    shell.execute(string.format('rm %s', scripts[i]))
end