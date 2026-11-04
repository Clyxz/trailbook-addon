-- Kills: creatures that died and gave experience; Forever closes the combat log to addons, so kills without experience are missing
local _, ns = ...

ns.On("CHAT_MSG_COMBAT_XP_GAIN", function(text)
    text = ns.Read(text)
    if not text then
        return
    end
    local name, xp = ns.ParseMessage(text, COMBATLOG_XPGAIN_FIRSTPERSON)
    if name then
        ns.Store.Event("kill", name, xp)
    end
end)
