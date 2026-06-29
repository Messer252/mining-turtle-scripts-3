-- ============================================================
-- STATIONARY CHUNK LOADER  (stationary_chunkloader.lua)
-- Run this on a Chunky Turtle placed in the SAME chunk as the
-- controller computer. It does not move, dig, or do anything
-- except stay running, since the Chunky Turtle's chunk-loading
-- is automatic and passive the moment it's crafted that way.
--
-- This keeps the controller's chunk active permanently, so the
-- controller never freezes mid-rednet.receive while you're away.
-- ============================================================

print("Stationary chunk loader active.")
print("This turtle does nothing on purpose -- its job is just")
print("to keep this chunk loaded for the controller computer.")

while true do
    os.sleep(60)
end
