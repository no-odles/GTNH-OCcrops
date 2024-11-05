local config = require("config")


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
local nx = -1
local ny = -1
local target_crop
local seed_store_slot=1
local extra_seed_store_slot = 1
local drop_store_slot=1
local poslist = {}

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

local function getPosList()
    return poslist
end

local function setEntry(key, val)
    farmdb[{key[1], key[2]}] = val
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

local function setEmpty(key)
    farmdb[{key[1], key[2]}] = EMPTY
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

    return key, worst
end

local function getAdj(pos)
    local x,y = pos[1], pos[2]
    local xi, yi = table.unpack(config.crop_start_pos)
    local adj = {}
    local newpos = {{x+1, y},{x-1,y},{x,y-1},{x, y+1}}

    for i = 1,#newpos do
        local xn, yn = table.unpack(newpos[i])
        if math.abs(xi-xn) < nx and math.abs(yi-yn) < ny then
            adj[#adj + 1 ] = newpos[i]
        end
    end
    return adj
end

local function getAdjDBEntries(pos)
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

local function setBounds(bx, by)
    nx, ny = bx, by
    local x0, y0 = table.unpack(config.crop_start_pos)

    -- generate poslist
    if #poslist == 0 then
        for yi = 0, ny-1 do

            if yi % 2 == 0 then
                for xi = 0,-(nx-1),-1 do
                    poslist[#poslist + 1] = {x0+xi,y0+yi}
                end
            else
                for xi = -(nx-1),0,1 do
                    poslist[#poslist + 1] = {x0+xi,y0+yi}
                end
            end

        end
    end
end

local function validLayout()
    local valid = false
    local next_to_start = getAdjDBEntries(config.crop_start_pos) -- just two cause it's in the corner
    local key
    local val
    for i = 1,#next_to_start do
        key = next_to_start[i]
        val = farmdb[key]
        valid = valid or  (val ~= nil and (val >= 0 or val == WRONG_PLANT))
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
    getPosList=getPosList,
    getTargetCrop=getTargetCrop,
    setBounds=setBounds, 
    setEntry=setEntry, 
    incSeedStoreSlot=incSeedStoreSlot,
    incExtraSeedStoreSlot=incExtraSeedStoreSlot,
    incDropStoreSlot=incDropStoreSlot,
    setEmpty=setEmpty,
    setTargetCrop=setTargetCrop,
    getWorst=getWorst, 
    validLayout=validLayout,
    getAdjDBEntries=getAdjDBEntries,
    getAdj=getAdj
}