local shell = require('shell')
local args = {...}
local branch
local repo
local scripts = {
    'actions.lua',
    'config.lua',
    'database.lua',
    'geolyse.lua',
    -- 'events.lua',
    'navigation.lua',
    'propogate.lua'
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
    repo = 'https://raw.githubusercontent.com/no-odles/GTNH-OCcrops/refs/heads/main/src/'
end

-- INSTALL
for i=1, #scripts do
    shell.execute(string.format('wget -f %s%s/%s', repo, branch, scripts[i]))
end