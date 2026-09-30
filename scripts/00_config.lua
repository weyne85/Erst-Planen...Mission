-- 00_config.lua
-- Zentrale Konfiguration. ALLE Namen (Zonen, Gruppen, Units), Frequenzen, Texte und Zeiten stehen hier.
-- Aenderungen an der Mission (Umbenennungen usw.) erfordern nur Anpassungen in dieser Datei.
-- Laedt nach mist, Moose, CTLD-i18n, CTLD und vor allen anderen scripts/.

TRN = TRN or {}

TRN.CFG = {
  VERSION = "1.0",
  DEBUG = false,                      -- true: zusaetzliche Log-Eintraege in dcs.log

  SIDE = coalition.side.BLUE,         -- Seite der Spieler und der eigenen Kraefte
  ENEMY = coalition.side.RED,         -- Seite der Gegner

  -- Sound: Ordner INNERHALB der .miz, in dem die .ogg-Dateien liegen (siehe README).
  SOUND_FOLDER = "TRN Sounds/",
  AIRBOSS_SOUND_FOLDER = "Airboss Soundfiles/",  -- Moose-Soundpaket fuer den Airboss (siehe README)

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
      HARD   = { main = { "TRN_SAM_SA10" }, escorts = { "TRN_SAM_SA15", "TRN_SAM_ZSU23" } },
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
  -- Sounds: Ereignis -> Datei, englischer Text, ungefaehre Dauer in Sekunden.
  -- Ohne vorhandene Datei erscheint der Text weiterhin als Bildschirmmeldung.
  -- ------------------------------------------------------------------
  SOUNDS = {
    -- allgemein
    welcome         = { file = "gen_welcome.ogg",        dur = 5, text = "Welcome to the training range. Open the F10 menu, Training Zones, to select an exercise." },
    zone_busy       = { file = "gen_zone_busy.ogg",      dur = 4, text = "Zone is busy with another flight. Try again later." },
    zone_stopped    = { file = "gen_zone_stopped.ogg",   dur = 3, text = "Exercise stopped. Zone cleaned up." },
    zone_timeout    = { file = "gen_timeout.ogg",        dur = 4, text = "Time expired. Exercise ended." },
    -- Zone 1
    ga_briefing     = { file = "ga_briefing.ogg",        dur = 6, text = "Ground attack range is hot. Targets marked in the target area. Report when in." },
    ga_hit          = { file = "ga_hit.ogg",             dur = 3, text = "Good hit. Target destroyed." },
    ga_complete     = { file = "ga_complete.ogg",        dur = 5, text = "All targets destroyed. Range will reset shortly." },
    -- Zone 2 (Carrier): Sprache und Sounds kommen komplett vom Airboss (Moose-Soundpaket)
    -- Zone 3
    sead_briefing   = { file = "sead_briefing.ogg",      dur = 6, text = "Enemy air defence in the area. Suppress or destroy as briefed." },
    sead_radar      = { file = "sead_radar.ogg",         dur = 3, text = "Threat radar detected." },
    sead_launch     = { file = "sead_launch.ogg",        dur = 3, text = "Missile launch! Missile launch!" },
    sead_complete   = { file = "sead_complete.ogg",      dur = 5, text = "Objective complete. Air defence neutralized." },
    -- Zone 4
    int_briefing    = { file = "int_briefing.ogg",       dur = 6, text = "Hostile aircraft inbound. Intercept and identify." },
    int_bogey       = { file = "int_bogey_dope.ogg",     dur = 3, text = "Bogey dope." },
    int_splash      = { file = "int_splash.ogg",         dur = 3, text = "Splash one." },
    int_complete    = { file = "int_complete.ogg",       dur = 5, text = "All hostile aircraft destroyed. New wave shortly." },
    -- Zone 5
    jtac_checkin    = { file = "jtac_checkin.ogg",       dur = 5, text = "Roger, checked in. Standby for nine-line." },
    jtac_nineline   = { file = "jtac_nineline.ogg",      dur = 4, text = "Nine-line follows. Ready to copy." },
    jtac_hot        = { file = "jtac_cleared_hot.ogg",   dur = 4, text = "Cleared hot. Marking target." },
    jtac_bda        = { file = "jtac_bda.ogg",           dur = 5, text = "Good hits. Target destroyed. Standby for next tasking." },
    jtac_negative   = { file = "jtac_negative.ogg",      dur = 3, text = "Negative. Follow the sequence: check in, nine-line, in hot." },
    -- Zone 6
    ctld_briefing   = { file = "ctld_briefing.ogg",      dur = 6, text = "Logistics tasking received." },
    ctld_complete   = { file = "ctld_complete.ogg",      dur = 5, text = "Delivery confirmed. Well done." },
  },
}
