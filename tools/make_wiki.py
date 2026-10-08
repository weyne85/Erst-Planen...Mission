#!/usr/bin/env python3
"""Erzeugt die GitHub-Wiki-Seiten (wiki/*.md) aus README.md.

Die Wiki-Seiten enthalten den README-Text unveraendert, nur auf Seiten verteilt.
Aufruf: python3 tools/make_wiki.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "wiki"

# (Dateiname ohne .md, Titel, Start-Ueberschrift im README)
PAGES = [
    ("Grundkonzept", "Grundkonzept", "## 1. Grundkonzept"),
    ("Dateistruktur", "Dateistruktur und Ladereihenfolge", "## 2. Dateistruktur und Ladereihenfolge"),
    ("Mission-Grundeinstellungen", "Mission-Grundeinstellungen", "## 3. Mission-Grundeinstellungen"),
    ("Zonen", "Zonen im Detail", "## 4. Zonen im Detail"),
    ("Sounds", "Sounds", "## 5. Sounds (nur Moose-Soundpakete)"),
    ("Pruefen", "Pruefen und Testen", "## 6. Prüfen"),
    ("Anpassen", "Anpassen", "## 7. Anpassen"),
    ("Grenzen", "Bekannte Grenzen und Annahmen", "## 8. Bekannte Grenzen und Annahmen"),
    ("Fertige-Mission", "Fertige Mission (.miz)", "## 9. Fertige Mission (`mission/DCS_Training_Kaukasus.miz`)"),
    ("Bau-Checkliste", "Bau-Checkliste fuer den Mission Editor", "## 10. Bau-Checkliste für den Mission Editor"),
    ("Quellen", "Quellen der Bibliotheken", "## Quellen der Bibliotheken"),
]


def main():
    lines = (ROOT / "README.md").read_text(encoding="utf-8").split("\n")
    starts = []
    for _, _, head in PAGES:
        starts.append(next(i for i, l in enumerate(lines) if l.strip() == head))
    assert starts == sorted(starts), "Reihenfolge der Kapitel im README geaendert"
    # Intro = alles vor Kapitel 1 (ohne Titelzeile und Trennlinie am Ende)
    intro = "\n".join(lines[1:starts[0]]).strip().rstrip("-").strip()

    OUT.mkdir(exist_ok=True)
    for f in OUT.glob("*.md"):
        f.unlink()

    bounds = starts + [len(lines)]
    for n, (name, title, _) in enumerate(PAGES):
        body = lines[starts[n] + 1:bounds[n + 1]]
        text = "\n".join(body).strip().rstrip("-").strip()
        text = re.sub(r"^### ", "## ", text, flags=re.M)  # eine Ebene hoeher
        (OUT / f"{name}.md").write_text(f"# {title}\n\n{text}\n", encoding="utf-8")

    nav = "\n".join(f"- [[{t}|{n}]]" for n, t, _ in PAGES)
    (OUT / "Home.md").write_text(
        f"# DCS Trainingsmission Kaukasus\n\n{intro}\n\n## Seiten\n\n{nav}\n", encoding="utf-8")
    (OUT / "_Sidebar.md").write_text(f"**[[Start|Home]]**\n\n{nav}\n", encoding="utf-8")
    print(f"{len(PAGES) + 2} Wiki-Seiten in {OUT}")


if __name__ == "__main__":
    main()
