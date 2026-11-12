-- Creatures: once per session an npc line with a creature's NPC ID, its name and its classification, when another line names
-- it (a kill, a killer, a boss). No game file names creatures (Creature.db2 holds only about 180 pets and critters), so the
-- name comes from the game itself, in the client's language, the same for every creature of that ID: from the creature when
-- the addon saw it (Kills.lua tells what it sees in fights), else from the tooltip of a unit link for that NPC ID. The game may
-- first have to ask the server for an NPC it has not shown yet and hides creature tooltips inside instances: then it is asked
-- again a few seconds later and after the next loading screen, and the line comes at once should the addon see the creature
-- meanwhile. Without an answer no line is written; nothing is guessed from other names. The classification (normal, elite,
-- rare, rareelite, worldboss …) is known only for a creature the addon saw; if it sees one only after its line, the line is
-- written again, with it
local _, ns = ...

local RETRY_DELAYS = { 1, 3 }
local UNIT_LINK = "unit:Creature-0-0-0-0-%d-0000000000"

local Creatures = {}
ns.Creatures = Creatures

local described = {} -- [npcID] = the classification its npc line has, "" for none
local waiting = {} -- [npcID] = true while its npc line waits for the name
local seen = {} -- [npcID] = { name, classification } as the addon saw the creature this session

-- The NPC ID (a number) inside a creature or vehicle GUID ("Creature-0-<server>-<instance>-<zone>-<npcID>-<spawn>"), else nil
function Creatures.ID(guid)
    guid = ns.Read(guid)
    if type(guid) ~= "string" then
        return nil
    end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind == "Creature" or kind == "Vehicle" then
        return tonumber(id)
    end
    return nil
end

-- The name the game shows for an NPC ID in the first line of its unit link's tooltip, nil while it does not know it or hides it
local function gameName(npcID)
    if not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then
        return nil
    end
    local ok, data = pcall(C_TooltipInfo.GetHyperlink, UNIT_LINK:format(npcID))
    data = ok and ns.Read(data)
    local lines = type(data) == "table" and ns.Read(data.lines)
    local first = type(lines) == "table" and ns.Read(lines[1])
    return type(first) == "table" and ns.Name(first.leftText) or nil
end

local function write(npcID, name, classification)
    described[npcID] = classification or ""
    waiting[npcID] = nil
    if classification then
        ns.Store.Event("npc", npcID, name, classification)
    else
        ns.Store.Event("npc", npcID, name)
    end
end

-- Asks the game for the name, again after each of RETRY_DELAYS; still without one, the NPC waits for the next loading screen
local function ask(npcID, attempt)
    if described[npcID] then
        return
    end
    local name = gameName(npcID)
    if name then
        write(npcID, name)
    elseif RETRY_DELAYS[attempt] then
        C_Timer.After(RETRY_DELAYS[attempt], function()
            ask(npcID, attempt + 1)
        end)
    end
end

-- Remembers a creature the addon saw alive, its name and classification as the game shows them; writes its npc line now when
-- it waited for its name, and again when it was written without the classification
function Creatures.Seen(npcID, name, classification)
    local creature = seen[npcID] or {}
    seen[npcID] = creature
    creature.name = ns.Name(name) or creature.name
    creature.classification = ns.Read(classification) or creature.classification
    local due = waiting[npcID] or (described[npcID] == "" and creature.classification)
    if due and creature.name then
        write(npcID, creature.name, creature.classification)
    end
end

-- Writes the npc line once per session and NPC ID, or again when the classification has become known since: with the name
-- given when the game gave it exactly (a boss's name at the end of its fight), else with the name the addon saw, else with the
-- name the game shows for the ID, as soon as it shows one
function Creatures.Describe(npcID, name, classification)
    npcID = tonumber(ns.Read(npcID))
    if not npcID then
        return
    end
    local creature = seen[npcID] or {}
    classification = ns.Read(classification) or creature.classification
    if described[npcID] and (described[npcID] ~= "" or not classification) then
        return
    end
    name = ns.Name(name) or creature.name
    if name then
        write(npcID, name, classification)
    else
        waiting[npcID] = true
        ask(npcID, 1)
    end
end

-- A moment after the loading screen, so that the npc lines go into the chunk of the new place, after its arrival line
ns.On("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(1, function()
        for npcID in pairs(waiting) do
            ask(npcID, 1)
        end
    end)
end)
