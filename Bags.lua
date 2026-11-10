-- Bags: what the bags hold (the backpack and the bags in the four bag slots, not the bank), as each item ID with its count, but
-- no ammunition: every shot uses one up, which would make a line per shot. A few seconds after login and reload all of it (scope
-- all, through ns.Snapshot), then after each change only the items whose count changed, 0 for one that left the bags (scope
-- changed, once the game has updated the bags: BAG_UPDATE_DELAYED). Muddy Boots proved BAG_UPDATE_DELAYED and C_Container readable
-- on Forever (probe run 5) and reads the item class through GetItemInfoInstant as here
local _, ns = ...

local PROJECTILE = Enum and Enum.ItemClass and Enum.ItemClass.Projectile or 6
local itemInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local counts -- the count per item ID as last written, nil until the full list of this login or reload is written
local read -- the counts the full list was made of
local ammunition = {} -- per item ID whether it is ammunition (its item class), asked once

local function isAmmunition(id)
    if ammunition[id] == nil then
        local class = itemInfo and select(6, itemInfo(id))
        ammunition[id] = ns.Read(class) == PROJECTILE
    end
    return ammunition[id]
end

-- The count per item ID in the bags now; nil without the container API
local function contents()
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then
        return nil
    end
    local now = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, ns.Read(C_Container.GetContainerNumSlots(bag)) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            local id = type(info) == "table" and ns.Read(info.itemID)
            if id and not isAmmunition(id) then
                now[id] = (now[id] or 0) + (ns.Read(info.stackCount) or 1)
            end
        end
    end
    return now
end

-- Item IDs with their counts as ID:count, by ID, comma separated
local function listed(items)
    local ids = {}
    for id in pairs(items) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for i, id in ipairs(ids) do
        ids[i] = id .. ":" .. items[id]
    end
    return table.concat(ids, ",")
end

ns.Snapshot("bags", function()
    read = contents()
    if read then
        return "all", listed(read)
    end
end, {}, function()
    counts = read
end)

ns.On("BAG_UPDATE_DELAYED", function()
    local now = counts and contents()
    if not now then
        return
    end
    local changed = {}
    for id, count in pairs(now) do
        if counts[id] ~= count then
            changed[id] = count
        end
    end
    for id in pairs(counts) do
        if not now[id] then
            changed[id] = 0
        end
    end
    if next(changed) then
        counts = now
        ns.Store.Event("bags", "changed", listed(changed))
    end
end)
