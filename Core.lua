-- Core: game events, timers, values the game may hide, the player's position, players' names and the group's units, the last
-- spell, game messages, snapshots, the texts in the client's language and chat output
local _, ns = ...

local SPELL_WINDOW = 15
local SNAPSHOT_LOGIN_DELAY = 5
local SNAPSHOT_CHANGE_DELAY = 0.5

local frame = CreateFrame("Frame")
local handlers = {}
local lastSpell, lastSpellTime
local parsers = {}

-- The texts the addon shows, German for a German client and English for all others; dayFormat is the date format of ns.Day
local TEXTS = {
    de = {
        noEvent = "Dieses Event gibt es in diesem Client nicht: %s",
        recording = "Zeichnet auf",
        noPosition = "Keine Position",
        noPositionLong = "Keine Position (Dungeon oder Ladebildschirm)",
        noPositionShort = "keine Position, %d min",
        unsaved = "%d min ungespeichert",
        savedAt = "%s beim %s",
        summary = "%s, gespeichert %s, seitdem %d min und %d Zeilen ungespeichert. /reload speichert.",
        saved = "Gespeichert:",
        since = "Seitdem:",
        sinceValue = "%d min, %d Zeilen, ca. %d KB",
        fileTotal = "Datei gesamt:",
        aboutKB = "ca. %d KB",
        hints = "/reload speichert, Ziehen verschiebt, Rechtsklick öffnet das Menü",
        hintsMissing = "Ziehen verschiebt, Rechtsklick öffnet das Menü",
        shown = "Infobox an.",
        hidden = "Infobox aus, /trailbook zeigt sie wieder.",
        menuHide = "Ausblenden",
        menuClear = "Aufräumen …",
        clearQuestion = "Ältere Aufzeichnungen dieses Charakters löschen (%s, ca. %d KB)?\n\nLade sie vorher unter „Aufzeichnungen "
            .. "verwalten“ auf der Trailbook-Website hoch – danach gibt es sie nur noch dort.",
        cleared = "Ältere Aufzeichnungen gelöscht (ca. %d KB). Die Datei wird beim nächsten /reload oder Ausloggen kleiner.",
        nothingToClear = "Keine älteren Aufzeichnungen zum Aufräumen.",
        bigFile = "Die Datei wird groß: hochladen, dann aufräumen (Rechtsklick).",
        commands = "/trailbook blendet die Infobox aus oder ein, /trailbook clear räumt auf, /trailbook help zeigt die Schritte.",
        help = "So kommen deine Aufzeichnungen sicher auf die Website:",
        placeGame = "Im Spiel:",
        placeWebsite = "Auf trailbook.gg:",
        placeBack = "Wieder im Spiel:",
        helpSave = "WoW speichert nur beim Ausloggen und bei /reload. Nach einem Absturz fehlt alles seit dem letzten Speichern – die "
            .. "Trailbook-Infobox zeigt, wie lange das her ist.",
        helpUpload = "unter „Aufzeichnungen verwalten“ den Ordner WTF hineinziehen, von jedem PC, auf dem du spielst. Das geht "
            .. "jederzeit: Nur Neues kommt dazu, alles bisher Hochgeladene bleibt.",
        helpClear = "aufräumen, damit die Datei klein bleibt – Rechtsklick auf die Trailbook-Infobox, „Aufräumen …“.",
        dayFormat = "%d.%m.",
        noDataShort = "keine Daten geladen",
        noData = "Keine gespeicherten Daten geladen. Falls du schon aufgezeichnet hast: WoW beenden und Trailbook.lua.bak im "
            .. "SavedVariables-Ordner dieses Charakters sichern, bevor du wieder einloggst.",
    },
    en = {
        noEvent = "This client has no event %s",
        recording = "Recording",
        noPosition = "No position",
        noPositionLong = "No position (dungeon or loading screen)",
        noPositionShort = "no position, %d min",
        unsaved = "%d min unsaved",
        savedAt = "%s at %s",
        summary = "%s, saved %s, since then %d min and %d lines unsaved. /reload saves.",
        saved = "Saved:",
        since = "Since then:",
        sinceValue = "%d min, %d lines, about %d KB",
        fileTotal = "File in total:",
        aboutKB = "about %d KB",
        hints = "/reload saves, drag to move, right-click for the menu",
        hintsMissing = "Drag to move, right-click for the menu",
        shown = "Info box shown.",
        hidden = "Info box hidden, /trailbook shows it again.",
        menuHide = "Hide",
        menuClear = "Clear up …",
        clearQuestion = "Delete the older recordings of this character (%s, about %d KB)?\n\nUpload them first under “Manage "
            .. "recordings” on the Trailbook website – afterwards they only exist there.",
        cleared = "Older recordings deleted (about %d KB). The file shrinks with the next /reload or logout.",
        nothingToClear = "No older recordings to clear up.",
        bigFile = "The file is getting large: upload it, then clear up (right-click).",
        commands = "/trailbook shows or hides the info box, /trailbook clear clears up, /trailbook help shows the steps.",
        help = "How your recordings get safely onto the website:",
        placeGame = "In the game:",
        placeWebsite = "On trailbook.gg:",
        placeBack = "Back in the game:",
        helpSave = "WoW saves only when you log out and on /reload. After a crash, everything since the last save is missing – the "
            .. "Trailbook info box shows how long ago that was.",
        helpUpload = "under “Manage recordings”, drag in the WTF folder, from every PC you play on. Do it any time: only what is new "
            .. "is added, everything uploaded before stays.",
        helpClear = "clear up so the file stays small – right-click the Trailbook info box, “Clear up …”.",
        dayFormat = "%d %b",
        noDataShort = "no saved data loaded",
        noData = "No saved data loaded. If you have recorded before: quit WoW and back up Trailbook.lua.bak in this character's "
            .. "SavedVariables folder before you log in again.",
    },
}
local texts = GetLocale() == "deDE" and TEXTS.de or TEXTS.en

