local robot = require("robot")
local utils = require("utils")
local config = require("config")
local pos = config.start_pos -- standard cartesian coords, z coord is basically never used
local z = 0 -- secret third coordinate, mostly unused
local facing = 0 -- 0,1,2,3, clockwise
local temp_pos
local temp_face

--directions, NOT the same thing as the sides api
local DOWN = 7
local UP = 8
local NORTH = 9
local SOUTH = 10
local WEST = 11
local EAST = 12

local function getDir()
    return facing
end

local function getPos()
    return pos
end

local function carefulFly(dir)
    local success
    if dir == UP then
        repeat
            success = robot.up()
        until success
    elseif dir == DOWN then
        repeat
            success = robot.down()
        until success
    end
    
    return success
end

local function flyN(n, dir)
    for _=1,n do
        carefulFly(dir)
    end

    if dir == UP then 
        pos = {pos[1], pos[2], pos[3] + n}
    else
        pos = {pos[1], pos[2], pos[3] - n}
    end
end


local function carefulForward()
    local success
    repeat
        success = robot.forward()
    until success
    
    return success
end

local function moveN(n)
    for _=1,n do
        carefulForward()
    end
end

local function moveForward(n)
    if n == nil then
        n = 1
    end
    moveN(n)

    if facing == WEST then 
        pos = {pos[1] - n, pos[2]}
    elseif facing == EAST then
        pos = {pos[1] + n, pos[2]}
    elseif facing == NORTH then
        pos = {pos[1], pos[2] + n}
    else
        pos = {pos[1], pos[2] - n}
    end
    return
end

local function faceDir(dir)
    if dir == facing then
        return
    elseif dir == facing + 3 or dir == facing - 1 then
        robot.turnLeft() 
        facing = dir
    else
        repeat
            robot.turnRight()
            facing = (facing + 1) % 4
        until facing == dir
    end
end

local function dtheta(dir)
    --find the number of turns to rotate from `facing' to 'dir'
    local nturns = (dir - facing) % 4
    if nturns == 3 then
        nturns = 1
    end
    return nturns
end

local function moveTo(dest) 
    -- Move to dest in a straight line.
    local x1,y1,z1 = table.unpack(pos)
    local x2,y2,z2 = table.unpack(dest)

    -- handle z first, we assume that no one tries to fly too high. 
    if z2 == nil then
        z2 = z1
    elseif z2 > z1 then
        flyN(z2 - z1, UP)
    elseif z1 < z2 then 
        flyN(z1 - z2, DOWN)
    end

    if x1 == x2 and y1 == y2 then
        -- flyN handles the z-position for us, so exiting early is ok
        return 
    end

    local dx, dy = x1 - x2, y1 - y2
    local path = {}

    if dx > 0 then
        path[1] = {EAST, dx}
    elseif dx < 0 then
        path[1] = {WEST, -dx}
    end

    if dy > 0 then
        path[#path + 1] = {NORTH, dy}
    elseif dy < 0 then
        path[#path + 1] = {SOUTH, -dy}
    end

    if #path == 2 and dtheta(path[1][1]) > dtheta(path[2][1]) then
        -- If the y dirn is closer move that way first
        path[1], path[2] = path[2], path[1]
    end
    
    for i = 1,#path do
        local dir, n = table.unpack(path[i])
        faceDir(dir)
        moveForward(n)
    end

end

local function moveRel(dpos)
    local dx, dy, dz = table.unpack(dpos)
    if dz == nil then
        dz = 0
    end
    return moveTo({pos[1] + dx, pos[2] + dy, pos[3] + dz})
end

local function pause()
    temp_pos = getPos()
    temp_face = getDir()
end

local function resume()
    moveTo(temp_pos)
    faceDir(temp_face)
end


return {
    UP=UP, 
    DOWN=DOWN, 
    NORTH=NORTH, 
    SOUTH=SOUTH, 
    EAST=EAST, 
    WEST=WEST, 
    getPos=getPos, 
    getDir=getDir, 
    moveTo=moveTo, 
    moveRel=moveRel, 
    moveForward=moveForward, 
    flyN=flyN, 
    faceDir=faceDir,
    pause=pause,
    resume=resume
}