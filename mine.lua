rednet.open("right") -- Change to "left" or "back" to match your modem

local width = 7
local height = 7
local totalSlices = 1500

-- Automatic fuel management system
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

-- Aggressive movement that destroys gravel, sand, and mobs instantly
local function movement(dir)
    while not checkFuel() do
        os.sleep(5)
    end

    if dir == "forward" then
        while not turtle.forward() do
            turtle.dig()
            turtle.attack()
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

-- Digs one vertical column of the 7x7 grid
local function digColumn(goingUp)
    for h = 1, height - 1 do
        movement(goingUp and "up" or "down")
    end
end

-- Clears a single 7x7 vertical grid without backtracking
local function clearOneSlice(startAtBottom)
    local goingUp = startAtBottom
    
    for w = 1, width do
        digColumn(goingUp)
        goingUp = not goingUp 
        
        -- Move to the next vertical column row if we aren't done
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
print("Starting 7x7 tunnel: 1,500 blocks deep...")

for slice = 1, totalSlices do
    startAtBottom = clearOneSlice(startAtBottom)
    
    -- Orient the turtle straight into the tunnel wall to step forward
    if not startAtBottom then
        turtle.turnLeft()
        turtle.turnLeft()
    end
    
    movement("forward")
    
    -- Ping the Chunky Turtle to step into the newly loaded chunk zone
    rednet.broadcast("move_forward", "chunk_loader")
    
    -- Re-orient the turtle back to face the next zigzag grid pattern
    if not startAtBottom then
        turtle.turnLeft()
        turtle.turnLeft()
    end

    -- Status readout in terminal every 10 blocks
    if slice % 10 == 0 then
        print("Progress: " .. slice .. " / " .. totalSlices .. " slices.")
    end
end

print("Tunnel completely finished!")
