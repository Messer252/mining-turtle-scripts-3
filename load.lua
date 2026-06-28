rednet.open("right") -- Change to "left" or "back" to match your modem
print("Chunk loader active. Waiting for signal...")

local function checkFuel()
    if turtle.getFuelLevel() < 100 then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                return true
            end
        end
        print("Loader out of fuel!")
        return false
    end
    return true
end

while true do
    local id, message = rednet.receive("chunk_loader")
    if message == "move_forward" then
        while not checkFuel() do
            os.sleep(5)
        end
        
        -- Plow through falling gravel/sand to stay right behind the miner
        while not turtle.forward() do
            turtle.dig()
        end
    end
end
