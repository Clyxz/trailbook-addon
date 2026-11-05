# Trailbook: technische Beschreibung

Ein Addon für World of Warcraft: Forever. Es zeichnet den Weg eines Charakters und wichtige Momente auf, damit man sie später
ohne das Spiel ansehen kann. Im Spiel zeigt es nur eine kleine Infobox.

## Anzeige im Spiel

Eine kleine Infobox, die sich mit der Maus verschieben lässt: `Trailbook  23 min ungespeichert`. Der Punkt davor ist grün,
solange das Addon Positionen aufzeichnet, gelb ab 60 Minuten ohne Speichern und grau ohne Position (Dungeon,
Ladebildschirm). Beim Darüberfahren zeigt ein Tooltip, wann zuletzt gespeichert wurde (beim Login oder beim letzten
`/reload`), wie viele Minuten, Zeilen und KB seitdem ungespeichert sind und wie groß die Daten insgesamt sind. `/trailbook`
blendet die Infobox aus oder ein und schreibt denselben Stand in den Chat. Ein Rechtsklick öffnet ein Menü mit „Ausblenden“ und
„Aufräumen …“: Nach einer Rückfrage mit Tagen und Größe löscht das Aufräumen alle abgeschlossenen Abschnitte dieses Charakters
(auch die früherer Charaktere gleichen Namens), der laufende bleibt; `/trailbook clear` tut dasselbe. Ab 2 MB erinnert der
Tooltip daran. `/trailbook help` schreibt die Schritte vom Spielen über das Hochladen bis zum Aufräumen in den Chat, jeden mit
dem Ort, an dem er passiert (im Spiel oder auf der Website). Hat das Addon beim Einloggen keine gespeicherten Daten
geladen, ist der Punkt rot und die Infobox sagt `keine Daten geladen` (siehe unten). Die Texte im Spiel sind auf Deutsch, in einem
nicht deutschen Client auf Englisch.

Position und Sichtbarkeit liegen kontoweit in `WTF\Account\<Konto>\SavedVariables\Trailbook.lua` (`TrailbookSettings`). Diese
Datei enthält keine Wegdaten.

## Wo die Daten liegen

Eine Datei pro Charakter:

```
WTF\Account\<Konto>\<Realm>\<Charakter>\SavedVariables\Trailbook.lua
```

WoW schreibt sie nur beim Logout, bei `/reload` und beim Beenden. Nach einem Absturz fehlt alles seit dem letzten Speichern.
Daneben liegt `Trailbook.lua.bak`, der Stand vor dem letzten Speichern; WoW ersetzt ihn bei jedem Speichern.

Meldet das Addon beim Einloggen „Keine gespeicherten Daten geladen“ (im Chat und rot in der Infobox, bis zum nächsten
Reload), obwohl schon aufgezeichnet wurde: WoW beenden und
`Trailbook.lua.bak` sichern, bevor man wieder einloggt. Sonst überschreibt das nächste Speichern den alten Stand.

## Aufbau

```lua
TrailbookDB = {
    character = { guid = "Player-…", name = "…", surname = "…", class = "WARRIOR", race = 1, sex = 3, faction = "Alliance" },
    chunks = { "<Chunk>", "<Chunk>" },
    open = { "<Zeile>", "<Zeile>" },
    previous = { { character = { … }, chunks = { "<Chunk>" } } },
}
```

- `character`: wer der Charakter ist. Die GUID bleibt bei Umbenennung gleich und unterscheidet einen neuen Charakter mit
  gleichem Namen. Der Name hat in Forever zwei Teile, Vorname (`name`) und Nachname (`surname`), wie `UnitName` sie
  liefert; Namen sind pro Region eindeutig, Realms gibt es nicht (Aufzeichnungen vor 0.6.1 haben stattdessen `realm`).
  Die Klasse als Token des Spiels, das Volk als ID (ChrRaces.db2; das Token teilen sich mehrere Völker),
  `sex` wie `UnitSex` (2 männlich, 3 weiblich), für die Namensformen „Magierin“, „Zwergin“.
