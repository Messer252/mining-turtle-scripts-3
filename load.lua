-- Open wireless communication
rednet.open("right") -- Change to "left" or "back" if needed

print("Waiting for mining turtle...")

local function checkFuel()
    if turtle.getFuelLevel() < 50 then
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
        -- Check fuel before making a step
        if not checkFuel() then
            while turtle.getFuelLevel() < 50 do
                os.sleep(5)
                checkFuel()
            end
        end

        -- Clear any falling block obstacles
        while turtle.detect() do
            turtle.dig()
            os.sleep(0.4)
        end
        
        turtle.forward()
    end
end
