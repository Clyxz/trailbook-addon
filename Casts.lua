-- Casts: every spell, ability and item spell the character casts, by spell ID, when it ends: how long it took in tenths of a
-- second (0 = instant) and i when it was interrupted or failed; a channel (fishing, bandages) never gets i, ending one early is
-- normal, and a spell with a cast time that then channels (Mind Control) gives two lines, the cast and the channel. The auto
-- attacks are left out, they fire at every swing, and so is the effect the game casts at every login. Only the character's own
-- casts: Forever closes the combat log to addons and keeps the casts of other units secret
local _, ns = ...

local AUTO_ATTACKS = { [6603] = true, [75] = true, [5019] = true }
local NO_ACTIONS = { [836] = true } -- LOGINEFFECT: the game casts it on the character at every login and reload
local AUTO_CHECKS = { "IsAutoAttackSpell", "IsRangedAutoAttackSpell", "IsAutoRepeatSpell" }
local STOP_WAIT = 0.5

local openCast
local openChannel
local lastChannel -- the newest channel, kept after it ends
local autoAttacks = {} -- [spellID] = whether it is an auto attack, asked once per spell and session

-- Whether a spell is an auto attack: Attack, Auto Shot, Shoot, or one the game calls an auto attack or auto repeat spell
local function isAutoAttack(spellID)
    if autoAttacks[spellID] == nil then
        local auto = AUTO_ATTACKS[spellID] or false
        for _, name in ipairs(AUTO_CHECKS) do
            local check = not auto and C_Spell and C_Spell[name]
            if check then
                local ok, result = pcall(check, spellID)
                auto = ok and ns.Read(result) == true
            end
        end
        autoAttacks[spellID] = auto
    end
    return autoAttacks[spellID]
end

-- The spell ID of a cast event of the character's own, nil for other units, auto attacks, the login effect and secret values
local function ownSpell(unit, spellID)
    spellID = ns.Read(spellID)
    if ns.Read(unit) == "player" and spellID and not NO_ACTIONS[spellID] and not isAutoAttack(spellID) then
        return spellID
    end
    return nil
end

-- Whether a cast event of the character's is about the open cast (the one with a cast time in progress)
local function isOpenCast(unit, castGUID)
    return openCast ~= nil and ns.Read(unit) == "player" and openCast.guid == ns.Read(castGUID)
end

local function isChanneling(spellID)
    return openChannel ~= nil and openChannel.spell == spellID
end

local function write(spellID, seconds, outcome)
    ns.Store.Event("cast", spellID, math.floor(seconds * 10 + 0.5), outcome)
end

local function closeCast(outcome)
    write(openCast.spell, (openCast.stop or GetTime()) - openCast.start, outcome)
    openCast = nil
end

local function closeChannel()
    write(openChannel.spell, GetTime() - openChannel.start)
    openChannel = nil
end

local function interrupted(unit, castGUID)
    if isOpenCast(unit, castGUID) then
        closeCast("i")
    end
end

ns.On("UNIT_SPELLCAST_START", function(unit, castGUID, spellID)
    local id, guid = ownSpell(unit, spellID), ns.Read(castGUID)
    if not id or not guid then
        return
    end
    if openCast then
        closeCast("i")
    end
    openCast = { guid = guid, spell = id, start = GetTime() }
end)

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, castGUID, spellID)
    if isOpenCast(unit, castGUID) then
        closeCast()
        return
    end
    local id = ownSpell(unit, spellID)
    if not id or isChanneling(id) then
        return
    end
    -- a channel's SUCCEEDED may come before its CHANNEL_START in the same frame (GetTime() is the same all frame), and a channel
    -- that fails at once also ends in it: one frame later, a channel of this spell begun this frame means no instant cast
    local at = GetTime()
    C_Timer.After(0, function()
        if not (lastChannel and lastChannel.spell == id and lastChannel.start >= at) then
            write(id, 0)
        end
    end)
end)

ns.On("UNIT_SPELLCAST_INTERRUPTED", interrupted)
ns.On("UNIT_SPELLCAST_FAILED", interrupted)

ns.On("UNIT_SPELLCAST_STOP", function(unit, castGUID)
    if not isOpenCast(unit, castGUID) then
        return
    end
    local stopped = openCast
    stopped.stop = stopped.stop or GetTime()
    C_Timer.After(STOP_WAIT, function()
        if openCast == stopped then
            closeCast("i")
        end
    end)
end)

ns.On("UNIT_SPELLCAST_CHANNEL_START", function(unit, _, spellID)
    local id = ownSpell(unit, spellID)
    if not id then
        return
    end
    if openChannel then
        closeChannel()
    end
    openChannel = { spell = id, start = GetTime() }
    lastChannel = openChannel
end)

ns.On("UNIT_SPELLCAST_CHANNEL_STOP", function(unit)
    if openChannel and ns.Read(unit) == "player" then
        closeChannel()
    end
end)

ns.On("LOADING_SCREEN_ENABLED", function()
    openCast, openChannel = nil, nil
end)
