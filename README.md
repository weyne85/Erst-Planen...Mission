# DCS Trainingsmission Kaukasus

Trainingsmission für **Digital Combat Simulator** mit sechs unabhängigen Übungszonen, zufälligen CSAR-Einsätzen und einer belebten Umgebung (Flugverkehr, Schiffe, Konvois), gebaut mit **Moose**, **MIST** und **CTLD**.
Läuft im Singleplayer und im Multiplayer. Alle Ansagen sind **englisch**. Sprache gibt es nur über die **Moose-Soundpakete** (Range und Airboss), alle anderen Ansagen erscheinen als Text.

| Zone | Übung | Technik |
|------|-------|---------|
| 1 | Bodenangriff | Moose `RANGE` (Bomben/Strafing, Stimme) + eigene dynamische Ziele |
| 2 | Carrier-Landung | Moose `AIRBOSS` |
| 3 | SEAD/DEAD | eigenes Skript |
| 4 | Air Intercept | eigenes Skript (AWACS-Ansagen) |
| 5 | JTAC gegen bewegliche Ziele | eigenes Skript + CTLD-JTAC (Laser) |
| 6 | CTLD (Lasttransport) | CTLD + eigene Aufgaben |
| 7 | Zufällige CSAR-Einsätze | Moose `CSAR` + Zeitsteuerung |
| 8 | Konvois und Flugverkehr | Moose `RAT`, eigene Konvoi-Steuerung |

> **Wichtig – was hier enthalten ist und was nicht**
> - Enthalten: alle Lua-Skripte, dieses Briefing, ein Logik-Test ohne DCS und die **fertige Mission** `mission/DCS_Training_Kaukasus.miz` (Kapitel 9).
> - Die `.miz` wurde **ohne DCS** mit `tools/build_miz.py` (pydcs) erzeugt. Sie ist strukturell geprüft (Archiv, Skripte, alle 44 Namen aus `00_config.lua`), aber **nicht in DCS getestet**.
> - **Alle Positionen sind Platzhalter.** Öffne die Mission im Mission Editor und prüfe sie nach Kapitel 9, bevor du sie benutzt.
> - Die Moose-Soundpakete `Range Soundfiles` und `Airboss Soundfiles` sind in der `.miz` enthalten (Kapitel 5). Eigene Sounds gibt es nicht.
> - Die Skripte sind im Spiel **noch nicht getestet**. Der Logik-Test (Kapitel 6) prüft nur den Ablauf mit Attrappen.

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
            40_intercept.lua  50_jtac.lua  60_ctld.lua
            70_csar.lua  80_ambient.lua  99_init.lua
tests/      mock_test.lua   (Logik-Test ohne DCS)
tools/      build_miz.py (erzeugt die .miz, Karten und Kneeboards)   briefing.py   plot_map.py   types_extra.py
mission/    DCS_Training_Kaukasus.miz   (fertige Mission, Kapitel 9)
            map/ (Karten, Objektliste)   kneeboard/ (Kneeboard-Seiten je Flugzeugtyp)
