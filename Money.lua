-- Money: the character's money at login or reload and every change of it, in copper
local _, ns = ...

local money

ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    money = ns.Read(GetMoney())
    if isLogin or isReload then
        ns.Store.Event("money", nil, money)
    end
end)

ns.On("PLAYER_MONEY", function()
    local now = ns.Read(GetMoney())
    if now and money and now ~= money then
        ns.Store.Event("money", now - money, now)
    end
    money = now
end)
