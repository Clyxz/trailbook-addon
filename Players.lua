-- Players: once per session a player line with a player's GUID, name ("First Surname") and class token for each player another
-- line names by GUID: the group's members (Group.lua) and a player who killed the character (DeathRecap.lua). Players are in no
-- game file, so the viewer names them from these lines
local _, ns = ...

local Players = {}
ns.Players = Players

local described = {}

-- Writes the player line for a GUID once per session; nothing while the name is unknown, so that a later call may write it
function Players.Describe(guid, name, class)
    guid, name = ns.Read(guid), ns.Name(name)
    if type(guid) ~= "string" or not name or described[guid] then
        return
    end
    described[guid] = true
    ns.Store.Event("player", guid, name, ns.Read(class))
end

-- A player's name as Forever writes it in events and the death recap, "First-Surname" with the surname where other clients
-- have the realm, written as the player lines have it, "First Surname"; nil for no name
function Players.FromText(text)
    text = ns.Name(text)
    return text and (text:gsub("%-", " ", 1))
end

-- The name and class token the game knows for a player's GUID, nil while it knows none; on Forever the name already is "First
-- Surname" and the realm is empty
function Players.FromGUID(guid)
    guid = ns.Read(guid)
    if type(guid) ~= "string" or not GetPlayerInfoByGUID then
        return nil
    end
    local _, class, _, _, _, name = GetPlayerInfoByGUID(guid)
    name = ns.Name(name)
    if not name then
        return nil
    end
    return name, ns.Read(class)
end
