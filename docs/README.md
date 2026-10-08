# Referenz: MOOSE, MiST, CTLD für DCS-Missionen

Diese Datei wird per `@docs/README.md` in die `CLAUDE.md` importiert.
Sie ist ein **Wegweiser**, keine vollständige API-Doku. Funktionsnamen und Signaturen
werden immer live in der verlinkten Originaldoku geprüft (siehe Abschnitt 0).

---

## 0. Regeln für Claude Code (verbindlich)

- Funktionsnamen, Parameter und Rückgabewerte **nie aus dem Gedächtnis raten**.
  Vor dem Schreiben der Klassenmethode die Doku der jeweiligen Klasse per WebFetch lesen.
- Immer die **neueste Moose-Version** verwenden (Releases-Link unten) und die benutzte
  Version in der README.md der Mission nennen.
- Konnte eine Funktion nicht verifiziert werden: im Code mit `-- TODO: verifizieren`
  markieren und in der README.md der Mission ausdrücklich erwähnen.
- Veraltete Aufrufe vermeiden (z. B. `SPAWN:Limit` → heute `SPAWN:InitLimit`).
- Ausgabe pro Mission: genau eine `.lua` + eine `README.md`, sonst nichts.

---

## 1. Quellen (Originaldokumentation)

### MOOSE
- Doku-Startseite: https://flightcontrol-master.github.io/MOOSE_DOCS/
- Doku Develop-Branch (Beispiel Klasse SPAWN): https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Core.Spawn.html
- Releases (neueste Version): https://github.com/FlightControl-Master/MOOSE/releases
- Quellcode: https://github.com/FlightControl-Master/MOOSE
- Doku-URL-Muster: `.../Documentation/<Modul>.<Klasse>.html`, z. B. `Core.Zone.html`, `Core.Message.html`

### MiST
- Repository: https://github.com/mrSkortch/MissionScriptingTools
- Wiki/Dokumentation: http://wiki.hoggit.us/view/Mission_Scripting_Tools_Documentation

### CTLD
- Repository: https://github.com/ciribob/DCS-CTLD
- Mission-Editor-Funktionen: https://github.com/ciribob/DCS-CTLD#mission-editor-script-functions

---

## 2. MOOSE – Aufbau

MOOSE ist objektorientiert: Klassen vererben Methoden und Eigenschaften voneinander.
Die Doku gliedert sich in diese Kategorien:

| Kategorie | Zweck |
|---|---|
| Core | Basisbausteine (z. B. ZONE, SPAWN, MESSAGE) |
| Wrapper | objektorientierte Hülle um DCS-Objekte (Gruppen, Einheiten usw.) |
| Functional | fertige Hilfsfunktionen für das Missionsdesign |
| AI | Steuerung von KI-Einheiten |
| Tasking | Missions-/Aufgabensystem für menschliche Spieler |

### 2.1 ZONE (Core.Zone)
- Trigger-Zonen aus dem Mission Editor werden beim Laden von `Moose.lua` automatisch als ZONE erkannt.
  Der **ZONE-Name = Name der Trigger-Zone** im Editor.
- Zugriff: `ZONE:New("Zonenname")` bzw. `ZONE.FindByName("Zonenname")`
- Weitere Zonentypen (z. B. ZONE_POLYGON) ebenfalls direkt im Editor deklarierbar.
- Details (Koordinaten, Zufallspunkte, Markieren, Properties): in `Core.Zone.html` nachlesen.

