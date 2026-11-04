-- Store: the only writer of TrailbookDB; turns points and events into the lines of a chunk. TrailbookDB already exists while the
-- addon's files load, since the toc has LoadSavedVariablesFirst. The format version is in every chunk's header.
local _, ns = ...

local FORMAT = 1
local MAX_LINES = 2000
local ARRIVAL_WINDOW = 10

local Store = {}
ns.Store = Store

Store.fresh = type(TrailbookDB) ~= "table"
if Store.fresh then
    TrailbookDB = {}
end

local db = TrailbookDB
db.chunks = db.chunks or {}

local chunkStart
local chunkZone
local arrival = false
local loadedAt = time()
local unsavedLines = 0
local unsavedBytes = 0

local function field(value)
    value = ns.Read(value)
    if value == nil then
        return ""
    end
    return (tostring(value):gsub("[|\r\n]", " "))
end

local function line(...)
    local fields = {}
    for i = 1, select("#", ...) do
        fields[i] = field((select(i, ...)))
    end
    return table.concat(fields, "|")
end

local function counted(text)
    unsavedLines = unsavedLines + 1
    unsavedBytes = unsavedBytes + #text + 1
    return text
end

local function closeOpen()
    if db.open and #db.open > 1 then
        table.insert(db.chunks, table.concat(db.open, "\n"))
    end
    db.open = nil
end

local function add(...)
    if not db.open or #db.open >= MAX_LINES then
        Store.Begin()
    end
    table.insert(db.open, counted(line(time() - chunkStart, ...)))
end

local function header()
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    return line("Trailbook", FORMAT, chunkStart, instanceID, C_Map.GetBestMapForUnit("player"))
end

function Store.Begin()
    closeOpen()
    chunkStart = time()
    chunkZone = ns.Read(GetRealZoneText())
    arrival = false
    db.open = { counted(header()) }
end

-- A chunk at a place reached without walking, begun with its arrival event (login, reload, teleport) and its fields: WoW may
-- still report the old zone for a moment, so its header stays provisional for ARRIVAL_WINDOW seconds
function Store.Arrive(kind, ...)
    Store.Begin()
    arrival = true
    Store.Event(kind, ...)
end

function Store.ZoneChanged()
    local zone = ns.Read(GetRealZoneText())
    if db.open and arrival and time() - chunkStart <= ARRIVAL_WINDOW then
        chunkZone = zone
        arrival = false
        db.open[1] = header()
    elseif zone ~= chunkZone then
        Store.Begin()
    end
end

-- A teleport within one zone fires no zone change, while WoW may still report the continent's map for a moment: as long as a
-- chunk's header is provisional, its map and zone are read again every few seconds
ns.Every(2, function()
    if arrival and db.open and time() - chunkStart <= ARRIVAL_WINDOW then
        chunkZone = ns.Read(GetRealZoneText())
        db.open[1] = header()
    end
end)

function Store.Point(x, y, flags)
    add(x, y, flags)
end

function Store.Event(kind, ...)
    local x, y = ns.Here()
    add(kind, x, y, ...)
end

-- Who the data belongs to; a new GUID under the same name (character deleted and made again) moves the old data to previous
function Store.SetCharacter(info)
    local old = db.character
    if old and old.guid and info.guid and old.guid ~= info.guid then
        db.previous = db.previous or {}
        table.insert(db.previous, { character = old, chunks = db.chunks })
        db.chunks = {}
    end
    db.character = info
end

local function size(texts)
    local total = 0
    for _, text in ipairs(texts or {}) do
        total = total + #text + 1
    end
    return total
end

-- The bytes of the finished chunks, this character's and those of earlier characters of the same name
local function finishedBytes()
    local total = size(db.chunks)
    for _, entry in ipairs(db.previous or {}) do
        total = total + size(entry.chunks)
    end
    return total
end

-- What is on disk and what is not: savedAt (time of this login or reload), lines and bytes written since, totalBytes of all data
function Store.Stats()
    return { savedAt = loadedAt, lines = unsavedLines, bytes = unsavedBytes, totalBytes = finishedBytes() + size(db.open) }
end

-- The start (Unix seconds) of the earliest and of the latest of these chunks, widening first and last
local function span(chunks, first, last)
    for _, chunk in ipairs(chunks or {}) do
        local start = tonumber(chunk:match("^Trailbook|%d+|(%d+)"))
        if start then
            first, last = math.min(first or start, start), math.max(last or start, start)
        end
    end
    return first, last
end

-- The finished chunks Clear deletes: this character's (own = how many of db.chunks) and those of earlier characters of the same
-- name, with their bytes and the start of the first and of the last; nil when there are none
function Store.Finished()
    local count = #db.chunks
    local first, last = span(db.chunks)
    for _, entry in ipairs(db.previous or {}) do
        count = count + #(entry.chunks or {})
        first, last = span(entry.chunks, first, last)
    end
    if count == 0 then
        return nil
    end
    return { own = #db.chunks, bytes = finishedBytes(), first = first, last = last }
end

-- Deletes the finished chunks Finished counted (own: how many of db.chunks), not those finished since, and keeps the open chunk;
-- the file shrinks with the next save
function Store.Clear(own)
    local rest = {}
    for i = own + 1, #db.chunks do
        table.insert(rest, db.chunks[i])
    end
    db.chunks = rest
    db.previous = nil
end

closeOpen()