-- A text in the client's language, with its values filled in
function ns.Text(key, ...)
    return string.format(texts[key], ...)
end

-- A day as the client's language writes it briefly: 04.11. in German, 04 Nov in all others
function ns.Day(seconds)
    return date(texts.dayFormat, seconds)
end

frame:SetScript("OnEvent", function(_, event, ...)
    for _, handler in ipairs(handlers[event]) do
        xpcall(handler, geterrorhandler(), ...)
    end
end)

function ns.On(event, handler)
    if not handlers[event] then
        if not pcall(frame.RegisterEvent, frame, event) then
            ns.Print(ns.Text("noEvent", event))
            return
        end
        handlers[event] = {}
    end
    table.insert(handlers[event], handler)
end

function ns.Every(seconds, callback)
    C_Timer.NewTicker(seconds, function()
        xpcall(callback, geterrorhandler())
    end)
end

function ns.Read(value)
    if value ~= nil and issecretvalue and issecretvalue(value) then
        return nil
    end
    return value
end

-- A snapshot: read() gives the whole of something (gear, quest log, group, guild) as the fields of one event, nothing while the
-- game does not know it yet. It is written as an event of this kind a few seconds after login or reload and shortly after any of
-- the change events, once for changes that come together and only when it differs from the last one written; written() runs
-- after each write
function ns.Snapshot(kind, read, changeEvents, written)
    local last
    local pending = false
    local function write()
        pending = false
        local fields = { read() }
        local now = #fields > 0 and table.concat(fields, "\n") or nil
        if now ~= nil and now ~= last then
            last = now
            ns.Store.Event(kind, unpack(fields))
            if written then
                written()
            end
        end
    end
    local function schedule(delay)
        if not pending then
            pending = true
            C_Timer.After(delay, write)
        end
    end
    ns.On("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
        if isLogin or isReload then
            last = nil
            schedule(SNAPSHOT_LOGIN_DELAY)
        end
    end)
    for _, event in ipairs(changeEvents) do
        ns.On(event, function()
            schedule(SNAPSHOT_CHANGE_DELAY)
        end)
    end
end

-- A name as the game gave it, nil when it gave none: a secret value, an empty text or the placeholder for an unknown name
function ns.Name(value)
    value = ns.Read(value)
    if type(value) == "string" and value ~= "" and value ~= UNKNOWNOBJECT then
        return value
    end
    return nil
end

-- A player's name as Forever shows it, "First Surname" (UnitName's two returns), only the first name where there is no surname;
-- nil while the game does not know it
function ns.FullName(unit)
    local name, surname = UnitName(unit)
    name, surname = ns.Name(name), ns.Name(surname)
    if name and surname then
        return name .. " " .. surname
    end
    return name
end

-- The unit tokens of the other members of the character's party or raid, empty outside a group
function ns.GroupUnits()
    local list = {}
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = prefix .. i
        if ns.Read(UnitGUID(unit)) and not ns.Read(UnitIsUnit(unit, "player")) then
            table.insert(list, unit)
        end
    end
    return list
end

function ns.Here()
    local posY, posX = UnitPosition("player")
    posX, posY = ns.Read(posX), ns.Read(posY)
    if not posX or not posY then
        return nil
    end
    return math.floor(posX + 0.5), math.floor(posY + 0.5)
end

-- The spell that may just have moved the character (Hearthstone, a teleport): its last one of the last SPELL_WINDOW seconds
-- since its last death; nil while it is dead or a ghost, as a release or a resurrection moves it then, not a spell
function ns.RecentSpell()
    if ns.Read(UnitIsDeadOrGhost("player")) then
        return nil
    end
    if lastSpellTime and GetTime() - lastSpellTime <= SPELL_WINDOW then
        return lastSpell
    end
    return nil
end

local function compile(template)
    local parser = { order = {}, numeric = {} }
    local pattern = template:gsub("[%(%)%.%+%-%*%?%[%]%^]", "%%%0")
    pattern = pattern:gsub("%%(%d?)%$?([sd])", function(position, kind)
        table.insert(parser.order, tonumber(position) or #parser.order + 1)
        table.insert(parser.numeric, kind == "d")
        return kind == "d" and "([%d%.,]+)" or "(.+)"
    end)
    parser.pattern = "^" .. pattern
    return parser
end

-- The values of a game message built from one of the client's text templates (e.g. LOOT_ITEM_SELF), in the order of the
-- template's arguments (%1$s, %2$s …) whatever order a translation puts them in, numbers as numbers; nil when the text does not
-- start like the template
function ns.ParseMessage(text, template)
    local parser = parsers[template] or compile(template)
    parsers[template] = parser
    local captures = { text:match(parser.pattern) }
    if #captures == 0 then
        return nil
    end
    local values = {}
    for i, position in ipairs(parser.order) do
        values[position] = parser.numeric[i] and tonumber((captures[i]:gsub("%D", ""))) or captures[i]
    end
    return unpack(values, 1, #parser.order)
end

function ns.Print(text)
    print("|cffd9a066Trailbook:|r " .. text)
end

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
    if ns.Read(unit) == "player" then
        lastSpell, lastSpellTime = spellID, GetTime()
    end
end)

ns.On("PLAYER_DEAD", function()
    lastSpell, lastSpellTime = nil, nil
end)
