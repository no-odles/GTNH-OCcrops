local robot = require("robot")
local sides = require("sides")
local component = require("component")
local inv_c = component.inventory_controller

local nav = require("navigation")
local db = require("database")
local config = require("config")
local geo = require("geolyse")

local function halfFull()
    if inv_c.getStackInInternalSlot(config.inv_size // 2) == nil then
        return false
    else
        return  true
    end
end

local function isFull()
    robot.select(config.inv_size-3)  -- the -3 is for extra safety
    if inv_c.getStackInInternalSlot() == nil then
        return false
    else
        return  true
    end
end

local function storeInInv(side, internal_slot, ext_inv_size)
    local store_slot = 1
    local slot_is_empty = false
    local stored = false
    while not stored and store_slot <= ext_inv_size do
        slot_is_empty = inv_c.getSlotStackSize(side, store_slot) == 0
        if slot_is_empty then
            robot.select(internal_slot)
            stored = inv_c.dropIntoSlot(side, store_slot)
        end
        store_slot = store_slot + 1
    end
    return stored
end

local function dumpInv(dont_pause)
    print("Emptying inventory!")
    if not dont_pause then
        nav.pause()
    end

    nav.moveTo(config.above_storage)
    nav.faceDir(nav.EAST)
  
    local success
    local count = 0
    local item

    local seed_store_size = inv_c.getInventorySize(config.seed_store_side)
    local extra_seed_store_size = inv_c.getInventorySize(config.extra_seed_store_side)
    local drop_store_size = inv_c.getInventorySize(config.drop_store_side)

    for slot = config.first_storage_slot, config.inv_size do
        success = false
        item = inv_c.getStackInInternalSlot(slot)
        if item == nil then
            count = count + 1
            success = true
            if count > config.inv_search_limit then
                break
            end

        elseif item.name == "IC2:itemCropSeed" then
            count = 0
            if item.crop.name == db.getTargetCrop() then 
                success = storeInInv(config.seed_store_side, slot, seed_store_size)
            else
                success = storeInInv(config.extra_seed_store_side, slot, extra_seed_store_size)

            end
        else
            count = 0
            success = storeInInv(config.drop_store_side, slot, drop_store_size)

        end

        if not success then
            break
        end

    end

    if not dont_pause then
        nav.resume()
    end

    return success
end

local function pickUp()
    if isFull() then
        dumpInv()
    end

    while robot.suckDown(config.first_storage_slot) do -- TODO, check if this loop is necessary
        if isFull() then
            dumpInv()
        end
    end
end

local function restockSticks(dont_pause)
    print("Refilling Cropsticks!")
    if not dont_pause then
        nav.pause()
    end
    local sticks = inv_c.getStackInInternalSlot(config.cropstick_slot)
    local num_sticks
    if sticks == nil then
        num_sticks = 64
    else
        num_sticks = 64 - sticks.size
    end

    if num_sticks > 0 then
        nav.moveTo(config.cstick_restock_pos)
        robot.select(config.cropstick_slot)
        inv_c.suckFromSlot(sides.down, 2, num_sticks) --drawer main slot is 2, pretty sure 1 is the upgrade slot
        

        if config.dump_when_restock and halfFull() then
            dumpInv(true)
        end
    end

    if not dont_pause then
        nav.resume()
    end

    -- check if out of cropsticks
    sticks = inv_c.getStackInInternalSlot(config.cropstick_slot)
    return sticks == 64
end


local function findSeed(score) 
    local success = false
    local count = 0 -- how many in a row to allow
    for slot = 1, config.inv_size do
        local item = inv_c.getStackInInternalSlot(slot)
        if item == nil then
            count = count + 1
            if count == 32 then
                break
            end
        elseif item.crop ~= nil and item.crop.name == db.getTargetCrop() then
            count = 0
            if geo.evalCrop(item) == score then
                success = true
                return success, slot
            end
        else
            count = 0
        end
    end
    return success, -1
end


return {
    dumpInv=dumpInv,
    pickUp=pickUp,
    restockSticks=restockSticks,
    isFull=isFull,
    halfFull=halfFull,
    findSeed=findSeed
}