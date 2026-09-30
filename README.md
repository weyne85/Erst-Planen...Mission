# DCS Trainingsmission Kaukasus

Trainingsmission für **Digital Combat Simulator** mit sechs unabhängigen Übungszonen, gebaut mit **Moose**, **MIST** und **CTLD**.
Läuft im Singleplayer und im Multiplayer. Alle Ansagen sind **englisch**.

| Zone | Übung | Technik |
|------|-------|---------|
| 1 | Bodenangriff | eigenes Skript (Moose `SPAWN`) |
| 2 | Carrier-Landung | Moose `AIRBOSS` |
| 3 | SEAD/DEAD | eigenes Skript |
| 4 | Air Intercept | eigenes Skript (AWACS-Ansagen) |
| 5 | JTAC gegen bewegliche Ziele | eigenes Skript + CTLD-JTAC (Laser) |
| 6 | CTLD (Lasttransport) | CTLD + eigene Aufgaben |

> **Wichtig – was hier enthalten ist und was nicht**
> - Enthalten: alle Lua-Skripte, dieses Briefing mit allen Namen für den Mission Editor, die Sound-Liste und ein Logik-Test ohne DCS.
> - **Nicht enthalten:** die fertige `.miz`. Zonen, Gruppen und Slots baust du nach Kapitel 4 selbst im Mission Editor.
> - **Nicht enthalten:** die `.ogg`-Sounddateien (Liste in Kapitel 5).
> - Die Skripte sind **im Spiel noch nicht getestet** (DCS steht in der Entwicklungsumgebung nicht zur Verfügung). Der Logik-Test (Kapitel 6) prüft nur den Ablauf mit Attrappen.

---

## 1. Grundkonzept

- Sechs Zonen, in beliebiger Reihenfolge und parallel nutzbar.
- Steuerung über ein **F10-Menü pro Spielergruppe**: `F10 > Training Zones`.
- Jede Zone bedient **eine Spielergruppe gleichzeitig**. Eine zweite Gruppe hört „Zone is busy“.
- **Schwierigkeit:** EASY, MEDIUM, HARD (Einsteiger bis Fortgeschrittene), wählbar beim Start.
- **Dynamik:** Ziele, Position und Gegner werden bei jeder Runde zufällig aus Vorlagen gewählt. Nach Abschluss startet die Zone nach 20 s automatisch neu.
- **Aufräumen:** Beim Stoppen, bei Zeitüberschreitung oder wenn die Spielergruppe verschwindet, werden alle erzeugten Einheiten entfernt.
- **Wetter/Zeit:** fest und klar. DCS erlaubt kein Ändern des Wetters per Skript; Variation gibt es nur bei Zielen, Startpunkten und beim Carrier (Recovery-Fenster, Wind).
- **Punkte/Ranglisten:** keine, nur Rückmeldung pro Übung.
- **Bearings:** rechtweisend (true). Mit `MAG_VAR` in `00_config.lua` lässt sich ein Offset einstellen.

---

## 2. Dateistruktur und Ladereihenfolge

```
README.md
libs/       mist.lua, Moose.lua, CTLD-i18n.lua, CTLD.lua     (unverändert, nur eingebunden)
scripts/    00_config.lua  01_core.lua  02_audio.lua  03_menu.lua
            10_ground_attack.lua  20_carrier.lua  30_sead_dead.lua
            40_intercept.lua  50_jtac.lua  60_ctld.lua  99_init.lua
sounds/     Ablage für die .ogg-Dateien (Kapitel 5)
tests/      mock_test.lua   (Logik-Test ohne DCS)
```

**Ladereihenfolge im Mission Editor** – ein Trigger, Typ `MISSION START`, ohne Bedingung, mit **15 Aktionen `DO SCRIPT FILE`** in genau dieser Reihenfolge:

1. `libs/mist.lua`
2. `libs/Moose.lua`
3. `libs/CTLD-i18n.lua`
4. `libs/CTLD.lua`
5. `scripts/00_config.lua`
6. `scripts/01_core.lua`
7. `scripts/02_audio.lua`
8. `scripts/03_menu.lua`
9. `scripts/10_ground_attack.lua`
10. `scripts/20_carrier.lua`
11. `scripts/30_sead_dead.lua`
12. `scripts/40_intercept.lua`
13. `scripts/50_jtac.lua`
14. `scripts/60_ctld.lua`
15. `scripts/99_init.lua`

`99_init.lua` muss zuletzt laufen.

