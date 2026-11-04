-- Progress: level ups, quests accepted and turned in, and the quest log as a snapshot of its quest IDs, each with the difficulty
-- the game gives it for the character (Core.lua: after login, reload, changes and level ups); once per session a quest line per
-- quest with its title and level, which no game file has
local _, ns = ...

local described = {}

local function lastArgument(...)
    return (select(select("#", ...), ...))
end

local function describe(questID)
    local title = ns.Read(C_QuestLog.GetTitleForQuestID(questID))
    if title and not described[questID] then
        described[questID] = true
        local index = C_QuestLog.GetLogIndexForQuestID(questID)
        local info = index and C_QuestLog.GetInfo(index)
        ns.Store.Event("quest", questID, title, info and info.difficultyLevel)
    end
end

local function questLog()
    local ids = {}
    for index = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(index)
        if info and not info.isHeader and info.questID > 0 then
            table.insert(ids, info.questID)
        end
    end
    table.sort(ids)
    return ids
end

-- A quest ID with ":" and its Enum.RelativeContentDifficulty (0 trivial to 4 impossible, as the quest log colours it), the bare
-- ID where the game gives none
local function withDifficulty(questID)
    local difficulty = ns.Read(C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID))
    return difficulty and questID .. ":" .. difficulty or questID
end

ns.Snapshot("quests", function()
    local entries = {}
    for _, questID in ipairs(questLog()) do
        table.insert(entries, withDifficulty(questID))
    end
    return table.concat(entries, ",")
end, { "QUEST_LOG_UPDATE", "PLAYER_LEVEL_UP" }, function()
    for _, questID in ipairs(questLog()) do
        describe(questID)
    end
end)

ns.On("PLAYER_LEVEL_UP", function(level)
    ns.Store.Event("level", level)
end)

ns.On("QUEST_ACCEPTED", function(...)
    local questID = lastArgument(...)
    describe(questID)
    ns.Store.Event("quest-accepted", questID)
end)

ns.On("QUEST_TURNED_IN", function(questID, xp, money)
    describe(questID)
    ns.Store.Event("quest-done", questID, xp, money)
end)
