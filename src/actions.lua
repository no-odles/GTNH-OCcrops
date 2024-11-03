local robot = require("robot")
local component = require("component")
local inv_c = component.inventory_controller
local computer = require("computer")
local os = require("os")

local config = require("config")
local nav = require("navigation")
local utils = require("utils")
local geo = require("geolyse")
local db = require("database")
local inv = require("inventory")

local function charge()
    geo.pause()
    while computer.energy() / computer.maxEnergy() < 0.99 do
        os.sleep(0.2)
    end
    geo.resume()
end

local function till()
    robot.useDown()
end



local function placeCropstick(n)
    if n == nil then
        -- place cropsticks like there's an air block below
        if utils.dblCrop(nav.getPos()) then
            n = 2 
        else
            n = 1
        end
    end

    robot.select(config.cropstick_slot)
    if robot.count() < n+1 then
        inv.restockSticks()
    end

    inv_c.equip()

    for _=1,n do
        robot.useDown()
    end

    inv_c.equip() -- return spade to hand

end

local function weed(replace)
    robot.useDown()
    if geo.scanForWeeds() then
        -- must be grass
        robot.swingDown()
        robot.moveRel({0,0,-1})
        till()
        robot.moveRel({0,0,1})

        if replace then
            placeCropstick(1)
        end
    end

    if replace and utils.dblCrop(nav.getPos()) then
        placeCropstick(1)
    end

    robot.pickUp()
end

local function recursiveWeedIterator(prev, done, replace)
    --not exactly optimal, but won't get stuck in loops
    if geo.scanForWeeds() then 
        weed(replace)
        local adj = db.getAdj()
        local pos = nav.getPos()
        done[#done + 1] = pos
        local todo = utils.setDiff(adj, done)

        for i = 1,#todo do
            recursiveWeedIterator(pos, done)
        end
    end
    nav.moveTo(prev)
end

local function recursiveWeed(replace)
    nav.pause()
    local adj = db.getAdj()
    local pos = nav.getPos()
    recursiveWeedIterator(pos, {}, replace)

    nav.resume()
end



local function harvest()
    robot.useDown()
    placeCropstick(1)
end


local function recoverMissing()
    --will always leave the robot at z = 0
    local success
    local pos = nav.getPos()
    if pos[2] == 0 then
        robot.swingDown()
        nav.moveRel({0,0,-1})
    end
    till()
    nav.moveRel({0,0,1})
    placeCropstick()

    local block, score = nav.scanDown()
    if block == geo.CSTICK then
        return true
    else
        return false
    end
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
        return false, block, score
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

        if block == geo.TDIRT then 
            placeCropstick() --will fail if theres water, but nbd
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
    nav.moveTo(config.crop_start_pos)
    nav.faceDir(nav.WEST)


    -- first row, determine width
    while isfarm do
        xdim = xdim + 1
        isfarm = prospectNext()
    end

    -- move to next row
    nav.moveRel({-1,0,0})
    nav.faceDir(nav.NORTH)


    while not prospectNext() do
        ydim = ydim + 1 
        if ydim % 2 == 0 then
            nav.faceDir(nav.WEST)
        else
            nav.faceDir(nav.EAST)
        end

        for _ = 1, xdim do
            valid_farm = valid_farm and prospectNext()
        end
        if not valid_farm then
            print("Farm isn't rectangular!")
            return valid_farm, -1, -1
        end

        nav.faceDir(nav.UP)
    end

    return valid_farm, xdim, ydim
end

local function init()
    -- charge
    charge()

    -- restock inventory
    inv.restockSticks()


    robot.select(config.spade_slot)
    inv_c.equip()

    -- determine target crop 
    nav.moveTo(config.crop_start_pos)
    local success = geo.setTarget()

    if success then
        print("Crop is %s", db.getTargetCrop)
    else
        print("Invalid target plant! Make sure the lower right corner has the target plant in it.")
        return
    end

    --Determine grid size
    local valid_farm
    local nx, ny
    valid_farm, nx, ny = prospectRegion()
    db.setBounds(nx, ny)
    
    if not db.validLayout() then
        valid_farm = false
        print("Invalid Layout! Make sure there is at least one crop next to the initial one so they can spread.")
    end

    return valid_farm
end

return {
    init=init, 
    recursiveWeed=recursiveWeed, 
    till=till, 
    placeCropstick=placeCropstick, 
    recoverMissing=recoverMissing
}