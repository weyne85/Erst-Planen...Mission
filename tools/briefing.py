"""Briefing-Texte, Spieler-Routen (Wegpunkte) und Kneeboard-Seiten fuer die Trainingsmission.

Wird von tools/build_miz.py benutzt. Alle Frequenzen, Codes und Namen kommen aus scripts/00_config.lua
(einzige Quelle); Positionen kommen aus build_miz.POS; Flugplatzdaten (ATC-Frequenzen, Pistenrichtung) aus pydcs.
Nicht enthalten, weil pydcs sie nicht liefert und ich sie nicht raten will: TACAN/ILS der Flugplaetze.
"""
import json
import re
import subprocess
import textwrap
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import mgrs as mgrs_lib
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
_MGRS = mgrs_lib.MGRS()

M_TO_FT = 3.28084
KMH_TO_KT = 0.539957

LUA_DUMP = r'''
coalition = { side = { BLUE = 2, RED = 1 } }
dofile("scripts/00_config.lua")
local function dump(v)
  local t = type(v)
  if t == "table" then
    local isArray = (#v > 0)
    local parts = {}
    if isArray then
      for _, x in ipairs(v) do parts[#parts + 1] = dump(x) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    for k, x in pairs(v) do parts[#parts + 1] = string.format("%q:%s", tostring(k), dump(x)) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif t == "string" then return string.format("%q", v)
  elseif t == "number" or t == "boolean" then return tostring(v)
  end
  return "null"
end
print(dump(TRN.CFG))
'''


