local robot = require("robot")
local sides = require("sides")
local config = {
    inv_size = robot.inventorysize(),
    spade_slot = robot.inventorysize() - 0,
    cropstick_slot = robot.inventorysize() - 1,
    last_storage_slot = robot.inventorysize() - 2,
    crop_name = nil,
    resistance_target = 2,
    max_growth = 23,
    cstick_restock_pos = {-1,2,0},
    seed_store_side = sides.left,
    drop_store_side = sides.right

}

return config