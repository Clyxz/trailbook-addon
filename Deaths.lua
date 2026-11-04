-- Deaths: dying, releasing the spirit and coming back to life. After a login or reload the state is taken from the game without
-- writing anything, so that a character that was dead or a ghost still gets its release and its alive event.
local _, ns = ...

local state

local function fromGame()
    if ns.Read(UnitIsGhost("player")) then
        return "ghost"
    end
    if ns.Read(UnitIsDeadOrGhost("player")) then
        return "dead"
    end
    return nil
end

ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if isLogin or isReload then
        state = fromGame()
    end
end)

ns.On("PLAYER_DEAD", function()
    state = "dead"
    ns.Store.Event("death")
end)

ns.On("PLAYER_ALIVE", function()
    if state == "dead" and ns.Read(UnitIsGhost("player")) then
        state = "ghost"
        ns.Store.Event("release")
    elseif state == "dead" and not ns.Read(UnitIsDeadOrGhost("player")) then
        state = nil
        ns.Store.Event("alive")
    end
end)

ns.On("PLAYER_UNGHOST", function()
    state = nil
    ns.Store.Event("alive")
end)
