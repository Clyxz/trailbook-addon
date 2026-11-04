-- Gear: the item ID in each equipped slot (INVSLOT_FIRST_EQUIPPED to INVSLOT_LAST_EQUIPPED, 1 to 19), 0 = empty, as a snapshot
-- (Core.lua: after login, reload and changes)
local _, ns = ...

ns.Snapshot("gear", function()
    local ids = {}
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        ids[slot] = ns.Read(GetInventoryItemID("player", slot)) or 0
    end
    return table.concat(ids, ",")
end, { "PLAYER_EQUIPMENT_CHANGED" })
