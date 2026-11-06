-- Experience: the experience in the current level, the experience the level needs and the rested pool (bonus experience left
-- from resting, empty = none) as a snapshot (Core.lua: after login, reload, every gain, level up and entering or leaving a
-- rested area), only while the game knows the first two. What the pool grows while resting shows with the next of these, not at
-- every step. Forever's kill messages do not show the rested bonus; it shows as the pool going down
local _, ns = ...

ns.Snapshot("xp", function()
    local xp, xpMax = ns.Read(UnitXP("player")), ns.Read(UnitXPMax("player"))
    if xp and xpMax and xpMax > 0 then
        return xp, xpMax, ns.Read(GetXPExhaustion()) or ""
    end
end, { "PLAYER_XP_UPDATE", "PLAYER_UPDATE_RESTING", "PLAYER_LEVEL_UP" })
