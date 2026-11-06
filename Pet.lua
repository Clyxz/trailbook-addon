-- Pet: the character's companion as a snapshot (Core.lua: after login, reload and when it comes, goes, levels, gets a name or
-- dies; empty = none): its name, level and family as the game names it in the client's language (Wolf, Boar, Imp), and d while
-- it is dead. A hunter's pet, a warlock's demon, and also a creature the character controls for a while (Mind Control, Enslave
-- Demon): the game makes each of them the unit "pet". A player under Mind Control counts as none, as players are named only in
-- player lines (Players.lua). Nothing is written while the game does not know the name yet.
-- The game keeps a dead pet as the unit "pet" until it is revived or gone and only then sends UNIT_PET (seen in the test), so
-- while there is a pet it is asked every DEAD_CHECK seconds whether it is dead. UnitIsDead stays readable in fights in the open
-- world (Muddy Boots, run 10 Q75); where Forever hides it, the d is missing.
-- On Forever UNIT_PET, name, level and family work (tested with a hunter on 6 Nov 2026). The NPC ID in the pet's GUID is left
-- out: Forever gives every hunter's pet the same one (165189, "Generic Hunter Pet"); a newly tamed pet carries the name of its
-- beast instead (Muddy Boots saw "Gray Forest Wolf")
local _, ns = ...

local DEAD_CHECK = 2 -- seconds, as often as the trail checks the position

local changed = ns.Snapshot("pet", function()
    if not ns.Read(UnitExists("pet")) or ns.Read(UnitIsPlayer("pet")) then
        return ""
    end
    local name = ns.Name(UnitName("pet"))
    if name then
        local dead = ns.Read(UnitIsDead("pet")) and "d" or ""
        return name, ns.Read(UnitLevel("pet")) or "", ns.Name(UnitCreatureFamily("pet")) or "", dead
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
