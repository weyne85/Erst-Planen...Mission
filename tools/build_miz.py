#!/usr/bin/env python3
"""Erzeugt die Trainingsmission als .miz (Kaukasus) mit pydcs.

Aufruf (im Repo-Hauptverzeichnis):
    pip install pydcs
    python3 tools/build_miz.py [--sounds-dir PFAD_ZU_MOOSE_SOUND] [-o mission/DCS_Training_Kaukasus.miz]

Was erzeugt wird:
  * Trigger "MISSION START" mit 15x DO SCRIPT FILE (Ladereihenfolge wie in der README)
  * alle Triggerzonen, Vorlagegruppen (Late Activation), Range-Ziele, Traeger, CTLD-Logistik, JTAC
  * Spieler-Slots (Client) fuer alle Muster
  * optional: Moose-Soundordner "Range Soundfiles/" und "Airboss Soundfiles/" im Archiv

Die POSITIONEN sind Platzhalter (siehe README, Kapitel 9) und muessen im Mission Editor geprueft werden.
Die Namen stammen aus scripts/00_config.lua; das Skript prueft am Ende, ob alle dort verwendeten TRN_-Namen
in der Mission vorkommen.
"""
import argparse
import datetime
import re
import shutil
import sys
import zipfile
from pathlib import Path

import dcs
from dcs import countries, helicopters, planes, ships, statics, task, vehicles
from dcs.helicopters import HelicopterType
from dcs.mapping import Point
from dcs.mission import Mission, StartType
from dcs.terrain import Caucasus
from dcs.triggers import TriggerStart
from dcs.action import DoScriptFile
from dcs.task import OptROE

ROOT = Path(__file__).resolve().parent.parent

# ----------------------------------------------------------------------------------------------
# Positionen (DCS-Koordinaten: x = Norden, y = Osten; Meter). PLATZHALTER, im Editor pruefen!
# ----------------------------------------------------------------------------------------------
POS = {
    "range":        (-262000, 655000),   # Bomben-/Strafing-Range, NNO von Senaki
    "ga":           (-250000, 675000),   # dynamische Bodenziele
    "sead":         (-330000, 930000),   # Ebene ostlich von Tbilisi/Vaziani
    "int":          (-260000, 520000),   # Schwarzes Meer
    "jtac_pos":     (-282000, 664000),   # zwischen Senaki und Kutaisi
    "jtac_ip":      (-291000, 651000),
    "jtac_start":   (-283000, 650000),
    "jtac_end":     (-284000, 677000),
    "ctld_pick_1":  (-279000, 651000),   # nahe Senaki
    "ctld_pick_2":  (-284000, 644000),
    "ctld_task_1":  (-300000, 665000),
    "ctld_task_2":  (-268000, 690000),
    "ctld_task_3":  (-330000, 660000),
    "carrier":      (-330000, 540000),   # Schwarzes Meer, ca. 45 nm vor der Kueste
    "carrier_wp2":  (-300000, 480000),
}

CONFIG = ROOT / "scripts" / "00_config.lua"

LOAD_ORDER = [
    "libs/mist.lua", "libs/Moose.lua", "libs/CTLD-i18n.lua", "libs/CTLD.lua",
    "scripts/00_config.lua", "scripts/01_core.lua", "scripts/02_audio.lua", "scripts/03_menu.lua",
    "scripts/10_ground_attack.lua", "scripts/20_carrier.lua", "scripts/30_sead_dead.lua",
    "scripts/40_intercept.lua", "scripts/50_jtac.lua", "scripts/60_ctld.lua", "scripts/99_init.lua",
]


class CH_47Fbl1(HelicopterType):
    """CH-47F (DCS-Modul). In pydcs 0.15 nicht enthalten, daher hier mit der DCS-Typ-ID definiert."""
    id = "CH-47Fbl1"
    flyable = True
    large_parking_slot = True
    height = 5.9
    width = 18.3
    length = 30.1
    fuel_max = 2500          # bewusst niedrig gewaehlt; der Spieler kann im Editor/Rearm anpassen
    max_speed = 300
    chaff = 120
    flare = 120
    charge_total = 240
    chaff_charge_size = 1
    flare_charge_size = 1
    pylons = set()
    tasks = [task.Transport]
    task_default = task.Transport


helicopters.helicopter_map["CH-47Fbl1"] = CH_47Fbl1   # damit pydcs die Mission wieder laden (pruefen) kann


def P(m, key_or_xy, dx=0, dy=0):
    x, y = POS[key_or_xy] if isinstance(key_or_xy, str) else key_or_xy
    return Point(x + dx, y + dy, m.terrain)


