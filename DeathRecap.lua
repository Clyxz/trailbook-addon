-- DeathRecap: what killed the character, from the game's death recap a second after each death: the creature (NPC ID) or the
-- player (GUID), the spell, the environment, the damage and the boss fight in progress. Forever closes the combat log to addons,
-- so the recap is the only record of the killing blow. Its creature names carry a player's surname, so a creature is named by
-- its npc line (Creatures.lua) and a player by a player line (Players.lua)
local _, ns = ...

local RECAP_DELAY = 1
local MELEE_SPELL = 88163 -- Constants.DeathRecapConsts.SWING_DAMAGE_SPELL_ID, the recap window's stand-in for a melee swing

local lastTimestamp

-- The killing blow and its timestamp: the recap's entry with the highest timestamp, the first of them on a tie (the game's own
-- recap window calls entry 1 the killing blow); nil when the game has no recap
local function killingBlow()
    if not (C_DeathRecap and C_DeathRecap.HasRecapEvents and C_DeathRecap.GetRecapEvents) then
        return nil
    end
    if not ns.Read(C_DeathRecap.HasRecapEvents()) then
        return nil
    end
    local events = ns.Read(C_DeathRecap.GetRecapEvents())
    if type(events) ~= "table" then
        return nil
    end
    local best, bestTimestamp
    for _, value in ipairs(events) do
        local entry = ns.Read(value)
        local timestamp = type(entry) == "table" and ns.Read(entry.timestamp)
        if type(timestamp) == "number" and (not bestTimestamp or timestamp > bestTimestamp) then
            best, bestTimestamp = entry, timestamp
        end
    end
    return best, bestTimestamp
end

-- The NPC ID in a creature's GUID (Creatures.lua), nil for any other GUID and while that module is missing
local function creatureID(guid)
    if type(guid) == "string" and ns.Creatures and ns.Creatures.ID then
        return ns.Creatures.ID(guid)
    end
    return nil
end

-- The GUID of a player other than the character itself, nil for anything else
local function playerGUID(guid)
    if type(guid) == "string" and guid:find("^Player%-") and guid ~= ns.Read(UnitGUID("player")) then
        return guid
    end
    return nil
end

-- The spell ID of a recap entry, nil for a melee swing (also the recap's stand-in for one) and where there is none
local function spellOf(entry)
    local spellID = ns.Read(entry.spellId)
    if type(spellID) ~= "number" or spellID <= 0 or spellID == MELEE_SPELL or ns.Read(entry.event) == "SWING_DAMAGE" then
        return nil
    end
    return spellID
end

-- The environment that dealt the blow in lower case (falling, drowning, fatigue, fire, lava, slime), nil for none
local function environmentOf(entry)
    local environment = ns.Read(entry.environmentalType)
    if type(environment) == "string" and environment ~= "" then
        return environment:lower()
    end
    return nil
end

-- Writes the player line for a killer's GUID: name and class as the game knows them for the GUID, else the recap's name without a
-- class
local function describePlayer(guid, recapName)
    local name, class = ns.Players.FromGUID(guid)
    if not name then
        name = ns.Players.FromText(recapName)
    end
    ns.Players.Describe(guid, name, class)
end

local function write(encounterID)
    local entry, timestamp = killingBlow()
    if not entry or timestamp == lastTimestamp then
        return
    end
    lastTimestamp = timestamp
    local guid = ns.Read(entry.sourceGUID)
    local npcID, player = creatureID(guid), playerGUID(guid)
    ns.Store.Event("death-cause", npcID, player, spellOf(entry), environmentOf(entry), ns.Read(entry.amount), encounterID)
    if npcID and ns.Creatures.Describe then
        ns.Creatures.Describe(npcID)
    elseif player then
        describePlayer(player, ns.Read(entry.sourceName))
    end
end

-- The recap the game holds at a login or reload is an earlier death's, written before it or lost with it
ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if isLogin or isReload then
        local _, timestamp = killingBlow()
        lastTimestamp = timestamp
    end
end)

-- The boss fight is read at the death: a wipe may end it within the second before the recap is read
ns.On("PLAYER_DEAD", function()
    local encounterID = ns.Bosses and ns.Bosses.Current and ns.Bosses.Current()
    C_Timer.After(RECAP_DELAY, function()
        write(encounterID)
    end)
end)
