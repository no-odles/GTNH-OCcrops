
local sides = require("sides")
local component = require("component")
local geo = component.geolyzer

local db = require("database")
local config = require("config")
local actions = require("actions")
local nav = require("navigation")

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

local function isEmpty(block)
    return block == AIR
end

local function isFarmTile(block)
    return block == TDIRT or block == WATER
end

local function isFarmable(block)
    return block == PLANT or block == CSTICK or block == WEED
end

local function isWeed(crop_scan)
    return crop_scan["crop:growth"] > config.max_growth or 
    crop_scan["crop:name"] == "weed" or
    crop_scan["crop:name"] == 'Grass' or
    crop_scan["crop:growth"] > config.workingMaxGrowth or
    (crop_scan["crop:name"] == 'venomilia' and crop_scan["crop:growth"] > 7)
end

local function evalCrop(crop_scan)
    local growth = crop_scan["crop:growth"]
    local gain = crop_scan["crop:gain"]
    local res = crop_scan["crop:resistance"]
    local res_score

    if res <= config.resistance_target then
        res_score = res
    else
        res_score = -res
    end
    
    return math.min(0, growth + gain + res_score) -- -1 is empty, so literally any correct crop must be better than that
end

local function score(blockscan)
    local name = blockscan.name

    if name == "IC2:blockCrop" then
        local cname = blockscan["crop:name"]
        if cname == nil then
            -- empty / double cropstick
            return CSTICK, EMPTY
        elseif cname == db.getTargetCrop() then
            if isWeed(blockscan) then
                return WEED, WORST
            else
                return PLANT, evalCrop(blockscan)
            end
        else 
            return PLANT, WRONG_PLANT
        end
    elseif name == "minecraft:air" then
        return AIR, EMPTY
    elseif name == "minecraft:water" then
        return BWATER, WATER
    elseif name == "minecraft:dirt" then
        return DIRT, EMPTY
    elseif name == "minecraft:tilledDirt" then
        return TDIRT, EMPTY
    else 
        return UNKNOWN, WATER 
    end
end
local function scanForWeeds()
    local scan = geo.analyze(sides.down)
    return isWeed(scan)
end
local function scanForward()
    local scan = geo.analyze(sides.forward)
    return score(scan)
end

local function scanDown()
    local scan = geo.analyze(sides.down)
    return score(scan)
end


local function setTarget()
    local scan = geo.analyze(sides.down)
    local cname = scan["crop:name"]
    if cname == nil then
        return false, WORST
    else
        db.setTargetCrop(cname)
        local _, sc = score(scan)
        db.setEntry(config.crop_start_pos, sc)

        return true
    end
    
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

    -- functions
    scandown=scanDown, 
    scanForward=scanForward, 
    isEmpty=isEmpty, 
    isFarmTile=isFarmTile, 
    isFarmable=isFarmable, 
    isWeed=isWeed, 
    score=score,
    scanForWeeds=scanForWeeds
}