# Kaukasus Allround Training

Trainingsmission für **DCS World** auf der Karte **Kaukasus**, gebaut nur mit **Moose** (keine MiST, kein ciribob-CTLD).
Sie verbindet **Trainingsszenarien auf Abruf** (F10-Menü) mit einer **endlosen Boden-Kampagne** zwischen Senaki (BLAU) und Sukhumi (ROT).
Läuft im Singleplayer und mit kleinen Gruppen (2–8 Spieler). In-Game-Texte sind **englisch**, Sprache gibt es nur über die Moose-Soundpakete (kein SRS).

> **Wichtig – Stand dieser Mission**
> - Geliefert werden nur **Skripte + diese Bauanleitung**. Die `.miz` baust du selbst im Mission Editor (Kapitel 5–7).
> - Alle Orte sind **Vorschläge**. Prüfe Gelände, Abstände und Straßen im Editor.
> - Die Skripte sind **nicht in DCS getestet**. Geprüft sind Syntax, Lint und ein Logik-Test mit Attrappen (Kapitel 10).
> - Alle Moose-Aufrufe wurden im Quelltext von Moose 2.9.18 nachgeschlagen. Offene Punkte stehen in Kapitel 12.
> - Fehlende Editor-Objekte meldet die Mission beim Start (Startbericht nach 10 s, Details in `dcs.log`, Zeilen `[KA] Missing ...`).

---

## Inhalt

1. Überblick und Moose-Module
2. Versionen
3. Dateien und Ladereihenfolge
4. Sounds (manuell einbauen)
5. Mission-Grundeinstellungen und Spieler-Slots
6. Frequenzen, TACAN, Lasercodes
7. Szenarien und Editor-Objekte
8. Kampagne
9. Umgebung
10. Prüfen
11. Bewusst nicht verwendete Module
12. Offene Punkte (TODO: verifizieren)

---

## 1. Überblick und Moose-Module

| Teil | Wer | Moose-Module |
|------|-----|--------------|
| Bomben/Strafing-Range | immer offen | `RANGE`, `RADIOQUEUE` (intern) |
| CAS mit JTAC-Drohne | 1 Gruppe | `AUTOLASE`, `SUPPRESSION`, `ARMYGROUP`, `FLIGHTGROUP`, `AUFTRAG` (PATROLZONE, ORBIT), `SPAWN` |
| SEAD/DEAD gegen IADS | 1 Gruppe | `MANTIS` (nutzt `SEAD` intern), `SHORAD`, `SPAWN` |
| Strike (feste Ziele) | 1 Gruppe | `TARGET`, `SET_STATIC`, `STATIC` (ReSpawn), `SPAWN` |
| Anti-Ship | 1 Gruppe | `NAVYGROUP`, `TARGET`, `SPAWN` |
| BFM auf Abruf | parallel | `SPAWN`, `FLIGHTGROUP`, `AUFTRAG` (INTERCEPT) |
| Raketenabwehr | alle | `FOX` |
| Carrier | alle | `AIRBOSS`, `RECOVERYTANKER`, `RESCUEHELO` |
| Tanker und AWACS | alle | `AIRWING`, `SQUADRON`, `AUFTRAG` (TANKER, AWACS), `FLIGHTGROUP` |
| ATIS und Navigation | alle / parallel | `ATIS`, `BEACON` (NDB), `ZONE`, F10-Marker |
| Heli-Logistik | alle Helis | `CTLD` (Ops) |
| CSAR | alle Helis | `CSAR` (blau), `AICSAR` (rote KI-Rettung) |
| Kampagne | alle | `CHIEF`, `COMMANDER`, `INTEL`, `OPSZONE`, `BRIGADE`, `PLATOON`, `AIRWING`, `SQUADRON`, `AUFTRAG`, `OPSTRANSPORT`, `PLAYERTASKCONTROLLER`, `SEAD`, `AMMOTRUCK` |
| Umgebung | – | `RAT`, `RATMANAGER`, `CLEANUP_AIRBASE`, `ATC_GROUND_UNIVERSAL` |
| Grundlage | – | `CLIENTMENUMANAGER` (F10-Menü), `CLIENTWATCH` (Spieler), `SET_*`, `ZONE`, `MESSAGE`, `TIMER`, `COORDINATE`, `UTILS` |
| Fremdskript | A-10C | `A10_laste_Winds.lua` (CaptMikeDK, MIT) |

**Bedienung:** `F10 > Other > Training`

| Untermenü | Einträge |
|-----------|----------|
| CAS (JTAC) | Start, Stop, Status |
| SEAD / DEAD | Start, Stop, Status, Reveal threats |
| Strike | Start, Stop, Status |
| Anti-Ship | Start, Stop, Status |
| BFM | MiG-21 / MiG-29 / Su-27 / F-5E > Offensive, Defensive, Neutral, Head-on; Knock it off; Picture |
| Navigation | Start route (jet), Start route (helicopter), Next checkpoint, Stop |
| Info | Range, Tankers and AWACS, Frequencies/TACAN/laser codes, Front status |

Weitere F10-Menüs kommen von Moose selbst: `On the Range`, `Airboss`, `FOX`, `CTLD`, `CSAR`, `Front Tasks` (PLAYERTASK), `LASTE` (nur A-10C).

**Regeln der Szenarien**
- „1 Gruppe“: CAS, SEAD, Strike, Anti-Ship bedienen **eine Spielergruppe gleichzeitig**, andere hören „busy“.
- Nach Erfolg startet die nächste Runde nach 30 s automatisch (neue Zufallsauswahl).
- Stop, Zeitlimit oder Verlassen des Slots: alle erzeugten Einheiten werden entfernt, zerstörte Strike-Statics neu aufgebaut.
- BFM und Navigation laufen **pro Gruppe parallel**; eine neue Auswahl ersetzt die laufende.
- Keine Schwierigkeitsstufen, keine Punkte (bewusst so gewählt).