**Zuständigkeiten**

| Datei | Inhalt |
|-------|--------|
| `00_config.lua` | **Alle** Namen (Zonen, Gruppen, Units), Frequenzen, TACAN, Schwierigkeitsstufen, Zeiten, Sound-Zuordnung. Umbenennungen in der Mission erfordern nur Änderungen hier. |
| `01_core.lua` | Hilfsfunktionen (Timer, Peilung, MGRS, Spawn), Zonen-Verwaltung (Sessions, Timeout, Aufräumen). |
| `02_audio.lua` | Einzige Stelle für Ansagen. Sendet nur an die betroffene Gruppe, reiht Ansagen hintereinander ein (kein Überlappen). |
| `03_menu.lua` | F10-Menü pro Spielergruppe, automatisch für neue Spieler und nach Respawn. |
| `10`–`60` | Je eine Zone, eigenständig. |
| `99_init.lua` | Prüft Abhängigkeiten, startet Carrier, CTLD und Menü. |

---

## 3. Mission-Grundeinstellungen

- **Karte:** Kaukasus.
- **Wetter:** klar, kein Nebel, leichter Wind (≤ 5 m/s), feste Tageszeit am Tag (Case I).
- **Koalitionen:** Spieler und Carrier = **BLUE**. Alle Ziele, SAMs und Gegner = **RED**.
- **Länder:** Wähle für BLUE Länder, für die im Editor alle Muster verfügbar sind. Prüfe die Verfügbarkeit von Mi-8MTV2 und AH-64D im Editor.
- **Zonen-Abstand:** Halte zwischen den Zonen mindestens ca. 40 nm Abstand, damit SAM-Bedrohung und Ansagen anderer Zonen nicht stören. Zone 5 (JTAC) und Zone 1 (Bodenangriff) dürfen nicht überlappen.
- **Startflugplatz:** ein Flugplatz mit allen Spieler-Slots (BLUE), Startstellungen frei wählbar.

### Spieler-Slots (Client)

| Muster | Anzahl (Empfehlung) | Zonen |
|--------|---------------------|-------|
| F/A-18C | 2 | 1, 2, 3, 4, 5 |
| F-16C | 2 | 1, 3, 4, 5 |
| A-10C II | 2 | 1, 5 |
| F-14B | 2 | 2, 4 |
| CH-47F (Chinook) | 2 | 6 |
| Mi-8MTV2 | 2 | 6 |
| AH-64D (Apache) | 2 | 1, 5, Begleitschutz in 6 |

Im Singleplayer genügt ein Slot (`Player`). Die Slots dürfen beliebig benannt sein; das Menü erkennt jede BLUE-Spielergruppe automatisch. CTLD erkennt Transporter am **Flugzeugtyp** (`CH-47Fbl1`, `Mi-8MT`), nicht am Namen. Der Apache kann keine Lasten tragen und sichert nur.

---

## 4. Zonen im Detail

Alle Namen stehen in `scripts/00_config.lua` und können dort geändert werden. **Late Activation** = im Editor „Late Activation“ anhaken, damit die Vorlage nicht von selbst erscheint.

### Zone 1 – Bodenangriff (`scripts/10_ground_attack.lua`)

**Ziel:** Waffeneinsatz gegen zufällige Bodenziele. **Muster:** A-10C II, F/A-18C, F-16C, AH-64D.

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzone | `TRN_GA_ZONE` | Zielgebiet, Radius ca. 3 km, freies Gelände |
| Vorlagen (Late Activation, RED) | `TRN_GA_VEH_1`, `_2`, `_3` | Lkw / leichte Fahrzeuge, je 2–4 Einheiten |
| Vorlagen (Late Activation, RED) | `TRN_GA_ARM_1`, `_2` | Panzer / Schützenpanzer, je 2–3 Einheiten |
| Vorlage (Late Activation, RED) | `TRN_GA_AAA_1` | Flak (nur HARD) |
| Vorlage (Late Activation, RED) | `TRN_GA_SHORAD_1` | kurzreichweitige Luftabwehr (nur HARD) |

**Ablauf**
1. `F10 > Training Zones > 1 Ground Attack > Start EASY / MEDIUM / HARD`.
2. Ansage mit Ziel-Positionen (MGRS) und Typ.
3. Treffer werden je zerstörter Zielgruppe angesagt („Targets remaining“).
4. Alle Ziele zerstört: Abschlussmeldung mit Zeit, nach 20 s neue Runde.

