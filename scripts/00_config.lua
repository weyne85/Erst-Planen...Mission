-- 00_config.lua
-- Zentrale Konfiguration. ALLE Namen (Zonen, Gruppen, Units), Frequenzen, Texte und Zeiten stehen hier.
-- Aenderungen an der Mission (Umbenennungen usw.) erfordern nur Anpassungen in dieser Datei.
-- Laedt nach mist, Moose, CTLD-i18n, CTLD und vor allen anderen scripts/.

TRN = TRN or {}

TRN.CFG = {
  VERSION = "1.0",
  DEBUG = false,                      -- true: zusaetzliche Log-Eintraege in dcs.log

  SIDE = coalition.side.BLUE,         -- Seite der Spieler und der eigenen Kraefte

  -- Sounds: es werden ausschliesslich die Moose-Soundpakete genutzt (Ordner INNERHALB der .miz, siehe README).
  -- Alle anderen Ansagen dieser Mission erscheinen als Text.
  AIRBOSS_SOUND_FOLDER = "Airboss Soundfiles/",  -- Zone 2 (Airboss)
  RANGE_SOUND_FOLDER = "Range Soundfiles/",      -- Zone 1 (Moose RANGE)

  MAG_VAR = 0,                        -- Korrektur in Grad, wird auf ALLE Peilungen addiert. 0 = rechtweisend (true)

  MENU_ROOT = "Training Zones",
  MENU_SCAN = 3,                      -- Sekunden zwischen den Pruefungen auf neue Spieler
  TICK = 5,                           -- Sekunden zwischen Zonen-Pruefungen (Ziel zerstoert? usw.)
  RESTART_DELAY = 20,                 -- Sekunden nach einer erfolgreichen Runde bis zur naechsten
  LEVELS = { "EASY", "MEDIUM", "HARD" },

  -- ------------------------------------------------------------------
  -- Zone 1: Bodenangriff
  -- ------------------------------------------------------------------
  GA = {
    id = "GA",
    title = "1 Ground Attack",
    zone = "TRN_GA_ZONE",                        -- Triggerzone: Zielgebiet
    roundTimeout = 1800,                         -- Sekunden je Runde, danach Abbruch
    -- Feste Bomben-/Strafing-Range (Moose RANGE, mit Range-Control-Stimme aus den Range Soundfiles).
    -- Ziele sind Units oder statische Objekte aus dem Mission Editor (RED oder neutral).
    range = {
      enabled = true,
      name = "Training Range",
      zone = "TRN_RANGE_ZONE",                                   -- Triggerzone der Range (Bomben ausserhalb werden nicht gewertet)
      bombTargets = { "TRN_RANGE_BOMB_1", "TRN_RANGE_BOMB_2", "TRN_RANGE_BOMB_3" },  -- Unit-/Static-Namen
      goodHitM = 25,                                             -- Trefferradius in Metern
      strafePits = {
        { targets = { "TRN_RANGE_STRAFE_1" }, boxLength = 3000, boxWidth = 300, goodPass = 20, foulLine = 610 },
      },
      rangeControlMHz = 256.0,
      instructorMHz = 257.0,
    },
    levels = {
      EASY   = { pool = { "TRN_GA_VEH_1", "TRN_GA_VEH_2", "TRN_GA_VEH_3" }, count = 2, defenders = {} },
      MEDIUM = { pool = { "TRN_GA_VEH_1", "TRN_GA_VEH_2", "TRN_GA_VEH_3", "TRN_GA_ARM_1", "TRN_GA_ARM_2" }, count = 3, defenders = {} },
      HARD   = { pool = { "TRN_GA_VEH_1", "TRN_GA_VEH_2", "TRN_GA_VEH_3", "TRN_GA_ARM_1", "TRN_GA_ARM_2" }, count = 4,
                 defenders = { "TRN_GA_AAA_1", "TRN_GA_SHORAD_1" } },
    },
  },

  -- ------------------------------------------------------------------
  -- Zone 2: Carrier (Moose AIRBOSS)
  -- ------------------------------------------------------------------
  CARRIER = {
    id = "CARRIER",
    title = "2 Carrier Landing",
    unit = "TRN_CARRIER",                        -- Unit-Name des Traegers (Schiff, nicht die Gruppe)
    alias = "Stennis",
    tacan = { channel = 74, mode = "X", morse = "STN" },
    icls = { channel = 1, morse = "STN" },
    marshalRadio = 305.0,                        -- MHz, AM
    lsoRadio = 264.0,                            -- MHz, AM
    controlledAreaNm = 50,                       -- Kontrollbereich des Airboss
    menuRecovery = { minutes = 30, windOnDeck = 25, uturn = true },  -- Recovery-Menue des Airboss
    -- Automatische Recovery-Fenster: Traeger dreht regelmaessig in den Wind. Wetter ist fest (klar) -> Case I.
    autoRecovery = { enabled = true, firstDelayMin = 3, lengthMin = 30, pauseMin = 15, cases = { 1 } },
  },

  -- ------------------------------------------------------------------
  -- Zone 3: SEAD/DEAD
  -- ------------------------------------------------------------------
  SEAD = {
    id = "SEAD",
    title = "3 SEAD/DEAD",
    zone = "TRN_SEAD_ZONE",
    roundTimeout = 2400,
    modes = { "SEAD", "DEAD" },                  -- SEAD: Radare ausschalten/zerstoeren, DEAD: alles zerstoeren
    warnRangeKm = 45,                            -- ab dieser Entfernung meldet "Threat radar" (einmalig je Runde)
    levels = {
      EASY   = { main = { "TRN_SAM_SA2", "TRN_SAM_SA3" }, escorts = {} },
      MEDIUM = { main = { "TRN_SAM_SA6", "TRN_SAM_SA11" }, escorts = { "TRN_SAM_ZSU23" } },
      HARD   = { main = { "TRN_SAM_SA8" }, escorts = { "TRN_SAM_SA15", "TRN_SAM_ZSU23" } },
    },
    radarAttributes = { "SAM SR", "SAM TR" },    -- Unit-Attribute, die als "Radar" zaehlen (SEAD-Ziel)
  },

  -- ------------------------------------------------------------------
  -- Zone 4: Air Intercept
  -- ------------------------------------------------------------------
  INT = {
    id = "INT",
    title = "4 Air Intercept",
    zone = "TRN_INT_ZONE",
    roundTimeout = 1500,
    spawnRingKm = 70,                            -- Entfernung vom Zonenmittelpunkt, auf der die Gegner starten
    spawnAltM = { 4000, 9000 },                  -- Starthoehe in Metern (min, max)
    awacsInterval = 30,                          -- Sekunden zwischen "Bogey Dope"-Ansagen
    awacsCallsign = "Magic",
    levels = {
      EASY   = { pool = { "TRN_BANDIT_MIG21" }, groups = 1, extra = {} },
      MEDIUM = { pool = { "TRN_BANDIT_MIG29", "TRN_BANDIT_SU27" }, groups = 1, extra = {} },
      HARD   = { pool = { "TRN_BANDIT_MIG29", "TRN_BANDIT_SU27", "TRN_BANDIT_MIG23" }, groups = 2, extra = { "TRN_BANDIT_TU22" } },
    },
  },

  -- ------------------------------------------------------------------
  -- Zone 5: JTAC gegen bewegliche Ziele
  -- ------------------------------------------------------------------
  JTAC = {
    id = "JTAC",
    title = "5 JTAC Moving Targets",
    callsign = "Axeman",
    jtacTemplate = "TRN_JTAC",                   -- Gruppe (Late Activation): JTAC-Fahrzeug/Soldat
    jtacZone = "TRN_JTAC_POS",                   -- Triggerzone: Position des JTAC
    ipZone = "TRN_JTAC_IP",                      -- Triggerzone: Initial Point fuer die 9-Line
    startZone = "TRN_JTAC_START",                -- Triggerzone: hier starten die Ziele
    endZone = "TRN_JTAC_END",                    -- Triggerzone: dorthin fahren die Ziele
    laserCode = 1688,
    roundTimeout = 2400,
    levels = {
      EASY   = { pool = { "TRN_JTAC_TGT_1" }, speedKmh = 20 },
      MEDIUM = { pool = { "TRN_JTAC_TGT_1", "TRN_JTAC_TGT_2" }, speedKmh = 35 },
      HARD   = { pool = { "TRN_JTAC_TGT_2", "TRN_JTAC_TGT_3" }, speedKmh = 50, escorts = { "TRN_JTAC_ESC_1" } },
    },
  },

  -- ------------------------------------------------------------------
  -- Zone 6: CTLD (Lasttransport)
  -- ------------------------------------------------------------------
  CTLD = {
    id = "CTLD",
    title = "6 CTLD Transport",
    pickupZones = { "TRN_CTLD_PICKUP_1", "TRN_CTLD_PICKUP_2" },   -- Triggerzonen: Lager (Kisten/Truppen)
    logisticUnits = { "TRN_CTLD_LOGI_1", "TRN_CTLD_LOGI_2" },     -- Statische Objekte: Logistik (Kisten spawnen)
    taskZones = { "TRN_CTLD_TASK_1", "TRN_CTLD_TASK_2", "TRN_CTLD_TASK_3" },  -- Triggerzonen: Einsatzorte
    roundTimeout = 2400,
    -- Aufgabentyp je Schwierigkeit (Aktionen aus dem CTLD-Callback)
    levels = {
      EASY   = { task = "TROOPS", text = "Deliver troops" },
      MEDIUM = { task = "UNPACK", text = "Deliver crates and build a defence" },
      HARD   = { task = "FOB",    text = "Build a forward operating base" },
    },
  },

  -- ------------------------------------------------------------------
  -- Zone 7: Zufaellige CSAR-Einsaetze (Moose CSAR). Eigenes F10-Menue "CSAR" fuer Hubschrauber (von Moose).
  -- ------------------------------------------------------------------
  CSAR = {
    id = "CSAR",
    title = "7 CSAR",
    enabled = true,
    pilotTemplate = "TRN_CSAR_PILOT",                 -- Gruppe (Late Activation): ein Infanterist
    zones = { "TRN_CSAR_1", "TRN_CSAR_2", "TRN_CSAR_3", "TRN_CSAR_4" },   -- Triggerzonen: hier stuerzen Piloten ab
    mashPrefix = "TRN_MASH",                          -- Triggerzonen mit diesem Praefix = Sanitaetsstation (MASH)
    mashZones = { "TRN_MASH_1" },
    intervalSec = { 900, 1800 },                      -- Zufallsabstand zwischen automatischen Einsaetzen (min, max)
    firstDelaySec = { 240, 600 },                     -- Wartezeit bis zum ersten Einsatz nach Missionsstart
    maxActive = 1,                                    -- gleichzeitig offene Einsaetze
    expireSec = 2700,                                 -- offener Einsatz verfaellt nach dieser Zeit
    onlyWithHelicopter = true,                        -- nur wenn mindestens ein Rettungshubschrauber (Spieler) da ist
    beaconSound = "beacon.ogg",                       -- Datei im Ordner l10n/DEFAULT der .miz (aus MOOSE_SOUND "CTLD CSAR")
    callsigns = { "Viper", "Hawk", "Raven", "Cobra", "Falcon", "Spartan", "Dagger", "Ghost" },
    aircraft = { "F-16C", "F/A-18C", "A-10C II", "F-14B" },
  },

  -- ------------------------------------------------------------------
  -- Beleben: Flugplatzbetrieb (Moose RAT), Militaerkonvois
  -- ------------------------------------------------------------------
  AMBIENT = {
    id = "AMBIENT",
    title = "8 Convoys and Traffic",
    -- KI-Flugverkehr zwischen den Flugplaetzen. Starts von der Piste (kein Parkplatz-Konflikt mit Spielern).
    rat = {
      enabled = true,
      airfields = { "Kobuleti", "Senaki-Kolkhi", "Kutaisi", "Batumi" },
      flights = {
        { template = "TRN_RAT_C130", alias = "RAT C-130", count = 2, intervalSec = 600, delaySec = 120 },
        { template = "TRN_RAT_AN26", alias = "RAT An-26", count = 1, intervalSec = 900, delaySec = 420 },
      },
    },

    -- Konvois fahren auf Strassen zwischen den Zonen und werden nach Ankunft oder Zeitablauf entfernt.
    -- side BLUE = freundlicher Nachschub (nur Leben auf der Karte), RED = feindlicher Konvoi (Gelegenheitsziel, wird angesagt).
    convoys = {
      {
        id = "blue_log", side = "BLUE", announce = false,
        templates = { "TRN_CONVOY_BLUE_1", "TRN_CONVOY_BLUE_2" },
        zones = { "TRN_CONV_A", "TRN_CONV_B", "TRN_CONV_C", "TRN_CONV_D" },
        speedKmh = { 30, 50 }, intervalSec = { 420, 900 }, firstDelaySec = { 60, 180 }, maxActive = 2, ttlSec = 1800,
      },
      {
        id = "red_raid", side = "RED", announce = true,
        templates = { "TRN_CONVOY_RED_1", "TRN_CONVOY_RED_2" },
        zones = { "TRN_CONV_RED_A", "TRN_CONV_RED_B" },
        speedKmh = { 30, 45 }, intervalSec = { 900, 1500 }, firstDelaySec = { 300, 600 }, maxActive = 1, ttlSec = 2400,
      },
    },
  },

  -- ------------------------------------------------------------------
  -- Ansagen: Ereignis -> englischer Text und Anzeigedauer in Sekunden (Ueberlappungsschutz).
  -- Nur Text, keine eigenen Sounddateien.
  -- ------------------------------------------------------------------
  MESSAGES = {
    -- allgemein
    welcome         = { dur = 5, text = "Welcome to the training range. Open the F10 menu, Training Zones, to select an exercise." },
    zone_busy       = { dur = 4, text = "Zone is busy with another flight. Try again later." },
    zone_stopped    = { dur = 3, text = "Exercise stopped. Zone cleaned up." },
    zone_timeout    = { dur = 4, text = "Time expired. Exercise ended." },
    -- Zone 1
    ga_briefing     = { dur = 6, text = "Ground attack range is hot. Targets marked in the target area. Report when in." },
    ga_hit          = { dur = 3, text = "Good hit. Target destroyed." },
    ga_complete     = { dur = 5, text = "All targets destroyed. Range will reset shortly." },
    -- Zone 2 (Carrier): Sprache und Sounds kommen komplett vom Airboss (Moose-Soundpaket)
    -- Zone 3
    sead_briefing   = { dur = 6, text = "Enemy air defence in the area. Suppress or destroy as briefed." },
    sead_radar      = { dur = 3, text = "Threat radar detected." },
    sead_launch     = { dur = 3, text = "Missile launch! Missile launch!" },
    sead_complete   = { dur = 5, text = "Objective complete. Air defence neutralized." },
    -- Zone 4
    int_briefing    = { dur = 6, text = "Hostile aircraft inbound. Intercept and identify." },
    int_splash      = { dur = 3, text = "Splash one." },
    int_complete    = { dur = 5, text = "All hostile aircraft destroyed. New wave shortly." },
    -- Zone 5
    jtac_checkin    = { dur = 5, text = "Roger, checked in. Standby for nine-line." },
    jtac_hot        = { dur = 4, text = "Cleared hot. Marking target." },
    jtac_bda        = { dur = 5, text = "Good hits. Target destroyed. Standby for next tasking." },
    jtac_negative   = { dur = 3, text = "Negative. Follow the sequence: check in, nine-line, in hot." },
    -- Zone 6
    ctld_briefing   = { dur = 6, text = "Logistics tasking received." },
    ctld_complete   = { dur = 5, text = "Delivery confirmed. Well done." },
  },
}
