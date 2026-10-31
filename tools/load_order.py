"""Einzige Quelle der Ladereihenfolge der Hauptmission.

`build_miz.py` baut daraus den MISSION-START-Trigger, `tools/sync_docs.py`
erzeugt daraus die Liste in README.md und `tests/load_order.lua` fuer den
Mock-Test. Aenderungen nur hier, danach `python3 tools/sync_docs.py`.
"""

LOAD_ORDER = [
    "libs/mist.lua", "libs/Moose.lua", "libs/CTLD-i18n.lua", "libs/CTLD.lua",
    "scripts/00_config.lua", "scripts/01_core.lua", "scripts/02_audio.lua", "scripts/03_menu.lua",
    "scripts/10_ground_attack.lua", "scripts/20_carrier.lua", "scripts/30_sead_dead.lua",
    "scripts/40_intercept.lua", "scripts/50_jtac.lua", "scripts/60_ctld.lua", "scripts/70_csar.lua",
    "scripts/80_ambient.lua", "libs/A10_laste_Winds.lua", "scripts/99_init.lua",
]

# Nur die eigenen Skripte aus scripts/ in Ladereihenfolge, ohne Pfad und Endung
# (das erwartet der Mock-Test, der libs/ durch Attrappen ersetzt).
SCRIPT_ORDER = [p.split("/", 1)[1][: -len(".lua")] for p in LOAD_ORDER if p.startswith("scripts/")]
