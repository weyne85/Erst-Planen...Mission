# Grundkonzept

- Sechs Zonen, in beliebiger Reihenfolge und parallel nutzbar.
- Steuerung über ein **F10-Menü pro Spielergruppe**: `F10 > Training Zones`.
- Jede Zone bedient **eine Spielergruppe gleichzeitig**. Eine zweite Gruppe hört „Zone is busy“.
- **Schwierigkeit:** EASY, MEDIUM, HARD (Einsteiger bis Fortgeschrittene), wählbar beim Start.
- **Dynamik:** Ziele, Position und Gegner werden bei jeder Runde zufällig aus Vorlagen gewählt. Nach Abschluss startet die Zone nach 20 s automatisch neu.
- **Aufräumen:** Beim Stoppen, bei Zeitüberschreitung oder wenn die Spielergruppe verschwindet, werden alle erzeugten Einheiten entfernt.
- **Wetter/Zeit:** fest und klar. DCS erlaubt kein Ändern des Wetters per Skript; Variation gibt es nur bei Zielen, Startpunkten und beim Carrier (Recovery-Fenster, Wind).
- **Punkte/Ranglisten:** keine, nur Rückmeldung pro Übung.
- **Bearings:** rechtweisend (true). Mit `MAG_VAR` in `00_config.lua` lässt sich ein Offset einstellen.
