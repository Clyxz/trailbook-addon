-- Loot: items you receive by looting, as a reward or purchase, and by crafting, as item ID, count and origin
local _, ns = ...

local MESSAGES = {
    { LOOT_ITEM_SELF_MULTIPLE, "loot" },
    { LOOT_ITEM_SELF, "loot" },
    { LOOT_ITEM_PUSHED_SELF_MULTIPLE, "received" },
    { LOOT_ITEM_PUSHED_SELF, "received" },
    { LOOT_ITEM_CREATED_SELF_MULTIPLE, "created" },
    { LOOT_ITEM_CREATED_SELF, "created" },
}

ns.On("CHAT_MSG_LOOT", function(text)
    text = ns.Read(text)
    if not text then
        return
    end
    text = text:gsub("^|HlootHistory:%d+|h.-|h: ", "")
    for _, message in ipairs(MESSAGES) do
        if message[1] then
            local link, count = ns.ParseMessage(text, message[1])
            if link then
                ns.Store.Event("item", tonumber(link:match("item:(%d+)")), count or 1, message[2])
                return
            end
        end
    end
end)
