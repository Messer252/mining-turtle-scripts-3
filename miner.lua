-- ============================================================
-- MINING TURTLE SCRIPT  (miner.lua)
-- Run this on each of the 8 Mining Turtles.
-- Each turtle will be assigned column 1-8 by the controller.
-- Turtle placement: line them up side-by-side facing the same
-- direction at the tunnel entrance, 1 block apart horizontally.
--
-- Cross-section view (looking into tunnel):
--   [1][2][3][4][5][6][7][8]   <- turtles start here
--   All 8 blocks wide, 8 blocks tall per slice
-- ============================================================

local PROTOCOL = "tunnel_mine"

-- Open modem (tries all sides)
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

local myID     = os.getComputerID()
local myCol    = nil   -- assigned column 1-8
local totalSlices = nil

-- ── Utility: fuel check ─────────────────────────────────────
local function checkFuel(needed)
    needed = needed or 50
    if turtle.getFuelLevel() < needed then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled. Level: " .. turtle.getFuelLevel())
                return true
            end
        end
        print("[WARN] Low fuel (" .. turtle.getFuelLevel() .. "). Waiting for fuel...")
        return false
    end
    return true
end

-- ── Utility: safe dig in a direction ────────────────────────
local function safeDig(dir)
    local inspect, data
    if dir == "forward" then
        inspect = turtle.inspect
        -- avoid digging other turtles
        local ok, blk = turtle.inspect()
        if ok and blk and blk.name and blk.name:find("turtle") then
            os.sleep(0.5)
            return false
        end
        turtle.dig()
        turtle.attack()
    elseif dir == "up" then
        local ok, blk = turtle.inspectUp()
        if ok and blk and blk.name and blk.name:find("turtle") then
            os.sleep(0.5)
            return false
        end
        turtle.digUp()
        turtle.attackUp()
    elseif dir == "down" then
        local ok, blk = turtle.inspectDown()
        if ok and blk and blk.name and blk.name:find("turtle") then
            os.sleep(0.5)
            return false
        end
        turtle.digDown()
        turtle.attackDown()
    end
    return true
end

-- ── Utility: move with digging ──────────────────────────────
local function move(dir)
    while not checkFuel() do os.sleep(5) end
    local moveFn, digDir
    if dir == "forward" then
        moveFn = turtle.forward; digDir = "forward"
    elseif dir == "up"      then
        moveFn = turtle.up;      digDir = "up"
    elseif dir == "down"    then
        moveFn = turtle.down;    digDir = "down"
    elseif dir == "back"    then
        moveFn = turtle.back;    digDir = nil   -- can't dig backwards
    end

    local tries = 0
    while not moveFn() do
        if digDir then safeDig(digDir) end
        os.sleep(0.1)
        tries = tries + 1
        if tries > 200 then
            print("[ERROR] Stuck! Could not move " .. dir .. " after 200 tries.")
            break
        end
    end
end

-- ── Mine one 1×8 vertical column (one slice, turtle's lane) ──
-- Turtle starts at the BOTTOM of its column, facing forward.
-- Pattern: dig above 7 times (going up), dig the block in front
-- each time, then return to bottom.
--
-- Actually, each turtle only needs to mine its own 1-wide column.
-- It digs the block in front at each height, then moves up/down.
--
-- The 8-tall column is mined by:
--   - dig forward (ground level)
--   - move up, dig forward  (level 2)
--   - ... repeat up to level 8
--   - descend back to ground
local COLUMN_HEIGHT = 8

local function mineColumn()
    -- Mine at current height (ground level = height 1)
    safeDig("forward")

    -- Rise and mine each level above
    for h = 2, COLUMN_HEIGHT do
        move("up")
        safeDig("forward")
        -- Also clear the block above on the last level
        if h == COLUMN_HEIGHT then
            -- nothing extra needed; already at top
        end
    end

    -- Descend back to ground level
    for h = 2, COLUMN_HEIGHT do
        move("down")
    end
end

-- ── Wait for START signal from controller ───────────────────
print("Miner ID " .. myID .. " ready. Waiting for controller START...")

while true do
    local senderID, msg = rednet.receive(PROTOCOL, 60)
    if msg and msg.cmd == "START" then
        myCol      = msg.column
        totalSlices = msg.total
        print("Assigned column " .. myCol .. " | Length: " .. totalSlices)
        break
    end
end

-- ── Main mining loop ─────────────────────────────────────────
-- Each iteration: mine my column, report done, wait for ADVANCE.
for slice = 1, totalSlices do
    -- Mine the 8-tall column for this slice
    mineColumn()

    -- Report this slice is done to the controller
    rednet.send(senderID, {cmd = "SLICE_DONE", col = myCol, slice = slice}, PROTOCOL)

    if slice % 10 == 0 then
        print("Slice " .. slice .. " / " .. totalSlices .. " done.")
    end

    -- Wait for controller's ADVANCE signal (unless this is the last slice)
    if slice < totalSlices then
        local advID, advMsg
        repeat
            advID, advMsg = rednet.receive(PROTOCOL, 120)
            if advMsg == nil then
                print("[WARN] Timeout waiting for ADVANCE. Retrying...")
            end
        until advMsg and advMsg.cmd == "ADVANCE"

        -- Move forward one block into the next slice
        move("forward")
    end
end

print("Column " .. myCol .. " complete! All " .. totalSlices .. " slices mined.")
