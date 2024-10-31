local robot = require("robot")
local config = require("config")
nav = require("navigation")
local sides = require("sides")

local component = require("component")
local inv_c = component.inventory_controller

local function isdone()

end

local function sgn(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

local function dblCrop(pos)
    -- check whether there should be a double cropstick here
    local x, y = pos[1], pos[2]
    return (x % 2 + y % 2 ) == 1
end

local function isFull()
    return 
end

local function dumpInv
    nav.pause()
    nav.moveTo(config.stick_pos)
    local success = false
    local seed_slot, drop_slot = db.getSeedStoreSlot(), db.getDropStoreSlot()
    for slot = 1, config.last_storage_slot do
        success = false
        robot.select(slot)
        item = inv_c.getStackInInternalSlot()
        if item.name == "IC2:itemCropSeed" then
            while ~success and seed_slot <= inv_c.getInventorySize(config.seed_store_side) do
                success = dropIntoSlot(config.seed_store_side, seed_slot)
                seed_slot = db.incSeedStoreSlot()
            end
        else
            while ~success and drop_slot <= inv_c.getInventorySize(config.drop_store_side) do
                success = dropIntoSlot(config.drop_store_side, seed_slot)
                seed_slot = db.incDropStoreSlot()
            end
        end

    end
    nav.resume()
    return success
end

local function restockSticks()
    nav.pause()
    nav.moveTo(config.stick_pos)
    robot.select(config.cropstick_slot)
    inv_c.suckFromSlot(sides.down, 2) --drawer main slot is 2, pretty sure 1 is the upgrade slot
    resume()
end

return {
    isDone=isDone, 
    sgn=sgn, 
    dblCrop=dblCrop, 
    dumpInv=dumpInv, 
    restockSticks=restockSticks}