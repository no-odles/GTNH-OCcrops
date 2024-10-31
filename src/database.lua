local geo = require("geolyse")

local farmdb = {}
local nx = {}
local ny = {}
local target_crop
local seed_store_slot=1
local drop_store_slot=1

local function getDB()
    return farmdb
end

local function getEntry(key)
    return farmdb[key]
end

local function getBounds()
    return nx, ny
end

local function getTargetCrop()
    return target_crop
end

local function getSeedStoreSlot()
    return seed_store_slot
end

local function getDropStoreSlot()
    return drop_store_slot
end

local function setEntry(key, val)
    farmdb[key] = val
end

local function setBounds(bx, by)
    nx, ny = bx, by
end

local function setTargetCrop(crop)
    target_crop = crop
end

local function incSeedStoreSlot()
    seed_store_slot = seed_store_slot + 1
    return seed_store_slot
end

local function incDropStoreSlot()
    drop_store_slot = drop_store_slot + 1
    return drop_store_slot
end

local function getWorst()
    local worst = geo.WATER
    local key
    for i = 1,nx do
        for j = 1,ny do 
            if farmdb[{i,j}] < worst then
                key = {i,j}
                worst = farmdb[key]
            end
        end
    end

    return key
end

local function validLayout()
    local valid = false
    local next_to_start = {{3,1}, {1,3}} -- just two cause it's in the corner
    local key
    for i = 1,#next_to_start do
        key = next_to_start[i]
        valid = valid or farmdb[key] >= 0
        valid = valid or farmdb[key] == geo.WRONG_PLANT
    end

    return valid
end

return {
    getDB=getDB, 
    getBounds=getBounds, 
    getEntry=getEntry, 
    getSeedStoreSlot=getSeedStoreSlot,
    getDropStoreSlot=getDropStoreSlot,
    setBounds=setBounds, 
    setEntry=setEntry, 
    incSeedStoreSlot=incSeedStoreSlot,
    incDropStoreSlot=incDropStoreSlot,
    getWorst=getWorst, 
    validLayout=validLayout,
}