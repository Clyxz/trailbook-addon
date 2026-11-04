-- Daytime: whether it is day or night in the game, as the sun or moon at the minimap shows it, as a snapshot (Core.lua: after
-- login, reload and when it turns); 1 = day, 0 = night. The game decides it, no game file has the hours
local _, ns = ...

if not (C_DateAndTime and C_DateAndTime.IsDayTime) then
    return
end

ns.Snapshot("daytime", function()
    local isDay = ns.Read(C_DateAndTime.IsDayTime())
    if isDay ~= nil then
        return isDay and 1 or 0
    end
end, { "DIEL_CYCLE_CHANGED" })
