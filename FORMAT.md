# Trailbook: technische Beschreibung

Ein Addon für World of Warcraft: Forever. Es zeichnet den Weg eines Charakters und wichtige Momente auf, damit man sie später
ohne das Spiel ansehen kann. Im Spiel zeigt es nur eine kleine Infobox.

## Anzeige im Spiel

Eine kleine Infobox, die sich mit der Maus verschieben lässt: `Trailbook  23 min ungespeichert`. Der Punkt davor ist grün,
solange das Addon Positionen aufzeichnet, gelb ab 60 Minuten ohne Speichern und grau ohne Position (Dungeon,
Ladebildschirm). Beim Darüberfahren zeigt ein Tooltip, wann zuletzt gespeichert wurde (beim Login oder beim letzten
`/reload`), wie viele Minuten, Zeilen und KB seitdem ungespeichert sind und wie groß die Daten insgesamt sind. Rechts daneben
sitzt ein Knopf `/reload`: Er lädt die Oberfläche neu, dabei speichert WoW. `/trailbook`
blendet die Infobox aus oder ein und schreibt denselben Stand in den Chat. Ein Rechtsklick öffnet ein Menü mit „Ausblenden“ und
„Aufräumen …“: Nach einer Rückfrage mit Tagen und Größe löscht das Aufräumen alle abgeschlossenen Abschnitte dieses Charakters
(auch die früherer Charaktere gleichen Namens), der laufende bleibt; `/trailbook clear` tut dasselbe. Ab 2 MB erinnert der
Tooltip daran. `/trailbook help` schreibt die Schritte vom Spielen über das Hochladen bis zum Aufräumen in den Chat, jeden mit
dem Ort, an dem er passiert (im Spiel oder auf der Website). Hat das Addon beim Einloggen keine gespeicherten Daten
geladen, ist der Punkt rot, die Infobox sagt `keine Daten geladen` und der Knopf `/reload` fehlt, denn das nächste Speichern
würde den alten Stand überschreiben (siehe unten). Die Texte im Spiel sind auf Deutsch, in einem
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

Die Datei behält alles; sie wächst um etwa 50 KB pro Spielstunde, bei viel Kampf auch mehr. Der Viewer importiert sie auf seiner Seite
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
Tabellen der Spieldateien (Gegenstände, Karten, Flugpunkte, Klassen, Zauber, Bosskämpfe, Berufe, Gebiete). Was in keiner
Spieldatei steht, schreibt das Addon selbst mit: Spieler, Quests (Titel, Stufe) und NPCs in einer eigenen Zeile einmal je
Sitzung (`player`, `quest`, `npc`; die Spieldateien von Forever nennen nur Haustiere und Kleintiere), die Gilde mit ihrem
Namen im Zustand `guild`, den Namen des Begleiters im Zustand `pet`, und was das Spiel erst beim Spielen ausrechnet
(Schwierigkeit einer Quest, Tag oder Nacht). Nennt das Spiel für etwas aus einer Spieldatei keine ID, steht ersatzweise sein
Name in der Sprache des Clients da (das Gebiet in `discovery`, die Familie in `pet`).

