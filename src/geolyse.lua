
local sides = require("sides")
local component = require("component")
local geo = component.geolyzer

local db = require("database")
local config = require("config")


local function isEmpty(block)
    return block == db.AIR
end

local function isWater(block)
    return block == db.WATER
end

local function isFarmTile(block)
    return block == db.TDIRT or block == db.WATER
end

local function isEmptyCropstick(block)
    return block == db.CSTICK
end

local function isFarmable(block)
    return block == db.PLANT or block == db.CSTICK or block == db.WEED
end

local function isPlant(block)
    return block == db.PLANT or block == db.WEED
end

local function isWeed(block)
    return block == db.WEED
end

local function scanIsGrown(scan)
    return scan["crop:size"] == scan["crop:maxSize"]
end

local function scanIsWeed(scan)
    if scan.name == "IC2:blockCrop" and not(scan["crop:name"] == nil) then
        return scan["crop:growth"] > config.max_growth or 
        scan["crop:name"] == "weed" or
        scan["crop:name"] == 'Grass' or
        (scan["crop:name"] == 'venomilia' and scan["crop:growth"] > 7)
    elseif scan.name == "minecraft:tallgrass" then
        return true
    else 
        return false
    end
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
    
    return math.max(0, growth + gain + res_score) -- -1 is empty, so literally any correct crop must be better than that
end

local function score(blockscan)
    local name = blockscan.name

    if name == "IC2:blockCrop" then
        local cname = blockscan["crop:name"]
        if cname == nil then
            -- empty / double cropstick
            return db.CSTICK, db.EMPTY
        elseif cname == db.getTargetCrop() then
            return db.PLANT, evalCrop(blockscan)
        elseif scanIsWeed(blockscan) then
            return db.WEED, db.WORST
        else
            return db.PLANT, db.WRONG_PLANT
        end
    elseif name == "minecraft:air" then
        return db.AIR, db.EMPTY
    elseif name == "minecraft:tallgrass" then
        return db.WEED, db.WORST
    elseif name == "minecraft:water" then
        return db.BWATER, db.WATER
    elseif name == "minecraft:dirt" then
        return db.DIRT, db.EMPTY
    elseif name == "minecraft:tilledDirt" then
        return db.TDIRT, db.EMPTY
    else 
        return db.UNKNOWN, db.WATER 
    end
end
local function scanForWeeds()
    local scan = geo.analyze(sides.down)
    return scanIsWeed(scan)
end


local function scanForward()
    local scan = geo.analyze(sides.forward)
    return score(scan)
end

local function scanDown()
    local scan = geo.analyze(sides.down)
    return score(scan)
end

local function scanCrop()
    local scan = geo.analyze(sides.down)
    local block, bscore = score(scan)

    if isPlant(block) then
        return block, bscore, scanIsGrown(scan), scanIsWeed(scan)
    end

    return block, bscore, nil, nil

end


local function setTarget()
    local scan = geo.analyze(sides.down)
    local cname = scan["crop:name"]
    if cname == nil then
        return false, db.WORST
    else
        db.setTargetCrop(cname)
        local _, sc = score(scan)
        db.setEntry(config.crop_start_pos, sc)

        return true
    end
    
end



return {
    -- functions
    scanDown=scanDown, 
    scanForward=scanForward, 
    isEmpty=isEmpty, 
    isWater=isWater,
    isEmptyCropstick=isEmptyCropstick,
    isFarmTile=isFarmTile, 
    isFarmable=isFarmable, 
    isPlant=isPlant,
    isWeed=isWeed, 
    score=score,
    evalCrop=evalCrop,
    scanForWeeds=scanForWeeds,
    scanCrop=scanCrop,
    setTarget=setTarget
}