def load_cfg():
    """Liest scripts/00_config.lua mit Lua und liefert die Konfiguration als dict."""
    out = subprocess.run(["lua5.1", "-e", LUA_DUMP], cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return json.loads(out)


# ---------------------------------------------------------------------------------------------- Format
def mgrs(lat, lng, prec=3):
    s = _MGRS.toMGRS(lat, lng, MGRSPrecision=prec)
    m = re.match(r"(\d{2}[A-Z])([A-Z]{2})(\d+)", s)
    if not m:
        return s
    digits = m.group(3)
    h = len(digits) // 2
    return f"{m.group(1)} {m.group(2)} {digits[:h]} {digits[h:]}"


def ddm(lat, lng):
    def one(v, pos, neg, deg_width):
        hemi = pos if v >= 0 else neg
        v = abs(v)
        d = int(v)
        return f"{hemi} {d:0{deg_width}d}°{(v - d) * 60:06.3f}'"
    return one(lat, "N", "S", 2) + " " + one(lng, "E", "W", 3)


def freq(mhz):
    return f"{mhz:.3f}"


def hz_to_mhz(hz):
    return hz / 1e6


# ---------------------------------------------------------------------------------------------- Routen
# Eintrag: (Name, Hoehe in m, Geschwindigkeit in km/h, Hoehentyp, Kommentar)
JET_FA18 = [
    ("RANGE IP", 3000, 650, "BARO", "Zone 1: 10 km N of range"),
    ("RANGE", 2500, 600, "BARO", "Zone 1: bombs + strafe (run-in 180)"),
    ("GA ZONE", 3000, 650, "BARO", "Zone 1: dynamic ground targets"),
    ("JTAC IP", 3500, 650, "BARO", "Zone 5: initial point"),
    ("JTAC", 3000, 600, "BARO", "Zone 5: JTAC position"),
    ("SEAD IP", 4500, 700, "BARO", "Zone 3: IP 25 km W of site"),
    ("SEAD ZONE", 5000, 700, "BARO", "Zone 3: SAM site (SEAD/DEAD)"),
    ("INT ZONE", 6000, 750, "BARO", "Zone 4: intercept area"),
    ("CARRIER", 500, 500, "BARO", "Zone 2: carrier start pos."),
]
ROUTES = {
    "FA-18C_hornet": JET_FA18,
    "F-16C_50": JET_FA18[:-1],
    "A-10C_2": [
        ("RANGE IP", 2400, 450, "BARO", "Zone 1: 10 km N of range"),
        ("RANGE", 1800, 420, "BARO", "Zone 1: bombs + strafe (run-in 180)"),
        ("GA ZONE", 2400, 450, "BARO", "Zone 1: dynamic ground targets"),
        ("JTAC IP", 2400, 450, "BARO", "Zone 5: initial point"),
        ("JTAC", 2400, 420, "BARO", "Zone 5: JTAC position"),
    ],
    "F-14B": [
        ("INT ZONE", 6000, 750, "BARO", "Zone 4: intercept area"),
        ("CARRIER", 500, 500, "BARO", "Zone 2: carrier start pos."),
    ],
    "AH-64D_BLK_II": [
        ("JTAC IP", 150, 200, "RADIO", "Zone 5: initial point"),
        ("JTAC", 150, 180, "RADIO", "Zone 5: JTAC position"),
        ("GA ZONE", 150, 200, "RADIO", "Zone 1: dynamic ground targets"),
        ("RANGE", 150, 200, "RADIO", "Zone 1: range"),
        ("TASK 1", 150, 200, "RADIO", "Zone 6: escort CTLD task zone"),
        ("TASK 2", 150, 200, "RADIO", "Zone 6: escort CTLD task zone"),
        ("TASK 3", 150, 200, "RADIO", "Zone 6: escort CTLD task zone"),
    ],
}
HELO_ROUTE = [
    ("PICKUP 1", 100, 180, "RADIO", "Zone 6: troops/crates pickup"),
    ("TASK 1", 100, 200, "RADIO", "Zone 6: delivery zone"),
    ("PICKUP 2", 100, 200, "RADIO", "Zone 6: pickup"),
    ("TASK 2", 100, 200, "RADIO", "Zone 6: delivery zone"),
    ("TASK 3", 100, 200, "RADIO", "Zone 6: delivery zone"),
    ("MASH", 100, 180, "RADIO", "Zone 7: rescue drop-off"),
    ("CSAR 1", 100, 200, "RADIO", "Zone 7: possible crash area"),
    ("CSAR 2", 100, 200, "RADIO", "Zone 7: possible crash area"),
    ("CSAR 3", 100, 200, "RADIO", "Zone 7: possible crash area"),
    ("CSAR 4", 100, 200, "RADIO", "Zone 7: possible crash area"),
]
ROUTES["CH-47Fbl1"] = HELO_ROUTE
ROUTES["Mi-8MT"] = HELO_ROUTE


def point_table(pos):
    """Name -> (x, y) in DCS-Koordinaten."""
    rx, ry = pos["range"]
    sx, sy = pos["sead"]
    return {
        "RANGE IP": (rx + 10000, ry), "RANGE": pos["range"], "GA ZONE": pos["ga"],
        "JTAC IP": pos["jtac_ip"], "JTAC": pos["jtac_pos"],
        "SEAD IP": (sx, sy - 25000), "SEAD ZONE": pos["sead"],
        "INT ZONE": pos["int"], "CARRIER": pos["carrier"],
        "PICKUP 1": pos["ctld_pick_1"], "PICKUP 2": pos["ctld_pick_2"],
        "TASK 1": pos["ctld_task_1"], "TASK 2": pos["ctld_task_2"], "TASK 3": pos["ctld_task_3"],
        "MASH": pos["mash_1"],
        "CSAR 1": pos["csar_1"], "CSAR 2": pos["csar_2"], "CSAR 3": pos["csar_3"], "CSAR 4": pos["csar_4"],
    }


# ---------------------------------------------------------------------------------------------- Typen
TYPES = {
    "FA-18C_hornet": dict(name="F/A-18C", zones="1,2,3,4,5", proc=["cas", "sead", "jtac", "carrier", "intercept"],
                          maps=["overview", "west", "sea"]),
    "F-16C_50": dict(name="F-16C", zones="1,3,4,5", proc=["cas", "sead", "jtac", "intercept"],
                     maps=["overview", "west"]),
    "A-10C_2": dict(name="A-10C II", zones="1,5", proc=["cas", "jtac", "laste"], maps=["west"]),
    "F-14B": dict(name="F-14B", zones="2,4", proc=["carrier", "intercept"],
                  maps=["sea", "overview"]),
    "AH-64D_BLK_II": dict(name="AH-64D", zones="1,5,6,7", proc=["jtac", "ctld", "csar"], maps=["west"]),
    "CH-47Fbl1": dict(name="CH-47F", zones="6,7", proc=["ctld", "csar"], maps=["west"]),
    "Mi-8MT": dict(name="Mi-8MT", zones="6,7", proc=["ctld", "csar"], maps=["west"]),
}


# ---------------------------------------------------------------------------------------------- Geografie
class Geo:
    """Positionen mit Breite/Laenge und MGRS (aus pydcs)."""

    def __init__(self, terrain, pos):
        from dcs.mapping import Point
        self.terrain = terrain
        self.pos = pos
        self.points = point_table(pos)
        self._Point = Point

    def ll(self, xy):
        p = self._Point(xy[0], xy[1], self.terrain).latlng()
        return p.lat, p.lng

    def mgrs(self, xy, prec=3):
        return mgrs(*self.ll(xy), prec)

    def ddm(self, xy):
        return ddm(*self.ll(xy))


# ---------------------------------------------------------------------------------------------- Seiten
W, H, DPI = 768, 1024, 100
INK = "#111111"


def _page(title, subtitle, blocks, path):
    """blocks: Liste von (stil, text). stil: 'h' Ueberschrift, 'n' Text, 'm' Monospace-Zeile, 's' klein, '-' Leerzeile."""
    fig = plt.figure(figsize=(W / DPI, H / DPI), dpi=DPI, facecolor="white")
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, W)
    ax.set_ylim(H, 0)
    ax.axis("off")
    ax.add_patch(plt.Rectangle((0, 0), W, 64, color="#1f3b5c"))
    ax.text(18, 24, title, color="white", fontsize=17, fontweight="bold", va="center", family="DejaVu Sans")
    ax.text(18, 49, subtitle, color="#cfd9e6", fontsize=10.5, va="center", family="DejaVu Sans")
    y = 88
    for style, text in blocks:
        if style == "-":
            y += 10
            continue
        if style == "h":
            y += 6
            ax.text(18, y, text, fontsize=13.5, fontweight="bold", color="#1f3b5c", va="top", family="DejaVu Sans")
            ax.plot([18, W - 18], [y + 24, y + 24], color="#1f3b5c", lw=1)
            y += 32
        elif style == "n":
            for line in textwrap.wrap(text, 66) or [""]:
                ax.text(18, y, line, fontsize=11.5, color=INK, va="top", family="DejaVu Sans")
                y += 19
        elif style == "s":
            for line in textwrap.wrap(text, 92) or [""]:
                ax.text(18, y, line, fontsize=9, color="#444444", va="top", family="DejaVu Sans")
                y += 15
        elif style == "m":
            ax.text(18, y, text, fontsize=10.2, color=INK, va="top", family="DejaVu Sans Mono")
            y += 18
        elif style == "mb":
            ax.text(18, y, text, fontsize=10.2, color=INK, va="top", family="DejaVu Sans Mono", fontweight="bold")
            y += 18
    if y > H - 10:
        raise ValueError(f"Kneeboard-Seite '{title}' ist zu lang ({y} > {H})")
    fig.savefig(path, dpi=DPI, facecolor="white")
    plt.close(fig)
    return path


