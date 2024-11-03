local act = require('actions')

local valid = act.init()

--someone has been up to something nefarious
-- print(string.format("Missing crop at position {%d,%d}, attempting to recover", pos[1], pos[2]))
-- local success = actions.recoverMissing()
-- if success then
--     return CSTICK, EMPTY
-- end