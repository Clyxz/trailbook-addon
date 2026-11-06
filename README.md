<p align="center"><img src="media/logo.svg" width="128" alt="Trailbook logo: a map pin on a closed leather book"></p>

<h1 align="center">Trailbook</h1>

<p align="center"><a href="https://trailbook.gg"><img src="media/website.svg" width="300" alt="Open the Trailbook website"></a></p>

<p align="center"><img src="https://trailbook.gg/media/trailbook-replay.gif" width="720" alt="A route replays on the Trailbook map while the timeline runs"></p>

<p align="center"><a href="#english">English</a> · <a href="#deutsch">Deutsch</a></p>

<p align="center"><img src="media/divider.svg" width="100%" alt=""></p>

## English

An addon for World of Warcraft: Forever that records where your character goes and what happens on the way: quests,
experience, loot, levels, deaths and what caused them, boss fights, professions, spells cast, gold, gear, group and guild. The [Trailbook website](https://trailbook.gg) shows it on a
map with a timeline, on any computer and only to you, unless you share a character.

Trailbook was inspired by [Muddy Boots](https://www.curseforge.com/wow/addons/muddy-boots) by Mookz, which lets you relive
your journey right on the in-game world map. Trailbook covers the other side and takes your journey out of the game; as a side
effect it stays safe even if a reinstall, a new computer or a broken save wipes the SavedVariables folder.

Both addons run side by side without getting in each other's way, each keeps its own data. If you like to look back on your
travels inside the game, give Muddy Boots a try as well.

### How it works

First install the addon from [CurseForge](https://www.curseforge.com/wow/addons/trailbook); the CurseForge app keeps it up to
date. Or copy the files of this repository into a folder named `Trailbook` in `World of Warcraft\_forever_\Interface\AddOns`.
Then:

1. **In the game:** play. The small Trailbook info box shows how long it has been since the last save; `/trailbook` shows or
   hides it, `/trailbook help` shows these steps in the game.
2. **On [trailbook.gg](https://trailbook.gg):** open "Manage recordings" and drag the WTF folder in, from every PC you play on.
   Do it any time: only what is new is added, everything uploaded before stays.
3. **Back in the game:** clear up so the file stays small: right-click the Trailbook info box, "Clear up …" (or
   `/trailbook clear`).

### So that nothing gets lost

- WoW saves only when you log out, on `/reload` and when you quit. After a crash everything since the last save is missing:
  type `/reload` now and then, at the latest when the info box turns yellow.
- Until you upload, your recordings are only on your computer. Upload after every session.
- If the addon says "No saved data loaded": quit WoW and back up `Trailbook.lua.bak` before you log in again.

### What gets recorded

Everything stays in one file per character on your computer
(`WTF\Account\<account>\<realm>\<character>\SavedVariables\Trailbook.lua`) until you upload it to trailbook.gg yourself. The
addon sends nothing anywhere.

- **Your route:** your position every few seconds outdoors (not inside dungeons), and whether you were mounted, swimming, in
  combat, dead or a ghost; zones, subzones, flights, your Hearthstone and other teleports.
- **Progress:** levels, experience and rested pool, quests you accepted and turned in, your quest log, areas you discovered.
- **Fights and deaths:** creatures that gave you experience, boss fights (pull, kill or wipe), each death with what caused it
  (the creature, player or fall that killed you), and how you came back to life.
- **Your character:** gear, gold, items you received, your guild and rank, your professions and their skill, spells and recipes
  you learned, and every spell or ability you cast (not the auto attack).
- **Other players:** your group members and a player who killed or resurrected you, by name, with their class where the game
  shows it. The shared view of a character leaves them out.
- **Sessions:** login, reload and logout, client version and language, day or night, and when you took a screenshot (only the
  time, not the picture).

Not recorded: chat and whispers, what is in your bags and bank, who you mail or trade with, and nothing about other players
beyond the above.

### More

- [FORMAT.md](FORMAT.md) (in German) describes what the addon records and how its data is built, readable without the addon.
- License: [MIT](LICENSE)

<p align="center"><img src="media/divider.svg" width="100%" alt=""></p>

## Deutsch

Ein Addon für World of Warcraft: Forever schreibt mit, wo dein Charakter unterwegs ist und was dabei passiert: Quests,
Erfahrung, Beute, Level, Tode und ihre Ursachen, Bosskämpfe, Berufe, gewirkte Zauber, Gold, Ausrüstung, Gruppe und Gilde. Die [Trailbook-Website](https://trailbook.gg) zeigt
es auf einer Karte mit Zeitleiste, auf jedem Rechner und nur für dich, ausser du teilst einen Charakter.

Inspiriert hat Trailbook das Addon [Muddy Boots](https://www.curseforge.com/wow/addons/muddy-boots) von Mookz, mit dem du
deine Reise direkt auf der Weltkarte im Spiel nacherlebst. Trailbook deckt die andere Seite ab und holt deine Reise aus dem
Spiel heraus; nebenbei bleibt sie so erhalten, auch wenn eine Neuinstallation, ein neuer Rechner oder eine kaputte Speicherung
den Ordner SavedVariables löscht.

Beide Addons laufen nebeneinander, ohne sich in die Quere zu kommen, und speichern ihre Daten getrennt. Wenn du deine Reisen
auch im Spiel selbst noch einmal ansehen möchtest, probier Muddy Boots ruhig zusätzlich aus.

### So geht's

Zuerst das Addon über [CurseForge](https://www.curseforge.com/wow/addons/trailbook) installieren, mit der CurseForge-App kommen
Updates von selbst. Oder die Dateien dieses Repositorys in einen Ordner `Trailbook` unter
`World of Warcraft\_forever_\Interface\AddOns` kopieren. Dann:

1. **Im Spiel:** spielen. Die kleine Trailbook-Infobox zeigt, wie lange nicht gespeichert wurde; `/trailbook` blendet sie aus
   oder ein, `/trailbook help` zeigt diese Schritte im Spiel.
2. **Auf [trailbook.gg](https://trailbook.gg):** „Aufzeichnungen verwalten“ öffnen und den Ordner WTF hineinziehen, von jedem PC,
   auf dem du spielst. Das geht jederzeit: Nur Neues kommt dazu, alles bisher Hochgeladene bleibt.
3. **Wieder im Spiel:** aufräumen, damit die Datei klein bleibt: Rechtsklick auf die Trailbook-Infobox, „Aufräumen …“ (oder
   `/trailbook clear`).

### Damit nichts verloren geht

- WoW speichert nur beim Ausloggen, bei `/reload` und beim Beenden. Nach einem Absturz fehlt alles seit dem letzten Speichern:
  zwischendurch `/reload`, spätestens wenn die Infobox gelb wird.
- Bis zum Hochladen liegen deine Aufzeichnungen nur auf deinem Rechner. Lade nach jedem Spielen hoch.
- Meldet das Addon „Keine gespeicherten Daten geladen“: WoW beenden und `Trailbook.lua.bak` sichern, bevor du wieder einloggst.

### Was aufgezeichnet wird

Alles bleibt in einer Datei pro Charakter auf deinem Rechner
(`WTF\Account\<Konto>\<Realm>\<Charakter>\SavedVariables\Trailbook.lua`), bis du sie selbst auf trailbook.gg hochlädst. Das Addon
schickt nichts irgendwohin.

- **Dein Weg:** alle paar Sekunden deine Position im Freien (nicht in Dungeons), dazu ob du auf dem Reittier, schwimmend, im
  Kampf, tot oder als Geist unterwegs warst; Zonen, Unterzonen, Flüge, dein Ruhestein und andere Teleports.
- **Fortschritt:** Level, Erfahrung und Erholt-Vorrat, angenommene und abgegebene Quests, dein Questlog, entdeckte Gebiete.
- **Kämpfe und Tode:** Gegner, die dir Erfahrung gaben, Bosskämpfe (Pull, Sieg oder Wipe), jeder Tod mit seiner Ursache (der
  Gegner, Spieler oder Sturz, der dich getötet hat) und wie du wieder ins Leben kamst.
- **Dein Charakter:** Ausrüstung, Gold, erhaltene Gegenstände, deine Gilde und dein Rang, deine Berufe mit ihrer Fertigkeit,
  gelernte Zauber und Rezepte und jeder Zauber und jede Fähigkeit, die du wirkst (ohne den automatischen Angriff).
- **Andere Spieler:** deine Gruppenmitglieder und ein Spieler, der dich getötet oder wiederbelebt hat, mit Namen und, wo das
  Spiel sie zeigt, Klasse. Die geteilte Ansicht eines Charakters lässt sie weg.
- **Sitzungen:** Login, Reload und Logout, Client-Version und Sprache, Tag oder Nacht und wann du einen Screenshot gemacht hast
  (nur der Zeitpunkt, nicht das Bild).

Nicht aufgezeichnet werden Chat und Flüstern, was in deinen Taschen und deiner Bank liegt, mit wem du Post oder Handel
austauschst, und über andere Spieler nichts außer dem oben Genannten.

### Mehr

- [FORMAT.md](FORMAT.md) beschreibt, was das Addon aufzeichnet und wie seine Daten aufgebaut sind, lesbar auch ohne das Addon.
- Lizenz: [MIT](LICENSE)
