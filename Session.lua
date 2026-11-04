-- Session: login, reload and logout, who the character is, and a warning when the saved data did not load (in the chat, and in
-- the status line through ns.dataMissing until the next reload). Forever names are
-- unique per region and have two parts, the first name and the surname (UnitName's two returns); there are no realms to name.
local _, ns = ...

local function character()
    local _, class = UnitClass("player")
    local _, _, race = UnitRace("player")
    local name, surname = UnitName("player")
    return {
        guid = ns.Read(UnitGUID("player")),
        name = ns.Read(name),
        surname = ns.Read(surname),
        class = ns.Read(class),
        race = ns.Read(race),
        sex = ns.Read(UnitSex("player")),
        faction = ns.Read(UnitFactionGroup("player")),
    }
end

local function warnIfDataMissing()
    local level = ns.Read(UnitLevel("player"))
    ns.dataMissing = ns.Store.fresh and level ~= nil and level > 1
    if ns.dataMissing then
        ns.Print(ns.Text("noData"))
    end
end

ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if not isLogin and not isReload then
        return
    end
    ns.Store.SetCharacter(character())
    ns.Store.Arrive(isLogin and "login" or "reload", UnitLevel("player"), (GetBuildInfo()), GetLocale())
    warnIfDataMissing()
end)

ns.On("PLAYER_LOGOUT", function()
    ns.Store.Event("logout")
end)
