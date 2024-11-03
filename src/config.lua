local robot = require("robot")
local sides = require("sides")
local config = {
    inv_size = robot.inventorysize(),
    spade_slot = 1,
    cropstick_slot = 2,
    first_storage_slot = 3,
    crop_name = nil,
    resistance_target = 2,
    max_growth = 23,
    cstick_restock_pos = {-1,2,0},
    above_storage = {-1, 4, 0},
    start_pos={1,1},
    seed_store_side = sides.front,
    extra_seed_store_side = sides.right,
    drop_store_side = sides.right,
    dump_when_restock=true

}

return config