def _map_page(title, subtitle, map_path, path):
    """Setzt eine bestehende Karte mittig auf eine Hochformat-Seite (ohne Verzerrung)."""
    src = Image.open(map_path).convert("RGB")
    scale = min((W - 20) / src.width, (H - 100) / src.height)
    img = src.resize((int(src.width * scale), int(src.height * scale)), Image.LANCZOS)
    canvas = Image.new("RGB", (W, H), "white")
    canvas.paste(img, ((W - img.width) // 2, 80))
    fig = plt.figure(figsize=(W / DPI, H / DPI), dpi=DPI)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.imshow(canvas)
    ax.add_patch(plt.Rectangle((0, 0), W, 64, color="#1f3b5c"))
    ax.text(18, 24, title, color="white", fontsize=17, fontweight="bold", va="center")
    ax.text(18, 49, subtitle, color="#cfd9e6", fontsize=10.5, va="center")
    ax.axis("off")
    fig.savefig(path, dpi=DPI)
    plt.close(fig)
    return path


def frequency_page(tname, info, cfg, airports, path):
    c = cfg
    blocks = [("h", "AIRFIELDS (UHF / VHF AM, runway)")]
    for n in ("Kobuleti", "Senaki-Kolkhi", "Kutaisi", "Batumi"):
        a = airports[n]
        r = a.runways[0]
        blocks.append(("m", f"{n:<14} {hz_to_mhz(a.atc_radio.uhf_hz):7.3f} {hz_to_mhz(a.atc_radio.vhf_high_hz):7.3f}  RWY {r.name}"))
    blocks.append(("s", "TACAN/ILS of the airfields: see aircraft database/F10 map (not listed here)."))
    blocks.append(("-", ""))
    car, rng, jt = c["CARRIER"], c["GA"]["range"], c["JTAC"]
    if "carrier" in info["proc"]:
        blocks += [("h", "CARRIER  (USS Stennis, moves - follow TACAN)"),
                   ("m", f"TACAN {car['tacan']['channel']}{car['tacan']['mode']}  {car['tacan']['morse']}    ICLS ch {car['icls']['channel']}  {car['icls']['morse']}"),
                   ("m", f"MARSHAL {freq(car['marshalRadio'])} AM    LSO {freq(car['lsoRadio'])} AM"),
                   ("s", "Recovery windows open automatically (Case I). F10 > Airboss for Marshal/recovery."), ("-", "")]
    if "cas" in info["proc"]:
        blocks += [("h", "RANGE (bombing / strafing)"),
                   ("m", f"RANGE CONTROL {freq(rng['rangeControlMHz'])} AM    INSTRUCTOR {freq(rng['instructorMHz'])} AM"),
                   ("s", "F10 > On the Range for results and smoke."), ("-", "")]
    if "jtac" in info["proc"]:
        code = jt["laserCode"]
        laserB = (code - 1000) // 100
        laserCD = code - 1000 - laserB * 100
        fm = 30 + laserB + laserCD * 0.05
        blocks += [("h", "JTAC"),
                   ("m", f"CALLSIGN {jt['callsign'].upper()}   LASER {code}   FM {fm:.2f} (CTLD)"),
                   ("s", "Tasking and 9-line come as on-screen text. F10 > Training Zones > 5 JTAC."), ("-", "")]
    if "intercept" in info["proc"]:
        blocks += [("h", "INTERCEPT (AWACS)"),
                   ("m", f"AWACS CALLSIGN {c['INT']['awacsCallsign'].upper()}   BRAA every {c['INT']['awacsInterval']} s"),
                   ("s", "AWACS calls arrive as on-screen text (no radio frequency)."), ("-", "")]
    if "ctld" in info["proc"] or "csar" in info["proc"]:
        blocks += [("h", "RESCUE / TRANSPORT"),
                   ("m", "CTLD: F10 > CTLD in the helicopter"),
                   ("m", "CSAR: F10 > CSAR   (beacon frequency in MAYDAY msg)"),
                   ("s", "MASH zone and all airfields accept rescued pilots."), ("-", "")]
    blocks += [("h", "F10 MENUS"),
               ("m", "Training Zones: Info / Start EASY|MEDIUM|HARD / Stop"),
               ("s", "Every zone serves one flight at a time. Rounds restart automatically.")]
    return _page(f"{info['name']}  FREQUENCIES", "Training Mission Caucasus", blocks, path)


def zones_page(tname, info, geo, cfg, path):
    z = set(info["zones"].split(","))
    P = geo.pos
    blocks = [("h", "ZONES AND TARGETS (MGRS 100 m, lat/long)")]

    def add(name, key, note=""):
        blocks.append(("m", f"{name:<11} {geo.mgrs(P[key]):<16} {note}"))
        blocks.append(("s", "            " + geo.ddm(P[key])))

    def head(t):
        blocks.append(("mb", t))

    if "1" in z:
        head("ZONE 1 GROUND ATTACK")
        add("RANGE", "range", "bomb x3, strafe")
        add("GA ZONE", "ga", "dynamic targets")
    if "2" in z:
        head("ZONE 2 CARRIER")
        add("CARRIER", "carrier", "start position")
    if "3" in z:
        head("ZONE 3 SEAD/DEAD")
        add("SEAD ZONE", "sead", "30 nm E Kutaisi")
    if "4" in z:
        head("ZONE 4 INTERCEPT")
        add("INT ZONE", "int", "R 20 km")
    if "5" in z:
        head("ZONE 5 JTAC")
        add("JTAC IP", "jtac_ip")
        add("JTAC", "jtac_pos")
        add("TGT START", "jtac_start", "road")
        add("TGT END", "jtac_end", "road")
    if "6" in z:
        head("ZONE 6 CTLD")
        add("PICKUP 1", "ctld_pick_1")
        add("PICKUP 2", "ctld_pick_2")
        add("TASK 1", "ctld_task_1")
        add("TASK 2", "ctld_task_2")
        add("TASK 3", "ctld_task_3")
    if "7" in z:
        head("ZONE 7 CSAR")
        add("MASH", "mash_1", "drop-off")
        for i in range(1, 5):
            add(f"CSAR {i}", f"csar_{i}", "crash area")
    return _page(f"{info['name']}  ZONES", "Positions are mission placeholders - verify in the ME", blocks, path)


def route_page(tname, info, geo, path):
    route = ROUTES[tname]
    blocks = [("h", "WAYPOINTS (preloaded in the flight plan)")]
    blocks.append(("mb", f"{'WP':<3} {'NAME':<10} {'ALT ft':>7} {'KT':>4}  MGRS"))
    n = 2   # WP 1 = Start vom Flugplatz
    blocks.append(("m", f"{1:<3} {'TAKEOFF':<10} {'':>7} {'':>4}  {'Kobuleti' if tname in ('FA-18C_hornet','F-16C_50','A-10C_2','F-14B') else 'Senaki-Kolkhi'}"))
    for name, alt, spd, atype, note in route:
        alt_txt = f"{alt * M_TO_FT:.0f}" + ("R" if atype == "RADIO" else "")
        blocks.append(("m", f"{n:<3} {name:<10} {alt_txt:>7} {spd * KMH_TO_KT:>4.0f}  {geo.mgrs(geo.points[name])}"))
        blocks.append(("s", f"    {note}"))
        n += 1
    blocks.append(("m", f"{n:<3} {'LAND':<10} {'':>7} {'':>4}  {'Kobuleti' if tname in ('FA-18C_hornet','F-16C_50','A-10C_2','F-14B') else 'Senaki-Kolkhi'}"))
    blocks.append(("-", ""))
    blocks.append(("s", "R = radar altitude (AGL). Altitudes of jets are barometric (MSL). All points are optional: "
                        "fly the zones you need, skip the rest. Zone targets spawn at random inside each zone."))
    if tname in ("FA-18C_hornet", "F-14B"):
        blocks.append(("s", "CARRIER waypoint = start position only. The ship moves: use TACAN and the Airboss menu."))
    return _page(f"{info['name']}  ROUTE", "Flight plan waypoints", blocks, path)


PROC = {
    "cas": [
        ("h", "ZONE 1 - RANGE AND GROUND ATTACK"),
        ("n", "Range: F10 > On the Range. Bombs within 25 m = good hit. Strafe run-in heading 180 (from the north), "
              "foul line 2000 ft, 20+ hits = good pass. Max strafe altitude: see range menu."),
        ("n", "Ground attack: F10 > Training Zones > 1 Ground Attack > Start EASY / MEDIUM / HARD."),
        ("n", "Targets and their MGRS are announced. 'Targets remaining' after each kill. New round 20 s after the last."),
        ("m", "EASY   2 groups, trucks only"),
        ("m", "MEDIUM 3 groups, trucks + armour"),
        ("m", "HARD   4 groups + AAA + SHORAD"),
    ],
    "sead": [
        ("h", "ZONE 3 - SEAD / DEAD"),
        ("n", "Start: Training Zones > 3 SEAD/DEAD > Start <level> > SEAD or DEAD."),
        ("n", "SEAD: all search/track radars destroyed. DEAD: whole site destroyed (if no radar is detected, SEAD counts as DEAD)."),
        ("n", "Calls: 'Threat radar detected' within 45 km (bearing, range); 'Missile launch' on every SAM launch."),
        ("m", "EASY   SA-2 or SA-3"),
        ("m", "MEDIUM SA-6 or SA-11 + ZSU-23"),
        ("m", "HARD   SA-8 + SA-15 + ZSU-23"),
    ],
    "jtac": [
        ("h", "ZONE 5 - JTAC, MOVING TARGETS"),
        ("n", "Start: Training Zones > 5 JTAC > Start <level>. Then in this order:"),
        ("m", "1 Check in   2 Request 9-line   3 In hot   4 BDA"),
        ("n", "9-line: IP, heading and distance IP-target, elevation, target description, MGRS, mark (laser + smoke), "
              "friendlies, egress, remarks. 'In hot': JTAC lases and marks with smoke; position is updated."),
        ("m", "EASY   slow trucks, 20 km/h"),
        ("m", "MEDIUM mixed, 35 km/h"),
        ("m", "HARD   fast column + escort, 50 km/h"),
    ],
    "carrier": [
        ("h", "ZONE 2 - CARRIER (AIRBOSS)"),
        ("n", "The carrier steams a loop and turns into the wind for recovery windows (first after 3 min, then every "
              "45 min, 30 min long, Case I)."),
        ("n", "F10 > Airboss: request Marshal, start recovery, check grades. Follow Marshal instructions and the LSO."),
        ("n", "Use TACAN and ICLS to find the ship - it does not stay at the waypoint position."),
    ],
    "intercept": [
        ("h", "ZONE 4 - AIR INTERCEPT"),
        ("n", "Start: Training Zones > 4 Air Intercept > Start <level>. Bandits spawn ~70 km from the zone centre "
              "at 13000-30000 ft and fly through the zone."),
        ("n", "AWACS gives bogey dope (BRAA, altitude, hot/cold) every 30 s as on-screen text. 'Splash one' after each group."),
        ("m", "EASY   1 fighter (MiG-21)"),
        ("m", "MEDIUM a pair (MiG-29 / Su-27)"),
        ("m", "HARD   two groups + a bomber"),
    ],
    "ctld": [
        ("h", "ZONE 6 - CTLD"),
        ("n", "Start: Training Zones > 6 CTLD > Start <level>. A task and a delivery zone are announced."),
        ("m", "EASY   deliver troops"),
        ("m", "MEDIUM deliver crates, unpack a defence"),
        ("m", "HARD   build a FOB"),
        ("n", "F10 > CTLD: load troops in a pickup zone, order crates near a logistic tent (within 200 m), transport, "
              "unpack. Chinook and Mi-8 carry loads; the Apache only escorts."),
    ],
    "laste": [
        ("h", "LASTE WIND / TEMP (A-10C)"),
        ("n", "F10 > Other > LASTE > Request LASTE Winds. Shows MGRS, magnetic variation, QNH (inHg) and wind/temp "
              "for the CDU layers 00, 02, 08, 26. Wind is a 5-digit string (e.g. 08001). Clear LASTE Data closes it."),
        ("n", "1. Set the altimeter pressure knob to the QNH shown."),
        ("n", "2. CDU: SYS > OSB 06 LASTE > OSB 07 WIND."),
        ("n", "3. Type the layer altitude into the scratchpad, press its OSB."),
        ("n", "4. OSB 07 WNDEDIT: type wind (e.g. 08001) > OSB 02 WIND; type temp (e.g. 19 or -32) > OSB 03 TEMP."),
        ("n", "5. UFC WP returns to the steerpoint page."),
        ("s", "Script: CaptMikeDK, MIT license. The menu only appears in A-10C / A-10C II slots."),
    ],
    "csar": [
        ("h", "ZONE 7 - CSAR (random)"),
        ("n", "A pilot goes down every 15-30 min (if a helicopter is present). 'MAYDAY' message with frequency. "
              "F10 > CSAR: List Active, Request Smoke / Flare, Check Onboard."),
        ("n", "Land within 75 m (or hover within 10 m, below 20 m height), wait for him to board, "
              "deliver to the MASH zone or any airfield. Missions expire after 45 min."),
        ("n", "Training Zones > 7 CSAR > Request CSAR mission now: starts one on demand."),
    ],
}


def procedure_pages(tname, info, path_fn):
    pages = []
    keys = list(info["proc"])
    # zwei Prozeduren je Seite, damit der Text gut lesbar bleibt
    for i in range(0, len(keys), 2):
        blocks = []
        for k in keys[i:i + 2]:
            blocks += PROC[k] + [("-", "")]
        pages.append(_page(f"{info['name']}  PROCEDURES {i // 2 + 1}", "Zones and how to fly them", blocks, path_fn(i // 2 + 1)))
    return pages


MAP_TITLES = {"overview": "Overview", "west": "West Georgia", "sea": "Black Sea"}


def build_kneeboards(outdir, geo, cfg, airports, map_paths):
    """Erzeugt alle Seiten. map_paths: dict Kartenname -> PNG. Rueckgabe: dict Typ-ID -> Liste von Pfaden."""
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    result = {}
    for tname, info in TYPES.items():
        base = tname.replace("/", "_")
        pages = []
        pages.append(frequency_page(tname, info, cfg, airports, outdir / f"{base}_1_freq.png"))
        pages.append(zones_page(tname, info, geo, cfg, outdir / f"{base}_2_zones.png"))
        pages.append(route_page(tname, info, geo, outdir / f"{base}_3_route.png"))
        pages += procedure_pages(tname, info, lambda n, b=base: outdir / f"{b}_4_proc{n}.png")
        for j, mp in enumerate(info["maps"], start=1):
            pages.append(_map_page(f"{info['name']}  MAP {j}", MAP_TITLES[mp] + " (no terrain, zones only)", map_paths[mp],
                                   outdir / f"{base}_5_map{j}.png"))
        result[tname] = pages
    return result


# ---------------------------------------------------------------------------------------------- Briefing
def briefing_texts(geo, cfg):
    c = cfg
    P = geo.pos
    car, rng, jt = c["CARRIER"], c["GA"]["range"], c["JTAC"]

    def m(key):
        return geo.mgrs(P[key])

    situation = (
        "TRAINING MISSION CAUCASUS\n\n"
        "Six independent training zones, random CSAR missions and a living environment (air traffic, ships, convoys). "
        "All zones are used from the F10 menu 'Training Zones'. Each zone serves one flight at a time, "
        "difficulty EASY / MEDIUM / HARD is chosen at the start and rounds restart automatically.\n\n"
        "ZONES\n"
        f"1 Ground Attack - range (bombs, strafe) at MGRS {m('range')} and dynamic targets at {m('ga')}.\n"
        f"2 Carrier - USS Stennis, TACAN {car['tacan']['channel']}{car['tacan']['mode']} {car['tacan']['morse']}, "
        f"ICLS {car['icls']['channel']}. F10 > Airboss.\n"
        f"3 SEAD/DEAD - SAM site 30 nm east of Kutaisi at {m('sead')}.\n"
        f"4 Air Intercept - area at {m('int')} over the sea, AWACS '{c['INT']['awacsCallsign']}'.\n"
        f"5 JTAC - moving targets on the road, JTAC '{jt['callsign']}' at {m('jtac_pos')}, laser code {jt['laserCode']}.\n"
        f"6 CTLD - pickup zones at {m('ctld_pick_1')} and {m('ctld_pick_2')}, three delivery zones.\n"
        f"7 CSAR - random rescue missions, MASH at {m('mash_1')}.\n"
        "8 Convoys and traffic - friendly supply convoys, hostile convoys as targets of opportunity (INTEL message).\n\n"
        "FREQUENCIES\n"
        f"Marshal {freq(car['marshalRadio'])} AM, LSO {freq(car['lsoRadio'])} AM, "
        f"Range Control {freq(rng['rangeControlMHz'])} AM, Instructor {freq(rng['instructorMHz'])} AM. "
        "Airfield ATC frequencies are on the kneeboard.\n\n"
        "NAVIGATION\n"
        "Waypoints for every zone are preloaded in the client flight plans. Kneeboard pages: frequencies, "
        "zones and targets, route, procedures and maps."
    )
    blue = (
        "Pick a zone, start it from F10 > Training Zones and fly the exercise.\n"
        "Jets: ground attack, SEAD/DEAD, JTAC support, carrier landings, intercepts.\n"
        "Helicopters: CTLD transport tasks and random CSAR rescues; the Apache escorts and supports the JTAC.\n"
        "Stay clear of other zones when their SAM sites are active."
    )
    red = "Hostile SAM sites, ground units, fighters and convoys appear in the zones when a round starts."
    return situation, blue, red
