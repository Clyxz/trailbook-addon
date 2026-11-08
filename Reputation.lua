-- Reputation: the character's standing with every faction it knows, as a snapshot (Core.lua: after login and reload and after each
-- reputation change, only when it changed): "factionID:standing" by faction ID (Faction.db2), standing as the game counts it, from 0
-- at the start of Neutral (negative below it), from which the viewer derives the level (Hated to Exalted) and the progress within
-- it. Headers that only group factions (Horde, Alliance, Other) stay out; one that holds reputation itself is written like a
-- faction. The game lists factions under headers the player may have collapsed: for the read they are expanded, and those that were
-- collapsed are collapsed again, so the reputation window looks as before. The change event is the game's reputation message, not
-- UPDATE_FACTION, which also fires when a header opens or closes and would answer every read with the next
local _, ns = ...

local R = C_Reputation
if not (R and R.GetNumFactions and R.GetFactionDataByIndex and R.ExpandAllFactionHeaders and R.CollapseFactionHeader) then
    return
end

-- The rows the reputation window lists now, by their index, and how many it lists
local function rows()
    local list = {}
    local count = ns.Read(R.GetNumFactions()) or 0
    for index = 1, count do
        local data = ns.Read(R.GetFactionDataByIndex(index))
        if type(data) == "table" then
            list[index] = data
        end
    end
    return list, count
end

-- A header's key for finding it again after the expansion: its faction ID, its name where it has none
local function headerKey(data)
    return ns.Read(data.factionID) or ns.Read(data.name)
end

ns.Snapshot("reputation", function()
    local collapsed = {}
    for _, data in pairs(rows()) do
        if ns.Read(data.isHeader) and ns.Read(data.isCollapsed) then
            local key = headerKey(data)
            if key then
                collapsed[key] = true
            end
        end
    end
    local expanded = next(collapsed) ~= nil
    if expanded then
        R.ExpandAllFactionHeaders()
    end
    local all, count = rows()
    local standing = {}
    for _, data in pairs(all) do
        local id, value = ns.Read(data.factionID), ns.Read(data.currentStanding)
        if id and id > 0 and type(value) == "number" and (not ns.Read(data.isHeader) or ns.Read(data.isHeaderWithRep)) then
            standing[id] = value
        end
    end
    if expanded then
        -- from the last row up, so that closing a header does not move the rows of the headers before it
        for index = count, 1, -1 do
            local data = all[index]
            if data and ns.Read(data.isHeader) and collapsed[headerKey(data)] then
                R.CollapseFactionHeader(index)
            end
        end
    end
    local ids = {}
    for id in pairs(standing) do
        table.insert(ids, id)
    end
    if #ids == 0 then
        return
    end
    table.sort(ids)
    local entries = {}
    for _, id in ipairs(ids) do
        table.insert(entries, id .. ":" .. standing[id])
    end
    return table.concat(entries, ",")
end, { "CHAT_MSG_COMBAT_FACTION_CHANGE" })