---

## 2. Versionen

| Bibliothek | Version | Datei |
|------------|---------|-------|
| MOOSE | **2.9.18** (Release 14.06.2026, Commit `73d3ed119cd9e7e3f2cfcabbaa34513d30529b54`) | `libs/Moose_.lua` (Release-Datei ohne Kommentare) |
| LASTE-Skript | 1.1 (14.06.2026, CaptMikeDK, MIT) | `libs/A10_laste_Winds.lua` (unverändert) |
| MiST | – (nicht benötigt) | – |
| CTLD | Moose `Ops.CTLD` (Teil von Moose 2.9.18) | – |

---

## 3. Dateien und Ladereihenfolge

```
Kaukasus_Allround/
  README.md            diese Anleitung
  .luacheckrc          Lint-Konfiguration
  libs/                Moose_.lua, A10_laste_Winds.lua
  scripts/             00_config.lua ... 99_init.lua
  tests/mock_test.lua  Logik-Test ohne DCS
```

| Datei | Inhalt |
|-------|--------|
| `00_config.lua` | **Alle** Namen, Frequenzen, TACAN, Zeiten. Umbenennen nur hier. |
| `01_core.lua` | Hilfsfunktionen, Prüfung der Editor-Objekte, Spieler-Erkennung, Session-Verwaltung |
| `02_menu.lua` | F10-Menü „Training“ (CLIENTMENUMANAGER) |
| `10_range.lua` … `14_antiship.lua` | Range, CAS, SEAD, Strike, Anti-Ship |
| `20_bfm.lua`, `21_fox.lua` | BFM, FOX |
| `30_carrier.lua`, `31_tanker_awacs.lua`, `32_atis_nav.lua` | Carrier, Tanker/AWACS, ATIS/NDB/Navigation |
| `40_ctld.lua`, `41_csar.lua` | CTLD, CSAR/AICSAR |
| `50_campaign.lua` | Kampagne |
| `60_ambient.lua` | RAT, Cleanup, ATC Ground |
| `99_init.lua` | Abhängigkeiten prüfen, alles starten, Startbericht |

**Ladereihenfolge im Mission Editor:** ein Trigger, Typ `MISSION START`, ohne Bedingung, mit **20 Aktionen `DO SCRIPT FILE`** in genau dieser Reihenfolge:

1. `libs/Moose_.lua`
2. `scripts/00_config.lua`
3. `scripts/01_core.lua`
4. `scripts/02_menu.lua`
5. `scripts/10_range.lua`
6. `scripts/11_cas.lua`
7. `scripts/12_sead.lua`
8. `scripts/13_strike.lua`
9. `scripts/14_antiship.lua`
10. `scripts/20_bfm.lua`
11. `scripts/21_fox.lua`
12. `scripts/30_carrier.lua`
13. `scripts/31_tanker_awacs.lua`
14. `scripts/32_atis_nav.lua`
15. `scripts/40_ctld.lua`
16. `scripts/41_csar.lua`
17. `scripts/50_campaign.lua`
18. `scripts/60_ambient.lua`
19. `libs/A10_laste_Winds.lua`
20. `scripts/99_init.lua`

`99_init.lua` muss zuletzt laufen. Nach jeder Änderung an einer Datei: im Editor die Aktion neu auswählen (DCS kopiert die Datei beim Speichern in die `.miz`).

---

## 4. Sounds (manuell einbauen)

Quelle: Repository **MOOSE_SOUND** (FlightControl-Master, GitHub). Eigene Sounds werden nicht verwendet.

| Ordner in der `.miz` (Wurzel des Archivs) | Quelle in MOOSE_SOUND | Nutzer |
|-------------------------------------------|----------------------|--------|
| `Range Soundfiles/` | `RANGE/Range Soundfiles` | RANGE |
| `Airboss Soundfiles/` | `AIRBOSS/Airboss Soundfiles` | AIRBOSS |
| `ATIS Soundfiles/` (mit Unterordnern `Caucasus/` und `NATO Alphabet/`) | `ATIS/ATIS Soundfiles` | ATIS |

**Schritte**
1. Mission im Editor fertig bauen und speichern, Editor schließen.
2. `.miz` mit 7-Zip öffnen (Rechtsklick > 7-Zip > Öffnen).
3. Die drei Ordner **auf die oberste Ebene** des Archivs ziehen (neben `mission`, `l10n`, …), Ordnernamen exakt wie oben.
4. Laut Moose-Doku löscht DCS beim Speichern nur Dateien in `l10n/DEFAULT/`, die kein Trigger nutzt; **eigene Ordner bleiben erhalten**. Prüfe nach dem nächsten Speichern trotzdem, ob die Ordner noch da sind.

**Funkfeuer-Ton `beacon.ogg`** (CTLD-Zonen, CSAR-Piloten, NDB): aus `CTLD CSAR/beacon.ogg`.
Er muss in `l10n/DEFAULT/` liegen und von einem Trigger benutzt werden, sonst entfernt DCS ihn:
- Trigger `ONCE`, Bedingung `FLAG IS TRUE` Flag `9999` (wird nie gesetzt), Aktion `SOUND TO ALL` mit `beacon.ogg`.

---

## 5. Mission-Grundeinstellungen und Spieler-Slots

