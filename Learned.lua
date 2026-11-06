-- Learned: each spell, ability, passive effect and recipe the character learns, by spell ID, once per spell and session. Forever
-- may or may not send each of the game's signals for it (the learned-spell event, the new-recipe event, the chat line with its
-- link), so all of them are heard and the first one writes. Like the game's own spellbook, the two events count only while the
-- character is in the world: while it loads, the game announces spells it already knows
local _, ns = ...

local MESSAGES = { "ERR_LEARN_SPELL_S", "ERR_LEARN_ABILITY_S", "ERR_LEARN_PASSIVE_S", "ERR_LEARN_RECIPE_S" }

local written = {}
local inWorld = false

local function learned(spellID)
    spellID = ns.Read(spellID)
    if spellID and not written[spellID] then
        written[spellID] = true
        ns.Store.Event("learned", spellID)
    end
end

local function learnedInWorld(spellID)
    if inWorld then
        learned(spellID)
    end
end

-- The spell ID in the link of a chat line saying the character learned something, nil for any other line
local function linkedSpell(text)
    for _, name in ipairs(MESSAGES) do
        local template = _G[name]
        if template then
            local link = ns.ParseMessage(text, template)
            if link then
                return tonumber(link:match("|Hspell:(%d+)") or link:match("|Henchant:(%d+)"))
            end
        end
    end
    return nil
end

ns.On("PLAYER_ENTERING_WORLD", function()
    inWorld = true
end)

ns.On("PLAYER_LEAVING_WORLD", function()
    inWorld = false
end)

ns.On("LEARNED_SPELL_IN_SKILL_LINE", learnedInWorld)
ns.On("NEW_RECIPE_LEARNED", learnedInWorld)

ns.On("CHAT_MSG_SYSTEM", function(text)
    text = ns.Read(text)
    if text then
        learned(linkedSpell(text))
    end
end)