def build(sounds_dir, out_path):
    m = Mission(Caucasus())
    m.coalition["blue"].add_country(countries.USA())
    m.coalition["red"].add_country(countries.Russia())
    usa = m.country("USA")
    rus = m.country("Russia")

    # ---------------------------------------------------------------- Wetter / Zeit (fest, klar)
    m.start_time = datetime.datetime(2024, 6, 21, 10, 0, 0)
    w = m.weather
    w.clouds_density = 0
    w.enable_fog = False
    w.enable_dust = False
    w.qnh = 760
    w.visibility_distance = 80000
    w.wind_at_ground = dcs.weather.Wind(270, 3) if hasattr(dcs.weather, "Wind") else w.wind_at_ground
    w.season_temperature = 22

    m.set_description_text(
        "TRAINING MISSION CAUCASUS - six independent training zones.\n"
        "F10 > Training Zones: 1 Ground Attack (+ Range), 2 Carrier (F10 > Airboss), 3 SEAD/DEAD, "
        "4 Air Intercept, 5 JTAC, 6 CTLD. Difficulty EASY/MEDIUM/HARD is chosen at start."
    )
    m.set_description_bluetask_text("Use the F10 menu 'Training Zones'. Each zone serves one flight at a time.")
    m.set_description_redtask_text("-")

    # ---------------------------------------------------------------- Triggerzonen
    def zone(name, key, radius):
        m.triggers.add_triggerzone(P(m, key), radius=radius, name=name)

    zone("TRN_RANGE_ZONE", "range", 4500)
    zone("TRN_GA_ZONE", "ga", 3000)
    zone("TRN_SEAD_ZONE", "sead", 3000)
    zone("TRN_INT_ZONE", "int", 20000)
    zone("TRN_JTAC_POS", "jtac_pos", 300)
    zone("TRN_JTAC_IP", "jtac_ip", 500)
    zone("TRN_JTAC_START", "jtac_start", 500)
    zone("TRN_JTAC_END", "jtac_end", 500)
    zone("TRN_CTLD_PICKUP_1", "ctld_pick_1", 200)
    zone("TRN_CTLD_PICKUP_2", "ctld_pick_2", 200)
    zone("TRN_CTLD_TASK_1", "ctld_task_1", 400)
    zone("TRN_CTLD_TASK_2", "ctld_task_2", 400)
    zone("TRN_CTLD_TASK_3", "ctld_task_3", 400)

    # ---------------------------------------------------------------- Hilfsfunktionen Vorlagen
    def ground_template(name, key, units, country=rus, dx=0, dy=0, heading=0, late=True):
        """units: Liste von Fahrzeugtypen. Erstellt eine Gruppe mit Late Activation."""
        first = units[0]
        g = m.vehicle_group(country, name, first, P(m, key, dx, dy), heading=heading, group_size=1)
        for i, t in enumerate(units[1:], start=1):
            v = m.vehicle(f"{name}-{i + 1}", t)
            v.position = Point(g.units[0].position.x + 40 * i, g.units[0].position.y + 25 * (i % 2), m.terrain)
            v.heading = 0
            g.add_unit(v)
        g.late_activation = late
        return g

    # ---------------------------------------------------------------- Zone 1: Range (feste Ziele)
    def named_vehicle(name, unit_name, vtype, key, dx, dy, country=rus):
        g = m.vehicle_group(country, name, vtype, P(m, key, dx, dy), heading=0, group_size=1)
        g.units[0].name = unit_name
        return g

    named_vehicle("TRN_RANGE_BOMB_GRP_1", "TRN_RANGE_BOMB_1", vehicles.Unarmed.Ural_375, "range", 0, 0)
    named_vehicle("TRN_RANGE_BOMB_GRP_2", "TRN_RANGE_BOMB_2", vehicles.Unarmed.Ural_375, "range", 600, 300)
    named_vehicle("TRN_RANGE_BOMB_GRP_3", "TRN_RANGE_BOMB_3", vehicles.Unarmed.Ural_375, "range", -500, 700)
    named_vehicle("TRN_RANGE_STRAFE_GRP_1", "TRN_RANGE_STRAFE_1", vehicles.Unarmed.Ural_375, "range", -2500, -2000)

    # ---------------------------------------------------------------- Zone 1: dynamische Ziele (Vorlagen)
    A = vehicles.Armor
    U = vehicles.Unarmed
    ground_template("TRN_GA_VEH_1", "ga", [U.Ural_375] * 3, dy=-1500)
    ground_template("TRN_GA_VEH_2", "ga", [U.KAMAZ_Truck, U.GAZ_66, U.GAZ_66], dy=-1400, dx=200)
    ground_template("TRN_GA_VEH_3", "ga", [U.UAZ_469] * 3, dy=-1300, dx=400)
    ground_template("TRN_GA_ARM_1", "ga", [A.T_72B] * 3, dy=-1200, dx=600)
    ground_template("TRN_GA_ARM_2", "ga", [A.BMP_2] * 3, dy=-1100, dx=800)
    ground_template("TRN_GA_AAA_1", "ga", [vehicles.AirDefence.ZSU_23_4_Shilka] * 2, dy=-1000, dx=1000)
    ground_template("TRN_GA_SHORAD_1", "ga", [vehicles.AirDefence.Strela_10M3] * 2, dy=-900, dx=1200)

    # ---------------------------------------------------------------- Zone 3: SAM-Vorlagen
    AD = vehicles.AirDefence
    ground_template("TRN_SAM_SA2", "sead", [AD.P_19_s_125_sr, AD.SNR_75V] + [AD.S_75M_Volhov] * 3, dy=-1500)
    ground_template("TRN_SAM_SA3", "sead", [AD.P_19_s_125_sr, AD.Snr_s_125_tr] + [AD.X_5p73_s_125_ln] * 3, dy=-1300)
    ground_template("TRN_SAM_SA6", "sead", [AD.Kub_1S91_str] + [AD.Kub_2P25_ln] * 3, dy=-1100)
    ground_template("TRN_SAM_SA11", "sead", [AD.SA_11_Buk_SR_9S18M1, AD.SA_11_Buk_CC_9S470M1] + [AD.SA_11_Buk_LN_9A310M1] * 3, dy=-900)
    ground_template("TRN_SAM_SA10", "sead", [AD.S_300PS_64H6E_sr, AD.S_300PS_40B6M_tr, AD.S_300PS_54K6_cp]
                    + [AD.S_300PS_5P85C_ln] * 2 + [AD.S_300PS_5P85D_ln] * 2, dy=-700)
    ground_template("TRN_SAM_SA15", "sead", [AD.Tor_9A331] * 2, dy=-500)
    ground_template("TRN_SAM_ZSU23", "sead", [AD.ZSU_23_4_Shilka] * 2, dy=-300)

    # ---------------------------------------------------------------- Zone 4: Bandit-Vorlagen (Luft)
    ix, iy = POS["int"]

    def bandit(name, ptype, size, dy):
        fg = m.flight_group(rus, name, ptype, None, Point(ix, iy - 60000 + dy, m.terrain), altitude=6000, speed=700,
                            group_size=size)
        fg.late_activation = True
        # Route: WP1 = Spawn (wird ersetzt), WP2 in der Zone, WP3 dahinter
        fg.add_waypoint(Point(ix, iy, m.terrain), 6000, 700)
        fg.add_waypoint(Point(ix, iy + 25000, m.terrain), 6000, 700)
        fg.points[0].tasks.append(OptROE(OptROE.Values.WeaponFree))
        return fg

    bandit("TRN_BANDIT_MIG21", planes.MiG_21Bis, 1, 0)
    bandit("TRN_BANDIT_MIG29", planes.MiG_29S, 2, 2000)
    bandit("TRN_BANDIT_SU27", planes.Su_27, 2, 4000)
    bandit("TRN_BANDIT_MIG23", planes.MiG_23MLD, 2, 6000)
    bandit("TRN_BANDIT_TU22", planes.Tu_22M3, 1, 8000)

    # ---------------------------------------------------------------- Zone 5: JTAC + Ziele
    jt = m.vehicle_group(usa, "TRN_JTAC", vehicles.Infantry.JTAC, P(m, "jtac_pos"), heading=0, group_size=1)
    jt.late_activation = True
    ground_template("TRN_JTAC_TGT_1", "jtac_start", [U.Ural_375] * 4, dx=300)
    ground_template("TRN_JTAC_TGT_2", "jtac_start", [A.BTR_80, A.BTR_80, U.Ural_375, U.Ural_375], dx=400)
    ground_template("TRN_JTAC_TGT_3", "jtac_start", [A.T_72B, A.T_72B, A.BMP_2, A.BMP_2, U.Ural_375, U.Ural_375], dx=500)
    ground_template("TRN_JTAC_ESC_1", "jtac_start", [AD.ZSU_23_4_Shilka] * 2, dx=600)

    # ---------------------------------------------------------------- Zone 6: CTLD Logistik-Objekte
    for i, key in enumerate(("ctld_pick_1", "ctld_pick_2"), start=1):
        sg = m.static_group(usa, f"TRN_CTLD_LOGI_{i}", statics.Fortification.FARP_Tent, P(m, key, 60, 0), heading=0)
        sg.units[0].name = f"TRN_CTLD_LOGI_{i}"

    # ---------------------------------------------------------------- Zone 2: Traeger
    cv = m.ship_group(usa, "TRN_CARRIER_GRP", ships.Stennis, P(m, "carrier"), heading=210, group_size=1)
    cv.units[0].name = "TRN_CARRIER"
    cv.add_waypoint(P(m, "carrier_wp2"), speed=18.5)   # pydcs erwartet km/h: 18.5 km/h = 10 kn
    cv.add_waypoint(P(m, "carrier"), speed=18.5)

    # ---------------------------------------------------------------- Spieler-Slots
    kob = m.terrain.airports["Kobuleti"]
    sen = m.terrain.airports["Senaki-Kolkhi"]

    def slots(label, ptype, airport, count):
        for i in range(1, count + 1):
            fg = m.flight_group_from_airport(usa, f"{label} {i}", ptype, airport, start_type=StartType.Cold, group_size=1)
            fg.units[0].set_client()

    slots("F-18C Client", planes.FA_18C_hornet, kob, 2)
    slots("F-16C Client", planes.F_16C_50, kob, 2)
    slots("A-10C II Client", planes.A_10C_2, kob, 2)
    slots("F-14B Client", planes.F_14B, kob, 2)
    slots("CH-47F Client", CH_47Fbl1, sen, 2)
    slots("Mi-8MT Client", helicopters.Mi_8MT, sen, 2)
    slots("AH-64D Client", helicopters.AH_64D_BLK_II, sen, 2)

    # ---------------------------------------------------------------- Skript-Trigger
    trig = TriggerStart(comment="TRN load scripts")
    for rel in LOAD_ORDER:
        src = ROOT / rel
        if not src.exists():
            sys.exit(f"Datei fehlt: {src}")
        key = m.map_resource.add_resource_file(str(src))
        trig.add_action(DoScriptFile(key))
    m.triggerrules.triggers.append(trig)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    m.save(str(out_path))
    return m


