rednet.open("right") -- Change to "left" or "back" to match your modem
print("Chunk loader active. Safe-distance mode engaged...")

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

while true do
    local id, message = rednet.receive("chunk_loader")
    
    if message == "move_forward" then
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
