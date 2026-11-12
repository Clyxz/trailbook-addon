-- Kills: creatures the character killed, by NPC ID where the addon saw them, with or without experience; their classification
-- (elite, rare …) goes into their npc line (Creatures.lua). Forever closes the combat log to addons, so a kill comes from two
-- sources, paired by name:
--   the game's experience line ("Mottled Boar dies, you gain 52 experience."): every kill that gives experience, anywhere,
--     also one of the group's. It names the creature only by name: the NPC ID is that of the creatures of this name the addon
--     saw alive in the last RECENT seconds, if they all have the same one
--   what the addon sees in the open world: during a fight and AFTER_FIGHT seconds after it, every CHECK seconds, the target
--     and the name plates; the target also when it changes and when the character attacks or casts. Killed is a creature that
--     had the character or its pet on its threat list when the addon last saw it alive, or the character's target that dies
--     in a fight after it was the target alive in the last RECENT seconds (so that one dying at the first blow counts too).
--     One that another player tapped never counts
-- A death the addon saw and an experience line of the same name within WINDOW seconds are one kill: the experience line writes
-- it at once. A death without one is a kill without experience (a grey creature, every kill at the highest level), written
-- GRACE seconds later, as long as the addon waits for its experience line, and before a loading screen at once. Inside dungeons
-- and raids Forever hides plates, targets and names, so kills there come only from experience lines, with their name. Muddy
-- Boots proved threat, tap, classification and name plates readable in the open world (probe runs 5 and 10)
local _, ns = ...

local CHECK = 0.5 -- seconds between looks at the target and the name plates during a fight
local AFTER_FIGHT = 5 -- seconds of looks after a fight, as the last creature can die as it ends
local RECENT = 5 -- seconds a creature counts as seen alive
local WINDOW = 2.5 -- seconds between a death and an experience line of the same name that are one kill
local GRACE = 1 -- seconds a death waits for its experience line
local PLATES = 40

local creatures = {} -- [GUID] = { npcID, name, classification, seen, targeted, fought, denied }, seen alive in the last RECENT s
local deaths = {} -- deaths waiting for their experience line, oldest first: { npcID, name, classification, at }
local gains = {} -- experience lines waiting for their death, oldest first: { name, at }
local fighting = false
local lookUntil = 0
local ticker

-- Whether the addon looks at name plates and counts the target's death: during a fight and a few seconds after it
local function looking()
    return fighting or GetTime() <= lookUntil
end

-- The first entry with this name in a list (oldest first) at most window seconds old, taken out of the list; nil if none
local function take(list, name, now, window)
    for i, entry in ipairs(list) do
        if entry.name == name and now - entry.at <= window then
            return table.remove(list, i)
        end
    end
    return nil
end

-- The NPC ID and classification of the creatures of this name seen alive in the last RECENT seconds, if they all have the same
-- NPC ID; nil when there is none or more than one
local function byName(name, now)
    local found
    for _, creature in pairs(creatures) do
        if creature.name == name and now - creature.seen <= RECENT then
            if found and found.npcID ~= creature.npcID then
                return nil
            end
            found = creature
        end
    end
    if found then
        return found.npcID, found.classification
    end
    return nil
end

-- A kill: by NPC ID with the creature's npc line in the same chunk where the addon knows the ID, else by the name of the
-- experience line
local function write(npcID, name, xp, classification)
    if npcID then
        ns.Store.Room(2)
        ns.Store.Event("kill", nil, xp, npcID)
        ns.Creatures.Killed(npcID, name, classification)
    else
        ns.Store.Event("kill", name, xp)
    end
end

-- Drops the experience lines whose death did not come within WINDOW seconds (the addon did not see it: a dungeon, no plate)
local function dropOldGains(now)
    while gains[1] and now - gains[1].at > WINDOW do
        table.remove(gains, 1)
    end
end

-- A creature the character killed died: its experience line came first and wrote the kill, or the death waits GRACE seconds
-- for one and is then a kill without experience
local function died(creature, now)
    dropOldGains(now)
    if take(gains, creature.name, now, WINDOW) then
        return
    end
    local death = { npcID = creature.npcID, name = creature.name, classification = creature.classification, at = now }
    table.insert(deaths, death)
    C_Timer.After(GRACE, function()
        for i, waiting in ipairs(deaths) do
            if waiting == death then
                table.remove(deaths, i)
                write(death.npcID, death.name, nil, death.classification)
                return
            end
        end
    end)
end

