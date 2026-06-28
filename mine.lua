-- Open wireless communication
rednet.open("left") -- Change to "left" or "back" if needed

local tunnelLength = 1000

local function checkFuel()
    -- If fuel is low, try to automatically refuel from inventory
    if turtle.getFuelLevel() < 50 then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled! Current level: " .. turtle.getFuelLevel())
                return true
            end
        end
        -- If no fuel found, pause and warn user
        print("OUT OF FUEL! Place coal in inventory.")
        return false
    end
    return true
end

local function digAndMove()
    -- Check fuel level before moving
    if not checkFuel() then
        while turtle.getFuelLevel() < 50 do
            os.sleep(5) -- Wait until user adds fuel
            checkFuel()
        end
    end

    -- Clear the path ahead
    while turtle.detect() do
        turtle.dig()
        os.sleep(0.4)
    end
    
    -- Move forward
    if turtle.forward() then
        -- Tell the Chunky Turtle behind it to move forward
        rednet.broadcast("move_forward", "chunk_loader")
        return true
    end
    return false
end

-- Start the 1000-block loop
print("Starting 1,000 block tunnel...")
for i = 1, tunnelLength do
    -- Clear upper block for 2-high tunnel
    while turtle.detectUp() do
        turtle.digUp()
        os.sleep(0.4)
    end
    
    digAndMove()
    
    -- Status update every 50 blocks
    if i % 50 == 0 then
        print("Progress: " .. i .. " / " .. tunnelLength .. " blocks.")
    end
end
print("Tunnel complete!")