- `chunks`: abgeschlossene Abschnitte, ältester zuerst. Jeder ist ein Text mit einer Zeile pro Eintrag.
- `open`: der Abschnitt, der beim Speichern gerade lief, Zeile für Zeile. Beim nächsten Laden wird er unverändert an
  `chunks` angehängt.
- `previous`: nur vorhanden, wenn ein Charakter gelöscht und unter demselben Namen neu erstellt wurde. WoW legt beide in
  dieselbe Datei; erkennt das Addon beim Login eine andere GUID, verschiebt es den alten `character` mit seinen `chunks`
  hierher, ältester zuerst, und beginnt leer. Gelöscht wird nichts.

## Import

Die Datei behält alles; sie wächst um etwa 30 KB pro Spielstunde. Der Viewer importiert sie auf seiner Seite
„Aufzeichnungen verwalten“ aus dem Ordner WTF, den man dort ablegt oder auswählt, und übernimmt nur, was er noch nicht hat.
Importieren nach dem Logout oder einem `/reload`: erst dann hat WoW die Datei geschrieben.

## Chunks

Ein Chunk ist ein Stück Weg. Ein neuer beginnt bei jedem Login und Reload, nach jedem Ladebildschirm und jedem Sprung (siehe
`teleport`), beim Wechsel in eine andere Zone und nach 2000 Zeilen.

Beginnt ein Chunk mit Login, Reload oder Teleport, ist sein Kopf vorläufig: WoW meldet dann oft noch die alte oder gar keine
Zone und erst ein bis zwei Sekunden später die richtige. Ein Zonenwechsel in den ersten 10 s eines solchen Chunks schreibt
deshalb nur den Kopf neu (Instanz und uiMapID), statt einen neuen Chunk zu beginnen. Ohne Zonenwechsel (Teleport
innerhalb derselben Zone) liest das Addon Instanz und uiMapID in diesen 10 s alle 2 s neu.

Felder sind durch `|` getrennt, ein leeres Feld heißt „unbekannt“. In Texten ersetzt das Addon `|` und Zeilenumbrüche durch
Leerzeichen.

```
Trailbook|1|1762380000|0|1429
0|login|-132|-8950|1|1.60.1|deDE
0|subzone|-132|-8950|Abtei von Nordhain
2|-132|-8950|-
4|-125|-8944|-
37|quest|-110|-8931|783|Titel der Quest|5
37|quest-accepted|-110|-8931|783
120|-96|-8920|m
```

### Kopf (erste Zeile)

`Trailbook|<Format>|<Start>|<Instanz>|<uiMapID>`

- Format: Version des Formats der Zeilen, steigt mit jeder Änderung daran (heute 1).
- Start: Unix-Zeit in Sekunden (UTC).
- Instanz: Karten-ID aus `GetInstanceInfo()` (Map.db2), etwa 0 = Östliche Königreiche, 1 = Kalimdor, 2991 = Insel Zephras;
  Dungeons, Raids und Schlachtfelder haben eigene IDs.
- uiMapID: Karte der Weltkarte (Taste M), sprachunabhängig. Direkt nach einem Teleport kann es kurz die Kontinentkarte sein
  (siehe vorläufiger Kopf).
- Aufzeichnungen vor 0.6.2 haben dahinter noch den Zonennamen in der Sprache des Clients; der Viewer braucht ihn nicht.

### Punkt

`<Sekunden>|<x>|<y>|<Flags>`

- Sekunden: seit dem Start des Chunks.
- x, y: Weltkoordinaten in ganzen Yards aus `UnitPosition("player")`. x ist der 2. Rückgabewert (wächst nach Westen),
  y der 1. (wächst nach Norden).
- Flags: `t` Flugroute, `m` Reittier, `g` Geist, `d` tot, `w` Schwimmen, `c` Kampf, `-` keine.

