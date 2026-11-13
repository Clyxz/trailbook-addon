-- Skills: the character's skill lines as the game's skills window lists them, by skill line ID (SkillLine.db2) with rank and
-- maximum, in two kinds of line. skills: the professions and secondary skills (Cooking, Fishing, First Aid, Riding and the like),
-- as a snapshot (Core.lua: after login, reload and changes of the skill list, only when it changed). weapons: the weapon skills
-- (Swords, Bows, Defense, Unarmed, Dual Wield …), which rise a point at a time in fights and all at once at a level-up, so written
-- like the bags (Bags.lua): a few seconds after login and reload all of them (scope all, through ns.Snapshot), then, shortly after
-- a change of the skill list, only those whose rank or maximum changed (scope changed; 0:0 for one the list no longer has).
-- Armor, class skills and languages stay out. Forever also lists each profession's child skill line (2937 under 171 Alchemy);
-- like the game's skills window, only the parent line is written. A collapsed header hides its skills from the list: while one
-- that may hold the skills of a kind is collapsed, nothing of that kind is written rather than a state that lacks them; the
-- whole weapon list follows once the list shows the weapons again
local _, ns = ...

if not (C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo) then
    return
end

local CHANGE_DELAY = 0.5 -- seconds after a change of the skill list, so that the changes of a level-up make one line
-- The kind of line each written skill line category goes into: secondary skills and professions, weapons. KNOWN also has the
-- categories that stay out (class skills, armor, languages). A header's skill ID is its category
local KINDS = { [9] = "skills", [11] = "skills", [6] = "weapons" }
local KNOWN = { [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true }

-- Per kind the skills the list shows as "rank:maximum" by skill line ID; a kind is missing while a collapsed header may hide
-- some of its skills (one of an unknown category may hide any); nil while the game lists no skills
local function listed()
    local count = ns.Read(C_SkillInfo.GetNumSkillLines())
    if not count or count == 0 then
        return nil
    end
    local found = { skills = {}, weapons = {} }
    for index = 1, count do
        local info = ns.Read(C_SkillInfo.GetSkillLineInfo(index))
        if type(info) == "table" then
            local id = ns.Read(info.skillID)
            if ns.Read(info.isHeader) then
                if ns.Read(info.isCollapsed) then
                    if not KNOWN[id] then
                        found.skills, found.weapons = nil, nil
                    elseif KINDS[id] then
                        found[KINDS[id]] = nil
                    end
                end
            else
                local kind = id and KINDS[ns.Read(info.skillLineCategoryID)]
                local skills = kind and found[kind]
                if skills and (ns.Read(info.parentSkillLineID) or 0) == 0 then
                    skills[id] = (ns.Read(info.rank) or "") .. ":" .. (ns.Read(info.maxRank) or "")
                end
            end
        end
    end
    return found
end

-- Skills by skill line ID as ID:rank:maximum, by ID, comma separated
local function joined(skills)
    local ids = {}
    for id in pairs(skills) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for i, id in ipairs(ids) do
        ids[i] = id .. ":" .. skills[id]
    end
    return table.concat(ids, ",")
end

ns.Snapshot("skills", function()
    local found = listed()
    if found and found.skills then
        return joined(found.skills)
    end
end, { "SKILL_LINES_CHANGED" })

local weapons -- the weapon skills as last written, nil until the whole list of this login or reload is written
local read -- the weapon skills the whole list was made of
local pending = false

local writeAll = ns.Snapshot("weapons", function()
    local found = listed()
    read = found and found.weapons
    if read then
        return "all", joined(read)
    end
end, {}, function()
    weapons = read
end)

-- Writes the weapon skills whose rank or maximum changed since the last line
local function compare()
    pending = false
    local found = listed()
    local now = found and found.weapons
    if not now then
        return
    end
    local changed = {}
    for id, value in pairs(now) do
        if weapons[id] ~= value then
            changed[id] = value
        end
    end
    for id in pairs(weapons) do
        if not now[id] then
            changed[id] = "0:0"
        end
    end
    if next(changed) then
        weapons = now
        ns.Store.Event("weapons", "changed", joined(changed))
    end
end

ns.On("SKILL_LINES_CHANGED", function()
    if not weapons then
        writeAll()
    elseif not pending then
        pending = true
        C_Timer.After(CHANGE_DELAY, compare)
    end
end)
