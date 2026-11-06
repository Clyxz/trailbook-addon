-- Pet: the character's companion as a snapshot (Core.lua: after login, reload and when it comes, goes, levels, gets a name or
-- dies; empty = none): its name, level, family, and d while it is dead. The family goes in by its ID (CreatureFamily.db2) where
-- the game gives one, else by the name the game shows in the client's language (Wolf, Boar, Imp). A hunter's pet, a warlock's
-- demon, and also a creature the character controls for a while (Mind Control, Enslave Demon): the game makes each of them the
-- unit "pet". A player under Mind Control counts as none, known by UnitIsPlayer or by the GUID so that one hidden answer does
-- not let a player in, as players are named only in player lines (Players.lua). Nothing is written while the game does not
-- know the name yet. The game keeps a dead pet as the unit "pet" until it is revived or gone and only then sends UNIT_PET, so
-- while there is a pet it is asked every DEAD_CHECK seconds whether it is dead; where Forever hides that, the d is missing.
-- Tested on Forever with a hunter on 6 Nov 2026: UNIT_PET, name, level, family, and UnitIsDead in a fight in the open world.
-- The NPC ID in the pet's GUID is left out, as Forever gives every hunter's pet the same one (165189, "Generic Hunter Pet")
local _, ns = ...

local DEAD_CHECK = 2 -- seconds, as often as the trail checks the position

-- Whether the unit "pet" is a player: by the game's answer or, should that be hidden, by the GUID
local function isPlayer()
    if ns.Read(UnitIsPlayer("pet")) then
        return true
    end
    local guid = ns.Read(UnitGUID("pet"))
    return type(guid) == "string" and guid:find("^Player%-") ~= nil
end

-- The family's ID where the game gives it as UnitCreatureFamily's second value, else its name; the other one is nil
local function family()
    local name, id = UnitCreatureFamily("pet")
    id = ns.Read(id)
    if type(id) == "number" then
        return id, nil
    end
    return nil, ns.Name(name)
end

local changed = ns.Snapshot("pet", function()
    if not ns.Read(UnitExists("pet")) or isPlayer() then
        return ""
    end
    local name = ns.Name(UnitName("pet"))
    if name then
        local familyID, familyName = family()
        local dead = ns.Read(UnitIsDead("pet")) and "d" or ""
        return name, ns.Read(UnitLevel("pet")) or "", familyName or "", dead, familyID or ""
    end
end, {})

-- UNIT_PET names the owner of the pet that came or went, the other two the unit that changed
ns.On("UNIT_PET", function(unit)
    if ns.Read(unit) == "player" then
        changed()
    end
end)
for _, event in ipairs({ "UNIT_NAME_UPDATE", "UNIT_LEVEL" }) do
    ns.On(event, function(unit)
        if ns.Read(unit) == "pet" then
            changed()
        end
    end)
end

-- Whether the pet died (see above); the snapshot writes only when that or anything else changed
ns.Every(DEAD_CHECK, function()
    if ns.Read(UnitExists("pet")) then
        changed()
    end
end)