Alle 2 s wird die Position geprüft. Geschrieben wird sie, wenn sie mindestens 3 Yards vom letzten Punkt entfernt ist oder
sich die Flags geändert haben. In Dungeons, Raids und Schlachtfeldern gibt das Spiel keine Position, dort gibt es keine
Punkte. Ändert sich die Position zwischen zwei Prüfungen schneller als 35 Yards pro Sekunde (außer auf Flugrouten und beim
Fliegen), gilt das als Sprung: Es beginnt ein neuer Chunk mit einer `teleport`-Zeile.

### Ereignis

`<Sekunden>|<Art>|<x>|<y>|<Felder…>`

x und y sind leer, wenn das Spiel keine Position liefert. Dinge werden über ihre IDs genannt; deren Namen stehen in den
Tabellen der Spieldateien (Gegenstände, Karten, Flugpunkte, Klassen). Was in keiner Spieldatei steht, schreibt das Addon
selbst mit: Mitspieler und Quests (Titel, Stufe) in einer eigenen Zeile einmal je Sitzung (`player`, `quest`), die Gilde mit
ihrem Namen im Zustand `guild`, und was das Spiel erst beim Spielen ausrechnet (Schwierigkeit einer Quest, Tag oder Nacht).

Ein Zustand (`gear`, `quests`, `group`, `guild`, `daytime`) wird ganz geschrieben: 5 s nach Login und Reload und 0,5 s nach
einer Änderung; Änderungen, die zusammen kommen (etwa ein Ausrüstungsset), ergeben eine Zeile, und nur, wenn sich etwas
geändert hat. Solange das Spiel einen Zustand noch nicht kennt (die Gilde kurz nach dem Login), wird nichts geschrieben.

| Art | Felder | Wann |
|---|---|---|
| `login` | Level, Client-Version, Sprache | Einloggen |
| `reload` | Level, Client-Version, Sprache | nach `/reload` |
| `logout` | – | Logout oder `/reload`, gleich danach speichert WoW |
| `level` | neues Level | Levelaufstieg |
| `quest-accepted` | Quest-ID | Quest angenommen |
| `quest-done` | Quest-ID, Erfahrung, Kupfer | Quest abgegeben |
| `quest` | Quest-ID, Titel, Stufe (laut Questlog; leer, wenn die Quest dort nicht steht) | einmal je Sitzung und Quest, sobald sie im Questlog steht, angenommen oder abgegeben wird |
| `quests` | IDs der Quests im Questlog (ab 0.6.3 ohne die Einträge, die das Spiel dort versteckt), aufsteigend, mit Komma getrennt, jede mit `:` und ihrer Schwierigkeit für den Charakter, wie das Questlog sie färbt (`Enum.RelativeContentDifficulty`: 0 grau, 1 grün, 2 gelb, 3 orange, 4 rot); leer = keine | Zustand, auch nach jedem Levelaufstieg |
| `death` | – | gestorben |
| `release` | – | Geist freigelassen |
| `alive` | – | wieder lebendig |
| `subzone` | Name (leer = keine) | neue Unterzone |
| `dungeon-in` | Instanz-ID (die Karte in Map.db2), Schwierigkeit (DifficultyID) | Dungeon, Raid oder Schlachtfeld betreten; auch nach Login oder Reload in einer Instanz |
| `dungeon-out` | Instanz-ID | wieder verlassen |
| `flight` | Flugpunkt-ID von, nach (TaxiNodes.db2) | Flugroute gebucht; die Landung zeigt sich am Ende des Flags `t` |
| `teleport` | Zauber-ID, falls in den 15 s davor gewirkt (8690 = Ruhestein) | erste Zeile eines Chunks an einem neuen Ort, ohne dorthin gelaufen zu sein: nach einem Ladebildschirm oder einem Sprung (Ruhestein ohne Ladebildschirm, Geist freilassen, Beschwörung); den Abreiseort zeigt der letzte Punkt des vorigen Chunks |
| `screenshot` | – | Screenshot gespeichert; der Dateiname trägt Datum und Uhrzeit in Ortszeit |
| `item` | ItemID, Anzahl, Herkunft: `loot` geplündert, `received` Belohnung oder Kauf, `created` hergestellt | Gegenstand erhalten (aus der Beute-Meldung im Chat) |
| `gear` | 19 ItemIDs nach Platz, mit Komma getrennt, 0 = leer | Zustand |
| `money` | Änderung, neuer Stand, beides in Kupfer; Änderung leer = Stand beim Login oder Reload | Gold geändert |
| `kill` | Name, Erfahrung | Gegner gestorben, der Erfahrung gab; Forever sperrt das Kampflog, Kills ohne Erfahrung (graue Gegner, Höchststufe) fehlen |
| `group` | GUIDs der anderen Mitglieder, aufsteigend, mit Komma getrennt; leer = keine Gruppe | Zustand |
| `player` | GUID, Name („Vorname Nachname“), Klasse (Token wie `WARRIOR`) | einmal je Sitzung und Mitspieler, sobald das Spiel den Namen kennt |
| `guild` | Name der Gilde, Rang, Rangnummer (0 = Gildenmeister); ein leeres Feld = keine Gilde | Zustand |
| `daytime` | 1 = Tag, 0 = Nacht, wie Sonne oder Mond an der Minimap | Zustand |