- **Karte:** Kaukasus. **Zeit:** Tag. **Wetter:** klar bis leicht bewölkt, Wind ≤ 10 kn.
- **Koalitionen:** Spieler, Carrier, Tanker, blaue Brigade = **BLAU**. Ziele, rote Brigade, Gegner = **ROT**. RAT-Zivilflugzeug = **NEUTRAL**.
- **Flugplätze im Editor auf Koalition setzen:** Kutaisi, Senaki-Kolkhi, Batumi, Kobuleti = BLAU; Sukhumi-Babushara, Gudauta = ROT.
- **Länder:** für BLAU ein Land wählen, das alle Spielermuster anbietet (F-4E, Mi-24P, AH-64D im Editor prüfen). Für die BFM-F-5E ein rotes Land, das die F-5E-3 anbietet.
- **Supercarrier:** CVN-71, 72, 73 oder 75 (Supercarrier-Modul). Ob MP-Spieler das Modul brauchen, im Editor/Server prüfen.

### Spieler-Slots (Client)

**Jeder Slot eine eigene Gruppe** (eine Einheit pro Gruppe), sonst erscheinen Menüs doppelt.

| Muster | Anzahl | Start | Gruppenname | Szenarien |
|--------|--------|-------|-------------|-----------|
| F/A-18C | 2 | Kutaisi | frei | alle Jet-Szenarien, AAR (Drogue) |
| F/A-18C | 2 | Carrier `BLUE_Carrier` | frei | Carrier, alle Jet-Szenarien |
| F-16C | 2 | Kutaisi | frei | alle Jet-Szenarien, AAR (Boom) |
| A-10C II | 2 | Kutaisi | frei | Range, CAS, Strike, AAR (Boom), LASTE |
| F-4E | 2 | Kutaisi | frei | Range, CAS, Strike, Anti-Ship, BFM, AAR (Boom) |
| CH-47F | 2 | FARP `BLUE_FARP_Senaki` | **beginnt mit `BLUE Heli`**, z. B. `BLUE Heli CH-47F 1` | CTLD, CSAR, Navigation |
| Mi-24P | 2 | FARP `BLUE_FARP_Senaki` | **beginnt mit `BLUE Heli`** | CTLD, CSAR, CAS, Range |
| AH-64D | 2 | FARP `BLUE_FARP_Senaki` | **beginnt mit `BLUE Heli`** | CAS, Range, CSAR-Begleitschutz |

CTLD und CSAR erkennen Hubschrauber am Gruppennamen-Präfix `BLUE Heli` (änderbar: `blueHeliPrefix` in `00_config.lua`).
Im Singleplayer genügt ein Slot (Typ `Player`).

---

## 6. Frequenzen, TACAN, Lasercodes

Alle Funkfrequenzen sind UHF AM (auch für die F-4E nutzbar). Der Logik-Test prüft, dass keine Frequenz doppelt vergeben ist.

| Station | Frequenz | TACAN / Kennung |
|---------|----------|-----------------|
| Range Control | 250.000 AM | – |
| Range Instructor | 251.000 AM | – |
| Tanker Texaco (Boom, KC-135) | 252.000 AM | 51Y TEX, FL200, 300 kn |
| Tanker Arco (Drogue, KC-135MPRS) | 253.000 AM | 52Y ARC, FL180, 280 kn |
| AWACS Overlord (E-3A, nur Datenlink) | 254.000 AM | – |
| ATIS Kutaisi | 260.000 AM | – |
| ATIS Senaki-Kolkhi | 261.000 AM | – |
| ATIS Batumi | 262.000 AM | – |
| LSO | 264.000 AM | – |
| Recovery-Tanker (S-3B) | 265.000 AM | 63Y SHL |
| Marshal | 305.000 AM | – |
| Carrier | – | TACAN 71X CVN, ICLS 11 |
| NDB FARP Senaki | 420 kHz AM (ADF) | Ton `beacon.ogg` |
| CTLD-/CSAR-Funkfeuer | von Moose vergeben, siehe F10 > CTLD / CSAR | – |

| Laser | Code |
|-------|------|
| JTAC-Drohne CAS-Zone | 1688 |
| Front-Drohne (Kampagne) | 1686 |

Flugplatz-TACAN/ILS sind absichtlich **nicht** aufgeführt (keine verlässlichen Daten). Im Spiel: `F10 > Training > Info > Frequencies, TACAN, laser codes`.

---

## 7. Szenarien und Editor-Objekte

**Legende:** *LA* = Late Activation (Vorlage erscheint nicht selbst, Skript spawnt sie).
Einheitennamen sind frei, außer wo angegeben. Trigger: keine (alles per Skript), außer Kapitel 3 und 4.
Zonen sind **runde Trigger-Zonen**. „Vorschlag“ = Ort im Editor prüfen.

### 7.1 Range – `10_range.lua`

Bomben- und Bordkanonenauswertung mit Stimme. Ergebnisse: `F10 > On the Range`.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort (Vorschlag) | LA | Skill |
|------|-----|---------------------|-------|-----------------|----|-------|
| `BLUE_Range_Zone1` | Zone, R 6 km | – | – | ca. 15 nm südöstlich Kutaisi, offenes Gelände | – | – |
| `RED_Range_Bomb_Target1`, `RED_Range_Bomb_Target2`, `RED_Range_Bomb_Target3` | Static **oder** Einheit (Name = Einheitenname) | z. B. Container, Fahrzeugwracks | ROT | in der Range-Zone, 300 m Abstand | nein | – |
| `RED_Range_Strafe_Pit1_Target1`, `RED_Range_Strafe_Pit1_Target2` | Static oder Einheit | z. B. 2 Lkw nebeneinander | ROT | Pit 1 in der Range-Zone | nein | – |
| `RED_Range_Strafe_Pit2_Target1`, `RED_Range_Strafe_Pit2_Target2` | Static oder Einheit | wie Pit 1 | ROT | Pit 2, 1 km neben Pit 1 | nein | – |

Anflugrichtung der Strafe-Pits = Ausrichtung des ersten Ziels im Editor (Box 3000 × 300 m, Foul Line 610 m).

