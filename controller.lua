-- ============================================================
-- CONTROLLER COMPUTER SCRIPT
-- Place this on a CC:Tweaked Computer with a Wireless Modem.
-- Coordinates 8 Mining Turtles and 1 Chunky Turtle.
-- ============================================================

local PROTOCOL_MINE  = "tunnel_mine"
local PROTOCOL_CHUNK = "tunnel_chunk"
local SAFE_DISTANCE  = 2   -- Chunky turtle trails this many slices behind

-- Open the wireless modem (tries common sides)
local modemOpened = false
for _, side in ipairs({"right","left","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        rednet.open(side)
        modemOpened = true
        print("Modem opened on: " .. side)
        break
    end
end
if not modemOpened then
    error("No wireless modem found! Attach one to the computer.")
end

term.clear()
term.setCursorPos(1,1)
print("=========================================")
print("   8x8 TUNNEL CONTROLLER - CC:Tweaked   ")
print("=========================================")
print()

-- ── Collect miner IDs ──────────────────────────────────────
local minerIDs = {}
print("Enter the Computer IDs of the 8 Mining Turtles.")
print("(They must be online and running miner.lua first.)")
print()
for i = 1, 8 do
    while true do
        io.write("  Miner #" .. i .. " ID: ")
        local id = tonumber(read())
        if id and id > 0 then
            minerIDs[i] = id
            break
        end
        print("  Invalid. Please enter a positive integer.")
    end
end

-- ── Collect chunky turtle ID ────────────────────────────────
local chunkyID
while true do
    io.write("\nChunky Turtle ID: ")
    chunkyID = tonumber(read())
    if chunkyID and chunkyID > 0 then break end
    print("  Invalid. Please enter a positive integer.")
end

-- ── Tunnel length ───────────────────────────────────────────
local totalSlices
while true do
    io.write("\nTunnel length (blocks): ")
    totalSlices = tonumber(read())
    if totalSlices and totalSlices > 0 then break end
    print("  Invalid. Must be a positive integer.")
end

print()
print("-----------------------------------------")
print("  Miners : " .. table.concat(minerIDs, ", "))
print("  Chunky : " .. chunkyID)
print("  Length : " .. totalSlices .. " slices")
print("-----------------------------------------")
print()
io.write("Press ENTER to begin...")
read()
print()

-- ── Send START to all miners ────────────────────────────────
-- Each miner is told: its column index (1-8) and total slices.
for col, id in ipairs(minerIDs) do
    rednet.send(id, {
        cmd    = "START",
        column = col,
        total  = totalSlices
    }, PROTOCOL_MINE)
end

-- Tell the chunky turtle to start listening
rednet.send(chunkyID, {
    cmd   = "START",
    total = totalSlices
}, PROTOCOL_CHUNK)

print("All turtles signalled. Mining started!")
print()

-- ── Main coordination loop ──────────────────────────────────
local slicesDone   = 0   -- slices fully cleared by all 8 miners
local chunkySlice  = 0   -- how far the chunky turtle has moved

-- Track which miners have reported done for the current slice
local pendingMiners = {}
local function resetPending()
    for _, id in ipairs(minerIDs) do
        pendingMiners[id] = true
    end
end
resetPending()

while slicesDone < totalSlices do

    local currentSlice = slicesDone + 1  -- the slice we're waiting on right now

    -- Wait for all 8 miners to report slice completion FOR THIS SLICE SPECIFICALLY
    local allDone = false
    while not allDone do
        local senderID, msg = rednet.receive(PROTOCOL_MINE, 300)
        if senderID == nil then
            print("[WARN] Timeout waiting for miner reports. Retrying...")
        elseif msg and msg.cmd == "SLICE_DONE"
               and msg.slice == currentSlice
               and pendingMiners[senderID] then
            pendingMiners[senderID] = nil
            -- Check if all miners are done
            allDone = true
            for _, id in ipairs(minerIDs) do
                if pendingMiners[id] then allDone = false; break end
            end
        end
        -- Any SLICE_DONE for a slice that isn't currentSlice is silently
        -- discarded here -- it's either a stale duplicate or arrived
        -- out of order, and re-counting it would desync the tracker.
    end

    slicesDone = slicesDone + 1
    resetPending()

    -- Advance miners to next slice (if there is one)
    if slicesDone < totalSlices then
        for _, id in ipairs(minerIDs) do
            rednet.send(id, {cmd = "ADVANCE", forSlice = slicesDone}, PROTOCOL_MINE)
        end
    end

    -- Advance chunky turtle once miners are SAFE_DISTANCE ahead
    if slicesDone > SAFE_DISTANCE and chunkySlice < (slicesDone - SAFE_DISTANCE) then
        local steps = (slicesDone - SAFE_DISTANCE) - chunkySlice
        rednet.send(chunkyID, {cmd = "ADVANCE", steps = steps}, PROTOCOL_CHUNK)
        chunkySlice = chunkySlice + steps
    end

    -- Progress report every 5 slices
    if slicesDone % 5 == 0 or slicesDone == totalSlices then
        print(string.format("Progress: %d / %d slices complete (%.0f%%)",
            slicesDone, totalSlices, (slicesDone / totalSlices) * 100))
    end
end

-- Tell chunky to advance to the end
if chunkySlice < totalSlices then
    rednet.send(chunkyID, {
        cmd   = "ADVANCE",
        steps = totalSlices - chunkySlice
    }, PROTOCOL_CHUNK)
end

print()
print("=========================================")
print("   TUNNEL COMPLETE! All slices mined.   ")
print("=========================================")