-- Whether the character or its pet is on the creature's threat list
local function threatened(unit)
    if ns.Read(UnitThreatSituation("player", unit)) ~= nil then
        return true
    end
    return ns.Read(UnitExists("pet")) and ns.Read(UnitThreatSituation("pet", unit)) ~= nil or false
end

-- Whether another player tapped the creature: as the game says now, else as it said when the addon last saw it alive
local function tapDenied(unit, creature)
    local denied = ns.Read(UnitIsTapDenied(unit))
    if denied == nil then
        denied = creature.denied
    end
    return denied == true
end

-- Looks at a unit: a creature the character can attack is remembered while alive (and told to Creatures.lua when first seen),
-- one the character killed is a death. Players, their pets and totems are left out, and so is every unit whose GUID the game
-- hides
local function look(unit)
    local guid = ns.Read(UnitGUID(unit))
    local creature = guid and creatures[guid]
    local npcID = creature and creature.npcID or ns.Creatures.ID(guid)
    if not npcID or ns.Read(UnitPlayerControlled(unit)) then
        return
    end
    local now = GetTime()
    if ns.Read(UnitIsDead(unit)) then
        local killed = creature and now - creature.seen <= RECENT
            and (creature.fought or looking() and creature.targeted and now - creature.targeted <= RECENT)
        if killed and not tapDenied(unit, creature) then
            creatures[guid] = nil
            died(creature, now)
        end
        return
    end
    if not creature then
        local name = ns.Name(UnitName(unit))
        if not name or not ns.Read(UnitCanAttack("player", unit)) then
            return
        end
        creature = { npcID = npcID, name = name, classification = ns.Read(UnitClassification(unit)) }
        creatures[guid] = creature
        ns.Creatures.Seen(npcID, name, creature.classification)
    end
    creature.seen = now
    creature.fought = threatened(unit)
    creature.denied = ns.Read(UnitIsTapDenied(unit))
    if ns.Read(UnitIsUnit(unit, "target")) then
        creature.targeted = now
    end
end

-- Forgets the creatures not seen alive in the last RECENT seconds
local function forget(now)
    for guid, creature in pairs(creatures) do
        if now - creature.seen > RECENT then
            creatures[guid] = nil
        end
    end
end

local function check()
    if not looking() then
        if ticker then
            ticker:Cancel()
            ticker = nil
        end
        return
    end
    forget(GetTime())
    for i = 1, PLATES do
        local unit = "nameplate" .. i
        if ns.Read(UnitExists(unit)) then
            look(unit)
        end
    end
    look("target")
end

local function lookAtTarget()
    forget(GetTime())
    look("target")
end

ns.On("PLAYER_REGEN_DISABLED", function()
    fighting = true
    if not ticker then
        ticker = C_Timer.NewTicker(CHECK, function()
            xpcall(check, geterrorhandler())
        end)
    end
    check()
end)

ns.On("PLAYER_REGEN_ENABLED", function()
    fighting = false
    lookUntil = GetTime() + AFTER_FIGHT
end)

-- A plate goes away when its creature dies: the last moment the addon can see that death
ns.On("NAME_PLATE_UNIT_REMOVED", function(unit)
    unit = ns.Read(unit)
    if unit and ns.Read(UnitIsDead(unit)) then
        look(unit)
    end
end)

-- The target alive just before the character's attack, for a creature that dies at the first blow
ns.On("PLAYER_TARGET_CHANGED", lookAtTarget)
ns.On("PLAYER_ENTER_COMBAT", lookAtTarget)
ns.On("START_AUTOREPEAT_SPELL", lookAtTarget)
for _, event in ipairs({ "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED" }) do
    ns.On(event, function(unit)
        if ns.Read(unit) == "player" then
            lookAtTarget()
        end
    end)
end

ns.On("CHAT_MSG_COMBAT_XP_GAIN", function(text)
    text = ns.Read(text)
    if not text then
        return
    end
    local name, xp = ns.ParseMessage(text, COMBATLOG_XPGAIN_FIRSTPERSON)
    if not name then
        return
    end
    local now = GetTime()
    local death = take(deaths, name, now, WINDOW)
    if death then
        write(death.npcID, name, xp, death.classification)
        return
    end
    dropOldGains(now)
    table.insert(gains, { name = name, at = now })
    local npcID, classification = byName(name, now)
    write(npcID, name, xp, classification)
end)

-- A loading screen ends the wait: the deaths still waiting are kills without experience, written in the chunk they belong to
ns.On("LOADING_SCREEN_ENABLED", function()
    while deaths[1] do
        local death = table.remove(deaths, 1)
        write(death.npcID, death.name, nil, death.classification)
    end
end)