| Stufe | Ziele | Verteidiger |
|-------|-------|-------------|
| EASY | 2 (nur Lkw) | keine |
| MEDIUM | 3 (Lkw und Panzer) | keine |
| HARD | 4 | Flak und SHORAD |

Zeitlimit je Runde: 30 min.

### Zone 2 – Carrier-Landung (`scripts/20_carrier.lua`)

**Ziel:** Anflug und Trap. **Muster:** F/A-18C, F-14B. Technik: Moose **AIRBOSS** (Marshal, Case I/II/III, LSO-Ansagen, Grading).

| Objekt | Name | Hinweise |
|--------|------|----------|
| Träger (Schiff, BLUE) | Unit `TRN_CARRIER` | Flugzeugträger aus dem Editor (z. B. CVN-74 Stennis). **Unit-Name**, nicht Gruppen-Name. |
| Route des Trägers | – | mindestens 2 Wegpunkte, weit auseinander (> 40 nm), im offenen Meer, Geschwindigkeit ca. 10 kn |

- TACAN 74X `STN`, ICLS Kanal 1, Marshal 305.0 AM, LSO 264.0 AM (änderbar in `00_config.lua`).
- **Automatik:** alle 45 min öffnet ein Recovery-Fenster (30 min, Case I). Der Träger dreht dann in den Wind.
- **Manuell:** `F10 > Airboss` (Marshal anfordern, Recovery-Fenster starten, Grades ansehen).
- `F10 > Training Zones > 2 Carrier Landing > Info` zeigt Position, TACAN, ICLS und Frequenzen.
- Schwierigkeit: Das Wetter ist fest klar, deshalb plant die Automatik Case I. Für mehr Anspruch kannst du Case II/III über das Airboss-Menü starten.
- Die Carrier-Zone hat **keine** `Start`-Einträge, weil der Airboss dauerhaft läuft.
- **Sounds:** Airboss braucht das **Moose-Soundpaket** (Kapitel 5).

### Zone 3 – SEAD/DEAD (`scripts/30_sead_dead.lua`)

**Ziel:** SAM-Systeme unterdrücken (SEAD) oder zerstören (DEAD). **Muster:** F/A-18C, F-16C.

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzone | `TRN_SEAD_ZONE` | Bereich, in dem die SAM-Stellung entsteht, Radius ca. 3 km |
| Vorlagen (Late Activation, RED) | `TRN_SAM_SA2`, `TRN_SAM_SA3` | EASY |
| Vorlagen (Late Activation, RED) | `TRN_SAM_SA6`, `TRN_SAM_SA11` | MEDIUM |
| Vorlage (Late Activation, RED) | `TRN_SAM_SA10` | HARD |
| Vorlagen (Late Activation, RED) | `TRN_SAM_SA15`, `TRN_SAM_ZSU23` | Begleitschutz (MEDIUM: nur ZSU, HARD: beide) |

Jede SAM-Vorlage enthält ein komplettes System (Such-/Feuerleitradar, Werfer, Fahrzeuge).

**Ablauf**
1. `Start EASY / MEDIUM / HARD`, dann Modus wählen: **SEAD** oder **DEAD**.
2. Ansage: Modus, System, MGRS der Stellung.
3. **„Threat radar detected“** (mit Peilung und Entfernung), sobald du dich auf 45 km näherst (einmal je Runde).
4. **„Missile launch!“** (mit Peilung und Entfernung) bei jedem Raketenstart eines SAM der Runde.
5. Erfolg:
   - **SEAD:** alle Such- und Feuerleitradare zerstört.
   - **DEAD:** die gesamte SAM-Gruppe zerstört.
6. Danach neue Runde mit neuem System und neuer Position.

Zeitlimit je Runde: 40 min. Hinweis: Jamming (elektronischer Angriff) wird nicht simuliert.

### Zone 4 – Air Intercept (`scripts/40_intercept.lua`)

**Ziel:** Gegnerische Flugzeuge abfangen. **Muster:** F-14B, F/A-18C, F-16C.

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzone | `TRN_INT_ZONE` | Mittelpunkt des Einsatzgebiets (über Wasser oder dünn besiedeltem Gebiet) |
| Vorlage (Late Activation, RED) | `TRN_BANDIT_MIG21` | EASY: 1 Flugzeug |
| Vorlagen (Late Activation, RED) | `TRN_BANDIT_MIG29`, `TRN_BANDIT_SU27` | Paare (2 Flugzeuge) |
| Vorlage (Late Activation, RED) | `TRN_BANDIT_MIG23` | Paar (HARD) |
| Vorlage (Late Activation, RED) | `TRN_BANDIT_TU22` | Bomber (HARD) |

