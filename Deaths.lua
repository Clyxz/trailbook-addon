-- Deaths: dying, releasing the spirit and coming back to life, and how, as the game's own buttons and dialogs show it: at the
-- corpse, at a spirit healer (also a battleground's), by another player's resurrection (the offerer's GUID when in the group,
-- which has player lines, else "First Surname") or by the character's own spell or item. Without such a sign it is a player's
-- resurrection only when one was offered and the spirit never released, else the way is left empty, never guessed. Forever
-- fires PLAYER_DEAD twice for one death, again at the release and right after a resurrection: only the first counts. After a
-- login or reload the state is taken from the game without writing anything, so that a character that was dead or a ghost
-- still gets its release and its alive event.
local _, ns = ...

local SIGN_WINDOW = 60
local RECHECK_DELAY = 1
local SELF_RESURRECT_KINDS = { [0] = "spell", [1] = "item" } -- by Enum.SelfResurrectOptionType: Spell, Item
local SPIRIT_HEALER = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.SpiritHealer

local state
local sign
local offer

local function fromGame()
    if ns.Read(UnitIsGhost("player")) then
        return "ghost"
    end
    if ns.Read(UnitIsDeadOrGhost("player")) then
        return "dead"
    end
    return nil
end

local function mark(kind, detail)
    sign = { kind = kind, detail = detail, time = GetTime() }
end

-- The player who offered a resurrection since the death: their GUID when they are in the character's group, else their name;
-- nil without an offer
local function offerer()
    if not offer then
        return nil
    end
    for _, unit in ipairs(ns.GroupUnits()) do
        if offer == ns.FullName(unit) or offer == ns.Read((UnitName(unit))) then
            return ns.Read(UnitGUID(unit)) or offer
        end
    end
    return offer
end

-- How the character came back and by whom or what (the alive line's two fields): the newest sign of the last minute, else res
-- when it was no ghost and a player had offered one; nothing when the game gave no sign
local function revival(wasGhost)
    if sign and GetTime() - sign.time <= SIGN_WINDOW then
        return sign.kind, sign.detail
    end
    if not wasGhost and offer then
        return "res", offerer()
    end
    return nil
end

local function die()
    state = "dead"
    sign, offer = nil, nil
    ns.Store.Event("death")
end

local function revive(wasGhost)
    state = nil
    local kind, detail = revival(wasGhost)
    ns.Store.Event("alive", kind, detail)
end

ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if isLogin or isReload then
        state = fromGame()
    end
end)

-- A PLAYER_DEAD while the game says the character is alive (the one right after a resurrection) is a death only if the
-- character reads dead a second later
ns.On("PLAYER_DEAD", function()
    if state then
        return
    end
    if ns.Read(UnitIsDeadOrGhost("player")) == false then
        C_Timer.After(RECHECK_DELAY, function()
            if not state and ns.Read(UnitIsDeadOrGhost("player")) then
                die()
            end
        end)
        return
    end
    die()
end)

ns.On("PLAYER_ALIVE", function()
    if state == "dead" and ns.Read(UnitIsGhost("player")) then
        state = "ghost"
        ns.Store.Event("release")
    elseif state == "dead" and not ns.Read(UnitIsDeadOrGhost("player")) then
        revive(false)
    end
end)

ns.On("PLAYER_UNGHOST", function()
    revive(true)
end)

ns.On("RESURRECT_REQUEST", function(inviter)
    offer = ns.Players.FromText(inviter) or offer
end)

if AcceptResurrect then
    hooksecurefunc("AcceptResurrect", function()
        mark("res", offerer())
    end)
end

if RetrieveCorpse then
    hooksecurefunc("RetrieveCorpse", function()
        mark("corpse")
    end)
end

if AcceptXPLoss then
    hooksecurefunc("AcceptXPLoss", function()
        mark("spirit")
    end)
end

if AcceptAreaSpiritHeal then
    hooksecurefunc("AcceptAreaSpiritHeal", function()
        mark("spirit")
    end)
end

if SPIRIT_HEALER and C_PlayerInteractionManager and C_PlayerInteractionManager.ConfirmationInteraction then
    hooksecurefunc(C_PlayerInteractionManager, "ConfirmationInteraction", function(interactionType)
        if ns.Read(interactionType) == SPIRIT_HEALER then
            mark("spirit")
        end
    end)
end

if C_DeathInfo and C_DeathInfo.UseSelfResurrectOption then
    hooksecurefunc(C_DeathInfo, "UseSelfResurrectOption", function(optionType, id)
        local kind = SELF_RESURRECT_KINDS[ns.Read(optionType)]
        if kind then
            mark(kind, ns.Read(id))
        end
    end)
end
