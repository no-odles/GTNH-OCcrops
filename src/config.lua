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
    above_storage = {1, 4, 0},
    crop_start_pos={-1,1},
    start_pos={0,0,0},
    seed_store_side = sides.front,
    extra_seed_store_side = sides.up,
    drop_store_side = sides.down,
    dump_when_restock=true,
    score_goal = 31 + 23 + 2

}

return config