**Route der Vorlagen (wichtig):** Wegpunkt 1 beliebig (wird beim Start durch die Spawn-Position ersetzt), **Wegpunkt 2 innerhalb von `TRN_INT_ZONE`**, Wegpunkt 3 auf der anderen Seite der Zone. ROE „Weapons free“. Ohne Route bleiben die Gegner stehen.

**Ablauf**
1. `Start EASY / MEDIUM / HARD`.
2. Die Gegner starten in zufälliger Richtung ca. 70 km vom Zonenmittelpunkt, in 4000–9000 m Höhe.
3. AWACS („Magic“) gibt alle 30 s **Bogey Dope**: BRAA, Höhe, hot/cold, Kontaktanzahl (Text plus Signalton).
4. „Splash one“ nach jeder zerstörten Gruppe, dann Abschluss und nächste Welle.

| Stufe | Gegner |
|-------|--------|
| EASY | 1 Kampfflugzeug (MiG-21) |
| MEDIUM | 1 Paar (MiG-29 oder Su-27) |
| HARD | 2 Gruppen aus den Paar-Vorlagen und 1 Bomber |

Zeitlimit je Runde: 25 min. Hinweis: Höhe und Peilungen erscheinen als Text auf dem Bildschirm. Sprachdateien enthalten nur feste Sätze, keine Zahlen.

### Zone 5 – JTAC gegen bewegliche Ziele (`scripts/50_jtac.lua`)

**Ziel:** Zusammenarbeit mit einem JTAC gegen fahrende Bodenziele. **Muster:** A-10C II, F/A-18C, F-16C, AH-64D.

| Objekt | Name | Hinweise |
|--------|------|----------|
| Vorlage (Late Activation, BLUE) | `TRN_JTAC` | ein Soldat oder Fahrzeug, wird für die Laser-Steuerung aus CTLD gebraucht |
| Triggerzone | `TRN_JTAC_POS` | Position des JTAC, erhöhter Punkt mit Sicht auf die Straße, Radius ca. 300 m |
| Triggerzone | `TRN_JTAC_IP` | Initial Point für die 9-Line |
| Triggerzone | `TRN_JTAC_START` | Startpunkt der Ziele (an einer **Straße**) |
| Triggerzone | `TRN_JTAC_END` | Endpunkt der Ziele (an einer **Straße**, ≥ 8 km von Start) |
| Vorlagen (Late Activation, RED) | `TRN_JTAC_TGT_1`, `_2`, `_3` | fahrende Ziele: Lkw, Schützenpanzer, gemischte Kolonne |
| Vorlage (Late Activation, RED) | `TRN_JTAC_ESC_1` | Begleitschutz (nur HARD): Flak-Panzer |

**Ablauf (F10-Menü)**
1. `Start EASY / MEDIUM / HARD`: JTAC und Ziele erscheinen, die Ziele fahren auf Straßen von Start nach Ende.
2. **`1 Check in`** – JTAC bestätigt.
3. **`2 Request 9-line`** – JTAC gibt die 9-Line: IP, Heading und Distanz IP→Ziel, Zielhöhe, Beschreibung, Position (MGRS), Markierung (Laser 1688, Rauch), Friendlies, Egress, Remarks.
4. **`3 In hot`** – JTAC lasert das Ziel (Laser-Code 1688), markiert mit Rauch und gibt die aktuelle Position durch.
5. **`4 Request BDA`** – Anzahl lebender Fahrzeuge.
6. Alle Ziele zerstört: automatisches BDA, danach neue Aufgabe.

Reihenfolge wird geprüft („Negative. Follow the sequence…“). Stirbt der JTAC, startet die Runde neu.

| Stufe | Ziele | Tempo |
|-------|-------|-------|
| EASY | eine Gruppe (Lkw) | 20 km/h |
| MEDIUM | Lkw oder gemischt | 35 km/h |
| HARD | Kolonne plus Begleitschutz | 50 km/h |

Zeitlimit je Runde: 40 min.

### Zone 6 – CTLD (`scripts/60_ctld.lua`)