### 7.2 CAS mit JTAC – `11_cas.lua`

Zwei zufällige rote Gruppen fahren in der Zone Patrouille (ARMYGROUP/AUFTRAG), weichen unter Beschuss aus (SUPPRESSION). Eine MQ-9 kreist darüber und lasert automatisch (AUTOLASE, Code 1688, Infos unter `F10 > Autolase`, falls vorhanden). Erfolg: alle Ziele zerstört. Zeitlimit 45 min.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `RED_CAS_Zone1` | Zone, R 5 km | – | – | Raum Khashuri, flaches Gelände mit Straßen | – | – |
| `RED_CAS_Armor_Template` | Gruppe | 4 × T-72B | ROT | beliebig | ja (Vorlage) | Average |
| `RED_CAS_Infantry_Template` | Gruppe | 6 × Infantry AK + 2 × BTR-80 | ROT | beliebig | ja | Average |
| `RED_CAS_Convoy_Template` | Gruppe | 4 × Ural-375 + 2 × BTR-80 | ROT | beliebig | ja | Average |
| `RED_CAS_Mixed_Template` | Gruppe | 2 × BMP-2 + 1 × ZSU-23-4 + 2 × Ural-375 | ROT | beliebig | ja | Average |
| `BLUE_CAS_JTAC_Template` | Flugzeug | 1 × MQ-9 Reaper, Startart „Turning Point“ (in der Luft) | BLAU | beliebig | ja | Excellent |

### 7.3 SEAD/DEAD – `12_sead.lua`

Pro Runde 2 zufällige SAM-Stellungen, 2 SHORAD-Gruppen nahe den SAMs und ein Frühwarnradar. MANTIS schaltet die Radare je nach Bedrohung ein/aus und weicht HARMs aus. Erfolg: alle SAM-Stellungen zerstört. `Reveal threats` markiert die Stellungen auf der eigenen F10-Karte. Zeitlimit 60 min.

Die Vorlagen werden mit festen Namen gespawnt (`RED SEAD SAM SA-6#001` …). MANTIS erkennt daran Typ und Reichweite – die Vorlagennamen selbst sind frei, müssen aber wie unten heißen, weil die Konfiguration sie nennt.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `RED_SEAD_Zone1` | Zone, R 15 km | – | – | Raum Tskhinvali; ≥ 40 nm von Range, CAS, Strike und den RAT-Flugplätzen | – | – |
| `RED_SEAD_SA-2_Template` | Gruppe | SA-2: SNR-75 Fan Song, P-19, 3 Starter | ROT | beliebig | ja | High |
| `RED_SEAD_SA-3_Template` | Gruppe | SA-3: SNR-125, P-19, 2 Starter | ROT | beliebig | ja | High |
| `RED_SEAD_SA-6_Template` | Gruppe | SA-6: 1S91 Straight Flush, 3 × 2P25 | ROT | beliebig | ja | High |
| `RED_SEAD_SA-11_Template` | Gruppe | SA-11: 9S18M1, 9S470M1, 2 × 9A310M1 | ROT | beliebig | ja | High |
| `RED_SEAD_SHORAD_SA-15_Template` | Gruppe | 1 × SA-15 Tor | ROT | beliebig | ja | High |
| `RED_SEAD_SHORAD_SA-8_Template` | Gruppe | 1 × SA-8 Osa | ROT | beliebig | ja | High |
| `RED_SEAD_EWR_Template` | Gruppe | 1 × 1L13 EWR | ROT | beliebig | ja | High |

Jede SAM-Vorlage muss ihre eigenen Such-/Feuerleitradare enthalten (eigenständige Stellung).

### 7.4 Strike – `13_strike.lua`

Eine der vier Stellungen wird zufällig gewählt. Ziele sind **alle Statics innerhalb der Zone**. Die Mission nennt MGRS und Höhe jedes Ziels (für JDAM/JSOW). 2 Flak-Gruppen schützen das Ziel. Erfolg: alle Statics zerstört; danach werden sie neu aufgebaut. Zeitlimit 45 min.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `RED_Strike_Zone1`, `RED_Strike_Zone2`, `RED_Strike_Zone3`, `RED_Strike_Zone4` | Zone, R 500 m | darin 2–6 **Statics** (Bunker, Lagerhalle, Tanks, Kommandoposten) | ROT (Statics) | Raum Borjomi/Khashuri, je ≥ 5 km auseinander | Statics: nein | – |
| `RED_Strike_AAA_Template` | Gruppe | 1 × ZSU-23-4 oder 2 × ZU-23 | ROT | beliebig | ja | Average |

Keine anderen Statics in diese Zonen stellen.

### 7.5 Anti-Ship – `14_antiship.lua`

Ein zufälliger Schiffsverband fährt zwischen Zufallspunkten der Zone (NAVYGROUP). Die Mission nennt die letzte bekannte Position. Erfolg: Verband versenkt. Zeitlimit 60 min.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `RED_AntiShip_Zone1` | Zone, R 25 km | nur Wasser | – | Schwarzes Meer, ca. 60 nm westlich Poti, ≥ 40 nm vom Carrier | – | – |
| `RED_AntiShip_Convoy_Template` | Schiffsgruppe | 3 Frachter + 1 Fregatte (Grisha) | ROT | auf See | ja | Average |
| `RED_AntiShip_Patrol_Template` | Schiffsgruppe | 2 × Molniya oder Grisha | ROT | auf See | ja | Average |
| `RED_AntiShip_Frigate_Template` | Schiffsgruppe | 1 × Rezky oder Neustrashimy | ROT | auf See | ja | High |

### 7.6 BFM – `20_bfm.lua`

