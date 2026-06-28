rednet.open("right") -- Change to your modem side
print("Chunk loader active. Waiting for signal...")

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

while true do
    local id, message = rednet.receive("chunk_loader")
    if message == "move_forward" then
        -- Wait half a second to let the mining turtle finish its turns
        os.sleep(0.5)

        while not checkFuel() do os.sleep(5) end
        
        while not turtle.forward() do
            turtle.dig() -- Clears gravel, but safeDig on the miner protects this guy
        end
    end
end
