local robot = require("robot")
local sides = require("sides")
local component = require("component")
local inv_c = component.inventory_controller

local config = require("config")
local nav = require("navigation")


local function isDone()

end

local function sgn(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

local function dblCrop(pos)
    -- check whether there should be a double cropstick here
    local x, y = pos[1], pos[2]
    return (x % 2 + y % 2 ) == 1
end

local function isFull()
    robot.select(config.inv_size)
    if inv_c.getStackInInternalSlot() == nil then
        return false
    else
        return  true
    end
end

local function elEq(a,b)
    if type(a) == type({}) then
        if type(b) == type({}) then
            if #a == #b then
                for k,v in pairs(a) do
                    if not elEq(b[k], v)  then
                        return false
                    end
                end
                return true
            else
                return false
            end
        else
            return false
        end
    else
        return a == b
    end
end

local function setDiff(a,b)
    local out = {}
    for k,v in pairs(a) do
        local in_b = false
        for _, vb in pairs(b) do
            in_b = elEq(v, vb)
            if in_b then
                break
            end
        end
        if not in_b then
            out[k] = v
        end
    end
    return out
end


return {
    isDone=isDone, 
    sgn=sgn, 
    dblCrop=dblCrop,
    isFull=isFull,
    setDiff=setDiff,
    elEq=elEq
}