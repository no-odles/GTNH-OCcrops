
sides = require("sides")
component = require("component")
geo = component.geolyzer

db = require("database")
config = require("config")
actions = require("actions")
nav = require("navigation")

-- Block Enums
local AIR = 0
local DIRT = 1
local TDIRT = 2
local WATER = 3
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
    return block == PLANT or block == CSTICK or block == DCSTICK or block == WEED
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
    local is_weed = false
    local name = blockscan.name

    if name == "IC2:blockCrop" then
        local cname = blockscan["crop:name"]
        if cname == nil then
            -- empty / double cropstick
            return EMPTY
        elseif cname == db.getTargetCrop() then
            if isWeed(blockscan) then
                actions.recursiveWeed()
                return EMPTY
            else
                return evalCrop(blockscan)
            end
        else 
            return WRONG_PLANT
        end
    else 
        local pos = nav.get_pos()[1,2]
        local known_score = db.getEntry(pos)
        if known_score == nil then 
            -- In the init stage

        elseif known_score ~= WATER then
            --someone has been up to something nefarious
            print(string.format("Missing crop at position {%d,%d}, attempting to recover", pos[1], pos[2]))
            local success = actions.recoverMissing()
            if success then
                return EMPTY
            end
        end
        return WATER
    end
end

local function scanForward()
    --TODO: Fix scan = geo.scan(geo.getDir())
    return score(scan)
end

local function scanDown()
    scan = geo.scan(sides.down)
    return score(scan)
end



return {
    -- BLOCK NAMES
    AIR=AIR,
    DIRT=DIRT,
    TDIRT=TDIRT,
    WATER=WATER,
    CSTICK=CSTICK,
    WEED=WEED,
    PLANT=PLANT,
    UNKNOWN=UNKOWN,

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
    score=score
}