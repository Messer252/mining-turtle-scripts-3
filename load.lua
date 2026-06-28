rednet.open("right") -- Change to "left" or "back" to match your modem
print("Chunk loader active. Safe-distance mode engaged...")

-- Find out our own ID to print it out for the user
print("My Computer ID is: " .. os.getComputerID())

local function checkFuel()
    if turtle.getFuelLevel() < 100 then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then return true end
        end
        return false
    end
    return true
end

local signalsReceived = 0
local assignedMinerID = nil

while true do
    -- Listen for messages
    local senderID, message = rednet.receive("chunk_loader")
    
    if message == "move_forward" then
        -- Lock onto the very first miner that messages it
        if assignedMinerID == nil then
            assignedMinerID = senderID
            print("Successfully paired with Mining Turtle ID: " .. assignedMinerID)
        end
        
        -- ONLY move if the message came from our specific locked miner
        if senderID == assignedMinerID then
            signalsReceived = signalsReceived + 1
            
            if signalsReceived > 1 then
                while not checkFuel() do os.sleep(5) end
                while not turtle.forward() do
                    turtle.dig() 
                end
                print("Advanced 1 block. Keeping safe distance.")
            else
                print("Mining turtle started first layer. Holding position...")
            end
        end
    end
end