Wähle Gegner und Startlage, der Gegner erscheint neben dir (über 5 000 ft AGL, in der Luft). „Knock it off“ entfernt ihn, „Picture“ zeigt Peilung/Entfernung.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `RED_BFM_MiG-21_Template` | Flugzeug | 1 × MiG-21Bis, Kanone + 2 × R-60, Startart in der Luft | ROT | beliebig | ja | Excellent |
| `RED_BFM_MiG-29_Template` | Flugzeug | 1 × MiG-29A, Kanone + 2 × R-73 | ROT | beliebig | ja | Excellent |
| `RED_BFM_Su-27_Template` | Flugzeug | 1 × Su-27, Kanone + 2 × R-73 | ROT | beliebig | ja | Excellent |
| `RED_BFM_F-5E_Template` | Flugzeug | 1 × F-5E-3, Kanone + 2 × AIM-9 | ROT | beliebig | ja | Excellent |

### 7.7 FOX – `21_fox.lua`

Ohne Editor-Objekte. Überall aktiv: Raketen auf Spieler werden kurz vor dem Einschlag zerstört, mit Startwarnung. Jeder Spieler kann es unter `F10 > FOX` für sich abschalten (auch gegen SAMs an der Front wirksam).

### 7.8 Carrier – `30_carrier.lua`

AIRBOSS mit LSO-Bewertung und Marshal (Stimme). Eine Recovery wird über `F10 > Airboss` angefordert (30 min, 25 kn Wind über Deck). S-3B-Tanker und Rettungshubschrauber starten in der Luft.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `BLUE_Carrier` | **Einheitenname** des Trägers | CVN-71/72/73/75 (Supercarrier), Gruppe frei benannt, + 2 Begleitschiffe als eigene Gruppen | BLAU | ca. 40 nm westlich Batumi/Kobuleti, Route mit 4–6 Wegpunkten parallel zur Küste | nein | – |
| `BLUE_Carrier_Tanker_Template` | Flugzeug | 1 × S-3B Tanker | BLAU | beliebig | ja | High |
| `BLUE_Carrier_RescueHelo_Template` | Hubschrauber | 1 × SH-60B | BLAU | beliebig | ja | High |

### 7.9 Tanker und AWACS – `31_tanker_awacs.lua`

Eine Ops-AIRWING in Kutaisi hält beide Tanker und das AWACS auf Station (Missionen wiederholen sich, bei Spritmangel startet Ablösung). Die Rennbahn beginnt in der Zonenmitte.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `BLUE_Airwing_Kutaisi_Warehouse` | **Static** | z. B. „Warehouse“ | BLAU | **max. 5 km** vom Flugplatz Kutaisi | – | – |
| `BLUE_Tanker_Boom_Template` | Flugzeug | 1 × KC-135 (**Boom**) | BLAU | Kutaisi | ja | High |
| `BLUE_Tanker_Drogue_Template` | Flugzeug | 1 × KC-135MPRS (**Drogue**) | BLAU | Kutaisi | ja | High |
| `BLUE_AWACS_Template` | Flugzeug | 1 × E-3A | BLAU | Kutaisi | ja | High |
| `BLUE_Tanker_Boom_Zone` | Zone, R 1 km | Start der Boom-Rennbahn (Kurs 090, 30 nm) | – | zwischen Kutaisi und Kobuleti | – | – |
| `BLUE_Tanker_Drogue_Zone` | Zone, R 1 km | Start der Drogue-Rennbahn (Kurs 000, 30 nm) | – | über See, ca. 25 nm westlich Kobuleti | – | – |
| `BLUE_AWACS_Zone` | Zone, R 1 km | Start der AWACS-Rennbahn (Kurs 090, 40 nm) | – | südlich Kutaisi, abseits der Front | – | – |

Wichtig: Moose wählt den Tanker nach dem Betankungssystem der Vorlage. Boom-Mission braucht eine Boom-Vorlage, Drogue-Mission eine Drogue-Vorlage.

### 7.10 ATIS, NDB und Navigation – `32_atis_nav.lua`

- **ATIS** (Sprache aus `ATIS Soundfiles/`) für Kutaisi, Senaki-Kolkhi, Batumi – sendet nur, wenn Spieler in der Mission sind. Keine Editor-Objekte nötig.
- **NDB** 420 kHz am FARP Senaki für ADF-Anflüge der Hubschrauber.
- **Navigationsübung:** 4 zufällige Checkpoints werden auf deiner F10-Karte markiert, mit geplanten Zeiten (Jet 300 kn, Heli 110 kn Grundgeschwindigkeit). Beim Durchflug meldet die Mission die Abweichung in Sekunden.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `BLUE_FARP_Senaki` | **Static** FARP | FARP (Heliport) mit Munitions-/Treibstoff-Statics | BLAU | ca. 3 km östlich Senaki-Kolkhi | – | – |
| `BLUE_Nav_Zone1`, `BLUE_Nav_Zone2`, `BLUE_Nav_Zone3`, `BLUE_Nav_Zone4`, `BLUE_Nav_Zone5`, `BLUE_Nav_Zone6`, `BLUE_Nav_Zone7`, `BLUE_Nav_Zone8` | Zone, R 1 nm | auf markanten Punkten (Brücke, Kreuzung, See, Ortsmitte) | – | Westgeorgien zwischen Kutaisi, Senaki, Poti, Kobuleti, Zestafoni; 10–30 nm auseinander; nicht an der Front | – | – |

### 7.11 CTLD – `40_ctld.lua`

