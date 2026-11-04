<p align="center"><img src="media/logo.svg" width="128" alt="Trailbook logo: a map pin on a closed leather book"></p>

<h1 align="center">Trailbook</h1>

<p align="center"><a href="https://trailbook-96g8h.ondigitalocean.app"><img src="media/website.svg" width="300" alt="Open the Trailbook website"></a></p>

<p align="center"><img src="https://trailbook-96g8h.ondigitalocean.app/media/trailbook-replay.gif" width="720" alt="A route replays on the Trailbook map while the timeline runs"></p>

<p align="center"><a href="#english">English</a> · <a href="#deutsch">Deutsch</a></p>

<p align="center"><img src="media/divider.svg" width="100%" alt=""></p>

## English

An addon for World of Warcraft: Forever that records where your character goes and what happens on the way: quests, loot,
levels, deaths, gold, gear, group and guild. The [Trailbook website](https://trailbook-96g8h.ondigitalocean.app) shows it on a
map with a timeline, on any computer and only to you, unless you share a character.

Trailbook was inspired by [Muddy Boots](https://www.curseforge.com/wow/addons/muddy-boots) by Mookz, which lets you relive
your journey right on the in-game world map. Trailbook covers the other side and takes your journey out of the game; as a side
effect it stays safe even if a reinstall, a new computer or a broken save wipes the SavedVariables folder.

Both addons run side by side without getting in each other's way, each keeps its own data. If you like to look back on your
travels inside the game, give Muddy Boots a try as well.

### How it works

1. Install the addon from [CurseForge](https://www.curseforge.com/wow/addons/trailbook); the CurseForge app keeps it up to
   date. Or copy the files of this repository into a folder named `Trailbook` in
   `World of Warcraft\_forever_\Interface\AddOns`.
2. Play. A small line in the game shows how long it has been since the last save; `/trailbook` shows or hides it.
3. Afterwards open "Manage recordings" on the Trailbook website and drag the WTF folder in. Only what is new is taken over.
4. To keep the file small, clear up in the game once your recordings are on the website: right-click the line, "Clear up"
   (or `/trailbook clear`).

### So that nothing gets lost

- WoW saves only when you log out, on `/reload` and when you quit. After a crash everything since the last save is missing:
  type `/reload` now and then, at the latest when the line turns yellow.
- Until you import, your routes are only on your computer. Import after every session.
- If the addon says "No saved data loaded": quit WoW and back up `Trailbook.lua.bak` before you log in again.

### More

- [FORMAT.md](FORMAT.md) (in German) describes what the addon records and how its data is built, readable without the addon.
- License: [MIT](LICENSE)

<p align="center"><img src="media/divider.svg" width="100%" alt=""></p>

## Deutsch

Ein Addon für World of Warcraft: Forever schreibt mit, wo dein Charakter unterwegs ist und was dabei passiert: Quests, Beute,
Level, Tode, Gold, Ausrüstung, Gruppe und Gilde. Die [Trailbook-Website](https://trailbook-96g8h.ondigitalocean.app) zeigt
es auf einer Karte mit Zeitleiste, auf jedem Rechner und nur für dich, ausser du teilst einen Charakter.

Inspiriert hat Trailbook das Addon [Muddy Boots](https://www.curseforge.com/wow/addons/muddy-boots) von Mookz, mit dem du
deine Reise direkt auf der Weltkarte im Spiel nacherlebst. Trailbook deckt die andere Seite ab und holt deine Reise aus dem
Spiel heraus; nebenbei bleibt sie so erhalten, auch wenn eine Neuinstallation, ein neuer Rechner oder eine kaputte Speicherung
den Ordner SavedVariables löscht.

Beide Addons laufen nebeneinander, ohne sich in die Quere zu kommen, und speichern ihre Daten getrennt. Wenn du deine Reisen
auch im Spiel selbst noch einmal ansehen möchtest, probier Muddy Boots ruhig zusätzlich aus.

### So geht's

1. Addon über [CurseForge](https://www.curseforge.com/wow/addons/trailbook) installieren, mit der CurseForge-App kommen Updates
   von selbst. Oder die Dateien dieses Repositorys in einen Ordner `Trailbook` unter
   `World of Warcraft\_forever_\Interface\AddOns` kopieren.
2. Spielen. Eine kleine Zeile im Spiel zeigt, wie lange nicht gespeichert wurde; `/trailbook` blendet sie aus oder ein.
3. Danach auf der Trailbook-Website „Aufzeichnungen verwalten“ öffnen und den Ordner WTF hineinziehen. Übernommen wird nur,
   was neu ist.
4. Damit die Datei klein bleibt, im Spiel aufräumen, sobald die Aufzeichnungen auf der Website sind: Rechtsklick auf die
   Zeile, „Aufräumen …“ (oder `/trailbook clear`).

### Damit nichts verloren geht

- WoW speichert nur beim Ausloggen, bei `/reload` und beim Beenden. Nach einem Absturz fehlt alles seit dem letzten Speichern:
  zwischendurch `/reload`, spätestens wenn die Zeile gelb wird.
- Bis zum Import liegen deine Wege nur auf deinem Rechner. Importiere nach jedem Spielen.
- Meldet das Addon „Keine gespeicherten Daten geladen“: WoW beenden und `Trailbook.lua.bak` sichern, bevor du wieder einloggst.

### Mehr

- [FORMAT.md](FORMAT.md) beschreibt, was das Addon aufzeichnet und wie seine Daten aufgebaut sind, lesbar auch ohne das Addon.
- Lizenz: [MIT](LICENSE)
