-- Creatures: once per session an npc line with a creature's NPC ID and its name, when another line names it (a killer, a boss).
-- No game file names creatures (Creature.db2 holds only about 180 pets and critters), so the name comes from the game itself: the
-- tooltip of a unit link for that NPC ID, in the client's language, the same for every creature of that ID. The game may first
-- have to ask the server for an NPC it has not shown yet and hides creature tooltips inside instances: then it is asked again a
-- few seconds later and after the next loading screen. Without an answer no line is written; nothing is guessed from other names
local _, ns = ...

local RETRY_DELAYS = { 1, 3 }
local UNIT_LINK = "unit:Creature-0-0-0-0-%d-0000000000"

local Creatures = {}
ns.Creatures = Creatures

local described = {}
local waiting = {}

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

local function write(npcID, name)
    described[npcID] = true
    waiting[npcID] = nil
    ns.Store.Event("npc", npcID, name)
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
    else
        waiting[npcID] = true
    end
end

-- Writes the npc line once per session and NPC ID: with the name given when the game gave it exactly (a boss's name at the end
-- of its fight), else with the name the game shows for the ID, as soon as it shows one
function Creatures.Describe(npcID, name)
    npcID = tonumber(ns.Read(npcID))
    if not npcID or described[npcID] then
        return
    end
    name = ns.Name(name)
    if name then
        write(npcID, name)
    else
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
