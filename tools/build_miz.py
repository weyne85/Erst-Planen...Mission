#!/usr/bin/env python3
"""Erzeugt die Trainingsmission als .miz (Kaukasus) mit pydcs.

Aufruf (im Repo-Hauptverzeichnis):
    pip install pydcs matplotlib adjustText mgrs pillow   (und lua5.1)
    python3 tools/build_miz.py [--sounds-dir PFAD_ZU_MOOSE_SOUND] [-o mission/DCS_Training_Kaukasus.miz]

Was erzeugt wird:
  * Trigger "MISSION START" mit 15x DO SCRIPT FILE (Ladereihenfolge wie in der README)
  * alle Triggerzonen, Vorlagegruppen (Late Activation), Range-Ziele, Traeger, CTLD-Logistik, JTAC
  * Spieler-Slots (Client) fuer alle Muster
  * Briefing (Lage, Zonen, Frequenzen), Wegpunkte fuer alle Client-Slots, Kneeboard-Seiten je Flugzeugtyp
  * Karten und Objektliste (mission/map), Kneeboard-PNGs (mission/kneeboard)
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
sys.path.insert(0, str(Path(__file__).resolve().parent))
import briefing
from types_extra import CH_47Fbl1
from dcs import countries, helicopters, planes, ships, statics, task, vehicles
from dcs.mapping import Point
from dcs.mission import Mission, StartType
from dcs.terrain import Caucasus
from dcs.triggers import TriggerOnce, TriggerStart
from dcs.action import DoScriptFile, SoundToAll
from dcs.condition import FlagIsTrue
from dcs.task import OptROE
import random

ROOT = Path(__file__).resolve().parent.parent

# ----------------------------------------------------------------------------------------------
# Positionen (DCS-Koordinaten: x = Norden, y = Osten; Meter). PLATZHALTER, im Editor pruefen!
# ----------------------------------------------------------------------------------------------
POS = {
    "range":        (-262000, 655000),   # Bomben-/Strafing-Range, NNO von Senaki
    "ga":           (-250000, 675000),   # dynamische Bodenziele
    "sead":         (-284900, 739400),   # ca. 30 nm (55,6 km) ostlich von Kutaisi
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
    # CSAR (Absturzzonen und Sanitaetsstation)
    "csar_1":       (-258000, 640000),
    "csar_2":       (-300000, 668000),
    "csar_3":       (-265000, 700000),
    "csar_4":       (-325000, 665000),
    "mash_1":       (-283000, 646000),   # bei Senaki-Kolkhi (Hubschrauberbasis)
    # Konvoi-Endpunkte (nahe den Flugplaetzen Senaki, Kutaisi, Kobuleti, Batumi; Strassen pruefen!)
    "conv_a":       (-279500, 650500),
    "conv_b":       (-282000, 680000),
    "conv_c":       (-315500, 640000),
    "conv_d":       (-353500, 621500),
    "conv_red_a":   (-146000, 838000),   # bei Beslan
    "conv_red_b":   (-127000, 765000),   # bei Nalchik
}

# Schiffsrouten (Meter, x = Nord, y = Ost). Alle Punkte liegen mit grossem Abstand zur Kueste im Schwarzen Meer.
SHIP_LANES = {
    "cargo_1":  [(-180000, 400000), (-262000, 468000), (-330000, 470000), (-262000, 468000), (-180000, 400000)],
    "tanker_1": [(-290000, 430000), (-215000, 385000), (-290000, 430000)],
    "cargo_2":  [(-300000, 555000), (-345000, 570000), (-300000, 555000)],
}

CONFIG = ROOT / "scripts" / "00_config.lua"

LOAD_ORDER = [
    "libs/mist.lua", "libs/Moose.lua", "libs/CTLD-i18n.lua", "libs/CTLD.lua",
    "scripts/00_config.lua", "scripts/01_core.lua", "scripts/02_audio.lua", "scripts/03_menu.lua",
    "scripts/10_ground_attack.lua", "scripts/20_carrier.lua", "scripts/30_sead_dead.lua",
    "scripts/40_intercept.lua", "scripts/50_jtac.lua", "scripts/60_ctld.lua", "scripts/70_csar.lua",
    "scripts/80_ambient.lua", "libs/A10_laste_Winds.lua", "scripts/99_init.lua",
]



def P(m, key_or_xy, dx=0, dy=0):
    x, y = POS[key_or_xy] if isinstance(key_or_xy, str) else key_or_xy
    return Point(x + dx, y + dy, m.terrain)


def build(sounds_dir, out_path, extras=None):
    """extras: optional dict(kneeboards={Typ-ID: [PNG]}, pictures=[PNG]) fuer Phase 2 (nach der Kartenerzeugung)."""
    extras = extras or {}
    m = Mission(Caucasus())
    cfg = briefing.load_cfg()
    geo = briefing.Geo(m.terrain, POS)
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

    situation, blue_task, red_task = briefing.briefing_texts(geo, cfg)
    m.set_description_text(situation)
    m.set_description_bluetask_text(blue_task)
    m.set_description_redtask_text(red_task)
    for pic in extras.get("pictures", []):
        m.add_picture_blue(str(pic))

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
    ground_template("TRN_SAM_SA8", "sead", [AD.Osa_9A33_ln] * 3, dy=-700)   # SA-8: kurze Reichweite (ca. 15 km), Radar je Fahrzeug
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
    cv.points[-1].tasks.append(task.SwitchWaypoint(from_waypoint=len(cv.points), to_waypoint=1))   # endlose Schleife

    # ---------------------------------------------------------------- Flugplaetze der Spieler: BLUE
    for name in ("Kobuleti", "Senaki-Kolkhi", "Batumi", "Kutaisi"):
        m.terrain.airports[name].set_blue()

    # ---------------------------------------------------------------- Zone 7: CSAR
    for i, key in enumerate(("csar_1", "csar_2", "csar_3", "csar_4"), start=1):
        zone(f"TRN_CSAR_{i}", key, 2500)
    zone("TRN_MASH_1", "mash_1", 300)
    pilot = m.vehicle_group(usa, "TRN_CSAR_PILOT", vehicles.Infantry.Soldier_M4, P(m, "csar_1"), heading=0, group_size=1)
    pilot.late_activation = True

    # ---------------------------------------------------------------- Konvois
    for letter, key in zip("ABCD", ("conv_a", "conv_b", "conv_c", "conv_d")):
        zone(f"TRN_CONV_{letter}", key, 800)
    zone("TRN_CONV_RED_A", "conv_red_a", 800)
    zone("TRN_CONV_RED_B", "conv_red_b", 800)
    ground_template("TRN_CONVOY_BLUE_1", "conv_a", [U.Hummer, U.M_818, U.M_818, U.M978_HEMTT_Tanker, U.M_818], country=usa, dy=-300)
    ground_template("TRN_CONVOY_BLUE_2", "conv_a", [A.M1126_Stryker_ICV, U.M_818, U.M_818, U.Hummer], country=usa, dy=-250)
    ground_template("TRN_CONVOY_RED_1", "conv_red_a", [A.BTR_80, U.Ural_375, U.Ural_375, U.KAMAZ_Truck, U.Ural_375], dy=-300)
    ground_template("TRN_CONVOY_RED_2", "conv_red_a", [A.BMP_2, A.BTR_80, U.Ural_375, U.Ural_375, AD.ZSU_23_4_Shilka], dy=-250)

    # ---------------------------------------------------------------- Flugplatzbetrieb: RAT-Vorlagen (KI-Transporter)
    kx, ky = m.terrain.airports["Kobuleti"].position.x, m.terrain.airports["Kobuleti"].position.y
    for name, ptype, dy in (("TRN_RAT_C130", planes.C_130, 0), ("TRN_RAT_AN26", planes.An_26B, 2000)):
        fg = m.flight_group(usa, name, ptype, None, Point(kx, ky + 8000 + dy, m.terrain), altitude=3000, speed=450,
                            group_size=1)
        fg.late_activation = True
        fg.add_waypoint(Point(kx - 20000, ky + 30000 + dy, m.terrain), 3000, 450)

    # ---------------------------------------------------------------- Flugplatzbetrieb: Kulisse (Statics, Fahrzeuge)
    rnd = random.Random(7)   # feste Reihenfolge: bei jedem Bau gleiches Ergebnis

    def airfield_scene(airport_name, plane_types, vehicle_count):
        ap = m.terrain.airports[airport_name]
        slots = [sl for sl in ap.parking_slots if sl.airplanes][2::3]   # jeder dritte Platz, luftig verteilt
        for i, ptype in enumerate(plane_types):
            if i >= len(slots):
                break
            sg = m.static_group(usa, f"TRN_STATIC_{airport_name}_{i + 1}", ptype, slots[i].position, heading=rnd.randrange(0, 360))
            sg.units[0].name = f"TRN_STATIC_{airport_name}_{i + 1}"
        vtypes = [U.M978_HEMTT_Tanker, U.Hummer, U.Ural_4320_APA_5D, U.M_818]
        for j in range(vehicle_count):
            base = slots[(j + len(plane_types)) % len(slots)].position
            g = m.vehicle_group(usa, f"TRN_AIRFIELD_{airport_name}_{j + 1}", vtypes[j % len(vtypes)],
                                Point(base.x + 18, base.y + 12, m.terrain), heading=rnd.randrange(0, 360), group_size=1)

    airfield_scene("Kutaisi", [planes.A_10C_2, planes.A_10C_2, planes.F_16C_50, planes.F_16C_50, planes.FA_18C_hornet, planes.C_130], 4)
    airfield_scene("Batumi", [planes.FA_18C_hornet, planes.F_16C_50], 3)

    # ---------------------------------------------------------------- Schiffsverkehr (BLUE-Handelsschiffe, Pendelrouten)
    def ship_loop(name, stype, pts, speed_kmh):
        sg = m.ship_group(usa, name, stype, Point(pts[0][0], pts[0][1], m.terrain), heading=0, group_size=1)
        for x, y in pts[1:]:
            sg.add_waypoint(Point(x, y, m.terrain), speed=speed_kmh)
        # am letzten Wegpunkt zurueck zu Wegpunkt 1: endloser Pendelverkehr
        sg.points[-1].tasks.append(task.SwitchWaypoint(from_waypoint=len(sg.points), to_waypoint=1))
        return sg

    ship_loop("TRN_SHIP_CARGO_1", ships.Dry_cargo_ship_1, SHIP_LANES["cargo_1"], 22)
    ship_loop("TRN_SHIP_TANKER_1", ships.ELNYA, SHIP_LANES["tanker_1"], 20)
    ship_loop("TRN_SHIP_CARGO_2", ships.HandyWind, SHIP_LANES["cargo_2"], 20)

    # Begleitschiffe des Traegers (gleiche Route, seitlich versetzt)
    cx, cy = POS["carrier"]
    wx, wy = POS["carrier_wp2"]
    for i, off in enumerate((6000, -6000), start=1):
        ship_loop(f"TRN_ESCORT_{i}", ships.PERRY, [(cx, cy + off), (wx, wy + off), (cx, cy + off)], 18.5)

    # ---------------------------------------------------------------- Spieler-Slots
    kob = m.terrain.airports["Kobuleti"]
    sen = m.terrain.airports["Senaki-Kolkhi"]

    def slots(label, ptype, airport, count):
        for i in range(1, count + 1):
            fg = m.flight_group_from_airport(usa, f"{label} {i}", ptype, airport, start_type=StartType.Cold, group_size=1)
            fg.units[0].set_client()
            # Flugplan: Wegpunkte fuer die Zonen und Aufgaben (gleiche Tabelle wie im Kneeboard)
            for name, alt, spd, atype, _note in briefing.ROUTES[ptype.id]:
                x, y = geo.points[name]
                mp = fg.add_waypoint(Point(x, y, m.terrain), alt, spd, name=name)
                mp.alt_type = atype
            fg.land_at(airport)

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

    # CSAR-Funkfeuer: Datei muss in l10n/DEFAULT liegen. Ein nie ausgeloester Trigger referenziert sie, damit der
    # Mission Editor sie beim Speichern nicht als "ungenutzt" entfernt.
    if sounds_dir:
        beacon = Path(sounds_dir) / "CTLD CSAR" / "beacon.ogg"
        if beacon.exists():
            key = m.map_resource.add_resource_file(str(beacon))
            keep = TriggerOnce(comment="TRN keep beacon.ogg (never fires)")
            keep.add_condition(FlagIsTrue(9999))
            keep.add_action(SoundToAll(key))
            m.triggerrules.triggers.append(keep)
        else:
            print(f"WARNUNG: {beacon} nicht gefunden - CSAR-Funkfeuer hat keinen Ton")

    types = {"FA-18C_hornet": planes.FA_18C_hornet, "F-16C_50": planes.F_16C_50, "A-10C_2": planes.A_10C_2,
             "F-14B": planes.F_14B, "CH-47Fbl1": CH_47Fbl1, "Mi-8MT": helicopters.Mi_8MT,
             "AH-64D_BLK_II": helicopters.AH_64D_BLK_II}
    for tid, pages in extras.get("kneeboards", {}).items():
        for page in pages:
            m.add_aircraft_kneeboard(types[tid], Path(page))

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
    # Praefixe (z. B. TRN_MASH fuer TRN_MASH_1) gelten als vorhanden, wenn mindestens ein Objekt so beginnt
    missing = sorted(n for n in wanted if n not in have and not any(h.startswith(n) for h in have))
    return wanted, missing, m


def main():
    import shutil
    import tempfile

    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=str(ROOT / "mission" / "DCS_Training_Kaukasus.miz"))
    ap.add_argument("--sounds-dir", default=None, help="Pfad zum geklonten MOOSE_SOUND-Repository")
    args = ap.parse_args()
    out = Path(args.output)

    import plot_map

    # Phase 1: Mission ohne Karten/Kneeboards -> daraus Karten und Objektliste
    tmp = Path(tempfile.mkdtemp()) / "phase1.miz"
    build(None, tmp)
    items, airports = plot_map.load(tmp)
    plot_map.render_all(items, airports)

    # Kneeboards: Seiten als PNG nach mission/kneeboard/ (werden auch in die .miz gepackt)
    kbdir = ROOT / "mission" / "kneeboard"
    shutil.rmtree(kbdir, ignore_errors=True)
    kb_maps = plot_map.render_kneeboard_maps(items, airports, kbdir / "_maps")
    cfg = briefing.load_cfg()
    terrain = Caucasus()
    pages = briefing.build_kneeboards(kbdir, briefing.Geo(terrain, POS), cfg, terrain.airports, kb_maps)
    shutil.rmtree(kbdir / "_maps", ignore_errors=True)

    # Phase 2: endgueltige Mission mit Briefing-Bildern, Kneeboards und Soundordnern
    pictures = [ROOT / "mission" / "map" / "01_uebersicht.png", ROOT / "mission" / "map" / "02_west_georgien.png"]
    build(args.sounds_dir, out, extras=dict(kneeboards=pages, pictures=pictures))
    if args.sounds_dir:
        add_sounds(out, Path(args.sounds_dir))

    wanted, missing, m = check_names(out)
    print(f"Mission gespeichert: {out} ({out.stat().st_size / 1e6:.1f} MB)")
    print(f"Kneeboard-Seiten: {sum(len(v) for v in pages.values())} fuer {len(pages)} Flugzeugtypen in {kbdir}")
    print(f"Namenspruefung: {len(wanted) - len(missing)} von {len(wanted)} TRN_-Namen aus 00_config.lua in der Mission")
    if missing:
        print("FEHLEND:", ", ".join(missing))
        sys.exit(1)


if __name__ == "__main__":
    main()