### 2.2 SPAWN (Core.Spawn)
- Prinzip: Im Mission Editor wird eine **Template-Gruppe** (meist „Late Activation") angelegt;
  `SPAWN:New("Templatename")` erzeugt daraus zur Laufzeit neue Gruppen.
- Bestätigte Methoden (Details je Methode in der Doku prüfen):
  - `SPAWN:New(templateName)` – Konstruktor
  - `:InitLimit(maxLebend, maxGesamt)` – z. B. `:InitLimit(1, 0)` = nur eine lebende Gruppe gleichzeitig
  - `:InitRandomizeTemplate(tabelle)` – zufällige Template-Auswahl
  - `:InitRandomizeRoute(...)` – zufällige Route
  - `:InitRandomizeZones(zonenTabelle)` – zufällige Spawn-Zonen
  - `:Spawn()` – sofort spawnen, liefert das GROUP-Objekt
  - `:SpawnScheduled(intervall, zufall)` – wiederkehrend; hat eine kleine Spawn-Verzögerung
  - `:SpawnInZone(zone)` – in einer Zone spawnen
  - `:OnSpawnGroup(funktion)` – Callback, wenn eine neue Gruppe entsteht

Minimalbeispiel (Muster; vor Verwendung gegen die aktuelle Doku prüfen):

```lua
-- Template-Gruppe "RED_Convoy_Template" existiert im ME (Late Activation)
local convoy = SPAWN:New("RED_Convoy_Template")
  :InitLimit(1, 0)
  :Spawn()
```

### 2.3 MESSAGE (Core.Message)
- Nachrichten an Spieler, z. B. `MESSAGE:New(text, dauer):ToAll()`.
- Genaue Signatur in `Core.Message.html` prüfen.

### 2.4 Weitere Klassen
Bei Bedarf in der Doku-Startseite nachschlagen (Wrapper: GROUP, UNIT; Functional; AI; Tasking).
Dieser Abschnitt wird erweitert, sobald eine Mission weitere Klassen braucht.

---

## 3. MiST – Aufbau

- Sammlung von Lua-Funktionen und Datenbanken als Ergänzung zur DCS-Scripting-Engine.
- `mist.flagFuncs`: Funktionen, die wenig Lua-Wissen erfordern (ähnlich Slmod).
- Der Großteil von MiST setzt Lua-Kenntnisse voraus; Funktionsliste im Wiki (siehe Quellen).
- CTLD benötigt MiST (siehe Abschnitt 4).

---

## 4. CTLD – Aufbau und Einbindung

- Steht für „Complete Troops and Logistics Deployment" (Truppen- und Fracht-Logistik per Hubschrauber).
- **Voraussetzung:** MiST (laut CTLD-README Version 4.0.57 oder neuer).
- **Ladereihenfolge im Mission Editor:**
  1. MiST laden – als Initialization Script oder als erstes `DO SCRIPT FILE` mit Trigger „TIME MORE" 1
  2. CTLD wenige Sekunden später per zweitem Trigger („TIME MORE" + `DO SCRIPT FILE` mit `CTLD.lua`)
  - Ist MiST nicht geladen, zeigt CTLD eine Fehlermeldung.
- **Download:** über „Download ZIP" des Repositories und die `ctld.lua` daraus extrahieren.
  Wird nur die einzelne Rohdatei von der GitHub-Seite kopiert, kann ein Syntaxfehler
  (`unexpected symbol near '<'`) auftreten.
- **Konfiguration:** über `ctld.*`-Variablen in der Datei bzw. im Mission-Script, z. B.
  `ctld.slingLoad`, `ctld.staticBugFix`, `ctld.cratesRequiredForFOB`,
  `ctld.maximumSearchDistance`. Hinweis aus dem CTLD-README: `ctld.staticBugFix` auf `false`
  setzen, wenn `ctld.slingLoad = true` verwendet wird.
- **Fracht per Skript:** z. B. `ctld.spawnCrateAtZone` (Fracht in einer Trigger-Zone erzeugen);
  Parameter in der CTLD-Doku prüfen.

---

## 5. Namenskonvention für Missionen (Vorschlag, in README.md jeder Mission dokumentieren)

| Objekt | Schema | Beispiel |
|---|---|---|
| Template-Gruppe | `<COALITION>_<Rolle>_Template` | `RED_Convoy_Template` |
| Trigger-Zone | `<COALITION>_<Zweck>_Zone<N>` | `BLUE_Pickup_Zone1` |
| Skriptvariablen | sprechend, englisch | `redConvoySpawner` |

Pflichtangaben pro Gruppe/Einheit in der Mission-README:
Gruppenname, Einheitenname, Einheitentyp, Coalition/Land, Spawn-Ort (Zone/Koordinate),
Late Activation (ja/nein + Grund), Skill, Route/Wegpunkte, Trigger.

---

## 6. Ladereihenfolge-Checkliste (Mission Editor)

- [ ] Verwendete Versionen in der Mission-README eingetragen (MOOSE, MiST, CTLD)
- [ ] MiST vor CTLD geladen
- [ ] Mission-`.lua` erst nach den Bibliotheken geladen
- [ ] Alle im Code genannten Trigger-Zonen und Template-Gruppen existieren mit **exakt** gleichem Namen
- [ ] Erst lokal getestet, dann auf den Server
- [ ] Bei Fehlern: `dcs.log` auswerten

---

## 7. Eigene Ergänzungen (hier pflegen)

- Versionen: MOOSE `___`, MiST `___`, CTLD `___`
- Bewährte Code-Muster:
- Bekannte Stolpersteine:
