local component = require("component")
local inv_c = component.inventory_controller


local config = require("config")
local nav = require("navigation")
local utils = require("utils")
local geo = require("geolyse")
local db = require("database")
local inv = require("inventory")
local act = require('actions')

local worst = db.WATER
local worst_pos = {}
local harvesting = false



local function checkAndReplace(score)
    if score > worst then
        print("Searching for seed")
        local found, idx, num_seeds = inv.findSeed(score) 
        if not found then
            print("Lost a seed :(") -- :(
        else
            print(string.format("Planting %d seeds!", num_seeds))
            for _ = 1, num_seeds do
                print(string.format("Replacing Crop at {%d, %d} score (%d -> %d)", worst_pos[1], worst_pos[2], worst, score))

                nav.moveTo(worst_pos)
                local block2, score2, is_grown2, is_weed2 = geo.scanCrop()
                act.harvest(true, not is_grown2)

                act.plant(idx, score)

                worst_pos, worst = db.getWorstCrop()
                if worst >= score then
                    break
                end
            end
        end

    end
end

local function propagate(test_run)
    local looping = true

    local function inspectAt()
        local pos = nav.getPos()
        local block, score, is_grown, is_weed = geo.scanCrop()

        if is_weed then
            act.weed(true)
        elseif utils.dblCrop(pos) then
            if is_grown then -- non crop blocks will never be grown
                if inv.halfFull() then
                    looping = looping and inv.dumpInv()
                end
                worst_pos, worst = db.getWorstCrop()
                act.harvest(true, not is_grown)

                nav.pause()
                checkAndReplace(score)
                nav.resume()
            elseif geo.isPlant(block) and score <= db.WRONG_PLANT then
                act.harvest(true, not is_grown)
            end
        end
    end

    if test_run then
        return inspectAt()
    else
        act.doAtEach(inspectAt)
    end

    return looping

end

local function main()
    print("Initialising Farm")
    local valid = act.init()
    if not valid then
        return
    end

    worst_pos, worst = db.getWorstCrop()

    while propagate(false) do

        if not inv.restockSticks then
            print("Out of Cropsticks!")
            break
        end
        if not inv.dumpInv(true) then
            print("Full inventory!")
            break
        end

        
        if utils.needsCharge() then
            act.charge(true)
        end
        harvesting = worst >= config.score_goal
    end

    act.clean()

end

main()
