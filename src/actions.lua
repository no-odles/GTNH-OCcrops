local robot = require("robot")
local sides = require("sides")
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

local function doAtEach(action, reverse)
    local poslist = db.getPosList()
    local outlist = {}
    for i = 1, #poslist do
        local pos
        if reverse then
            pos = poslist[#poslist + 1 - i]
        else
            pos = poslist[i]
        end
        nav.moveTo(pos)
        outlist[#outlist + 1] = action()

    end
    return outlist

end


local function charge(dont_pause)
    if not dont_pause then
        nav.pause()
    end
    nav.moveTo(config.start_pos)
    while computer.energy() / computer.maxEnergy() < 0.99 do
        os.sleep(0.2)
    end
    if not dont_pause then
    nav.resume()
    end
end

-- Not possible
-- local function till()
--     robot.useDown()
-- end



local function placeCropstick(n)
    if n == nil then
        -- place cropsticks like there's an air block below
        if utils.dblCrop(nav.getPos()) then
            n = 2 
        else
            n = 1
        end
    end

    local success = true

    robot.select(config.cropstick_slot)
    if robot.count() < n+1 then
        local sticks = inv.restockSticks()
        if not sticks then
            print("Out of Cropsticks!")
        end
    end
    robot.select(config.cropstick_slot)

    inv_c.equip()

    for _=1,n do
        local succ, status = robot.useDown()
        success = succ and success
    end

    inv_c.equip() -- return spade to hand
    return success
end

local function weed(replace)
    robot.useDown()
    if geo.scanForWeeds() then
        -- must be grass
        robot.swingDown()

        -- always want to replace in this case
        placeCropstick(1)
        
    end

    if utils.dblCrop(nav.getPos()) and replace then
        placeCropstick(1)
    end
    db.setEmpty(nav.getPos())
    -- inv.pickUp()
end


local function iterativeWeed(replace) -- fun but ultimately silly
    nav.pause()
    local pos = nav.getPos()
    local done, todo = {}, {pos}
    while #todo > 0 do 
        pos = todo[#todo]
        todo[#todo] = nil
        done[#done + 1] = pos

        nav.moveTo(pos)
        if geo.scanForWeeds() then
            weed(replace)
            local adj = utils.setDiff(db.getAdj(pos), done)   
            for i = 1,#adj do
                todo[#todo + 1] = adj[i]
            end
        end

    end

    nav.resume()
end



local function harvest(replace, be_careful)
    local pos = nav.getPos()
    if be_careful then
        robot.useDown(sides.front)
        if replace and utils.dblCrop(pos) then
            placeCropstick(1)
        end
    else
        robot.swingDown(sides.front, true)
        if replace then
            placeCropstick()
        end
    end

    db.setEmpty(pos)
    
end

local function plant(idx, score)

    if score == nil then
        local item = inv_c.getStackInInternalSlot(idx)
        score = geo.evalCrop(item)
    end
    robot.select(idx)

    inv_c.equip()
    robot.useDown()
    inv_c.equip()

    db.setEntry(nav.getPos(), score)
end


-- local function recoverMissing()
--     --will always leave the robot at z = 0
--     local success
--     local pos = nav.getPos()
--     if pos[3] == 0 then
--         robot.swingDown()
--     else
--         nav.moveRel({0,0,1})
--     end

--     local success = placeCropstick()

--     if success then
--         local block, score = geo.scanDown()
--         db.setEntry(nav.getPos(), score)
--         return true
--     else
--         return false
--     end
-- end

local function prospectGround()
    local block, score = geo.scanDown()
    if geo.isWater(block) then
        return true, block, score
    else
        print("Found Non farmable block!")
        return false, block, score
    end
        
end

local function prospectNext()
    -- assume we start at z = 0
    nav.moveForward()
    local pos = nav.getPos()
    local on_farm = true
    local block, score = geo.scanDown()

    if geo.isEmpty(block) then 
        local success = placeCropstick()

        if success then
            block, score = geo.scanDown()
        else
            nav.flyN(1, nav.DOWN)
            on_farm, block, score = prospectGround()
            nav.flyN(1, nav.UP)
        end
    
    elseif geo.isFarmable(block) then
        if block == db.WEED then
            weed(true)
            block, score = geo.scanDown()
        elseif geo.isEmptyCropstick(block) then
            robot.swingDown() -- cstick may be wrong
            placeCropstick()
        end
    else -- something else
        on_farm = false
    end

    local x, y = table.unpack(pos)
    db.setEntry({x,y}, score) -- invalid blocks are always set to db.WATER (never replaced)

    if on_farm then
        return true
    else
        return false
    end
end

local function prospectRegion()
    -- Find out the dimensions of the farm
    local isfarm, done_scan = true, false
    local xdim, ydim = 1, 1

    -- initial conditions (to be extra sure)
    nav.moveTo(config.crop_start_pos)
    nav.faceDir(nav.WEST)


    -- first row, determine width
    while isfarm and xdim < config.max_farm_width do
        xdim = xdim + 1
        isfarm = prospectNext()
    end


    -- move to next row
    if not isfarm then
        nav.moveRel({1,0,0})
        xdim = xdim - 1
    end
    isfarm = true
    print(string.format("xdim is %d", xdim))


    while isfarm and ydim < config.max_farm_width do
        nav.faceDir(nav.NORTH)

        isfarm = prospectNext()
        if not isfarm then
            break
        end
        ydim = ydim + 1
        if ydim % 2 == 0 then
            nav.faceDir(nav.EAST)
        else
            nav.faceDir(nav.WEST)
        end

        if isfarm then
            for _ = 1, xdim-1 do
                isfarm = prospectNext() and isfarm
            end
            if not isfarm and config.strict_farm then
                print("Farm isn't rectangular!")
                return false, -1, -1
            else
                isfarm = true
            end
        end

    end
    print(string.format("ydim is %d", ydim))

    return true, xdim, ydim
end

local function init()
    -- charge
    charge()

    -- restock inventory
    inv.restockSticks(true)

    local spade_slot = inv_c.getStackInInternalSlot(config.spade_slot)
    if spade_slot == nil or spade_slot.name ~= "berriespp:itemSpade" then -- swap the spade back
        robot.select(config.spade_slot)
        inv_c.equip()
        spade_slot = inv_c.getStackInInternalSlot(config.spade_slot)
    end


    if not(spade_slot == nil) and spade_slot.name =="berriespp:itemSpade" then
        robot.select(config.spade_slot)
        inv_c.equip()
    else
        print("No spade found!")
        return false
    end


    -- determine target crop 
    nav.moveTo(config.crop_start_pos)
    local success = geo.setTarget()

    if success then
        print(string.format("Crop is %s", db.getTargetCrop()))
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

local function clean()
    nav.moveTo(config.crop_start_pos)

    local function clean_section()
        local pos = nav.getPos()
        if utils.dblCrop(pos) then
            local block, score, is_grown = geo.scanCrop()
            if is_grown then
                harvest(false)
            else
                robot.useDown() -- might as well try
                robot.swingDown() -- break the cropsticks
            end
            
        else
            local block, score = geo.scanDown()
            if geo.isEmptyCropstick(block)  or geo.isWeed(block) then
                robot.swingDown()
            end
        end
    end
    doAtEach(clean_section)

    inv.dumpInv(true)
    nav.home()
end


return {
    init=init, 
    iterativeWeed=iterativeWeed,
    weed=weed,
    charge=charge,
    -- till=till, 
    harvest=harvest,
    plant=plant,
    placeCropstick=placeCropstick, 
    -- recoverMissing=recoverMissing,
    clean=clean,
    doAtEach=doAtEach
}