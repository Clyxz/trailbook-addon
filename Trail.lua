-- Trail: the position every 2 s, kept after 3+ yards or when the movement flags change; a jump starts a new chunk
local _, ns = ...

local INTERVAL = 2
local MIN_STEP = 3
local JUMP_SPEED = 35

local last
local previous
local paused = true

local function currentFlags()
    local ghost = ns.Read(UnitIsGhost("player"))
    local dead = ns.Read(UnitIsDead("player"))
    local flags = (ns.Read(UnitOnTaxi("player")) and "t" or "")
        .. (ns.Read(IsMounted()) and "m" or "")
        .. (ghost and "g" or dead and "d" or "")
        .. (ns.Read(IsSwimming()) and "w" or "")
        .. (InCombatLockdown() and "c" or "")
    return flags ~= "" and flags or "-"
end

local function moved(x, y)
    return (x - last.x) ^ 2 + (y - last.y) ^ 2 >= MIN_STEP ^ 2
end

local function jumped(x, y, now)
    if not previous or ns.Read(UnitOnTaxi("player")) or ns.Read(IsFlying()) then
        return false
    end
    return math.sqrt((x - previous.x) ^ 2 + (y - previous.y) ^ 2) > JUMP_SPEED * (now - previous.time)
end

local function sample()
    local x, y = ns.Here()
    if paused or not x then
        return
    end
    local now = GetTime()
    if jumped(x, y, now) then
        ns.Store.Arrive("teleport", ns.RecentSpell())
        last = nil
    end
    previous = { x = x, y = y, time = now }
    local flags = currentFlags()
    if last and not moved(x, y) and flags == last.flags then
        return
    end
    ns.Store.Point(x, y, flags)
    last = { x = x, y = y, flags = flags }
end

local function restart()
    last = nil
end

ns.On("LOADING_SCREEN_ENABLED", function()
    paused = true
end)

ns.On("PLAYER_ENTERING_WORLD", function()
    paused = false
    previous = nil
    restart()
end)

ns.On("LOADING_SCREEN_DISABLED", function()
    paused = false
    if previous then
        previous.time = GetTime()
    end
end)

ns.On("ZONE_CHANGED_NEW_AREA", restart)

ns.Every(INTERVAL, sample)