```

**Ladereihenfolge im Mission Editor** – ein Trigger, Typ `MISSION START`, ohne Bedingung, mit **17 Aktionen `DO SCRIPT FILE`** in genau dieser Reihenfolge:

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
15. `scripts/70_csar.lua`
16. `scripts/80_ambient.lua`
17. `scripts/99_init.lua`

`99_init.lua` muss zuletzt laufen.

**Zuständigkeiten**

| Datei | Inhalt |
|-------|--------|
| `00_config.lua` | **Alle** Namen (Zonen, Gruppen, Units), Frequenzen, TACAN, Schwierigkeitsstufen, Zeiten, Ansage-Texte. Umbenennungen in der Mission erfordern nur Änderungen hier. |
| `01_core.lua` | Hilfsfunktionen (Timer, Peilung, MGRS, Spawn), Zonen-Verwaltung (Sessions, Timeout, Aufräumen). |
| `02_audio.lua` | Einzige Stelle für Textansagen. Sendet nur an die betroffene Gruppe, reiht Ansagen hintereinander ein (kein Überlappen). |
| `03_menu.lua` | F10-Menü pro Spielergruppe, automatisch für neue Spieler und nach Respawn. |
| `10`–`60` | Je eine Zone, eigenständig. |
| `70_csar.lua` | Zufällige CSAR-Einsätze (Moose `CSAR`). |
| `80_ambient.lua` | KI-Flugverkehr (Moose `RAT`) und Konvois. |
| `99_init.lua` | Prüft Abhängigkeiten, startet Range, Carrier, CTLD, CSAR, Flugverkehr, Konvois und Menü. |

---

## 3. Mission-Grundeinstellungen

- **Karte:** Kaukasus.
- **Wetter:** klar, kein Nebel, leichter Wind (≤ 5 m/s), feste Tageszeit am Tag (Case I).
- **Koalitionen:** Spieler und Carrier = **BLUE**. Alle Ziele, SAMs und Gegner = **RED**.
- **Länder:** Wähle für BLUE Länder, für die im Editor alle Muster verfügbar sind. Prüfe die Verfügbarkeit von Mi-8MTV2 und AH-64D im Editor.
- **Zonen-Abstand:** Halte zwischen den Zonen möglichst viel Abstand, damit SAM-Bedrohung und Ansagen anderer Zonen nicht stören. Die SEAD-Zone liegt bewusst nur ca. 30 nm östlich von Kutaisi (nahe Zone 5 und 1); die SAM-Systeme haben höchstens ca. 32 km Reichweite (SA-11) und erreichen die anderen Zonen nicht. Zone 5 (JTAC) und Zone 1 (Bodenangriff) dürfen nicht überlappen.
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

**Ziel:** Waffeneinsatz gegen Bodenziele. **Muster:** A-10C II, F/A-18C, F-16C, AH-64D. Die Zone hat zwei Teile.

**Teil A – Bomben- und Strafing-Range (Moose `RANGE`, feste Ziele, mit Sprache)**

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzone | `TRN_RANGE_ZONE` | Range-Bereich, Radius ca. 5 km. Bomben außerhalb werden nicht gewertet. |
| Bombenziele (Units oder statische Objekte) | `TRN_RANGE_BOMB_1`, `_2`, `_3` | z. B. Fahrzeuge, Kreise aus statischen Objekten. Trefferradius 25 m. |
| Strafing-Ziel (Unit oder statisches Objekt) | `TRN_RANGE_STRAFE_1` | Der Anflug-Kasten (3000 m × 300 m) folgt der im Editor gesetzten Ausrichtung des Ziels. |

- Range Control 256.0 MHz, Instructor 257.0 MHz (änderbar in `00_config.lua`; Marshal des Trägers 305.0 MHz).
- Bedienung und Bewertung über das eigene F10-Menü **`F10 > On the Range`** (Ergebnisse, Smoke, Hilfe). Die Stimme kommt aus den **Range Soundfiles** (Kapitel 5).

**Teil B – dynamische Ziele (eigenes Skript, Text-Ansagen)**

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzone | `TRN_GA_ZONE` | Zielgebiet, Radius ca. 3 km, freies Gelände |
| Vorlagen (Late Activation, RED) | `TRN_GA_VEH_1`, `_2`, `_3` | Lkw / leichte Fahrzeuge, je 2–4 Einheiten |
| Vorlagen (Late Activation, RED) | `TRN_GA_ARM_1`, `_2` | Panzer / Schützenpanzer, je 2–3 Einheiten |
| Vorlage (Late Activation, RED) | `TRN_GA_AAA_1` | Flak (nur HARD) |
| Vorlage (Late Activation, RED) | `TRN_GA_SHORAD_1` | kurzreichweitige Luftabwehr (nur HARD) |

**Ablauf Teil B**
1. `F10 > Training Zones > 1 Ground Attack > Start EASY / MEDIUM / HARD`.
2. Ansage mit Ziel-Positionen (MGRS) und Typ.
3. Treffer werden je zerstörter Zielgruppe angesagt („Targets remaining“).
4. Alle Ziele zerstört: Abschlussmeldung mit Zeit, nach 20 s neue Runde.

| Stufe | Ziele | Verteidiger |
|-------|-------|-------------|
| EASY | 2 (nur Lkw) | keine |
| MEDIUM | 3 (Lkw und Panzer) | keine |
| HARD | 4 | Flak und SHORAD |

Zeitlimit je Runde: 30 min. Die Range (Teil A) läuft dauerhaft und braucht keinen Start.

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
- **Sounds:** Airboss braucht das Moose-Paket `Airboss Soundfiles` (Kapitel 5).

### Zone 3 – SEAD/DEAD (`scripts/30_sead_dead.lua`)

**Ziel:** SAM-Systeme unterdrücken (SEAD) oder zerstören (DEAD). **Muster:** F/A-18C, F-16C.

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzone | `TRN_SEAD_ZONE` | Bereich, in dem die SAM-Stellung entsteht, Radius ca. 3 km |
| Vorlagen (Late Activation, RED) | `TRN_SAM_SA2`, `TRN_SAM_SA3` | EASY |
| Vorlagen (Late Activation, RED) | `TRN_SAM_SA6`, `TRN_SAM_SA11` | MEDIUM |
| Vorlage (Late Activation, RED) | `TRN_SAM_SA8` | HARD (SA-8 Osa, kurze Reichweite, 3 Fahrzeuge mit eigenem Radar) |
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
3. AWACS („Magic“) gibt alle 30 s **Bogey Dope**: BRAA, Höhe, hot/cold, Kontaktanzahl (als Text).
4. „Splash one“ nach jeder zerstörten Gruppe, dann Abschluss und nächste Welle.

| Stufe | Gegner |
|-------|--------|
| EASY | 1 Kampfflugzeug (MiG-21) |
| MEDIUM | 1 Paar (MiG-29 oder Su-27) |
| HARD | 2 Gruppen aus den Paar-Vorlagen und 1 Bomber |

Zeitlimit je Runde: 25 min. Hinweis: Alle Ansagen dieser Zone erscheinen als Text auf dem Bildschirm.

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

### Zone 7 – Zufällige CSAR-Einsätze (`scripts/70_csar.lua`)

**Ziel:** Abgestürzte Piloten finden, aufnehmen und zu einer Sanitätsstation bringen. **Muster:** CH-47F, Mi-8MT, AH-64D (nur Hubschrauber).

| Objekt | Name | Hinweise |
|--------|------|----------|
| Vorlage (Late Activation, BLUE) | `TRN_CSAR_PILOT` | ein Infanterist, wird von Moose als abgestürzter Pilot erzeugt |
| Triggerzonen | `TRN_CSAR_1` bis `_4` | mögliche Absturzgebiete, Radius ca. 2,5 km, Gelände begehbar, nicht im Wasser |
| Triggerzone | `TRN_MASH_1` | Sanitätsstation (MASH) bei der Hubschrauberbasis, Radius ca. 300 m. Der Namensanfang `TRN_MASH` gilt für alle MASH-Zonen. |
| Datei im Archiv | `beacon.ogg` in `l10n/DEFAULT/` | Funkfeuer-Ton (aus MOOSE_SOUND „CTLD CSAR“) |

**Ablauf**
1. Alle 15–30 min (Zufall) stürzt ein Pilot in einer zufälligen Zone ab, aber nur, wenn mindestens ein Rettungshubschrauber (Spieler) da ist. Das erste Mal nach 4–10 min.
2. Moose meldet „MAYDAY“ mit Funkfrequenz. Das Menü **`F10 > CSAR`** (von Moose) bietet „List Active CSAR“, Rauch, Leuchtkugel, „Check Onboard“ und „Smoke Closest MASH“.
3. Lande in der Nähe oder schwebe über dem Piloten, bis er einsteigt. Bringe ihn zu `TRN_MASH_1` oder auf einen Flugplatz (Radius ca. 500 m).
4. Meldung „Pilot rescued“. Wird er nicht in 45 min erreicht, verfällt der Einsatz.
5. Nur ein offener Einsatz gleichzeitig. **`F10 > Training Zones > 7 CSAR > Request CSAR mission now`** löst auf Wunsch sofort einen aus.
6. Wirft sich ein Spieler aus dem Flugzeug, entsteht automatisch ein Einsatz (Moose-Standard).

### Zone 8 – Konvois und Flugverkehr (`scripts/80_ambient.lua`)

**Ziel:** Die Mission wirkt belebt. Keine Spieler-Aufgabe, aber Ziele der Gelegenheit.

| Objekt | Name | Hinweise |
|--------|------|----------|
| Triggerzonen | `TRN_CONV_A`, `_B`, `_C`, `_D` | Endpunkte freundlicher Konvois (nahe Senaki, Kutaisi, Kobuleti, Batumi), Radius ca. 800 m, **an Straßen** |
| Triggerzonen | `TRN_CONV_RED_A`, `_B` | Endpunkte feindlicher Konvois (nahe Beslan und Nalchik), **an Straßen** |
| Vorlagen (Late Activation, BLUE) | `TRN_CONVOY_BLUE_1`, `_2` | Nachschub: Hummer, Lkw, Tanklaster, Stryker |
| Vorlagen (Late Activation, RED) | `TRN_CONVOY_RED_1`, `_2` | feindliche Kolonne: Schützenpanzer, Lkw, Flak |
| Vorlagen (Late Activation, BLUE) | `TRN_RAT_C130`, `TRN_RAT_AN26` | KI-Transporter für den Flugverkehr (Moose `RAT`) |

**Ablauf**
- **Flugverkehr (Moose RAT):** Zwei C-130 und eine An-26 fliegen zufällig zwischen Kobuleti, Senaki-Kolkhi, Kutaisi und Batumi. Sie starten von der Piste (kein Parkplatz-Konflikt mit Spielern), landen und werden danach ersetzt. Funkmeldungen an Spieler sind abgeschaltet.
- **Konvois:**
  - Freundliche Konvois (max. 2 gleichzeitig) fahren alle 7–15 min auf Straßen zwischen den BLUE-Zonen.
  - Ein feindlicher Konvoi (max. 1) erscheint alle 15–25 min. Alle Spieler erhalten eine **INTEL**-Meldung mit Start- und Zielposition (MGRS). Wird er zerstört, gibt es eine Meldung.
  - Konvois starten nur, solange ein Spieler da ist. Sie verschwinden bei Ankunft oder nach 30 bzw. 40 min.
  - **`F10 > Training Zones > 8 Convoys and Traffic > Report hostile convoys`** nennt die aktuelle Position.
- **In der `.miz` (ohne Skript):** Handelsschiffe pendeln im Schwarzen Meer (`TRN_SHIP_CARGO_1`, `_2`, `TRN_SHIP_TANKER_1`), zwei Fregatten (`TRN_ESCORT_1`, `_2`) begleiten den Träger, und auf den Flugplätzen Kutaisi und Batumi stehen Flugzeuge (A-10C, F-16C, F/A-18C, C-130) und Bodenfahrzeuge als Kulisse.

---

## 5. Sounds (nur Moose-Soundpakete)

Es werden **keine eigenen Sounddateien** verwendet. Sprache gibt es nur dort, wo Moose sie mitbringt:

| Zone | Paket | Ordner in der `.miz` | Quelle |
|------|-------|----------------------|--------|
| 1 (Range) | Range Soundfiles | `Range Soundfiles/` | [MOOSE_SOUND Releases](https://github.com/FlightControl-Master/MOOSE_SOUND/releases) |
| 2 (Carrier) | Airboss Soundfiles | `Airboss Soundfiles/` | [MOOSE_SOUND Releases](https://github.com/FlightControl-Master/MOOSE_SOUND/releases) |
| 7 (CSAR) | Funkfeuer `beacon.ogg` | `l10n/DEFAULT/beacon.ogg` | aus MOOSE_SOUND „CTLD CSAR“ |
| 3–6, 8 | – | – | Ansagen erscheinen als **Text** (auf Englisch) |

**In der mitgelieferten `.miz` sind beide Ordner bereits enthalten.** Nur wenn du die Mission im Editor selbst neu baust (Kapitel 10), musst du sie von Hand einbinden:

1. Mission im Editor speichern.
2. Die `.miz` mit einem ZIP-Programm öffnen (sie ist ein ZIP-Archiv).
3. Die Ordner `Range Soundfiles/` und `Airboss Soundfiles/` aus dem Moose-Soundpaket unverändert ins Archiv kopieren (eigene Ordner überstehen das erneute Speichern im Editor, Dateien direkt in `l10n/DEFAULT/` nicht).
4. Nach jedem erneuten Speichern im Editor prüfen, dass die Ordner noch vorhanden sind.

Die Ordnernamen stehen in `00_config.lua` (`RANGE_SOUND_FOLDER`, `AIRBOSS_SOUND_FOLDER`). Wenn du die Ordner anders nennst, passe sie dort an.

Ohne die Pakete läuft die Mission weiter; Range und Airboss senden dann nur Text. Alle Texte der Zonen 3–6 (Briefing, Warnungen, BRAA, 9-Line) stehen im Abschnitt `MESSAGES` von `00_config.lua`.

---

## 6. Prüfen

### Logik-Test ohne DCS

```
lua5.1 tests/mock_test.lua
```

Der Test ersetzt DCS, Moose, MIST und CTLD durch Attrappen und prüft: Laden der Skripte, Range- und Airboss-Konfiguration, Menüaufbau, alle sechs Übungszonen (Start, Auswertung, Auto-Restart, Aufräumen), Besetzt-Meldung, Setup-Fehler und Spieler-Ende sowie CSAR (zufällige Einsätze, Verfall, Anforderung), Flugverkehr und Konvois. Erwartet wird `0 Fehler`.

### Checkliste im Spiel (Singleplayer und Multiplayer)

1. Mission starten. In `Saved Games\DCS\Logs\dcs.log` nach `TRN: Training mission v... ready (8 zones)` suchen. Kein `ERROR` von `TRN:`.
2. `F10 > Training Zones` ist vorhanden, Begrüßung erscheint.
3. Zone 1: `F10 > On the Range` vorhanden, Range-Control-Stimme und Trefferbewertung bei Bombe und Strafing. Danach jede Zone einzeln: Start, Ziel/Gegner erscheinen, Ansagen, Abschluss, automatische neue Runde, Stop/Reset räumt auf.
4. Zone 2: Airboss antwortet (`F10 > Airboss`), TACAN und ICLS aktiv, Träger dreht in den Wind. Fehlt das Menü: in `dcs.log` nach `TRN: Airboss started on TRN_CARRIER` und `Airboss menu ensured` suchen (fehlt die erste Zeile, steht davor ein `TRN:`-Fehler; fehlt nur die zweite, ist das Flugzeug nicht trägerfähig oder nicht BLUE). Moose AIRBOSS und RANGE legen ihr F10-Menü nur beim Einsteigen an; für Spieler, die beim Start schon im Flugzeug sitzen, holt `03_menu.lua` das nach.
5. Zone 5: `Check in` → `9-line` → `In hot`: Laserpunkt und Rauch am Ziel.
6. Zone 6: Kisten am Logistik-Objekt bestellbar, Truppen im Lager ladbar, Aufgabe wird erkannt.
7. Multiplayer: zwei Gruppen, gleiche Zone gleichzeitig (zweite Gruppe hört „busy“), verschiedene Zonen parallel.
8. Zone 7: Mit einem Hubschrauber startet nach spätestens 15 min ein CSAR-Einsatz (`F10 > CSAR`), Rettung an `TRN_MASH_1`. Prüfe `TRN: CSAR started` in `dcs.log`.
9. Zone 8: Flugverkehr auf den Pisten, Konvois auf den Straßen (kommen nach 1–3 min), INTEL-Meldung zum Feindkonvoi.
10. Alle Zonen parallel laufen lassen (Leistung beobachten).

---

## 7. Anpassen

- **Namen ändern:** nur in `scripts/00_config.lua` und im Mission Editor.
- **Neue Vorlage für Ziele:** Gruppe im Editor anlegen (Late Activation) und in `00_config.lua` zur `pool`-Liste der Stufe hinzufügen.
- **Schwierigkeit anpassen:** Abschnitt `levels` der jeweiligen Zone in `00_config.lua`.
- **Zeitlimits, Neustart-Verzögerung, Frequenzen:** ebenfalls `00_config.lua`.

## 8. Bekannte Grenzen und Annahmen

- Annahmen: „JTAG“ = JTAC, „F-14U“ = F-14B, „Hip“ = Mi-8MTV2.
- Kein Wetterwechsel per Skript möglich (DCS-Einschränkung).
- Keine eigenen Sounds und keine Sprachsynthese: Sprache kommt nur von Moose RANGE und AIRBOSS, alles andere ist Text.
- SEAD-Erfolg = Such- und Feuerleitradare zerstört (Attribute `SAM SR` und `SAM TR`). Fehlt so ein Radar in der Vorlage, wird die Runde wie DEAD gewertet. Das gilt auch für die SA-8 (HARD), falls DCS ihr Radar nicht unter diesen Attributen führt; dann ist SEAD dort gleich DEAD (alle drei Fahrzeuge zerstören).
- Zone 1 (Range) und Zone 2 (Airboss) nutzen die Moose-Klassen unverändert; deren Verhalten, Menüs und Sounds stammen von Moose. Die Range-Ziele sind fest und werden nicht zufällig gewählt.
- Die Bibliotheken in `libs/` sind unverändert und stehen unter ihren eigenen Lizenzen (MIST, Moose, CTLD). Die Sounds stammen aus MOOSE_SOUND (GPL-3.0).

---

## 9. Fertige Mission (`mission/DCS_Training_Kaukasus.miz`)

**Benutzen:** Datei nach `Saved Games\DCS\Missions\` kopieren, im Mission Editor öffnen, **Positionen prüfen** (unten), speichern, starten.

**Was drin ist**
- Trigger „MISSION START“ mit den 17 `DO SCRIPT FILE`-Aktionen in der richtigen Reihenfolge, Skripte im Archiv.
- Alle Triggerzonen, Vorlagegruppen (Late Activation), Range-Ziele, Träger mit Route, CTLD-Logistik-Objekte, JTAC-Vorlage.
- Spieler-Slots (Client, BLUE/USA): je 2× F/A-18C, F-16C, A-10C II, F-14B (Kobuleti) sowie CH-47F, Mi-8MT, AH-64D (Senaki-Kolkhi).
- Zone 7: Absturz- und MASH-Zonen, Pilotenvorlage; Zone 8: Konvoi-Zonen, Konvoi- und Flugverkehr-Vorlagen.
- Belebung ohne Skript: Handelsschiffe mit Pendelroute, Begleitfregatten, parkende Flugzeuge und Fahrzeuge in Kutaisi und Batumi.
- Die Flugplätze Kobuleti, Senaki-Kolkhi, Batumi und Kutaisi gehören BLUE.
- Wetter fest und klar, 21.06.2024, 10:00 Uhr.
- Ordner `Range Soundfiles/` (44 Dateien) und `Airboss Soundfiles/` (110 Dateien) aus MOOSE_SOUND (GPL-3.0).
- Beim Bau prüft das Werkzeug, dass **alle 44** `TRN_`-Namen aus `00_config.lua` in der Mission vorkommen.

**Platzhalter-Positionen** (DCS-Koordinaten, x = Nord, y = Ost; Werte in `tools/build_miz.py`)

| Zone | Ort (ungefähr) | Prüfen im Editor |
|------|----------------|------------------|
| Range `TRN_RANGE_ZONE` | NNO von Senaki-Kolkhi | flaches Gelände, keine Siedlung; Strafing-Ziel `TRN_RANGE_STRAFE_1` hat freien Anflug (Kasten 3000 m × 300 m) |
| Bodenangriff `TRN_GA_ZONE` | zwischen Senaki und Kutaisi, nordöstlich | freies Gelände, ≥ 15 km von der Range |
| SEAD `TRN_SEAD_ZONE` | ca. 30 nm (56 km) östlich von Kutaisi | flaches Gelände, Radius 3 km. Die SAM-Reichweiten (höchstens ca. 32 km) erreichen die anderen Zonen nicht |
| Intercept `TRN_INT_ZONE` | Schwarzes Meer westlich von Sukhumi | über Wasser |
| Carrier `TRN_CARRIER` | Schwarzes Meer, ca. 45 nm vor der Küste, Route ca. 36 nm | über Wasser, keine Küste im Bereich der Route |
| JTAC | Straße zwischen Senaki und Kutaisi | `TRN_JTAC_START` und `TRN_JTAC_END` **auf einer Straße**, `TRN_JTAC_POS` erhöht mit Sicht auf die Straße |
| CTLD-Lager | bei Senaki-Kolkhi | Zonen und Logistik-Zelte auf ebenem Boden |
| CTLD-Einsatzorte | 10–25 nm von Senaki | Landefläche in jeder Zone |
| CSAR-Zonen `TRN_CSAR_1` bis `_4` | 15–30 km um Senaki und Kutaisi | begehbares Gelände, nicht im Wasser oder Steilhang; `TRN_MASH_1` bei der Hubschrauberbasis |
| Konvoi-Zonen `TRN_CONV_A` bis `_D` | neben den Flugplätzen Senaki, Kutaisi, Kobuleti, Batumi | **an einer Straße**, die die Zonen verbindet |
| Feindkonvoi `TRN_CONV_RED_A`, `_B` | bei Beslan und Nalchik | **an der Straße** zwischen beiden Orten |
| Schiffsrouten (`TRN_SHIP_*`) | Schwarzes Meer, 40+ nm vor der Küste | alle Wegpunkte im offenen Wasser |

Wenn eine Zone im Gebirge oder im Wasser liegt, verschiebe sie im Editor. Die Namen dürfen sich nicht ändern.

**Bekannte Punkte der `.miz`**
- Der CH-47F ist in pydcs 0.15 nicht enthalten. Er wurde mit der Typ-ID `CH-47Fbl1` (die ID, die auch CTLD verwendet) selbst definiert, mit Startsprit 2500 kg. Prüfe im Editor, dass die Slots als „CH-47F“ erscheinen.
- Der Träger ist der **Stennis (CVN-74)** und braucht das Supercarrier-Modul.
- Parkende Flugzeuge in Kutaisi und Batumi sind Statics (pydcs-Typen). Prüfe im Editor, dass sie sichtbar auf den Stellplätzen stehen.
- Der KI-Flugverkehr (RAT) kann Pisten kurz belegen; mit `rat.enabled = false` in `00_config.lua` abschaltbar.
- Das Werkzeug setzt für alle Slots leere Bewaffnung; wähle Beladung im Editor.
- Alle Spieler-Slots gehören zu BLUE/USA. Prüfe im Editor, ob alle Muster dort auswählbar sind.
- Die Länder-Zuordnung der Flugzeuge wird von DCS beim Laden nicht geprüft; Fehler zeigen sich erst im Editor oder Spiel.

**Briefing, Kneeboards und Flugpläne (in der `.miz`)**
- **Briefing** (Mission Editor: Briefing): Lage, alle Zonen mit MGRS, Frequenzen, Navigation; dazu zwei Karten als Bilder.
- **Flugpläne:** Jeder Client-Slot hat Wegpunkte für seine Zonen und Aufgaben (Name, Höhe, Geschwindigkeit), danach die Landung am Startflugplatz. Alle Punkte sind optional.

| Typ | Wegpunkte |
|-----|-----------|
| F/A-18C | RANGE IP, RANGE, GA ZONE, JTAC IP, JTAC, SEAD IP, SEAD ZONE, INT ZONE, CARRIER |
| F-16C | wie F/A-18C ohne CARRIER |
| A-10C II | RANGE IP, RANGE, GA ZONE, JTAC IP, JTAC |
| F-14B | INT ZONE, CARRIER |
| AH-64D | JTAC IP, JTAC, GA ZONE, RANGE, TASK 1 bis 3 |
| CH-47F, Mi-8MT | PICKUP 1, TASK 1, PICKUP 2, TASK 2, TASK 3, MASH, CSAR 1 bis 4 |

- **Kneeboards** (je Flugzeugtyp, 5–9 Seiten, `mission/kneeboard/<Typ>_*.png`, im Spiel über das Kneeboard-Menü): Frequenzen, Zonen mit MGRS und Breite/Länge, Wegpunkt-Tabelle, Verfahren der Zonen, Karten.
- **Frequenzen** kommen aus `00_config.lua`: Marshal 305.0 AM, LSO 264.0 AM, Range Control 256.0 AM, Instructor 257.0 AM, Träger-TACAN 74X STN, ICLS 1, JTAC-Laser 1688 (CTLD-Funk 40.40 FM), Flugplatz-ATC aus den DCS-Daten (UHF/VHF). **Nicht enthalten:** TACAN/ILS der Flugplätze, weil die Datenquelle sie nicht liefert. AWACS und JTAC sprechen nur als Bildschirmtext.
- Kneeboard-Karten zeigen nur Zonen und Flugplätze (kein Gelände). Die Positionen bleiben Platzhalter.

**Karten und Objektliste:** `mission/map/` enthält fünf Übersichtskarten (`01_uebersicht.png` bis `05_nord_konvoi.png`) und `objekte.md` (alle Namen mit Typ, Koalition, Position und Breite/Länge). Neu erzeugen mit `python3 tools/plot_map.py` (`pip install pydcs matplotlib adjustText`). Es gibt keinen Gelände-Hintergrund; nur die Flugplätze dienen zur Orientierung.

**Neu bauen** (z. B. nach Änderungen an Skripten, Namen oder Positionen; die Skripte, Karten und Kneeboards werden dabei neu erzeugt und in die `.miz` gepackt):

```
pip install pydcs matplotlib adjustText mgrs pillow
# außerdem wird lua5.1 benötigt (liest 00_config.lua)
git clone --depth 1 https://github.com/FlightControl-Master/MOOSE_SOUND
python3 tools/build_miz.py --sounds-dir MOOSE_SOUND
```

Ohne `--sounds-dir` entsteht die Mission ohne Soundordner. Positionen und Typen stehen am Anfang von `tools/build_miz.py`.

---

## 10. Bau-Checkliste für den Mission Editor

Für alle, die die Mission selbst im Editor aufbauen oder erweitern wollen. Die Namen sind exakt so zu schreiben (Groß-/Kleinschreibung beachten). Die Details je Zone stehen in Kapitel 4.

1. **Neue Mission**, Karte Kaukasus. Koalitionen: **BLUE = USA**, **RED = Russland**.
2. **Wetter/Zeit:** klar, Wind ≤ 5 m/s, Tageszeit am Tag, keine Wolken/Nebel.
3. **Triggerzonen** anlegen (Rechtsklick > Trigger Zone):

   | Name | Radius |
   |------|--------|
   | `TRN_RANGE_ZONE` | 4500 m |
   | `TRN_GA_ZONE` | 3000 m |
   | `TRN_SEAD_ZONE` | 3000 m |
   | `TRN_INT_ZONE` | 20000 m |
   | `TRN_JTAC_POS` | 300 m |
   | `TRN_JTAC_IP` | 500 m |
   | `TRN_JTAC_START` (Straße) | 500 m |
   | `TRN_JTAC_END` (Straße) | 500 m |
   | `TRN_CTLD_PICKUP_1`, `_2` | 200 m |
   | `TRN_CSAR_1` bis `_4` | 2500 m |
   | `TRN_MASH_1` | 300 m |
   | `TRN_CONV_A` bis `_D`, `TRN_CONV_RED_A`, `_B` (Straße) | 800 m |
   | `TRN_CTLD_TASK_1`, `_2`, `_3` | 400 m |

4. **Range-Ziele** (RED, Fahrzeuge oder statische Objekte; hier ist der **Unit-Name** wichtig): Units `TRN_RANGE_BOMB_1`, `_2`, `_3` und `TRN_RANGE_STRAFE_1` in der Range-Zone. Ausrichtung des Strafing-Ziels = Anflugrichtung.
5. **Vorlagegruppen** (Haken bei **Late Activation**; hier ist der **Gruppen-Name** wichtig):
   - Zone 1 (RED): `TRN_GA_VEH_1`, `_2`, `_3`, `TRN_GA_ARM_1`, `_2`, `TRN_GA_AAA_1`, `TRN_GA_SHORAD_1`
   - Zone 3 (RED, je komplettes System): `TRN_SAM_SA2`, `TRN_SAM_SA3`, `TRN_SAM_SA6`, `TRN_SAM_SA11`, `TRN_SAM_SA8`, `TRN_SAM_SA15`, `TRN_SAM_ZSU23`
   - Zone 4 (RED, Luftgruppen): `TRN_BANDIT_MIG21` (1), `TRN_BANDIT_MIG29` (2), `TRN_BANDIT_SU27` (2), `TRN_BANDIT_MIG23` (2), `TRN_BANDIT_TU22` (1). Route: Wegpunkt 1 beliebig, **Wegpunkt 2 in `TRN_INT_ZONE`**, Wegpunkt 3 dahinter. ROE „Weapons free“.
   - Zone 5: `TRN_JTAC` (**BLUE**), `TRN_JTAC_TGT_1`, `_2`, `_3`, `TRN_JTAC_ESC_1` (RED)
   - Zone 7: `TRN_CSAR_PILOT` (**BLUE**, ein Infanterist)
   - Zone 8: `TRN_CONVOY_BLUE_1`, `_2` (BLUE), `TRN_CONVOY_RED_1`, `_2` (RED), `TRN_RAT_C130`, `TRN_RAT_AN26` (BLUE, Flugzeuge, je eine Route mit mindestens 2 Wegpunkten)
6. **Träger:** Schiffsgruppe (BLUE) mit einer Unit **`TRN_CARRIER`** (Stennis). Route mit mindestens 2 weit entfernten Wegpunkten im offenen Meer (Schleife), ca. 10 kn.
7. **CTLD-Logistik:** zwei statische Objekte (BLUE, z. B. FARP-Zelt) mit den Namen `TRN_CTLD_LOGI_1` und `TRN_CTLD_LOGI_2`, je in einer Pickup-Zone.
8. **Spieler-Slots** (Client, BLUE): F/A-18C, F-16C, A-10C II, F-14B, CH-47F, Mi-8MTV2, AH-64D (Kapitel 3).
9. **Belebung (optional):** Handelsschiffe mit Pendelroute (Wegpunkt-Befehl „Switch waypoint“ am letzten Punkt auf Punkt 1), Begleitfregatten, parkende Flugzeuge und Fahrzeuge auf den Flugplätzen. Setze die Flugplätze Kobuleti, Senaki-Kolkhi, Batumi und Kutaisi auf BLUE.
10. **Trigger:** Typ **MISSION START**, keine Bedingung, 17× Aktion **DO SCRIPT FILE** in der Reihenfolge aus Kapitel 2 (`99_init.lua` zuletzt).
11. **Sounds:** Ordner `Range Soundfiles/` und `Airboss Soundfiles/` ins Archiv der `.miz` kopieren, `beacon.ogg` nach `l10n/DEFAULT/` (Kapitel 5). Damit der Editor `beacon.ogg` nicht entfernt, braucht es einen Trigger, der die Datei verwendet (z. B. „Sound to All“ mit einer nie wahren Bedingung).
12. **Briefing, Wegpunkte, Kneeboards (optional):** Briefing-Text im Editor (Briefing), Wegpunkte je Client-Slot wie in Kapitel 9, Kneeboard-Seiten aus `mission/kneeboard/` ins Archiv unter `KNEEBOARD/<Typ-ID>/IMAGES/` (z. B. `KNEEBOARD/FA-18C_hornet/IMAGES/`).
13. **Speichern** und mit Kapitel 6 prüfen.

---

## Quellen der Bibliotheken

- MIST: <https://github.com/mrSkortch/MissionScriptingTools>
- Moose: <https://github.com/FlightControl-Master/MOOSE_INCLUDE> (`Moose_Include_Static/Moose.lua`)
- CTLD: <https://github.com/ciribob/DCS-CTLD> (`CTLD.lua`, `CTLD-i18n.lua`)
