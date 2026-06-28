rednet.open("right") -- Change "right" to your actual modem side

local width = 7
local height = 7

-- Forcefully dig and move in any direction to prevent gravel/sand blocks
local function movement(dir)
    if dir == "forward" then
        while not turtle.forward() do
            turtle.dig()
            turtle.attack() -- Clears entities/mobs blocking the path
        end
    elseif dir == "up" then
        while not turtle.up() do
            turtle.digUp()
            turtle.attackUp()
        end
    elseif dir == "down" then
        while not turtle.down() do
            turtle.digDown()
            turtle.attackDown()
        end
    end
end

-- Clear one vertical column
local function digColumn(goingUp)
    for h = 1, height - 1 do
        movement(goingUp and "up" or "down")
    end
end

-- Clear a single 7x7 vertical slice
local function clearOneSlice(startAtBottom)
    local goingUp = startAtBottom
    
    for w = 1, width do
        digColumn(goingUp)
        
        -- Alternate vertical direction for the next column
        goingUp = not goingUp 
        
        -- If there are columns left, turn and advance to the next column
        if w < width then
            if goingUp then -- Finished going down, turning right at bottom
                turtle.turnRight()
                movement("forward")
                turtle.turnLeft()
            else -- Finished going up, turning right at top
                turtle.turnLeft()
                movement("forward")
                turtle.turnRight()
            end
        end
    end
    
    -- Figure out where we ended up so the next slice knows where to start
    return goingUp
end

-- Main Loop: Dig 10 slices deep
local startAtBottom = true
for slice = 1, 10 do
    -- Clear the slice and get the ending position (top or bottom)
    startAtBottom = clearOneSlice(startAtBottom)
    
    -- Face the digging wall and advance into the next slice
    if not startAtBottom then
        turtle.turnLeft()
        turtle.turnLeft()
    end
    
    movement("forward")
    
    -- Instantly signal the Chunky Turtle to step into the newly cleared slice
    rednet.broadcast("move_forward", "chunk_loader")
    
    -- Turn back around to face the direction of the next column grid if needed
    if not startAtBottom then
        turtle.turnLeft()
        turtle.turnLeft()
    end
end

