-- ============================================================
-- GLOWSTONE PLACER TURTLE  (glowstone_placer.lua)
-- Places glowstone on the ceiling every 8 blocks along a tunnel.
-- Equipped with a Chunk Controller module (Chunky Turtle build),
-- so chunk loading is automatic and passive -- no script logic
-- needed for that part.
--
-- SAFETY CHECK: before advancing each 8-block segment, this
-- turtle scouts 10 blocks straight ahead. If it finds a solid
-- block anywhere in that range before completing the scout, it
-- backs up to its last safe position and waits, retrying the
-- check periodically, rather than digging through or advancing
-- blind. This is meant to detect "the miners haven't cleared
-- this far yet" and avoid getting ahead of them.
-- ============================================================

local PLACE_INTERVAL = 8    -- place glowstone every N blocks
local SCOUT_DISTANCE = 10   -- how far ahead to check for solid blocks
local RETRY_DELAY    = 5    -- seconds to wait before re-checking if blocked

-- ── Ask for total distance to run ────────────────────────────
term.clear()
term.setCursorPos(1,1)
print("--- Glowstone Placer Turtle ---")
print()
write("How many blocks long should this run? ")
local totalDistance = tonumber(read())
if not totalDistance or totalDistance <= 0 then
    print("Invalid entry. Exiting.")
    return
end

print()
print("Will place glowstone every " .. PLACE_INTERVAL .. " blocks,")
print("over a total run of " .. totalDistance .. " blocks.")
print("Checking " .. SCOUT_DISTANCE .. " blocks ahead before each advance.")
print()

-- ── Fuel check ────────────────────────────────────────────────
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

-- ── Select glowstone in inventory ────────────────────────────
-- Returns true and selects the slot if found, false if none left.
local function selectGlowstone()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:glowstone" then
            turtle.select(slot)
            return true
        end
    end
    return false
end

-- ── Scout ahead: check SCOUT_DISTANCE blocks in front for solid ──
-- This does NOT move the turtle permanently -- it steps forward
-- block by block, checking each one, then returns to the exact
-- starting position before reporting the result. This is the only
-- reliable way to "see" multiple blocks ahead without a scanner
-- peripheral, since turtle.inspect() only sees 1 block at a time.
--
-- Returns true if all SCOUT_DISTANCE blocks ahead are clear
-- (the turtle was able to move through all of them and back).
-- Returns false if it hit a solid block before reaching the end,
-- and will have already returned to the start position either way.
local function scoutAhead(distance)
    local stepsMoved = 0
    local blocked = false

    for i = 1, distance do
        -- Check what's directly in front before attempting to move
        local hasBlock, data = turtle.inspect()
        if hasBlock then
            -- Something solid is here. Don't dig, don't move through it.
            blocked = true
            break
        end

        -- Nothing in front -- safe to step into this space to continue scouting
        while not checkFuel() do os.sleep(5) end
        if turtle.forward() then
            stepsMoved = stepsMoved + 1
        else
            -- Couldn't move forward even though inspect() showed nothing.
            -- This can happen with non-solid-but-blocking entities (e.g.
            -- another turtle). Treat as blocked rather than guessing.
            blocked = true
            break
        end
    end

    -- Return to the exact starting position
    for i = 1, stepsMoved do
        while not checkFuel() do os.sleep(5) end
        turtle.back()
    end

    return not blocked
end

-- ── Move forward one block, waiting on fuel if needed ─────────
local function moveForwardOne()
    while not checkFuel() do os.sleep(5) end
    while not turtle.forward() do
        -- Don't dig here -- if something is blocking after a successful
        -- scout, conditions changed (e.g. a miner turtle is passing
        -- through). Wait briefly and retry rather than digging blind.
        os.sleep(0.5)
    end
end

-- ── Place glowstone on the ceiling ────────────────────────────
local function placeGlowstoneUp()
    if not selectGlowstone() then
        print("[WARN] Out of glowstone! Waiting for resupply...")
        while not selectGlowstone() do
            os.sleep(5)
        end
        print("Glowstone resupplied. Continuing.")
    end

    -- Only place if the space above is actually empty (avoid wasting
    -- glowstone or trying to place into existing ceiling blocks)
    local hasBlockUp = turtle.inspectUp()
    if not hasBlockUp then
        turtle.placeUp()
    end
end

-- ── Main loop ──────────────────────────────────────────────────
local distanceTraveled = 0

-- Place the first glowstone immediately at the starting position
placeGlowstoneUp()
print("Placed glowstone at position 0.")

while distanceTraveled < totalDistance do

    -- Before advancing the next 8-block segment, scout ahead to make
    -- sure the path is actually clear. This prevents the turtle from
    -- getting ahead of the mining turtles into unmined tunnel.
    local remaining = totalDistance - distanceTraveled
    local scoutLength = math.min(SCOUT_DISTANCE, remaining)

    local pathClear = scoutAhead(scoutLength)

    if not pathClear then
        print("[HOLD] Solid block detected within " .. SCOUT_DISTANCE ..
              " blocks ahead. Waiting " .. RETRY_DELAY .. "s before rechecking...")
        os.sleep(RETRY_DELAY)
    else
        -- Path is clear for at least PLACE_INTERVAL blocks (since
        -- PLACE_INTERVAL <= SCOUT_DISTANCE) -- safe to advance the
        -- full segment and place the next glowstone.
        local stepsThisSegment = math.min(PLACE_INTERVAL, remaining)

        for i = 1, stepsThisSegment do
            moveForwardOne()
            distanceTraveled = distanceTraveled + 1
        end

        placeGlowstoneUp()
        print("Placed glowstone at position " .. distanceTraveled ..
              " / " .. totalDistance)
    end
end

print()
print("Run complete! Placed glowstone every " .. PLACE_INTERVAL ..
      " blocks over " .. totalDistance .. " blocks.")
