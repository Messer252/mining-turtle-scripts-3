rednet.open("right") -- Change to "left" or "back" to match your modem

term.clear()
term.setCursorPos(1,1)
print("--- Multi-Pair 2x3 Tunnel Program ---")

-- 1. Ask for the specific partner turtle ID
write("What is the ID of this turtle's Chunky Turtle? ")
local targetLoaderID = tonumber(read())

-- 2. Ask for the tunnel length
write("How many blocks long should the tunnel be? ")
local totalSlices = tonumber(read())

if not targetLoaderID or not totalSlices or totalSlices <= 0 then
    print("Invalid entries. Exiting.")
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

local function safeDig(dir)
    local success, data
    if dir == "forward" then success, data = turtle.inspect()
    elseif dir == "up" then success, data = turtle.inspectUp()
    elseif dir == "down" then success, data = turtle.inspectDown() end

    if success then
        if data.name == "computercraft:turtle" or data.name:find("turtle") then
            print("Turtle detected! Waiting...")
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

local function clearOneSlice()
    movement("up")
    movement("up")
    turtle.turnRight()
    movement("forward")
    turtle.turnLeft()
    movement("down")
    movement("down")
    turtle.turnLeft()
    movement("forward")
    turtle.turnRight()
end

-- Main Loop
print("Mining paired to Loader ID: " .. targetLoaderID)
for slice = 1, totalSlices do
    clearOneSlice()
    movement("forward")
    
    -- FIXED: Sends a private message ONLY to the designated Chunky Turtle ID
    rednet.send(targetLoaderID, "move_forward", "chunk_loader")

    if slice % 10 == 0 then
        print("Progress: " .. slice .. " / " .. totalSlices)
    end
end

print("Tunnel complete!")
