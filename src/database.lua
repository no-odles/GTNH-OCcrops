local config = require("config")
local utils = require("utils")


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
local WORST = -10 -- can't be worse than the worst
local WRONG_PLANT = -2 -- replace empty cropsticks before wrong plants
local EMPTY = -3
local WATER = 111 -- 'crop' will never be replaced (Max score should be 93 no matter the config)


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
    local i,j = table.unpack(key)
    if farmdb[i] == nil then
        return nil
    end
    return farmdb[i][j]
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
    local i,j = table.unpack(key)
    if farmdb[i] == nil then
        farmdb[i] = {}
    end
    farmdb[i][j] = val
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
    local i,j = table.unpack(key)
    if farmdb[i] == nil then
        farmdb[i] = {}
    end
    farmdb[i][j] = EMPTY
end
local function getWorstCrop()
    local worst = WATER
    local key
    for i = 1, #poslist do
        local pos = poslist[i]
        if not utils.dblCrop(pos) then
            local entry = getEntry(pos)
            if entry < worst then
                key = pos
                worst = entry
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
        -- local dx, dy = math.abs(xi-xn), math.abs(yi-yn)
        if  (xi-nx < xn and xn <= xi) and  (yi <= yn and yn < yi + ny) then
            adj[#adj + 1 ] = newpos[i]
        end
    end
    return adj
end

local function getAdjSingleCrops(pos)
    local x,y = pos[1], pos[2]
    local adj = {}
    local newpos = {{x+2, y},{x-2,y},{x,y-2},{x, y+2}, {x+1, y+1}, {x+1, y-1}, {x-1, y+1}, {x-1,y-1}}

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
    local next_to_start = getAdjSingleCrops(config.crop_start_pos) -- just two cause it's in the corner
    local key
    local val
    for i = 1,#next_to_start do
        key = next_to_start[i]
        val = getEntry(key)
        valid = valid or  (val ~= nil and (val >= 0 or val == WRONG_PLANT))
    end

    return valid
end

local function resetDB()
    farmdb = {}
    nx, ny = -1, -1
    target_crop = nil
    poslist = {}
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

    getWorstCrop=getWorstCrop, 
    validLayout=validLayout,
    getAdjSingleCrops=getAdjSingleCrops,
    getAdj=getAdj,
    resetDB=resetDB
}