Moose-CTLD für alle Hubschrauber mit Präfix `BLUE Heli`. Truppen und Kisten in den Ladezonen holen, Kisten überall außerhalb der Ladezonen aufbauen (Bauzeit 2 min), Sling-Load erlaubt. **Kopplung zur Kampagne:** abgesetzte Truppen laufen zur nächsten Front-Zone (bis 8 km) und helfen, sie zu erobern.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `BLUE_CTLD_Load_Zone1` | Zone, R 400 m | Ladezone mit Funkfeuer | – | am FARP Senaki | – | – |
| `BLUE_CTLD_Load_Zone2` | Zone, R 400 m | Ladezone mit Funkfeuer | – | Kutaisi, Hubschrauberbereich | – | – |
| `BLUE_CTLD_Infantry_Template` | Gruppe | 8 Soldaten (Gewehr/MG) | BLAU | beliebig | ja | Average |
| `BLUE_CTLD_ATGM_Template` | Gruppe | 4 Soldaten mit Panzerabwehrwaffen | BLAU | beliebig | ja | Average |
| `BLUE_CTLD_Mortar_Template` | Gruppe | 4 Einheiten, z. B. 2B11 Mörser + Soldaten | BLAU | beliebig | ja | Average |
| `BLUE_CTLD_Engineers_Template` | Gruppe | 4 Soldaten (Pioniere) | BLAU | beliebig | ja | Average |
| `BLUE_CTLD_Humvee_Template` | Gruppe | 1 × HMMWV TOW (2 Kisten) | BLAU | beliebig | ja | Average |
| `BLUE_CTLD_Avenger_Template` | Gruppe | 1 × M1097 Avenger (2 Kisten) | BLAU | beliebig | ja | Average |
| `BLUE_CTLD_FOB_Template` | Gruppe | z. B. 1 × M 818 + 1 × HMMWV (FOB, 4 Kisten) | BLAU | beliebig | ja | Average |

Die Größe der Truppen-Vorlagen muss zur Zahl in `00_config.lua` (`size`) passen.

### 7.12 CSAR – `41_csar.lua`

- **Blau (Moose CSAR):** abgeschossene Spieler und blaue KI-Piloten der Kampagne werden zu Rettungseinsätzen; dazu alle 20–40 min ein Zufallseinsatz in einer der CSAR-Zonen. Abliefern im MASH, am FARP oder auf einem Flugplatz. Menü `F10 > CSAR`.
- **Rot (AICSAR):** rote KI-Hubschrauber retten abgeschossene rote Piloten (z. B. der roten Kampfhubschrauber) – ein zusätzliches Ziel für blaue Spieler.

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `BLUE_CSAR_Pilot_Template` | Gruppe | 1 Soldat | BLAU | beliebig | ja | Average |
| `BLUE_MASH_Zone1`, `BLUE_MASH_Zone2` | Zone, R 300 m (Name beginnt mit `BLUE_MASH`) | Sanitätsbereich | – | FARP Senaki, Kutaisi | – | – |
| `BLUE_CSAR_Zone1`, `BLUE_CSAR_Zone2`, `BLUE_CSAR_Zone3`, `BLUE_CSAR_Zone4` | Zone, R 5 km | Zufallseinsätze | – | z. B. Hügel nördlich Kutaisi, Küste bei Poti, Raum Zugdidi, Wald östlich Senaki | – | – |
| `RED_CSAR_Pilot_Template` | Gruppe | 1 Soldat | ROT | beliebig | ja | Average |
| `RED_CSAR_Helo_Template` | Hubschrauber | 1 × Mi-8MTV2, **Kaltstart** | ROT | Gudauta | ja | Average |
| `RED_MASH_Zone1` | Zone, R 300 m | rotes MASH | – | Flugplatz Gudauta | – | – |

---

## 8. Kampagne – `50_campaign.lua`

