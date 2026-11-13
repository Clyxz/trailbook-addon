-- Currencies: the amount of every currency the character's currency window lists (Forever has its own, such as Merchant's Favor;
-- gold is Money.lua's), as "currencyID:amount" by currency ID (CurrencyTypes.db2), as a snapshot (Core.lua: after login and reload
-- and after a change of an amount, only when it changed); nothing while the window lists no currency. Headers stay out; the ID
-- comes from the currency's link. The game lists currencies under headers the player may have collapsed: for the read they are
-- expanded, and those that were collapsed are collapsed again, from the last row up, so the currency window looks as before (as
-- Reputation.lua does). The change event is CURRENCY_DISPLAY_UPDATE with the currency it names: one without a currency (the list
-- itself changed, a header opened or closed) is no change of an amount and would answer every read with the next
local _, ns = ...

local C = C_CurrencyInfo
if not (C and C.GetCurrencyListSize and C.GetCurrencyListInfo and C.GetCurrencyListLink and C.ExpandCurrencyList) then
    return
end

-- The rows the currency window lists now, by their index, and how many it lists
local function rows()
    local list = {}
    local count = ns.Read(C.GetCurrencyListSize()) or 0
    for index = 1, count do
        local info = ns.Read(C.GetCurrencyListInfo(index))
        if type(info) == "table" then
            list[index] = info
        end
    end
    return list, count
end

-- Expands every collapsed header, also those a header it expands reveals, and gives the names of those it expanded
local function expandAll()
    local opened = {}
    local index = 1
    while index <= (ns.Read(C.GetCurrencyListSize()) or 0) do
        local info = ns.Read(C.GetCurrencyListInfo(index))
        if type(info) == "table" and ns.Read(info.isHeader) and not ns.Read(info.isHeaderExpanded) then
            local name = ns.Read(info.name)
            if name then
                opened[name] = true
            end
            C.ExpandCurrencyList(index, true)
        end
        index = index + 1
    end
    return opened
end

local changed = ns.Snapshot("currencies", function()
    local opened = expandAll()
    local all, count = rows()
    local amounts = {}
    for index = 1, count do
        local info = all[index]
        if info and not ns.Read(info.isHeader) then
            local link = ns.Read(C.GetCurrencyListLink(index))
            local id = type(link) == "string" and tonumber(link:match("currency:(%d+)"))
            local amount = ns.Read(info.quantity)
            if id and type(amount) == "number" then
                amounts[id] = amount
            end
        end
    end
    -- from the last row up, so that closing a header does not move the rows of the headers before it
    for index = count, 1, -1 do
        local info = all[index]
        if info and ns.Read(info.isHeader) and opened[ns.Read(info.name)] then
            C.ExpandCurrencyList(index, false)
        end
    end
    local ids = {}
    for id in pairs(amounts) do
        ids[#ids + 1] = id
    end
    if #ids == 0 then
        return
    end
    table.sort(ids)
    for i, id in ipairs(ids) do
        ids[i] = id .. ":" .. amounts[id]
    end
    return table.concat(ids, ",")
end, {})

ns.On("CURRENCY_DISPLAY_UPDATE", function(currency)
    if ns.Read(currency) then
        changed()
    end
end)
