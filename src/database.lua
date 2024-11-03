-- Block Enums
local AIR = 0
local DIRT = 1
local TDIRT = 2
local BWATER = 3
local CSTICK = 4
local WEED = 6
local PLANT = 7
local UNKNOWN = -1

-- score Enums
local WORST = -3 -- can't be worse than the worst
local WRONG_PLANT = -2 -- replace wrong plants before empty cropsticks
local EMPTY = -1
local WATER = 111 -- crop will never be replaced (Max score should be 93 no matter the config)


local farmdb = {}
local nx = {}
local ny = {}
local target_crop
local seed_store_slot=1
local extra_seed_store_slot = 1
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

local function getExtraSeedStoreSlot()
    return extra_seed_store_slot
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

local function incExtraSeedStoreSlot()
    extra_seed_store_slot = extra_seed_store_slot + 1
    return extra_seed_store_slot
end

local function incDropStoreSlot()
    drop_store_slot = drop_store_slot + 1
    return drop_store_slot
end

local function getWorst()
    local worst = WATER
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

local function getAdj(pos)
    local x,y = pos[1], pos[2]
    local adj = {}
    local newpos = {{x+1, y},{x-1,y},{x,y-1},{x, y+1}}

    for i = 1,#newpos do
        if getEntry(newpos[i]) ~= nil then
            adj[#adj + 1 ] = newpos[i]
        end
    end
    return adj
end

local function validLayout()
    local valid = false
    local next_to_start = {{3,1}, {1,3}} -- just two cause it's in the corner
    local key
    for i = 1,#next_to_start do
        key = next_to_start[i]
        valid = valid or farmdb[key] >= 0
        valid = valid or farmdb[key] == WRONG_PLANT
    end

    return valid
end

return {
    -- BLOCK NAMES
    AIR=AIR,
    DIRT=DIRT,
    TDIRT=TDIRT,
    BWATER=BWATER,
    CSTICK=CSTICK,
    WEED=WEED,
    PLANT=PLANT,
    UNKNOWN=UNKNOWN,

    -- score Enums
    WORST=WORST,
    WRONG_PLANT=WRONG_PLANT,
    EMPTY=EMPTY,
    WATER=WATER,
    
    getDB=getDB, 
    getBounds=getBounds, 
    getEntry=getEntry, 
    getSeedStoreSlot=getSeedStoreSlot,
    getExtraSeedStoreSlot=getExtraSeedStoreSlot,
    getDropStoreSlot=getDropStoreSlot,
    getTargetCrop=getTargetCrop,
    setBounds=setBounds, 
    setEntry=setEntry, 
    incSeedStoreSlot=incSeedStoreSlot,
    incExtraSeedStoreSlot=incExtraSeedStoreSlot,
    incDropStoreSlot=incDropStoreSlot,
    setTargetCrop=setTargetCrop,
    getWorst=getWorst, 
    validLayout=validLayout,
    getAdj=getAdj
}