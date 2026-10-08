# Pruefen und Testen

## Logik-Test ohne DCS

```
lua5.1 tests/mock_test.lua
```

Der Test ersetzt DCS, Moose, MIST und CTLD durch Attrappen und prüft: Laden der Skripte, Range- und Airboss-Konfiguration, Menüaufbau, alle sechs Übungszonen (Start, Auswertung, Auto-Restart, Aufräumen), Besetzt-Meldung, Setup-Fehler und Spieler-Ende sowie CSAR (zufällige Einsätze, Verfall, Anforderung), Flugverkehr und Konvois. Erwartet wird `0 Fehler`.

## Checkliste im Spiel (Singleplayer und Multiplayer)

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
