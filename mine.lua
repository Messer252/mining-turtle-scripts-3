rednet.open("right") -- Change to "left" or "back" to match your modem

-- Ask the user for the tunnel length
term.clear()
term.setCursorPos(1,1)
print("--- 2x3 Tunnel Digging Program ---")
write("How many blocks long should the tunnel be? ")
local totalSlices = tonumber(read())

if not totalSlices or totalSlices <= 0 then
    print("Invalid number. Exiting.")
    return
end

local function checkFuel()
    if turtle.getFuelLevel() < 50 then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled! Level: " .. turtle.getFuelLevel())
                return true
            end
        end
        print("OUT OF FUEL! Place fuel in inventory.")
        return false
    end
    return true
end

-- Safety Dig Check to prevent hitting the Chunky Turtle
local function safeDig(dir)
    local success, data
    if dir == "forward" then success, data = turtle.inspect()
    elseif dir == "up" then success, data = turtle.inspectUp()
    elseif dir == "down" then success, data = turtle.inspectDown() end

    if success then
        if data.name == "computercraft:turtle" or data.name:find("turtle") then
            print("Chunky Turtle detected! Waiting...")
            os.sleep(1)
            return false 
        end
    end

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

-- Clears one 2x3 slice (Goes up 2 blocks, steps right, goes down 2 blocks)
local function clearOneSlice()
    -- Dig up to block 2 and block 3 (height) on the left side
    movement("up")
    movement("up")
    
    -- Move to the right side of the tunnel
    turtle.turnRight()
    movement("forward")
    turtle.turnLeft()
    
    -- Dig down to the floor on the right side
    movement("down")
    movement("down")
    
    -- Return to the left-side floor position
    turtle.turnLeft()
    movement("forward")
    turtle.turnRight()
end

-- Main Loop
print("Starting 2x3 tunnel for " .. totalSlices .. " blocks...")
for slice = 1, totalSlices do
    -- Clear out the 2x3 grid directly in front of us
    clearOneSlice()
    
    -- Step forward into the next layer
    movement("forward")
    
    -- Signal the Chunky Turtle to advance
    rednet.broadcast("move_forward", "chunk_loader")

    if slice % 10 == 0 then
        print("Progress: " .. slice .. " / " .. totalSlices)
    end
end

print("Tunnel complete!")
