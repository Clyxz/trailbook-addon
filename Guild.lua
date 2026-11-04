-- Guild: the character's guild, its rank there and the rank's number (0 = guild master) as a snapshot (Core.lua: after login,
-- reload and every guild update; empty = no guild); guilds are in no game file. Right after login the game may not know the
-- guild yet, then nothing is written until it does
local _, ns = ...

ns.Snapshot("guild", function()
    if not ns.Read(IsInGuild()) then
        return ""
    end
    local name, rank, rankIndex = GetGuildInfo("player")
    name = ns.Read(name)
    if name then
        return name, ns.Read(rank) or "", ns.Read(rankIndex) or ""
    end
end, { "PLAYER_GUILD_UPDATE", "GUILD_ROSTER_UPDATE" })
