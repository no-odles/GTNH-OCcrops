
local sides = require("sides")
local component = require("component")
local geo = component.geolyzer

local db = require("database")
local config = require("config")


local function isEmpty(block)
    return block == db.AIR
end

local function isWater(block)
    return block == db.BWATER
end

local function isFarmTile(block)
    return block == db.TDIRT or block == db.BWATER
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

local function parseScan(raw_scan)
    local scan = {}
    scan.name = raw_scan.name
    if not(raw_scan["crop:name"] == nil) then
        scan.crop = {}
        scan.crop.name = raw_scan["crop:name"]
        scan.crop.growth = raw_scan["crop:growth"]
        scan.crop.gain = raw_scan["crop:gain"]
        scan.crop.resistance = raw_scan["crop:resistance"]
        scan.crop.size = raw_scan["crop:size"]
        scan.crop.maxSize = raw_scan["crop:maxSize"]
    end

    return scan
end

local function scanIsGrown(scan)
    return scan["crop:size"] == scan["crop:maxSize"]--or not scan["crop:cangrow"] TODO: figure out the correct field for thiss
end

local function scanIsWeed(scan)
    if scan.name == "IC2:blockCrop" and not(scan["crop:name"] == nil) then
        return scan["crop:growth"] > config.max_growth or 
        scan["crop:name"] == "weed" or
        scan["crop:name"] == 'Grass' or
        (scan["crop:name"] == 'venomilia' and scan["crop:size"] > 7)
    elseif scan.name == "minecraft:tallgrass" then
        return true
    else 
        return false
    end
end



local function evalCrop(crop_scan)
    -- needs to handle both geolyzer output and itemStack objects
    local res_score, scan
    if crop_scan.crop == nil then
        scan = parseScan(crop_scan)
    else
        scan = crop_scan
    end

    res_score = -math.abs(scan.crop.resistance - config.resistance_target)

    if scan.crop.growth > config.max_growth then
        return db.WORST
    end
    
    local score =  math.max(0, scan.crop.growth + scan.crop.gain + res_score) -- -1 is empty, so literally any correct crop must be better than that
    if scan.crop.name == db.getTargetCrop() then
        return score
    else
        return score - config.wrong_plant_penalty
    end
end

local function score(blockscan)
    local name = blockscan.name

    if name == "IC2:blockCrop" then
        local cname = blockscan["crop:name"]
        if cname == nil then
            -- empty / double cropstick
            return db.CSTICK, db.EMPTY
        elseif scanIsWeed(blockscan) then
            return db.WEED, db.WORST
        else
            -- looks like a plant to me
            return db.PLANT, evalCrop(blockscan)
        end
    elseif name == "minecraft:air" then
        return db.AIR, db.WATER
    elseif name == "minecraft:tallgrass" then
        return db.WEED, db.WORST
    elseif name == "minecraft:water" then
        return db.BWATER, db.WATER
    elseif name == "minecraft:dirt" then
        return db.DIRT, db.WATER
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
        local is_wrong_plant = scan["crop:name"] ~= db.getTargetCrop()
        local is_weed = scanIsWeed(scan) or (config.non_targets_are_weeds and is_wrong_plant)
        return block, bscore, scanIsGrown(scan), is_weed, is_wrong_plant
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