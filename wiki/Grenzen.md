# Bekannte Grenzen und Annahmen

- Annahmen: „JTAG“ = JTAC, „F-14U“ = F-14B, „Hip“ = Mi-8MTV2.
- Kein Wetterwechsel per Skript möglich (DCS-Einschränkung).
- Keine eigenen Sounds und keine Sprachsynthese: Sprache kommt nur von Moose RANGE und AIRBOSS, alles andere ist Text.
- SEAD-Erfolg = Such- und Feuerleitradare zerstört (Attribute `SAM SR` und `SAM TR`). Fehlt so ein Radar in der Vorlage, wird die Runde wie DEAD gewertet. Das gilt auch für die SA-8 (HARD), falls DCS ihr Radar nicht unter diesen Attributen führt; dann ist SEAD dort gleich DEAD (alle drei Fahrzeuge zerstören).
- Zone 1 (Range) und Zone 2 (Airboss) nutzen die Moose-Klassen unverändert; deren Verhalten, Menüs und Sounds stammen von Moose. Die Range-Ziele sind fest und werden nicht zufällig gewählt.
- Die Bibliotheken in `libs/` sind unverändert und stehen unter ihren eigenen Lizenzen (MIST, Moose, CTLD, LASTE-Skript von CaptMikeDK unter MIT-Lizenz, https://github.com/CaptMikeDK/DCS-LASTE-Script). Die Sounds stammen aus MOOSE_SOUND (GPL-3.0).
