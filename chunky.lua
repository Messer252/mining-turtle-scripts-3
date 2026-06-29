-- ============================================================
-- CHUNKY TURTLE SCRIPT  (chunky.lua)
-- Run this on the single Chunk-Loading Turtle.
-- Place it a few blocks BEHIND the miner line at the start.
-- It follows at a safe distance, keeping chunks loaded.
-- ============================================================

local PROTOCOL = "tunnel_chunk"

-- Open modem
local modemOpened = false
for _, side in ipairs({"right","left","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        rednet.open(side)
        modemOpened = true
        break
    end
end
if not modemOpened then
    error("No wireless modem found! Attach one to this turtle.")
end

local myID = os.getComputerID()
print("Chunky Turtle ready. My ID: " .. myID)
print("Waiting for controller START...")

-- ── Fuel check ───────────────────────────────────────────────
local function checkFuel(needed)
    needed = needed or 100
    if turtle.getFuelLevel() < needed then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled. Level: " .. turtle.getFuelLevel())
                return true
            end
        end
        print("[WARN] Low fuel (" .. turtle.getFuelLevel() .. "). Waiting...")
        return false
    end
    return true
end

-- ── Safe forward movement (digs if blocked) ──────────────────
local function moveForward()
    while not checkFuel() do os.sleep(5) end
    local tries = 0
    while not turtle.forward() do
        -- Check if it's another turtle before digging
        local ok, blk = turtle.inspect()
        if ok and blk and blk.name and blk.name:find("turtle") then
            print("[HOLD] Turtle ahead. Waiting...")
            os.sleep(1)
        else
            turtle.dig()
            turtle.attack()
        end
        os.sleep(0.2)
        tries = tries + 1
        if tries > 100 then
            print("[ERROR] Can't advance after 100 tries. Stuck!")
            break
        end
    end
end

-- ── Wait for START ────────────────────────────────────────────
local controllerID = nil
local totalSlices  = nil

while true do
    local senderID, msg = rednet.receive(PROTOCOL, 120)
    if msg and msg.cmd == "START" then
        controllerID = senderID
        totalSlices  = msg.total
        print("Paired with controller ID: " .. controllerID)
        print("Total tunnel length: " .. totalSlices .. " slices")
        print("Chunk loading engaged. Safe-distance mode active.")
        break
    end
end

-- ── Main follow loop ──────────────────────────────────────────
local totalAdvanced = 0

while totalAdvanced < totalSlices do
    local senderID, msg = rednet.receive(PROTOCOL, 600)

    if msg == nil then
        print("[WARN] Timeout waiting for controller. Retrying...")
    elseif msg.cmd == "ADVANCE" and senderID == controllerID then
        local steps = msg.steps or 1
        print("Advancing " .. steps .. " block(s)...")
        for i = 1, steps do
            moveForward()
        end
        totalAdvanced = totalAdvanced + steps
        print("Position: " .. totalAdvanced .. " / " .. (totalSlices - 2) .. " (safe distance)")
    end
end

print()
print("Tunnel complete! Chunky turtle reached final position.")
