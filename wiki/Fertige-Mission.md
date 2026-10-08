# Fertige Mission (.miz)

**Benutzen:** Datei nach `Saved Games\DCS\Missions\` kopieren, im Mission Editor öffnen, **Positionen prüfen** (unten), speichern, starten.

**Was drin ist**
- Trigger „MISSION START“ mit den 18 `DO SCRIPT FILE`-Aktionen in der richtigen Reihenfolge, Skripte im Archiv.
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
