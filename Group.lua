-- Group: the GUIDs of the other members as a snapshot (Core.lua: after login, reload and changes; empty = no group), and once per
-- session a player line per member with name and class (Players.lua), as soon as the game knows them
local _, ns = ...

local function describe()
    for _, unit in ipairs(ns.GroupUnits()) do
        ns.Players.Describe(UnitGUID(unit), ns.FullName(unit), (select(2, UnitClass(unit))))
    end
end

ns.Snapshot("group", function()
    local guids = {}
    for _, unit in ipairs(ns.GroupUnits()) do
        table.insert(guids, ns.Read(UnitGUID(unit)))
    end
    table.sort(guids)
    return table.concat(guids, ",")
end, { "GROUP_ROSTER_UPDATE" }, describe)

ns.On("UNIT_NAME_UPDATE", describe)
