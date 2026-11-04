-- Group: the GUIDs of the other members as a snapshot (Core.lua: after login, reload and changes; empty = no group), and once per
-- session a player line per member with name and class, as soon as the game knows them; players are in no game file
local _, ns = ...

local described = {}

local function units()
    local list = {}
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = prefix .. i
        if ns.Read(UnitGUID(unit)) and not ns.Read(UnitIsUnit(unit, "player")) then
            table.insert(list, unit)
        end
    end
    return list
end

local function fullName(unit)
    local name, surname = UnitName(unit)
    name, surname = ns.Read(name), ns.Read(surname)
    if not name or name == UNKNOWNOBJECT then
        return nil
    end
    if surname and surname ~= "" then
        return name .. " " .. surname
    end
    return name
end

local function describe()
    for _, unit in ipairs(units()) do
        local guid = ns.Read(UnitGUID(unit))
        local name = fullName(unit)
        if name and not described[guid] then
            described[guid] = true
            ns.Store.Event("player", guid, name, ns.Read((select(2, UnitClass(unit)))))
        end
    end
end

ns.Snapshot("group", function()
    local guids = {}
    for _, unit in ipairs(units()) do
        table.insert(guids, ns.Read(UnitGUID(unit)))
    end
    table.sort(guids)
    return table.concat(guids, ",")
end, { "GROUP_ROSTER_UPDATE" }, describe)

ns.On("UNIT_NAME_UPDATE", describe)