Ein Zustand (`gear`, `quests`, `xp`, `skills`, `group`, `pet`, `guild`, `daytime`) wird ganz geschrieben: 5 s nach Login und
Reload und 0,5 s nach einer Änderung; Änderungen, die zusammen kommen (etwa ein Ausrüstungsset), ergeben eine Zeile, und nur,
wenn sich etwas geändert hat. Solange das Spiel einen Zustand noch nicht kennt (die Gilde kurz nach dem Login), wird nichts
geschrieben.

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
| `xp` | Erfahrung in diesem Level, Erfahrung, die das Level braucht, Erholt-Vorrat (leer = keiner) | Zustand, auch beim Betreten und Verlassen eines Gasthauses oder einer Stadt; was der Vorrat dort beim Ausruhen dazugewinnt, steht erst in der nächsten Zeile. Auf der Höchststufe keine |
| `discovery` | Gebiets-ID (AreaTable.db2; leer, wenn das Spiel sie nicht verrät), Erfahrung (leer = keine, oder unbekannt, wenn das Spiel die Chatzeile verbirgt), Name des Gebiets in der Sprache des Clients (nur, wenn die ID fehlt) | neues Gebiet entdeckt |
| `skills` | Berufe und Nebenberufe (Kochkunst, Angeln, Erste Hilfe, Reiten …), jeder als SkillLine-ID (SkillLine.db2), Rang und Höchstrang, mit `:` verbunden, nach ID aufsteigend, mit Komma getrennt; leer = keine. Waffen, Rüstungen, Sprachen und Klassenfertigkeiten fehlen, ebenso die Unterlinie, die das Spiel zu jedem Beruf führt (in SkillLine.db2 mit dem Beruf als ParentSkillLineID) | Zustand; solange im Fertigkeitenfenster eine Kategorie mit Berufen eingeklappt ist, kennt das Addon sie nicht und schreibt nichts |
| `learned` | Zauber-ID (SpellName.db2): eine Fähigkeit, ein Zauber, ein passiver Effekt oder ein Rezept | gelernt; einmal je Sitzung und Zauber |
| `death` | – | gestorben; meldet das Spiel denselben Tod noch einmal (Forever tut das, auch beim Freilassen des Geists), wird nichts geschrieben. Ältere Aufzeichnungen können denselben Tod mehrfach haben |
| `death-cause` | NPC-ID des Verursachers (leer, wenn es kein NPC war), GUID eines anderen Spielers, der getötet hat (dazu eine `player`-Zeile), Zauber-ID des tödlichen Treffers (leer = Nahkampf oder Umgebung), Umgebung (`falling` Sturz, `drowning` Ertrinken, `fatigue` Erschöpfung, `fire` Feuer, `lava` Lava, `slime` Schleim; leer = keine), Schaden des tödlichen Treffers, Encounter-ID des laufenden Bosskampfs (leer = keiner, oder unbekannt nach einem Login oder Reload mitten im Kampf: dann liegt der Tod zwischen `boss-pull` und `boss`) | etwa 1 s nach `death`, aus der Todesübersicht des Spiels, ihr letzter Treffer; fehlt, wenn das Spiel keine hat. Gehört zum letzten `death` davor, auch wenn `release`, `alive` oder ein neuer Chunk dazwischen liegen; x und y sind die beim Schreiben, den Ort des Todes hat die `death`-Zeile. Forever sperrt das Kampflog, die Todesübersicht ist die einzige Quelle |
| `release` | – | Geist freigelassen |
| `alive` | Art: `corpse` zurück zur Leiche, `spirit` beim Geistheiler (auch auf dem Schlachtfeld), `res` von einem anderen Spieler, `spell` eigener Zauber (Seelenstein, Reinkarnation), `item` eigener Gegenstand; leer, wenn das Spiel kein Zeichen gab (geraten wird nicht); dazu bei `res` die GUID des Spielers, wenn er in der Gruppe ist, sonst sein Name („Vorname Nachname“), bei `spell` die Zauber-ID, bei `item` die Gegenstands-ID | wieder lebendig; die Art kommt aus den Knöpfen und Dialogen, mit denen der Charakter zurückkam. Ältere Aufzeichnungen haben keine Felder |
| `subzone` | Name (leer = keine) | neue Unterzone |
| `dungeon-in` | Instanz-ID (die Karte in Map.db2), Schwierigkeit (DifficultyID) | Dungeon, Raid oder Schlachtfeld betreten; auch nach Login oder Reload in einer Instanz |
| `dungeon-out` | Instanz-ID | wieder verlassen |
| `boss-pull` | Encounter-ID (DungeonEncounter.db2, nennt Boss und Dungeon), Schwierigkeit (DifficultyID), Gruppengröße | Bosskampf begonnen, auch bei Weltbossen außerhalb von Dungeons |
| `boss` | Encounter-ID, Ausgang (1 besiegt, 0 Wipe oder abgebrochen, leer = vom Charakter verlassen oder vom Spiel nicht genannt), die Bosse mit NPC-ID und ihrem verbliebenen Leben, wie das Spiel es angibt (`NPC-ID:Wert`, nach NPC-ID, mit Komma getrennt, nur die NPC-ID, wenn das Spiel das Leben verbirgt; leer, wenn es keine Bosse nennt) | Bosskampf zu Ende, für den Charakter auch durch einen Ladebildschirm mitten im Kampf (Teleport hinaus, Geist freigelassen im Dungeon): dann ohne Ausgang und Bosse; seine Dauer ist die Zeit seit `boss-pull` |
| `flight` | Flugpunkt-ID von, nach (TaxiNodes.db2) | Flugroute gebucht; die Landung zeigt sich am Ende des Flags `t` |
| `teleport` | Zauber-ID, falls in den 15 s davor gewirkt (8690 = Ruhestein); leer, wenn der Charakter tot oder ein Geist ist oder seit dem Tod nichts gewirkt hat, denn dann versetzt ihn das Freilassen oder eine Wiederbelebung (in Aufzeichnungen bis 0.6.5 kann dort noch ein Zauber von vor dem Tod stehen) | erste Zeile eines Chunks an einem neuen Ort, ohne dorthin gelaufen zu sein: nach einem Ladebildschirm oder einem Sprung (Ruhestein ohne Ladebildschirm, Geist freilassen, Beschwörung); den Abreiseort zeigt der letzte Punkt des vorigen Chunks |
| `screenshot` | – | Screenshot gespeichert; der Dateiname trägt Datum und Uhrzeit in Ortszeit |
| `item` | ItemID, Anzahl, Herkunft: `loot` geplündert, `received` Belohnung oder Kauf, `created` hergestellt | Gegenstand erhalten (aus der Beute-Meldung im Chat) |
| `gear` | 19 ItemIDs nach Platz, mit Komma getrennt, 0 = leer | Zustand |
| `money` | Änderung, neuer Stand, beides in Kupfer; Änderung leer = Stand beim Login oder Reload | Gold geändert |
| `kill` | Name, Erfahrung | Gegner gestorben, der Erfahrung gab; Forever sperrt das Kampflog, Kills ohne Erfahrung (graue Gegner, Höchststufe) fehlen |
| `npc` | NPC-ID, Name in der Sprache des Clients | einmal je Sitzung und NPC, sobald eine andere Zeile ihn nennt (`death-cause`, `boss`): mit dem Namen, den das Spiel für diese NPC-ID zeigt (im Tooltip ihres Links; in Instanzen erst nach dem nächsten Ladebildschirm), bei Bossen mit dem, den das Spiel am Ende ihres Kampfes nennt. Nennt das Spiel keinen, fehlt die Zeile |
| `cast` | Zauber-ID (SpellName.db2), Dauer in Zehntelsekunden (0 = sofort), Ausgang (leer = gewirkt oder Kanal beendet, `i` = abgebrochen oder unterbrochen; ein Kanal wie Angeln bekommt nie `i`) | Zauber oder Fähigkeit zu Ende, auch Berufe, Sammeln, Angeln, Reittiere und Gegenstände, nicht der automatische Angriff (Angriff, Automatischer Schuss, Schießen) und nicht der Effekt, den das Spiel bei jedem Login wirkt (836); die Zeile steht am Ende, der Beginn liegt die Dauer davor. Ein Zauber mit Zauberzeit, der danach kanalisiert wird (Gedankenkontrolle), ergibt zwei Zeilen: erst die Zauberzeit, dann den Kanal |
| `group` | GUIDs der anderen Mitglieder, aufsteigend, mit Komma getrennt; leer = keine Gruppe | Zustand |
| `player` | GUID, Name („Vorname Nachname“), Klasse (Token wie `WARRIOR`; leer, wenn das Spiel sie nicht kennt) | einmal je Sitzung und Spieler, den eine andere Zeile mit seiner GUID nennt (Mitspieler in `group`, wer den Charakter getötet hat in `death-cause`), sobald das Spiel den Namen kennt |
| `pet` | Name des Begleiters, wie das Spiel ihn zeigt (ein Jäger kann sein Tier umbenennen; Muddy Boots sah frisch gezähmte Tiere unter dem Namen ihres Tiers, etwa `Gray Forest Wolf`), Level (leer, wenn das Spiel es verbirgt), Familie als Name in der Sprache des Clients, wie das Spiel ihn zeigt (`Wolf`, `Eber`, `Wichtel` in einem deutschen Client; nur, wenn das Spiel keine ID nennt, und leer, wenn es gar keine Familie nennt, etwa bei Humanoiden), `d`, solange er tot ist (leer = lebt), Familien-ID (CreatureFamily.db2; leer, wenn das Spiel sie nicht nennt); ein leeres Feld = kein Begleiter. Die NPC-ID fehlt, weil Forever jedem Tier eines Jägers dieselbe gibt (165189). Zeilen aus den Tests vor der Veröffentlichung von 0.7.1 enden früher, in zweien steht statt des `d` diese NPC-ID | Zustand, auch wenn er kommt oder geht, ein Level aufsteigt, einen Namen bekommt oder stirbt; solange das Spiel seinen Namen noch nicht kennt, wird nichts geschrieben. Ob er tot ist, fragt das Addon alle 2 s ab, solange es einen Begleiter gibt: Das Spiel behält ein totes Tier als Begleiter, bis es wiederbelebt wird oder verschwindet. Ein Tod mit „Tier wiederbeleben“ ergibt so drei Zeilen: mit `d` beim Tod, ohne Begleiter, sobald das Wiederbeleben beginnt, und wieder ohne `d` danach. Verbirgt Forever, ob er tot ist (in Dungeons möglich), fehlt das `d`. Begleiter ist, was das Spiel zur Einheit „pet“ macht: das Tier eines Jägers, der Dämon eines Hexenmeisters, aber auch eine Kreatur unter Gedankenkontrolle und ein versklavter Dämon; ein Spieler unter Gedankenkontrolle zählt als keiner (das Addon erkennt ihn an der Antwort des Spiels und an seiner GUID), denn Spieler nennt das Addon nur in `player`-Zeilen. Wie ein Begleiter kam oder ging, zeigen die `cast`-Zeilen davor (etwa 1515 Wildtier zähmen) |
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
| `Core.lua` | Events, Timer, vom Spiel versteckte Werte, Position, Namen von Spielern, die Gruppe, letzter Zauber, Spielmeldungen lesen, Zustände schreiben, Chat-Ausgabe |
| `Store.lua` | einziger Schreiber von `TrailbookDB` |
| `Session.lua` | Login, Reload, Logout, Charakter, Warnung bei fehlenden Daten |
| `Trail.lua` | Punkte und Sprünge |
| `Progress.lua` | Level, Quests und Questlog |
| `Experience.lua` | Erfahrung und Erholt-Vorrat |
| `Discoveries.lua` | entdeckte Gebiete |
| `Skills.lua` | Berufe und Nebenberufe |
| `Learned.lua` | gelernte Fähigkeiten, Zauber und Rezepte |
| `Players.lua` | Namen und Klassen der Spieler, die eine Zeile per GUID nennt |
| `Creatures.lua` | NPC-IDs und die Namen der NPCs |
| `Deaths.lua` | Tod, Geist, Wiederbelebung und wie |
| `DeathRecap.lua` | Ursache jedes Todes aus der Todesübersicht |
| `Bosses.lua` | Bosskämpfe |
| `Travel.lua` | neue Chunks bei Zone und Ladebildschirm, Unterzonen, Dungeons, Flugrouten, Zauber vor dem Ladebildschirm |
| `Screenshots.lua` | Screenshots |
| `Loot.lua` | erhaltene Gegenstände |
| `Gear.lua` | Ausrüstung |
| `Money.lua` | Gold |
| `Kills.lua` | Kills |
| `Casts.lua` | gewirkte Zauber |
| `Group.lua` | Gruppe |
| `Pet.lua` | Begleiter |
| `Guild.lua` | Gilde |
| `Daytime.lua` | Tag und Nacht |
| `Status.lua` | Statuszeile mit Knopf `/reload`, Tooltip, Menü mit Aufräumen und `/trailbook` |
