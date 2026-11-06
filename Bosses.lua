-- Bosses: boss fights, at the pull (encounter, difficulty, group size) and at the end (defeated or not, each boss's NPC ID with
-- the health it had left); the time between the two lines is the fight, world bosses get the same lines with a position. A
-- loading screen during the fight (a teleport out, a release in a dungeon) ends it for the character: its end line then has no
-- outcome. The game files name encounters (DungeonEncounter.db2) but not bosses, so each boss also gets an npc line
-- (Creatures.lua); Forever may leave out the boss list or hide the health. ns.Bosses.Current() is the encounter in progress
local _, ns = ...

local Bosses = {}
ns.Bosses = Bosses

local current

-- The encounter ID of the boss fight in progress (from its ENCOUNTER_START to its ENCOUNTER_END or a loading screen), nil when
-- there is none and after a login or reload in the middle of one (the game does not name a running encounter)
function Bosses.Current()
    return current
end

-- 1 when the boss died (the game gives success as a number or a boolean), 0 for a wipe or reset, nil when the game hides it
local function outcome(success)
    success = ns.Read(success)
    if success == nil then
        return nil
    end
    return (success == 1 or success == true) and 1 or 0
end

-- The bosses ENCOUNTER_END lists with an NPC ID the game shows, sorted by it, each { npcID, name, health } with the health as the
-- game gives it to three significant digits (nil where the game hides it); empty when the game sends no list
local function engaged(encounterUnitStatus)
    local list = {}
    local status = ns.Read(encounterUnitStatus)
    if type(status) ~= "table" then
        return list
    end
    for _, entry in ipairs(status) do
        local unit = ns.Read(entry)
        local npcID = type(unit) == "table" and tonumber(ns.Read(unit.creatureID))
        if npcID and npcID > 0 then
            local health = tonumber(ns.Read(unit.remainingHealthPercent))
            table.insert(list, {
                npcID = npcID,
                name = ns.Read(unit.creatureName),
                health = health and string.format("%.3g", health),
            })
        end
    end
    table.sort(list, function(a, b)
        return a.npcID < b.npcID
    end)
    return list
end

ns.On("ENCOUNTER_START", function(encounterID, _, difficultyID, groupSize)
    current = ns.Read(encounterID)
    ns.Store.Event("boss-pull", current, ns.Read(difficultyID), ns.Read(groupSize))
end)

ns.On("ENCOUNTER_END", function(encounterID, _, _, _, success, encounterUnitStatus)
    current = nil
    local list = engaged(encounterUnitStatus)
    local entries = {}
    for i, boss in ipairs(list) do
        entries[i] = boss.health and boss.npcID .. ":" .. boss.health or boss.npcID
    end
    ns.Store.Event("boss", ns.Read(encounterID), outcome(success), table.concat(entries, ","))
    if ns.Creatures and ns.Creatures.Describe then
        for _, boss in ipairs(list) do
            ns.Creatures.Describe(boss.npcID, boss.name)
        end
    end
end)

ns.On("LOADING_SCREEN_ENABLED", function()
    if current then
        ns.Store.Event("boss", current)
        current = nil
    end
end)
