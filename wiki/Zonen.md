# Zonen im Detail

Alle Namen stehen in `scripts/00_config.lua` und können dort geändert werden. **Late Activation** = im Editor „Late Activation“ anhaken, damit die Vorlage nicht von selbst erscheint.

## Zone 1 – Bodenangriff (`scripts/10_ground_attack.lua`)

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

## Zone 2 – Carrier-Landung (`scripts/20_carrier.lua`)

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

## Zone 3 – SEAD/DEAD (`scripts/30_sead_dead.lua`)

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

## Zone 4 – Air Intercept (`scripts/40_intercept.lua`)

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

## Zone 5 – JTAC gegen bewegliche Ziele (`scripts/50_jtac.lua`)

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

## Zone 6 – CTLD (`scripts/60_ctld.lua`)

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

## Zone 7 – Zufällige CSAR-Einsätze (`scripts/70_csar.lua`)

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

## Zone 8 – Konvois und Flugverkehr (`scripts/80_ambient.lua`)

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
