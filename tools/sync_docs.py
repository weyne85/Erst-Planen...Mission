#!/usr/bin/env python3
"""Erzeugt die generierten Teile der Doku aus tools/load_order.py.

Betroffen:
  - README.md: nummerierte Liste zwischen <!-- LOAD_ORDER:START --> und <!-- LOAD_ORDER:END -->
  - tests/load_order.lua: Skriptliste fuer den Mock-Test

Aufruf:  python3 tools/sync_docs.py           # schreiben
         python3 tools/sync_docs.py --check   # nur pruefen (Exit 1 bei Abweichung, fuer CI)
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from load_order import LOAD_ORDER, SCRIPT_ORDER  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
LUA_TEST_ORDER = ROOT / "tests" / "load_order.lua"
START = "<!-- LOAD_ORDER:START -->"
END = "<!-- LOAD_ORDER:END -->"


def readme_block() -> str:
    lines = [f"{n}. `{rel}`" for n, rel in enumerate(LOAD_ORDER, 1)]
    return "\n".join([START, *lines, END])


def readme_text(current: str) -> str:
    if START not in current or END not in current:
        sys.exit(f"README.md: Marker {START} / {END} fehlen")
    head, rest = current.split(START, 1)
    _, tail = rest.split(END, 1)
    return head + readme_block() + tail


def lua_text() -> str:
    lines = [f'  "{name}",' for name in SCRIPT_ORDER]
    return (
        "-- Generiert von tools/sync_docs.py aus tools/load_order.py. Nicht von Hand aendern.\n"
        "-- Ladereihenfolge der eigenen Skripte; libs/ ersetzt der Mock-Test durch Attrappen.\n"
        "return {\n" + "\n".join(lines) + "\n}\n"
    )


def main() -> None:
    check = "--check" in sys.argv[1:]
    current_readme = README.read_text(encoding="utf-8")
    wanted = {
        README: readme_text(current_readme),
        LUA_TEST_ORDER: lua_text(),
    }
    stale = []
    for path, text in wanted.items():
        old = path.read_text(encoding="utf-8") if path.exists() else None
        if old == text:
            continue
        stale.append(path)
        if not check:
            path.write_text(text, encoding="utf-8")
    if check and stale:
        names = ", ".join(str(p.relative_to(ROOT)) for p in stale)
        sys.exit(f"veraltet: {names} -> python3 tools/sync_docs.py laufen lassen")
    action = "geprueft" if check else "aktualisiert"
    print(f"{action}: README.md Ladereihenfolge ({len(LOAD_ORDER)} Eintraege), tests/load_order.lua")


if __name__ == "__main__":
    main()
