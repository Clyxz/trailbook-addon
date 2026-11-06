-- Skills: the character's professions and secondary skills (Cooking, Fishing, First Aid, Riding and the like) by skill line ID
-- with rank and maximum, as a snapshot (Core.lua: after login, reload and changes of the skill list, only when it changed);
-- weapons, armor, class skills and languages stay out. Forever also lists each profession's child skill line (2937 under 171
-- Alchemy); like the game's skills window, only the parent line is written. A collapsed header hides its skills from the list:
-- while one that may hold professions is collapsed, nothing is written rather than a state that lacks them
local _, ns = ...

if not (C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo) then
    return
end

local KEPT = { [9] = true, [11] = true } -- skill line categories: secondary skills, professions
local OTHER = { [6] = true, [7] = true, [8] = true, [10] = true } -- weapons, class, armor, languages

-- The kept skills the list shows as "ID:rank:maximum" by skill line ID, nil while a collapsed header may hide some of them
local function listed(count)
    local skills = {}
    for index = 1, count do
        local info = ns.Read(C_SkillInfo.GetSkillLineInfo(index))
        if type(info) == "table" then
            local id = ns.Read(info.skillID)
            if ns.Read(info.isHeader) then
                if ns.Read(info.isCollapsed) and not OTHER[id] then
                    return nil
                end
            elseif id and KEPT[ns.Read(info.skillLineCategoryID)] and (ns.Read(info.parentSkillLineID) or 0) == 0 then
                skills[id] = id .. ":" .. (ns.Read(info.rank) or "") .. ":" .. (ns.Read(info.maxRank) or "")
            end
        end
    end
    return skills
end

ns.Snapshot("skills", function()
    local count = ns.Read(C_SkillInfo.GetNumSkillLines())
    local skills = count and count > 0 and listed(count)
    if not skills then
        return
    end
    local ids = {}
    for id in pairs(skills) do
        table.insert(ids, id)
    end
    table.sort(ids)
    local entries = {}
    for _, id in ipairs(ids) do
        table.insert(entries, skills[id])
    end
    return table.concat(entries, ",")
end, { "SKILL_LINES_CHANGED" })