**Ziel:** Kisten und Truppen transportieren, absetzen, aufbauen. **Muster:** CH-47F, Mi-8MTV2 (Transport), AH-64D (Begleitschutz).

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzonen | `TRN_CTLD_PICKUP_1`, `_2` | Lager für Truppen (Radius ca. 200 m) |
| Statische Objekte (BLUE) | `TRN_CTLD_LOGI_1`, `_2` | Logistik-Objekte (z. B. Zelt/Lager). **Kisten entstehen im Umkreis von 200 m um dieses Objekt.** |
| Triggerzonen | `TRN_CTLD_TASK_1`, `_2`, `_3` | Einsatzorte, Radius ca. 300–500 m, Platz für Landung und Aufbau |

**Ablauf**
1. `Start EASY / MEDIUM / HARD`: eine zufällige Aufgabe an einem zufälligen Einsatzort.
2. Nutze das CTLD-Menü im Hubschrauber (`F10 > CTLD`): Truppen laden, Kisten bestellen, Kisten transportieren, auspacken, FOB bauen.
3. Die Aufgabe ist erfüllt, wenn die passende CTLD-Aktion **durch deine Gruppe innerhalb des Einsatzorts** ausgeführt wird.
4. Ansage „Delivery confirmed“, nach 20 s neue Aufgabe.

| Stufe | Aufgabe | erfüllt bei CTLD-Aktion |
|-------|---------|-------------------------|
| EASY | Truppen liefern | Truppen absetzen (`dropped_troops`) |
| MEDIUM | Kisten liefern, Verteidigung aufbauen | Kisten auspacken (`unpack`) |
| HARD | Vorgeschobene Basis (FOB) bauen | FOB bauen (`fob`) |

`Repeat task` im Menü wiederholt die Aufgabe. Zeitlimit je Runde: 40 min. Von Spielern erzeugte CTLD-Einheiten (Kisten, Truppen, Fahrzeuge) werden von der Zone **nicht** aufgeräumt.

**Hinweis zur CTLD-Konfiguration:** `60_ctld.lua` überschreibt nach dem Laden von CTLD die Tabellen `ctld.pickupZones`, `ctld.dropOffZones`, `ctld.wpZones` und `ctld.logisticUnits`. CTLD liest diese Tabellen zur Laufzeit. Im Spiel prüfen (Kapitel 6).

---

## 5. Sounds

Alle Ansagen erscheinen **immer auch als Text**. Fehlt eine Sounddatei, ist die Mission trotzdem spielbar.

