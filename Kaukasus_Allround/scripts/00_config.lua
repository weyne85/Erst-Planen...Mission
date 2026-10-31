-- =====================================================================
-- Kaukasus Allround Training - 00_config.lua
-- Single source of truth: every mission editor name, frequency, TACAN
-- channel and timer lives here. Scripts never hardcode names.
-- Naming scheme (docs/README.md section 5):
--   templates  <COALITION>_<Role>_Template
--   zones      <COALITION>_<Purpose>_Zone<N>
-- Exception: front zones (FRONT_*) belong to no coalition.
-- =====================================================================

KA = KA or {}

KA.CFG = {
  version = "1.0.0",

  -- Messages
  msgTime     = 15,      -- default message duration (s)
  magneticBrg = true,    -- bearings in messages magnetic (true) or true north (false)

  -- Player detection
  blueHeliPrefix = "BLUE Heli",   -- group name prefix of all BLUE helicopter client slots (CTLD/CSAR)

  -- ===================================================================
  -- Session scenarios (one player group per zone, BFM: one per group)
  -- ===================================================================
  session = {
    tick         = 5,     -- status check interval (s)
    restartDelay = 30,    -- new round after success (s)
  },

  -- -------------------------------------------------------------------
  -- Range (always open)
  -- -------------------------------------------------------------------
  range = {
    name           = "Kutaisi East Range",
    zone           = "BLUE_Range_Zone1",
    bombTargets    = { "RED_Range_Bomb_Target1", "RED_Range_Bomb_Target2", "RED_Range_Bomb_Target3" },
    goodHit        = 25,     -- m
    strafePits     = {
      { "RED_Range_Strafe_Pit1_Target1", "RED_Range_Strafe_Pit1_Target2" },
      { "RED_Range_Strafe_Pit2_Target1", "RED_Range_Strafe_Pit2_Target2" },
    },
    strafeBoxLength = 3000,  -- m
    strafeBoxWidth  = 300,   -- m
    strafeGoodPass  = 20,    -- hits
    strafeFoulLine  = 610,   -- m
    soundPath       = "Range Soundfiles/",
    controlFreq     = 250.0, -- MHz AM
    instructorFreq  = 251.0, -- MHz AM
  },

  -- -------------------------------------------------------------------
  -- CAS with JTAC (session)
  -- -------------------------------------------------------------------
  cas = {
    zone        = "RED_CAS_Zone1",
    targets     = { "RED_CAS_Armor_Template", "RED_CAS_Infantry_Template", "RED_CAS_Convoy_Template", "RED_CAS_Mixed_Template" },
    groupsPerRound = 2,
    jtacTemplate = "BLUE_CAS_JTAC_Template",   -- MQ-9 Reaper, late activation
    jtacAlias    = "BLUE JTAC CAS",            -- must contain autolase.recceprefix
    jtacAltFt    = 15000,
    jtacSpeedKts = 120,
    laserCode    = 1688,
    timeout      = 45 * 60,
  },

  -- -------------------------------------------------------------------
  -- SEAD / DEAD (session)
  -- -------------------------------------------------------------------
  sead = {
    zone       = "RED_SEAD_Zone1",
    -- alias must contain the MANTIS prefix and the SAM type (MANTIS auto mode)
    sams = {
      { template = "RED_SEAD_SA-2_Template",  alias = "RED SEAD SAM SA-2" },
      { template = "RED_SEAD_SA-3_Template",  alias = "RED SEAD SAM SA-3" },
      { template = "RED_SEAD_SA-6_Template",  alias = "RED SEAD SAM SA-6" },
      { template = "RED_SEAD_SA-11_Template", alias = "RED SEAD SAM SA-11" },
    },
    shorad = {
      { template = "RED_SEAD_SHORAD_SA-15_Template", alias = "RED SEAD SHORAD SA-15" },
      { template = "RED_SEAD_SHORAD_SA-8_Template",  alias = "RED SEAD SHORAD SA-8" },
    },
    ewr        = { template = "RED_SEAD_EWR_Template", alias = "RED SEAD EWR" },
    samPrefix    = "RED SEAD SAM",
    ewrPrefix    = "RED SEAD EWR",
    shoradPrefix = "RED SEAD SHORAD",
    samsPerRound   = 2,
    shoradPerRound = 2,
    timeout      = 60 * 60,
  },

  -- -------------------------------------------------------------------
  -- Strike (session): statics placed in the ME inside the site zones
  -- -------------------------------------------------------------------
  strike = {
    sites       = { "RED_Strike_Zone1", "RED_Strike_Zone2", "RED_Strike_Zone3", "RED_Strike_Zone4" },
    aaaTemplate = "RED_Strike_AAA_Template",
    aaaPerRound = 2,
    timeout     = 45 * 60,
  },

  -- -------------------------------------------------------------------
  -- Anti-ship (session)
  -- -------------------------------------------------------------------
  antiship = {
    zone      = "RED_AntiShip_Zone1",
    templates = { "RED_AntiShip_Convoy_Template", "RED_AntiShip_Patrol_Template", "RED_AntiShip_Frigate_Template" },
    speedKts  = 12,
    timeout   = 60 * 60,
  },

  -- -------------------------------------------------------------------
  -- BFM on demand (parallel, one bandit per player group)
  -- -------------------------------------------------------------------
  bfm = {
    bandits = {
      { name = "MiG-21",  template = "RED_BFM_MiG-21_Template" },
      { name = "MiG-29",  template = "RED_BFM_MiG-29_Template" },
      { name = "Su-27",   template = "RED_BFM_Su-27_Template" },
      { name = "F-5E",    template = "RED_BFM_F-5E_Template" },
    },
    minAltFt   = 5000,    -- bandit is never spawned below this altitude (AGL check by player alt)
    timeout    = 15 * 60,
  },

  -- -------------------------------------------------------------------
  -- FOX missile trainer (global)
  -- -------------------------------------------------------------------
  fox = {
    destroyMissiles = true,
    launchAlerts    = true,
    launchMarks     = false,
  },

  -- -------------------------------------------------------------------
  -- Carrier (AIRBOSS + recovery tanker + rescue helo)
  -- -------------------------------------------------------------------
  carrier = {
    unit          = "BLUE_Carrier",                       -- unit name of the CVN-71..75 (Supercarrier)
    alias         = "Carrier",
    soundFolder   = "Airboss Soundfiles/",
    tacan         = { channel = 71, mode = "X", morse = "CVN" },
    icls          = { channel = 11, morse = "CVN" },
    lsoFreq       = 264.0,
    marshalFreq   = 305.0,
    recoveryMin   = 30,      -- menu recovery window (min)
    windOnDeck    = 25,      -- kts
    tanker        = { template = "BLUE_Carrier_Tanker_Template", tacan = 63, morse = "SHL", freq = 265.0 },
    rescueHelo    = { template = "BLUE_Carrier_RescueHelo_Template" },
  },

  -- -------------------------------------------------------------------
  -- AAR and AWACS (Ops AIRWING at Kutaisi)
  -- -------------------------------------------------------------------
  support = {
    warehouse = "BLUE_Airwing_Kutaisi_Warehouse",   -- static (e.g. "Warehouse") within 5 km of Kutaisi
    name      = "BLUE Support Wing",
    tankers = {
      { name = "Texaco", template = "BLUE_Tanker_Boom_Template",   zone = "BLUE_Tanker_Boom_Zone",
        system = "boom",  tacan = 51, band = "Y", morse = "TEX", freq = 252.0, altFt = 20000, speedKts = 300, heading = 90, legNm = 30 },
      { name = "Arco",   template = "BLUE_Tanker_Drogue_Template", zone = "BLUE_Tanker_Drogue_Zone",
        system = "probe", tacan = 52, band = "Y", morse = "ARC", freq = 253.0, altFt = 18000, speedKts = 280, heading = 0,  legNm = 30 },
    },
    awacs = { name = "Overlord", template = "BLUE_AWACS_Template", zone = "BLUE_AWACS_Zone",
              freq = 254.0, altFt = 30000, speedKts = 350, heading = 90, legNm = 40 },
    repeats = 99,
  },

  -- -------------------------------------------------------------------
  -- ATIS (Moose sound files, no SRS) and navigation
  -- -------------------------------------------------------------------
  atis = {
    soundPath = "ATIS Soundfiles/",
    stations = {
      { airbase = "Kutaisi",       freq = 260.0 },
      { airbase = "Senaki-Kolkhi", freq = 261.0 },
      { airbase = "Batumi",        freq = 262.0 },
    },
  },
  nav = {
    checkpoints = { "BLUE_Nav_Zone1", "BLUE_Nav_Zone2", "BLUE_Nav_Zone3", "BLUE_Nav_Zone4",
                    "BLUE_Nav_Zone5", "BLUE_Nav_Zone6", "BLUE_Nav_Zone7", "BLUE_Nav_Zone8" },
    legs      = 4,         -- checkpoints per route
    speedKts  = 300,       -- planned ground speed for ETAs (jets)
    heloSpeedKts = 110,    -- planned ground speed for helicopters
    timeout   = 60 * 60,
    ndb = { object = "BLUE_FARP_Senaki", file = "beacon.ogg", freqMHz = 0.420, powerW = 1000 },
  },

  -- -------------------------------------------------------------------
  -- CTLD (Moose Ops.CTLD)
  -- -------------------------------------------------------------------
  ctld = {
    alias     = "Kaukasus Logistics",
    loadZones = { "BLUE_CTLD_Load_Zone1", "BLUE_CTLD_Load_Zone2" },
    troops = {
      { name = "Infantry Squad",  template = "BLUE_CTLD_Infantry_Template",  size = 8 },
      { name = "Anti-Tank Team",  template = "BLUE_CTLD_ATGM_Template",      size = 4 },
      { name = "Mortar Team",     template = "BLUE_CTLD_Mortar_Template",    size = 4 },
      { name = "Engineers",       template = "BLUE_CTLD_Engineers_Template", size = 4, engineers = true },
    },
    crates = {
      { name = "Humvee TOW",       template = "BLUE_CTLD_Humvee_Template",  crates = 2, mass = 1500 },
      { name = "Avenger SHORAD",   template = "BLUE_CTLD_Avenger_Template", crates = 2, mass = 1500 },
      { name = "Forward Ops Base", template = "BLUE_CTLD_FOB_Template",     crates = 4, mass = 1000, fob = true },
    },
    beaconSound = "beacon.ogg",
  },

  -- -------------------------------------------------------------------
  -- CSAR (Moose Ops.CSAR, BLUE) and AICSAR (RED AI rescue)
  -- -------------------------------------------------------------------
  csar = {
    alias        = "Kaukasus CSAR",
    pilotTemplate = "BLUE_CSAR_Pilot_Template",
    mashPrefix   = "BLUE_MASH",              -- zones/statics/groups starting with this are MASHes
    beaconSound  = "beacon.ogg",
    randomZones  = { "BLUE_CSAR_Zone1", "BLUE_CSAR_Zone2", "BLUE_CSAR_Zone3", "BLUE_CSAR_Zone4" },
    randomMinMin = 20,                        -- random CSAR event every 20..40 min
    randomMaxMin = 40,
    maxDowned    = 6,
  },
  aicsarRed = {
    alias        = "Red Rescue",
    pilotTemplate = "RED_CSAR_Pilot_Template",
    heloTemplate  = "RED_CSAR_Helo_Template",
    airbase      = "Gudauta",
    mashZone     = "RED_MASH_Zone1",
    helos        = 2,
  },

  -- -------------------------------------------------------------------
  -- Campaign: endless ground war Senaki - Sukhumi
  -- -------------------------------------------------------------------
  campaign = {
    -- front zones (round trigger zones). owner = initial owner
    zones = {
      { name = "FRONT_Zugdidi",    owner = "blue" },
      { name = "FRONT_Gali",       owner = "red"  },
      { name = "FRONT_Ochamchire", owner = "red"  },
      { name = "FRONT_Tkvarcheli", owner = "red"  },
    },
    garrison = { blue = "BLUE_Garrison_Template", red = "RED_Garrison_Template" },
    redFrontShorad = "RED_Front_SHORAD_Template",   -- spawned in every initially red zone
    redFrontShoradAlias = "RED Front SAM",
    captureTime  = 120,       -- s a zone must be held to change owner
    checkVictory = 60,        -- s
    resetDelay   = 180,       -- s between victory message and front reset
    replenish    = 10 * 60,   -- s between platoon/squadron refills

    blue = {
      chief    = "Blue HQ",
      agentPrefixes = { "BLUE Recce", "BLUE Brigade", "BLUE Garrison", "BLUE_CTLD_" },   -- detection agents (group name contains)
      brigade  = { warehouse = "BLUE_Brigade_Senaki_Warehouse", name = "BLUE Brigade",
        platoons = {
          { name = "BLUE Brigade Infantry",  template = "BLUE_Brigade_Infantry_Template",  n = 4, types = "infantry" },
          { name = "BLUE Brigade Tanks",     template = "BLUE_Brigade_Tank_Template",      n = 2, types = "armor" },
          { name = "BLUE Brigade IFV",       template = "BLUE_Brigade_IFV_Template",       n = 2, types = "armor" },
          { name = "BLUE Brigade Artillery", template = "BLUE_Brigade_Artillery_Template", n = 1, types = "arty" },
        } },
      airwing  = { warehouse = "BLUE_Airwing_Senaki_Warehouse", name = "BLUE Transport Wing",
        squadrons = {
          { name = "BLUE Transport Helos", template = "BLUE_Transport_Helo_Template", n = 2, types = "transport" },
        } },
      recce    = { template = "BLUE_Recce_Template", alias = "BLUE Recce JTAC Front", zone = "FRONT_Area_Zone",
                   altFt = 16000, speedKts = 120, laserCode = 1686 },
      ammo     = { trucks = "BLUE_Ammo_Truck", home = "BLUE_Ammo_Home_Zone" },
    },
    red = {
      chief    = "Red HQ",
      agentPrefixes = { "RED Brigade", "RED Recce", "RED Front SAM", "RED Garrison" },
      brigade  = { warehouse = "RED_Brigade_Sukhumi_Warehouse", name = "RED Brigade",
        platoons = {
          { name = "RED Brigade Infantry",  template = "RED_Brigade_Infantry_Template",  n = 4, types = "infantry" },
          { name = "RED Brigade Tanks",     template = "RED_Brigade_Tank_Template",      n = 2, types = "armor" },
          { name = "RED Brigade IFV",       template = "RED_Brigade_IFV_Template",       n = 2, types = "armor" },
          { name = "RED Brigade Artillery", template = "RED_Brigade_Artillery_Template", n = 1, types = "arty" },
          { name = "RED Brigade Trucks",    template = "RED_Brigade_Truck_Template",     n = 2, types = "transport" },
        } },
      airwing  = { warehouse = "RED_Airwing_Gudauta_Warehouse", name = "RED Attack Helo Wing",
        squadrons = {
          { name = "RED Attack Helos", template = "RED_Attack_Helo_Template", n = 2, types = "cas" },
        } },
      ammo     = { trucks = "RED_Ammo_Truck", home = "RED_Ammo_Home_Zone" },
    },
    playerTask = { name = "Front Tasking", menu = "Front Tasks" },
  },

  -- -------------------------------------------------------------------
  -- Ambient
  -- -------------------------------------------------------------------
  ambient = {
    rat = {
      total = 4,
      flights = {
        { template = "NEUTRAL_RAT_Civil_Template",     alias = "Civil",     airports = { "Batumi", "Kobuleti", "Kutaisi" }, min = 2 },
        { template = "BLUE_RAT_Transport_Template",    alias = "Transport", airports = { "Kutaisi", "Batumi" },             min = 1 },
      },
    },
    cleanupAirbases = { "Kutaisi", "Senaki-Kolkhi", "Batumi" },
    -- taxi speed watch: warning/kick above kickSpeedKts, immediate kick above maxKickSpeedKts
    atcGround = { airbases = { "Kutaisi", "Batumi" }, kickSpeedKts = 40, maxKickSpeedKts = 60 },
  },

  -- -------------------------------------------------------------------
  -- Frequency overview (checked for collisions in the mock test)
  -- -------------------------------------------------------------------
}

-- Frequencies that must not collide (MHz). Filled from the tables above.
function KA.CFG.AllFrequencies()
  local C = KA.CFG
  local list = {
    { "Range control", C.range.controlFreq }, { "Range instructor", C.range.instructorFreq },
    { "LSO", C.carrier.lsoFreq }, { "Marshal", C.carrier.marshalFreq },
    { "Recovery tanker", C.carrier.tanker.freq }, { "AWACS", C.support.awacs.freq },
  }
  for _, t in ipairs(C.support.tankers) do list[#list + 1] = { "Tanker " .. t.name, t.freq } end
  for _, a in ipairs(C.atis.stations) do list[#list + 1] = { "ATIS " .. a.airbase, a.freq } end
  return list
end
