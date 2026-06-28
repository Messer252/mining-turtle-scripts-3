rednet.open("right") -- Change to "left" or "back" to match your modem

local width = 7
local height = 7
local totalSlices = 1500

local function checkFuel()
    if turtle.getFuelLevel() < 100 then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled! Level: " .. turtle.getFuelLevel())
                return true
            end
        end
        print("OUT OF FUEL! Place coal/charcoal in inventory.")
        return false
    end
    return true
end

-- SAFETY CHECK: Prevents mining our chunk loader turtle
local function safeDig(dir)
    local success, data
    if dir == "forward" then success, data = turtle.inspect()
    elseif dir == "up" then success, data = turtle.inspectUp()
    elseif dir == "down" then success, data = turtle.inspectDown() end

    if success then
        -- If the block in front is any type of turtle, DO NOT DIG IT
        if data.name == "computercraft:turtle" or data.name:find("turtle") then
            print("Warning: Chunky Turtle in the way! Waiting...")
            os.sleep(1)
            return false -- Did not dig
        end
    end

    -- If it's a regular block, dig it normally
    if dir == "forward" then turtle.dig() turtle.attack()
    elseif dir == "up" then turtle.digUp() turtle.attackUp()
    elseif dir == "down" then turtle.digDown() turtle.attackDown() end
    return true
end

local function movement(dir)
    while not checkFuel() do os.sleep(5) end

    if dir == "forward" then
        while not turtle.forward() do
            safeDig("forward")
            os.sleep(0.1)
        end
    elseif dir == "up" then
        while not turtle.up() do
            safeDig("up")
            os.sleep(0.1)
        end
    elseif dir == "down" then
        while not turtle.down() do
            safeDig("down")
            os.sleep(0.1)
        end
    end
end

-- Digs one vertical column of the 7x7 grid
local function digColumn(goingUp)
    for h = 1, height - 1 do
        movement(goingUp and "up" or "down")
    end
end

-- Clears a single 7x7 vertical grid
local function clearOneSlice(startAtBottom)
    local goingUp = startAtBottom
    for w = 1, width do
        digColumn(goingUp)
        goingUp = not goingUp 
        if w < width then
            if goingUp then
                turtle.turnRight()
                movement("forward")
                turtle.turnLeft()
            else
                turtle.turnLeft()
                movement("forward")
                turtle.turnRight()
            end
        end
    end
    return goingUp
end

-- Main Loop: Progress 1,500 slices deep
local startAtBottom = true
print("Starting safe 7x7 tunnel...")

for slice = 1, totalSlices do
    startAtBottom = clearOneSlice(startAtBottom)
    
    if not startAtBottom then
        turtle.turnLeft()
        turtle.turnLeft()
    end
    
    movement("forward")
    
    -- Ping the Chunky Turtle to step forward
    rednet.broadcast("move_forward", "chunk_loader")
    
    if not startAtBottom then
        turtle.turnLeft()
        turtle.turnLeft()
    end

    if slice % 10 == 0 then
        print("Progress: " .. slice .. " / " .. totalSlices)
    end
end
print("Tunnel complete!")