**Einbinden**
1. Mission im Editor speichern.
2. Die `.miz` mit einem ZIP-Programm öffnen (sie ist ein ZIP-Archiv).
3. Im Archiv einen **eigenen Ordner** `TRN Sounds/` anlegen und die `.ogg`-Dateien hineinkopieren. (Dateien direkt in `l10n/DEFAULT/` entfernt der Editor beim nächsten Speichern; eigene Ordner bleiben erhalten.)
4. Für Zone 2 zusätzlich den Ordner `Airboss Soundfiles/` aus dem [Moose-Soundpaket](https://github.com/FlightControl-Master/MOOSE_SOUND/releases) ins Archiv kopieren.
5. Nach jedem erneuten Speichern im Editor die Ordner prüfen.

Die Ordnernamen stehen in `00_config.lua` (`SOUND_FOLDER`, `AIRBOSS_SOUND_FOLDER`).

**Format:** `.ogg`, englisch, ruhig gesprochen. Ansagen dürfen nur den festen Text enthalten. Zahlen, Peilungen und Koordinaten kommen aus dem Skript als Bildschirmtext.

**Benötigte Dateien** (Ordner `TRN Sounds/`)

| Datei | Text |
|-------|------|
| `gen_welcome.ogg` | Welcome to the training range. Open the F10 menu, Training Zones, to select an exercise. |
| `gen_zone_busy.ogg` | Zone is busy with another flight. Try again later. |
| `gen_zone_stopped.ogg` | Exercise stopped. Zone cleaned up. |
| `gen_timeout.ogg` | Time expired. Exercise ended. |
| `ga_briefing.ogg` | Ground attack range is hot. Targets marked in the target area. Report when in. |
| `ga_hit.ogg` | Good hit. Target destroyed. |
| `ga_complete.ogg` | All targets destroyed. Range will reset shortly. |
| `sead_briefing.ogg` | Enemy air defence in the area. Suppress or destroy as briefed. |
| `sead_radar.ogg` | Threat radar detected. |
| `sead_launch.ogg` | Missile launch! Missile launch! |
| `sead_complete.ogg` | Objective complete. Air defence neutralized. |
| `int_briefing.ogg` | Hostile aircraft inbound. Intercept and identify. |
| `int_bogey_dope.ogg` | Bogey dope. |
| `int_splash.ogg` | Splash one. |
| `int_complete.ogg` | All hostile aircraft destroyed. New wave shortly. |
| `jtac_checkin.ogg` | Roger, checked in. Standby for nine-line. |
| `jtac_nineline.ogg` | Nine-line follows. Ready to copy. |
| `jtac_cleared_hot.ogg` | Cleared hot. Marking target. |
| `jtac_bda.ogg` | Good hits. Target destroyed. Standby for next tasking. |
| `jtac_negative.ogg` | Negative. Follow the sequence: check in, nine-line, in hot. |
| `ctld_briefing.ogg` | Logistics tasking received. |
| `ctld_complete.ogg` | Delivery confirmed. Well done. |

Die Zuordnung Ereignis → Datei → Text steht im Abschnitt `SOUNDS` von `00_config.lua`. Die Dauer (`dur`) dort dient dem Überlappungsschutz; passe sie an deine Aufnahmen an.

---

## 6. Prüfen

### Logik-Test ohne DCS

```
lua5.1 tests/mock_test.lua
```

Der Test ersetzt DCS, Moose, MIST und CTLD durch Attrappen und prüft: Laden der Skripte, Menüaufbau, alle sechs Zonen (Start, Auswertung, Auto-Restart, Aufräumen), Besetzt-Meldung, Setup-Fehler und Spieler-Ende. Erwartet wird `0 Fehler`.

### Checkliste im Spiel (Singleplayer und Multiplayer)

1. Mission starten. In `Saved Games\DCS\Logs\dcs.log` nach `TRN: Training mission v... ready (6 zones)` suchen. Kein `ERROR` von `TRN:`.
2. `F10 > Training Zones` ist vorhanden, Begrüßung erscheint.
3. Jede Zone einzeln: Start, Ziel/Gegner erscheinen, Ansagen, Abschluss, automatische neue Runde, Stop/Reset räumt auf.
4. Zone 2: Airboss antwortet (`F10 > Airboss`), TACAN und ICLS aktiv, Träger dreht in den Wind.
5. Zone 5: `Check in` → `9-line` → `In hot`: Laserpunkt und Rauch am Ziel.
6. Zone 6: Kisten am Logistik-Objekt bestellbar, Truppen im Lager ladbar, Aufgabe wird erkannt.
7. Multiplayer: zwei Gruppen, gleiche Zone gleichzeitig (zweite Gruppe hört „busy“), verschiedene Zonen parallel.
8. Alle Zonen parallel laufen lassen (Leistung beobachten).

---

## 7. Anpassen

- **Namen ändern:** nur in `scripts/00_config.lua` und im Mission Editor.
- **Neue Vorlage für Ziele:** Gruppe im Editor anlegen (Late Activation) und in `00_config.lua` zur `pool`-Liste der Stufe hinzufügen.
- **Schwierigkeit anpassen:** Abschnitt `levels` der jeweiligen Zone in `00_config.lua`.
- **Zeitlimits, Neustart-Verzögerung, Frequenzen:** ebenfalls `00_config.lua`.

## 8. Bekannte Grenzen und Annahmen

- Annahmen: „JTAG“ = JTAC, „F-14U“ = F-14B, „Hip“ = Mi-8MTV2.
- Kein Wetterwechsel per Skript möglich (DCS-Einschränkung).
- Keine Sprachsynthese: Sounds sind feste Sätze, dynamische Werte erscheinen als Text.
- SEAD-Erfolg = Such- und Feuerleitradare zerstört (Attribute `SAM SR` und `SAM TR`). Fehlt so ein Radar in der Vorlage, wird die Runde wie DEAD gewertet.
- Zone 2 nutzt den Airboss unverändert; dessen Verhalten und Menüs stammen von Moose.
- Die Bibliotheken in `libs/` sind unverändert und stehen unter ihren eigenen Lizenzen (MIST, Moose, CTLD).

## Quellen der Bibliotheken

- MIST: <https://github.com/mrSkortch/MissionScriptingTools>
- Moose: <https://github.com/FlightControl-Master/MOOSE_INCLUDE> (`Moose_Include_Static/Moose.lua`)
- CTLD: <https://github.com/ciribob/DCS-CTLD> (`CTLD.lua`, `CTLD-i18n.lua`)
