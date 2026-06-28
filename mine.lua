-- Open wireless communication
rednet.open("right") -- Change "right" to your modem side

local width = 7
local height = 7

local function safeDig()
    while turtle.detect() do
        turtle.dig()
        os.sleep(0.4)
    end
end

local function safeDigUp()
    while turtle.detectUp() do
        turtle.digUp()
        os.sleep(0.4)
    end
end

-- Digs one vertical column of the 7x7 grid
local function digColumn(goingUp)
    for h = 1, height - 1 do
        if goingUp then
            safeDigUp()
            turtle.up()
        else
            while turtle.detectDown() do turtle.digDown() os.sleep(0.4) end
            turtle.down()
        end
    end
end

-- Main slice clearing logic
local function clearOneSlice()
    local goingUp = true
    
    for w = 1, width do
        digColumn(goingUp)
        goingUp = not goingUp -- Alternate going up and down
        
        -- If not on the last column, move right
        if w < width then
            turtle.turnRight()
            safeDig()
            turtle.forward()
            turtle.turnLeft()
        end
    end
    
    -- Return to the bottom-left corner of the slice
    turtle.turnLeft()
    for w = 1, width - 1 do
        turtle.forward()
    end
    turtle.turnRight()
    
    -- If we ended up at the top, drop back down to the bottom floor
    if not goingUp then
        for h = 1, height - 1 do
            turtle.down()
        end
    end
end

-- Loop to dig forward 10 slices deep
for slice = 1, 10 do
    clearOneSlice()
    
    -- Step forward into the new empty slice
    safeDig()
    if turtle.forward() then
        -- Signal the Chunky Turtle to move forward 1 space into the tunnel
        rednet.broadcast("move_forward", "chunk_loader")
    else
        print("Blocked! Check fuel or inventory.")
        break
    end
end
