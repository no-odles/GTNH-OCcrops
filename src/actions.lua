local robot = require("robot")
local config = require("config")
local nav = require("navigation")
local utils = require("utils")
local geo = require("geolyze")
local db = require("database")
local component = require("component")
local inventory_controller = component.inventory_controller

local function weed()

end

local function recursiveWeed()

end

local function till()

end

local function placeCropstick(n)
    if n == nil then
        n = 1
    end


end

local function recoverMissing()

end

local function prospectGround()
    local block, score = geo.scanDown()
    if block == geo.DIRT then
        till()
        block, score = geo.scanDown()
    end

    if geo.isFarmTile(block) then
        return true, block, score
    else
        return false
    end
end

local function prospectNext()
    -- assume we start at z = 0
    local on_farm = true
    nav.moveForward()
    local block, score = geo.scanDown()

    if geo.isEmpty(block) then 
        nav.flyN(1, nav.DOWN)
        on_farm, block, score = prospectGround()
        nav.flyN(1, nav.UP)

        if on_farm then 
            till()
            placeCropstick()
        end
    elseif geo.isFarmable(block) then
        if block == geo.WEED then
            weed()
        end
    else -- something else
        on_farm = false
    end

    if on_farm then
        local x, y = nav.getPos()
        db.setEntry({x,y}, score)
        return true
    else
        return false
    end
end

local function prospectRegion()
    -- Find out the dimensions of the farm
    local isfarm, done_scan, valid_farm = true, false, true
    local xdim, ydim = 0, 0

    -- initial conditions (to be extra sure)
    robot.select(config.spade_slot)
    inventory_controller.equip()
    nav.moveTo(config.start_pos)
    nav.faceDir(nav.WEST)


    -- first row, determine width
    while isfarm do
        xdim = xdim + 1
        isfarm = prospectNext()
    end

    -- move to next row
    nav.moveRel({-1,0,0})
    nav.faceDir(nav.NORTH)


    while ~prospectNext() do
        ydim = ydim + 1 
        if ydim % 2 then
            nav.faceDir(nav.WEST)
        else
            nav.faceDir(nav.EAST)
        end

        for _ = 1, xdim do
            valid_farm = valid_farm and prospectNext()
        end
        if ~valid_farm then
            print("Farm isn't rectangular!")
            return valid_farm, -1, -1
        end

        nav.faceDir(nav.UP)
    end

    return valid_farm, xdim, ydim
end

local function init()
    --Determine grid size
    local valid_farm


    nav.moveTo(config.start_pos)
    local success, score = geo.setTarget()

    if ~success then
        print("Invalid target plant! Make sure the lower right corner has the target plant in it.")
        return
    end
    db.setEntry(config.start_pos, score)

    local nx, ny
    valid_farm, nx, ny = prospectRegion()
    db.setBounds(nx, ny)
    
    if ~db.validLayout() then
        valid_farm = false
        print("Invalid Layout! Make sure there is at least one crop next to the initial one so they can spread.")
    end

    return valid_farm

    
end

return {init=init, 
    recursiveWeed=recursiveWeed, 
    till=till, 
    placeCropstick=placeCropstick, 
    recoverMissing=recoverMissing
}