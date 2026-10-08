# Dateistruktur und Ladereihenfolge

```
README.md
libs/       mist.lua, Moose.lua, CTLD-i18n.lua, CTLD.lua, A10_laste_Winds.lua     (unverändert, nur eingebunden)
scripts/    00_config.lua  01_core.lua  02_audio.lua  03_menu.lua
            10_ground_attack.lua  20_carrier.lua  30_sead_dead.lua
            40_intercept.lua  50_jtac.lua  60_ctld.lua
            70_csar.lua  80_ambient.lua  99_init.lua
tests/      mock_test.lua   (Logik-Test ohne DCS)
tools/      build_miz.py (erzeugt die .miz, Karten und Kneeboards)   briefing.py   plot_map.py   types_extra.py
mission/    DCS_Training_Kaukasus.miz   (fertige Mission, Kapitel 9)
            map/ (Karten, Objektliste)   kneeboard/ (Kneeboard-Seiten je Flugzeugtyp)
```

**Ladereihenfolge im Mission Editor** – ein Trigger, Typ `MISSION START`, ohne Bedingung, mit **18 Aktionen `DO SCRIPT FILE`** in genau dieser Reihenfolge:

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
17. `libs/A10_laste_Winds.lua`
18. `scripts/99_init.lua`

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
| `A10_laste_Winds.lua` | Fremdskript (CaptMikeDK, MIT): F10-Menü „LASTE“ nur in A-10C/A-10C II, zeigt Wind/Temperatur/QNH für die CDU. Läuft nach Moose, unabhängig von den Zonen. |
| `99_init.lua` | Prüft Abhängigkeiten, startet Range, Carrier, CTLD, CSAR, Flugverkehr, Konvois und Menü. |
