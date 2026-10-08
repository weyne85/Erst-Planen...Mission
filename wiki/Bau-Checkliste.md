# Bau-Checkliste fuer den Mission Editor

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
10. **Trigger:** Typ **MISSION START**, keine Bedingung, 18× Aktion **DO SCRIPT FILE** in der Reihenfolge aus Kapitel 2 (`99_init.lua` zuletzt).
11. **Sounds:** Ordner `Range Soundfiles/` und `Airboss Soundfiles/` ins Archiv der `.miz` kopieren, `beacon.ogg` nach `l10n/DEFAULT/` (Kapitel 5). Damit der Editor `beacon.ogg` nicht entfernt, braucht es einen Trigger, der die Datei verwendet (z. B. „Sound to All“ mit einer nie wahren Bedingung).
12. **Briefing, Wegpunkte, Kneeboards (optional):** Briefing-Text im Editor (Briefing), Wegpunkte je Client-Slot wie in Kapitel 9, Kneeboard-Seiten aus `mission/kneeboard/` ins Archiv unter `KNEEBOARD/<Typ-ID>/IMAGES/` (z. B. `KNEEBOARD/FA-18C_hornet/IMAGES/`).
13. **Speichern** und mit Kapitel 6 prüfen.
