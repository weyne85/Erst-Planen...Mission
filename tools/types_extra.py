"""Typen, die pydcs 0.15 nicht kennt (damit build_miz.py und plot_map.py sie gemeinsam nutzen)."""
from dcs import helicopters, task
from dcs.helicopters import HelicopterType


class CH_47Fbl1(HelicopterType):
    """CH-47F (DCS-Modul). Mit der DCS-Typ-ID definiert; Startsprit bewusst niedrig."""
    id = "CH-47Fbl1"
    flyable = True
    large_parking_slot = True
    height = 5.9
    width = 18.3
    length = 30.1
    fuel_max = 2500
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
