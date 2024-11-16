local robot = require("robot")
local sides = require("sides")
local config = {
    inv_size = robot.inventorySize(),
    spade_slot = 1,
    cropstick_slot = 2,
    first_storage_slot = 3,
    crop_name = nil,
    resistance_target = 2,
    max_growth = 23,
    cstick_restock_pos = {1,2,0},
    above_storage = {1, 3, 0},
    crop_start_pos={-1,1},
    start_pos={0,0,0},
    seed_store_side = sides.front,
    extra_seed_store_side = sides.up,
    drop_store_side = sides.down,
    dump_when_restock=false,
    score_goal = 31 + 23 + 2,
    max_farm_width=4,
    strict_farm=false, -- whether to abort if it finds non farm block during initialisation (cant be anything weird in the first row)
    non_targets_are_weeds=false,
    inv_search_limit=15, -- number of empty slots between items to allow before an inventroy is considered empty
    wrong_plant_penalty=3 -- amount to subtract from the score of wrong plants
}

return config