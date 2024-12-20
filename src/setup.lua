local shell = require('shell')
local args = {...}
local branch
local repo
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

-- BRANCH
if #args >= 1 then
    branch = args[1]
else
    branch = 'main'
end

-- REPO
if #args >= 2 then
    repo = args[2]
else
    repo = 'https://raw.githubusercontent.com/no-odles/GTNH-OCcrops/'
end

-- INSTALL
for i=1, #scripts do
    shell.execute(string.format('wget -f %s%s/src/%s', repo, branch, scripts[i]))
end