**Ablauf**
- Vier Front-Zonen zwischen Senaki und Sukhumi: Zugdidi (anfangs BLAU), Gali, Ochamchire, Tkvarcheli (anfangs ROT). Jede bekommt zu Beginn eine Besatzung; rote Zonen zusätzlich Flugabwehr (weicht HARMs aus, `SEAD`).
- Je Seite ein **CHIEF** mit einer **Brigade** (Infanterie, Panzer, Schützenpanzer, Artillerie). Blau hat KI-Transporthubschrauber, Rot Lkw-Transport und **Kampfhubschrauber** (keine roten Jäger).
- Ein CHIEF schickt Bodentruppen nur in **leere** Zonen. Besetzte Feindzonen bekommen zuerst Artillerie (Rot zusätzlich Kampfhubschrauber) und Panzer – und die **Spieler**: `F10 > Front Tasks` (PLAYERTASK) erzeugt CAS/BAI/SEAD-Aufträge aus dem, was die Front-Drohne und die blaue Brigade sehen. Die Drohne lasert mit Code 1686. CTLD-Truppen helfen beim Erobern.
- Eine Zone wechselt den Besitzer, wenn sie 2 min gehalten wird. Stand: `F10 > Training > Info > Front status` und Färbung auf der F10-Karte.
- **Endlos:** Verluste werden alle 10 min aufgefüllt. Hält eine Seite alle vier Zonen, kommt eine Meldung; nach 3 min werden alle Bodeneinheiten in den Front-Zonen entfernt (Spieler ausgenommen) und die Anfangslage wiederhergestellt.
- Munitions-Lkw (`AMMOTRUCK`) versorgen die Artillerie, wenn sie im Editor vorhanden sind (optional).

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `FRONT_Zugdidi` | Zone, **rund**, R 3 km | – | – | Ortsmitte Zugdidi | – | – |
| `FRONT_Gali` | Zone, rund, R 3 km | – | – | Ortsmitte Gali | – | – |
| `FRONT_Ochamchire` | Zone, rund, R 3 km | – | – | Ortsmitte Ochamchire | – | – |
| `FRONT_Tkvarcheli` | Zone, rund, R 3 km | – | – | Ortsmitte Tkvarcheli | – | – |
| `FRONT_Area_Zone` | Zone, R 45 km | Frontgebiet (Drohnen-Orbit, PLAYERTASK-Bereich) | – | Mitte zwischen Zugdidi und Ochamchire | – | – |
| `BLUE_Garrison_Template` | Gruppe | 4 Soldaten + 1 × M2A2 Bradley | BLAU | beliebig | ja | Average |
| `RED_Garrison_Template` | Gruppe | 4 × Infantry AK + 1 × BMP-2 | ROT | beliebig | ja | Average |
| `RED_Front_SHORAD_Template` | Gruppe | 1 × ZSU-23-4 + 1 × SA-13 | ROT | beliebig | ja | Average |
| `BLUE_Recce_Template` | Flugzeug | 1 × MQ-9 Reaper, Start in der Luft | BLAU | beliebig | ja | Excellent |
| `BLUE_Brigade_Senaki_Warehouse` | **Static** | z. B. „Warehouse“ | BLAU | ca. 5 km nördlich Senaki, an einer Straße | – | – |
| `BLUE_Brigade_Infantry_Template` | Gruppe | 6 Soldaten (Gewehr/MG) | BLAU | beliebig | ja | Average |
| `BLUE_Brigade_Tank_Template` | Gruppe | 2 × M1A2 Abrams | BLAU | beliebig | ja | Average |
| `BLUE_Brigade_IFV_Template` | Gruppe | 2 × M2A2 Bradley | BLAU | beliebig | ja | Average |
| `BLUE_Brigade_Artillery_Template` | Gruppe | 2 × M109 | BLAU | beliebig | ja | Average |
| `BLUE_Airwing_Senaki_Warehouse` | **Static** | z. B. „Warehouse“ | BLAU | **max. 5 km** vom Flugplatz Senaki-Kolkhi | – | – |
| `BLUE_Transport_Helo_Template` | Hubschrauber | 1 × CH-47D (KI) | BLAU | Senaki-Kolkhi | ja | Average |
| `BLUE_Ammo_Truck` … | Gruppen (Name **beginnt** mit `BLUE_Ammo_Truck`) | je 1 × M 818 (optional) | BLAU | in `BLUE_Ammo_Home_Zone` | nein | Average |
| `BLUE_Ammo_Home_Zone` | Zone, R 500 m | Heimat der Munitions-Lkw | – | beim Brigade-Lager | – | – |
| `RED_Brigade_Sukhumi_Warehouse` | **Static** | z. B. „Warehouse“ | ROT | Ostrand Sukhumi, an einer Straße | – | – |
| `RED_Brigade_Infantry_Template` | Gruppe | 6 × Infantry AK | ROT | beliebig | ja | Average |
| `RED_Brigade_Tank_Template` | Gruppe | 2 × T-72B | ROT | beliebig | ja | Average |
| `RED_Brigade_IFV_Template` | Gruppe | 2 × BMP-2 | ROT | beliebig | ja | Average |
| `RED_Brigade_Artillery_Template` | Gruppe | 2 × 2S1 Gvozdika | ROT | beliebig | ja | Average |
| `RED_Brigade_Truck_Template` | Gruppe | 2 × Ural-375 (Truppentransport) | ROT | beliebig | ja | Average |
| `RED_Airwing_Gudauta_Warehouse` | **Static** | z. B. „Warehouse“ | ROT | **max. 5 km** vom Flugplatz Gudauta | – | – |
| `RED_Attack_Helo_Template` | Hubschrauber | 1 × Mi-24V (Raketen/Kanone) | ROT | Gudauta | ja | Average |
| `RED_Ammo_Truck` … | Gruppen (Name beginnt mit `RED_Ammo_Truck`) | je 1 × Ural-375 (optional) | ROT | in `RED_Ammo_Home_Zone` | nein | Average |
| `RED_Ammo_Home_Zone` | Zone, R 500 m | Heimat der Munitions-Lkw | – | beim roten Brigade-Lager | – | – |

Die Gruppennamen der Brigade-Einheiten im Spiel lauten z. B. `BLUE Brigade Infantry_AID-12` (vergibt Moose). Nicht ändern: daran erkennen CHIEF, PLAYERTASK und AMMOTRUCK die Einheiten.

---

## 9. Umgebung – `60_ambient.lua`

- **RAT:** bis zu 4 KI-Flüge zwischen Batumi, Kobuleti und Kutaisi (weit weg von Front und SEAD-Zone).
- **CLEANUP_AIRBASE:** räumt Wracks auf Kutaisi, Senaki-Kolkhi, Batumi.
- **ATC Ground:** Rollgeschwindigkeit in Kutaisi und Batumi. Über 40 kn Warnung/Kick, über 60 kn sofortiger Kick (Werte in `00_config.lua`).

| Name | Art | Inhalt (Vorschlag) | Koal. | Ort | LA | Skill |
|------|-----|---------------------|-------|-----|----|-------|
| `NEUTRAL_RAT_Civil_Template` | Flugzeug | 1 × Yak-40 | NEUTRAL | Kutaisi | ja | Average |
| `BLUE_RAT_Transport_Template` | Flugzeug | 1 × C-130 | BLAU | Kutaisi | ja | Average |

---

## 10. Prüfen

### Logik-Test ohne DCS

```
cd Kaukasus_Allround
luac5.1 -p scripts/*.lua         # Syntax
luacheck scripts                 # Lint, muss 0 Warnungen melden
lua5.1 tests/mock_test.lua       # Logik-Test, muss mit "0 errors" enden
```

Der Test spielt mit Attrappen alle Szenarien durch (Start, busy, Erfolg, Neustart, Aufräumen, parallele BFM, Navigation, Spieler verlässt Slot, Skriptfehler), prüft Kampagnen-Sieg/Reset/Auffüllen, eine Mission mit fehlenden Objekten, fehlendes Moose, Frequenz-/TACAN-Kollisionen und dass jeder Name aus `00_config.lua` in dieser README steht.

