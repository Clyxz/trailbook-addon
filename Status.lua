-- Status: a small movable line that shows whether Trailbook records and how much is not saved yet, or that no saved data was
-- loaded (ns.dataMissing, Session.lua); /trailbook shows or hides it. A right-click opens its menu: hide it, or clear up, which
-- deletes the finished recordings of this character after asking (also /trailbook clear), once they are on the website. The frame
-- has no global name, so its place lives only in TrailbookSettings and not also in the client's layout cache per character.
local addonName, ns = ...

local REFRESH = 5
local WARN_MINUTES = 60
local BIG_FILE = 2 * 1024 * 1024
local DEFAULT_POINT = { "TOP", "TOP", 0, -120 }
local GOLD = "|cffffd100"
local YELLOW = "|cffffcc00"
local RED = "|cffff4040"

TrailbookSettings = TrailbookSettings or {}
local settings = TrailbookSettings
if settings.shown == nil then
    settings.shown = true
end

local loadKind = "Login"

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetHeight(22)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetColorTexture(0, 0, 0, 0.6)

local dot = frame:CreateTexture(nil, "ARTWORK")
dot:SetSize(8, 8)
dot:SetPoint("LEFT", 8, 0)

local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
label:SetPoint("LEFT", dot, "RIGHT", 6, 0)

local function recording()
    return ns.Here() ~= nil
end

local function minutesUnsaved(stats)
    return math.floor((time() - stats.savedAt) / 60)
end

local function kilobytes(bytes)
    return math.max(1, math.floor(bytes / 1024 + 0.5))
end

local function savedText(stats)
    return ns.Text("savedAt", date("%H:%M", stats.savedAt), loadKind)
end

local function summary()
    local stats = ns.Store.Stats()
    return ns.Text("summary", ns.Text(recording() and "recording" or "noPosition"), savedText(stats), minutesUnsaved(stats), stats.lines)
end

local function refresh()
    local minutes = minutesUnsaved(ns.Store.Stats())
    if ns.dataMissing then
        dot:SetColorTexture(1, 0.25, 0.25)
        label:SetText(GOLD .. "Trailbook|r  " .. RED .. ns.Text("noDataShort") .. "|r")
    elseif not recording() then
        dot:SetColorTexture(0.5, 0.5, 0.5)
        label:SetText(GOLD .. "Trailbook|r  " .. ns.Text("noPositionShort", minutes))
    elseif minutes >= WARN_MINUTES then
        dot:SetColorTexture(1, 0.8, 0)
        label:SetText(GOLD .. "Trailbook|r  " .. YELLOW .. ns.Text("unsaved", minutes) .. "|r")
    else
        dot:SetColorTexture(0.2, 0.8, 0.2)
        label:SetText(GOLD .. "Trailbook|r  " .. ns.Text("unsaved", minutes))
    end
    frame:SetWidth(label:GetStringWidth() + 30)
end

local function place()
    local point = settings.point or DEFAULT_POINT
    frame:ClearAllPoints()
    frame:SetPoint(point[1], UIParent, point[2], point[3], point[4])
end

local function showTooltip(self)
    local stats = ns.Store.Stats()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Trailbook " .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or ""))
    if ns.dataMissing then
        GameTooltip:AddLine(ns.Text("noData"), 1, 0.25, 0.25, true)
    end
    if recording() then
        GameTooltip:AddLine(ns.Text("recording"), 0.2, 0.8, 0.2)
    else
        GameTooltip:AddLine(ns.Text("noPositionLong"), 0.6, 0.6, 0.6)
    end
    GameTooltip:AddDoubleLine(ns.Text("saved"), savedText(stats), 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.Text("since"), ns.Text("sinceValue", minutesUnsaved(stats), stats.lines, kilobytes(stats.bytes)), 0.7, 0.7, 0.7, 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.Text("fileTotal"), ns.Text("aboutKB", kilobytes(stats.totalBytes)), 0.7, 0.7, 0.7, 1, 1, 1)
    if stats.totalBytes >= BIG_FILE then
        GameTooltip:AddLine(ns.Text("bigFile"), 1, 0.8, 0, true)
    end
    GameTooltip:AddLine(ns.Text(ns.dataMissing and "hintsMissing" or "hints"), 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function toggle()
    settings.shown = not settings.shown
    frame:SetShown(settings.shown)
    ns.Print(ns.Text(settings.shown and "shown" or "hidden") .. " " .. summary())
end

-- Asks before deleting the finished recordings, naming their days and size, and deletes them on yes
local function askClear()
    local finished = ns.Store.Finished()
    if not finished then
        ns.Print(ns.Text("nothingToClear"))
        return
    end
    local days = ns.Day(finished.first)
    if ns.Day(finished.last) ~= days then
        days = days .. " – " .. ns.Day(finished.last)
    end
    StaticPopup_ShowCustomGenericConfirmation({
        text = ns.Text("clearQuestion", days, kilobytes(finished.bytes)),
        acceptText = DELETE,
        cancelText = CANCEL,
        showAlert = true,
        callback = function()
            ns.Store.Clear(finished.own)
            ns.Print(ns.Text("cleared", kilobytes(finished.bytes)))
        end,
    })
end

frame:SetScript("OnEnter", showTooltip)
frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        GameTooltip:Hide()
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle("Trailbook")
            root:CreateButton(ns.Text("menuHide"), toggle)
            root:CreateButton(ns.Text("menuClear"), askClear)
        end)
    end
end)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    settings.point = { point, relativePoint, x, y }
end)

ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if isLogin or isReload then
        loadKind = isLogin and "Login" or "Reload"
    end
    refresh()
end)

SLASH_TRAILBOOK1 = "/trailbook"
SlashCmdList.TRAILBOOK = function(message)
    local command = strtrim(message or ""):lower()
    if command == "" then
        toggle()
    elseif command == "clear" then
        askClear()
    else
        ns.Print(ns.Text("commands"))
    end
end

place()
frame:SetShown(settings.shown)
ns.Every(REFRESH, refresh)