Die Plätze der Ausrüstung: 1 Kopf, 2 Hals, 3 Schultern, 4 Hemd, 5 Brust, 6 Taille, 7 Beine, 8 Füße, 9 Handgelenke,
10 Hände, 11 und 12 Finger, 13 und 14 Schmuck, 15 Rücken, 16 Waffenhand, 17 Schildhand, 18 Distanz, 19 Wappenrock.

## Abbildung auf die Minimap-Karte

Die Minimap-Kacheln eines Kontinents bilden ein Raster aus 64 × 64 Kacheln zu je 533⅓ Yards; die Weltkoordinate 0/0 liegt
an der Ecke von Kachel 32/32:

```
Spalte = 32 − x / 533,333
Zeile  = 32 − y / 533,333
```

Der ganzzahlige Teil ist die Kachel, der Rest mal Kachelbreite der Pixel darin. Geprüft am 3.11.2026 mit einem Testlauf in
Retail: Startplatz und Weg in Northshire liegen auf der Minimap richtig.

## Dateien

| Datei | Aufgabe |
|---|---|
| `Trailbook.toc` | Metadaten, gespeicherte Variablen (mit `LoadSavedVariablesFirst`, damit sie beim Laden der Dateien schon da sind), Ladereihenfolge |
| `Core.lua` | Events, Timer, vom Spiel versteckte Werte, Position, letzter Zauber, Spielmeldungen lesen, Zustände schreiben, Chat-Ausgabe |
| `Store.lua` | einziger Schreiber von `TrailbookDB` |
| `Session.lua` | Login, Reload, Logout, Charakter, Warnung bei fehlenden Daten |
| `Trail.lua` | Punkte und Sprünge |
| `Progress.lua` | Level, Quests und Questlog |
| `Deaths.lua` | Tod, Geist, Wiederbelebung |
| `Travel.lua` | neue Chunks bei Zone und Ladebildschirm, Unterzonen, Dungeons, Flugrouten, Zauber vor dem Ladebildschirm |
| `Screenshots.lua` | Screenshots |
| `Loot.lua` | erhaltene Gegenstände |
| `Gear.lua` | Ausrüstung |
| `Money.lua` | Gold |
| `Kills.lua` | Kills |
| `Group.lua` | Gruppe |
| `Guild.lua` | Gilde |
| `Daytime.lua` | Tag und Nacht |
| `Status.lua` | Statuszeile, Tooltip, Menü mit Aufräumen und `/trailbook` |
