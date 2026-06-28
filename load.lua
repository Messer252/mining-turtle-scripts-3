rednet.open("right") -- Change "right" to your modem side
print("Waiting for mining turtle...")

while true do
    local id, message = rednet.receive("chunk_loader")
    
    if message == "move_forward" then
        while turtle.detect() do
            turtle.dig()
            os.sleep(0.4)
        end
        turtle.forward()
    end
end
