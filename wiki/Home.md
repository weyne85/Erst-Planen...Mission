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
> - Die `.miz` wurde **ohne DCS** mit `tools/build_miz.py` (pydcs) erzeugt. Sie ist strukturell geprüft (Archiv, Skripte, alle 63 Namen aus `00_config.lua`), aber **nicht in DCS getestet**.
> - **Alle Positionen sind Platzhalter.** Öffne die Mission im Mission Editor und prüfe sie nach Kapitel 9, bevor du sie benutzt.
> - Die Moose-Soundpakete `Range Soundfiles` und `Airboss Soundfiles` sind in der `.miz` enthalten (Kapitel 5). Eigene Sounds gibt es nicht.
> - Die Skripte sind im Spiel **noch nicht getestet**. Der Logik-Test (Kapitel 6) prüft nur den Ablauf mit Attrappen.

## Seiten

- [[Grundkonzept|Grundkonzept]]
- [[Dateistruktur und Ladereihenfolge|Dateistruktur]]
- [[Mission-Grundeinstellungen|Mission-Grundeinstellungen]]
- [[Zonen im Detail|Zonen]]
- [[Sounds|Sounds]]
- [[Pruefen und Testen|Pruefen]]
- [[Anpassen|Anpassen]]
- [[Bekannte Grenzen und Annahmen|Grenzen]]
- [[Fertige Mission (.miz)|Fertige-Mission]]
- [[Bau-Checkliste fuer den Mission Editor|Bau-Checkliste]]
- [[Quellen der Bibliotheken|Quellen]]
