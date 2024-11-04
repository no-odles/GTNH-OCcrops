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



local function check_and_replace(score)
    if score > worst then
        local found, idx = inv.findSeed(score) 
        if not found then
            print("Lost a seed!") -- BAD
        else 
            nav.moveTo(worst_pos)
            local block2, score2, is_grown2 = geo.scanCrop()
            act.harvest(true)

            act.plant(idx, score)

            worst_pos, worst = db.getWorst()
            check_and_replace(score2)
        end

    end
end

local function propagate()
    local looping = true

    local function inspect_at()
        local pos = nav.getPos()
        local block, score, is_grown, is_weed = geo.scanCrop()

        if is_weed then
            act.recursiveWeed(true)
        elseif utils.dblCrop(pos) then
            if is_grown then -- non crop blocks will never be grown
                if inv.isFull() then
                    looping = looping and inv.dumpInv()
                end
                if harvesting then
                    act.harvest(true)
                else
                    nav.pause()
                    check_and_replace(score)
                    nav.resume()
                end
            end
        end
    end

    act.doAtEach(inspect_at)

    return looping

end

local function main()
    print("Initialising Farm")
    local valid = act.init()
    if not valid then
        return
    end
    worst_pos, worst = db.getWorst()
    while propagate() do
        if not inv.dumpInv() then
            print("Full inventory!")
            break
        end
        harvesting = worst >= config.score_goal
    end

    act.clean()

end

main()