def add_sounds(miz_path, sounds_dir):
    """Kopiert die Moose-Soundordner unveraendert ins Archiv."""
    wanted = {
        "Range Soundfiles": sounds_dir / "RANGE" / "Range Soundfiles",
        "Airboss Soundfiles": sounds_dir / "AIRBOSS" / "Airboss Soundfiles",
    }
    with zipfile.ZipFile(miz_path, "a", zipfile.ZIP_DEFLATED) as z:
        for folder, src in wanted.items():
            if not src.is_dir():
                print(f"WARNUNG: {src} nicht gefunden - Ordner '{folder}/' wird nicht eingebaut")
                continue
            files = sorted(p for p in src.iterdir() if p.is_file())
            for p in files:
                z.write(p, f"{folder}/{p.name}")
            print(f"Ordner '{folder}/' mit {len(files)} Dateien eingebaut")


def check_names(miz_path):
    """Prueft, dass alle TRN_-Namen aus 00_config.lua in der Mission vorkommen."""
    wanted = set(re.findall(r'"(TRN_[A-Za-z0-9_]+)"', CONFIG.read_text(encoding="utf-8")))
    m = Mission(Caucasus())
    m.load_file(str(miz_path))
    have = set()
    for z in m.triggers.zones():
        have.add(z.name)
    for coal in m.coalition.values():
        for country in coal.countries.values():
            for cat in ("plane_group", "helicopter_group", "vehicle_group", "ship_group", "static_group"):
                for g in getattr(country, cat, []):
                    have.add(g.name)
                    for u in g.units:
                        have.add(u.name)
    missing = sorted(n for n in wanted if n not in have)
    return wanted, missing, m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=str(ROOT / "mission" / "DCS_Training_Kaukasus.miz"))
    ap.add_argument("--sounds-dir", default=None, help="Pfad zum geklonten MOOSE_SOUND-Repository")
    args = ap.parse_args()

    out = Path(args.output)
    build(args.sounds_dir, out)
    if args.sounds_dir:
        add_sounds(out, Path(args.sounds_dir))

    wanted, missing, m = check_names(out)
    print(f"Mission gespeichert: {out} ({out.stat().st_size / 1e6:.1f} MB)")
    print(f"Namenspruefung: {len(wanted) - len(missing)} von {len(wanted)} TRN_-Namen aus 00_config.lua in der Mission")
    if missing:
        print("FEHLEND:", ", ".join(missing))
        sys.exit(1)


if __name__ == "__main__":
    main()
