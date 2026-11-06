-- Discoveries: each area the character discovers and the experience it gave, from the game's two messages (with experience in
-- the chat, without on the screen), one line for both. The messages name the area only in the client's language: the ID
-- (AreaTable.db2) is that of the explored area of that name at the character's position, asked again just before writing as the
-- game may mark it explored only after its message; with no such area the name is written. In Forever's chat lockdown the chat
-- text is hidden, then the screen message alone makes the line, without experience
local _, ns = ...

local SAME_DISCOVERY = 5
local XP_WAIT = 1.5
local MAP_WAIT = 0.5

local discoveries = {}

-- The ID (AreaTable.db2) of the explored area at the character's position that has this name, nil when the game names none
local function exploredArea(name)
    local explored = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredAreaIDsAtPosition
    if not explored or not C_Map.GetPlayerMapPosition or not C_Map.GetAreaInfo then
        return nil
    end
    local mapID = ns.Read(C_Map.GetBestMapForUnit("player"))
    local position = mapID and ns.Read(C_Map.GetPlayerMapPosition(mapID, "player"))
    if not position or not ns.Read(position.x) or not ns.Read(position.y) then
        return nil
    end
    local ok, areaIDs = pcall(explored, mapID, position)
    if not ok or type(areaIDs) ~= "table" then
        return nil
    end
    for _, areaID in ipairs(areaIDs) do
        local id = ns.Read(areaID)
        if id and ns.Read(C_Map.GetAreaInfo(id)) == name then
            return id
        end
    end
    return nil
end

local function write(discovery)
    if discovery.written then
        return
    end
    discovery.written = true
    local areaID = discovery.areaID or exploredArea(discovery.name)
    ns.Store.Event("discovery", areaID, discovery.xp, not areaID and discovery.name or nil)
end

-- A message that the area of this name was discovered (xp nil in the one without): its line comes MAP_WAIT s after the one with
-- experience or XP_WAIT s after the first one without, whichever is earlier; within SAME_DISCOVERY s it is the same discovery
local function discovered(name, xp)
    local now = GetTime()
    local discovery = discoveries[name]
    if discovery and now - discovery.time <= SAME_DISCOVERY then
        if xp and not discovery.xp and not discovery.written then
            discovery.xp = xp
            C_Timer.After(MAP_WAIT, function()
                write(discovery)
            end)
        end
        return
    end
    discovery = { name = name, time = now, xp = xp, areaID = exploredArea(name) }
    discoveries[name] = discovery
    C_Timer.After(xp and MAP_WAIT or XP_WAIT, function()
        write(discovery)
    end)
end

ns.On("CHAT_MSG_SYSTEM", function(text)
    text = ns.Read(text)
    if not text or not ERR_ZONE_EXPLORED_XP then
        return
    end
    local name, xp = ns.ParseMessage(text, ERR_ZONE_EXPLORED_XP)
    if name then
        discovered(name, xp)
    end
end)

ns.On("UI_INFO_MESSAGE", function(_, message)
    message = ns.Read(message)
    if not message or not ERR_ZONE_EXPLORED then
        return
    end
    local name = ns.ParseMessage(message, ERR_ZONE_EXPLORED)
    if name then
        discovered(name)
    end
end)
