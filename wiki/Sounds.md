# Sounds

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