### Checkliste im Spiel

- [ ] Startbericht nach 10 s: „ready“, keine Zeile „NOT running“, keine fehlenden Objekte.
- [ ] `F10 > Training` erscheint (auch im Singleplayer direkt nach dem Start).
- [ ] Range: Bombe werfen, Stimme auf 250.000, Ergebnis unter `F10 > On the Range`.
- [ ] CAS: Ziele fahren, Laser 1688 trifft, Runde endet und startet neu.
- [ ] SEAD: Radare schalten, SHORAD reagiert auf HARM, Reveal markiert.
- [ ] Strike: Ziele genannt, nach Zerstörung neu aufgebaut.
- [ ] Anti-Ship: Verband fährt, Status zeigt Position.
- [ ] BFM: alle vier Startlagen, Splash-Meldung.
- [ ] FOX: Rakete wird vor Einschlag zerstört, Abschalten per F10 wirkt.
- [ ] Carrier: Recovery per F10, Marshal/LSO-Stimme, S-3B auf 265.000 / 63Y.
- [ ] Tanker Texaco 51Y / Arco 52Y auf Station, AWACS im Datenlink.
- [ ] ATIS auf 260/261/262 hörbar, NDB 420 kHz im ADF.
- [ ] Navigation: Checkpoints markiert, Zeitmeldung beim Durchflug.
- [ ] CTLD: Truppen/Kisten laden, Funkfeuer hörbar, Truppen laufen zur Front-Zone.
- [ ] CSAR: Zufallseinsatz erscheint, Rettung ins MASH.
- [ ] Kampagne: Front-Zonen gefärbt, Brigaden bewegen sich, `F10 > Front Tasks` bietet Aufträge.
- [ ] Bei Fehlern: `dcs.log` nach `[KA]` und `ERROR` durchsuchen.

---

## 11. Bewusst nicht verwendete Module

| Modul | Grund |
|-------|-------|
| `FLIGHTCONTROL`, `AWACS` (Ops), `MSRS` | brauchen SRS (Text-to-Speech); diese Mission läuft ohne SRS |
| `TIRESIAS` | Fehler in 2.9.18: gespeichert wird der Typ `" Vehicle"`/`" AAA"` (mit Leerzeichen), geprüft wird `"Vehicle"`/`"AAA"` → abgeschaltete KI würde nie wieder eingeschaltet, Bodeneinheiten blieben eingefroren |
| `EASYA2G` | Hubschrauber-Unterstützung nicht dokumentiert; rote Kampfhubschrauber laufen über die AIRWING des roten CHIEF |
| `OPERATION`, `STRATEGO` | Phasen-Wiederholung laut Quelltext noch offen (TODO) bzw. eigener Graph über Flugplätze; der Kampagnen-Kreislauf ist deshalb mit eigenem Timer gelöst |
| `NAVFIX`/`Navigation.Point` | Version 0.1.0, Markertext wird vor Höhen/Speed-Angaben erzeugt und ist für alle sichtbar; Checkpoints nutzen eigene Gruppen-Marker |
| `BEACONS`, `RADIOS`, `TOWNS` | brauchen Daten aus Dateien (io), im DCS-Sandbox nicht verfügbar |
| `AICSAR` für BLAU | würde zusätzlich zu `CSAR` einen zweiten Piloten erzeugen; deshalb nur für ROT |
| Legacy (`AI_*`, `TASKING`, `DETECTION`, `DESIGNATE`, `ESCORT`, `WAREHOUSE` direkt, `ARTY`, `ZONE_CAPTURE_COALITION`, `MOVEMENT`) | Auswahl „nur moderne Ops-Module“ (`WAREHOUSE` steckt intern in BRIGADE/AIRWING) |
| `SCORING`, `PLAYERRECCE`, `TARS`, `EASYGCICAP` | nicht gewählt (keine Punkte, keine Aufklärung, kein BVR) |

---

## 12. Offene Punkte (TODO: verifizieren)

Diese Punkte lassen sich ohne DCS nicht prüfen. Im Code ist das Verhalten aus dem Moose-Quelltext abgeleitet:

1. **Replay der Geburt** (`KA.Players.ReplayBirth` in `01_core.lua`): Spieler, die vor dem Skriptstart im Slot saßen (Singleplayer), bekommen die Menüs von RANGE, AIRBOSS und FOX über ein nachgestelltes Birth-Ereignis. Prüfen, ob die Menüs im SP erscheinen.
2. **CLIENTMENUMANAGER** mit einer Einheit pro Gruppe: Menü erscheint einmal pro Spieler; bei Mehrsitzern (AH-64D, F-4E, CH-47F) prüfen, dass es nicht doppelt erscheint.
3. **Sound-Ordner** bleiben nach erneutem Speichern im Editor in der `.miz` (laut Moose-Doku ja).
4. **CHIEF-Kampagne:** Verhalten bei zwei CHIEFs auf denselben OPSZONEs, Transport der Infanterie (Hubschrauber/Lkw), Rückeroberung nach dem Reset.
5. **AUTOLASE**: ob ohne Spieler-Set ein koalitionsweites F10-Menü erscheint.
6. **FOX** gegen SAMs an der Front: Spieler sind überall geschützt, solange sie FOX nicht abschalten.
7. **BFM**: Gegner (FLIGHTGROUP mit INTERCEPT) greift nach dem Luftstart sofort an; sonst Startgeschwindigkeit/Höhe anpassen.
8. **ATC Ground**: Kick-Grenzen im Spiel prüfen (zu streng → Werte in `00_config.lua` erhöhen).
