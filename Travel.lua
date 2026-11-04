-- Travel: a new chunk for each zone and loading screen, plus subzones, dungeons, flights and the spell before a loading screen
local _, ns = ...

local subzone
local instance
local flightStart
local taxiNodes = {}
local spellBeforeLoading

local function checkSubzone()
    local name = ns.Read(GetSubZoneText())
    if name ~= subzone then
        subzone = name
        ns.Store.Event("subzone", name)
    end
end

local function checkInstance()
    local _, _, difficulty, _, _, _, _, instanceID = GetInstanceInfo()
    local now = ns.Read(IsInInstance()) and ns.Read(instanceID) or nil
    if now == instance then
        return
    end
    if instance then
        ns.Store.Event("dungeon-out", instance)
    end
    if now then
        ns.Store.Event("dungeon-in", now, ns.Read(difficulty))
    end
    instance = now
end

ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if not isLogin and not isReload then
        ns.Store.Arrive("teleport", spellBeforeLoading)
        spellBeforeLoading = nil
    end
    checkInstance()
    checkSubzone()
end)

ns.On("ZONE_CHANGED_NEW_AREA", function()
    ns.Store.ZoneChanged()
    checkSubzone()
end)

ns.On("ZONE_CHANGED", checkSubzone)
ns.On("ZONE_CHANGED_INDOORS", checkSubzone)

ns.On("LOADING_SCREEN_ENABLED", function()
    spellBeforeLoading = ns.RecentSpell()
end)

ns.On("TAXIMAP_OPENED", function()
    taxiNodes, flightStart = {}, nil
    for _, node in ipairs(C_TaxiMap.GetAllTaxiNodes(GetTaxiMapID())) do
        taxiNodes[node.slotIndex] = node.nodeID
        if node.state == Enum.FlightPathState.Current then
            flightStart = node.nodeID
        end
    end
end)

hooksecurefunc("TakeTaxiNode", function(slot)
    ns.Store.Event("flight", flightStart, taxiNodes[slot])
end)
