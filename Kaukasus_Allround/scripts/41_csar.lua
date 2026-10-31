-- =====================================================================
-- Kaukasus Allround Training - 41_csar.lua
-- BLUE: Moose Ops.CSAR for player helicopters. Downed players and (for
--       the campaign) downed BLUE AI pilots, plus random CSAR events.
-- RED:  Moose Functional.AICSAR - red AI helicopters rescue red pilots
--       (e.g. shot-down red attack helicopters). Different coalition, so
--       it never competes with the BLUE CSAR for the same pilot.
-- =====================================================================

KA = KA or {}
KA.CSAR = {}

local function scheduleRandom()
  local C = KA.CFG.csar
  local delay = math.random(C.randomMinMin * 60, C.randomMaxMin * 60)
  TIMER:New(function()
    local zones = {}
    for _, z in ipairs(C.randomZones) do
      local zone = ZONE:FindByName(z)
      if zone then zones[#zones + 1] = zone end
    end
    if #zones > 0 and KA.CSAR.obj then
      local zone = KA.Pick(zones)
      KA.Try("random CSAR", function()
        KA.CSAR.obj:SpawnCSARAtZone(zone, coalition.side.BLUE, "Downed pilot", true)
      end)
      KA.MsgBlue("CSAR: a pilot is down. Check F10 > CSAR for the location.", 20)
    end
    scheduleRandom()
  end):Start(delay)
end

local function startBlue()
  local C = KA.CFG.csar
  if not KA.Need("group", C.pilotTemplate, "CSAR") then return false end
  local csar = CSAR:New(coalition.side.BLUE, C.pilotTemplate, C.alias)
  csar.useprefix = true
  csar.csarPrefix = { KA.CFG.blueHeliPrefix }
  csar.enableForAI = true            -- downed BLUE AI pilots of the campaign too
  csar.mashprefix = { C.mashPrefix }
  csar.allowFARPRescue = true
  csar.immortalcrew = true
  csar.invisiblecrew = false
  csar.autosmoke = true
  csar.coordtype = 2                 -- MGRS
  csar.radioSound = C.beaconSound
  csar.limitmaxdownedpilots = true
  csar.maxdownedpilots = C.maxDowned
  csar:__Start(5)
  KA.CSAR.obj = csar
  KA.NeedAll("zone", C.randomZones, "CSAR random events")
  scheduleRandom()
  return true
end

local function startRed()
  local R = KA.CFG.aicsarRed
  local ok = KA.Need("group", R.pilotTemplate, "Red AICSAR")
  ok = KA.Need("group", R.heloTemplate, "Red AICSAR") and ok
  local base = KA.Need("airbase", R.airbase, "Red AICSAR")
  local mash = KA.Need("zone", R.mashZone, "Red AICSAR")
  if not (ok and base and mash) then return false end
  local ai = AICSAR:New(R.alias, coalition.side.RED, R.pilotTemplate, R.heloTemplate, base, mash, R.helos)
  ai.verbose = false
  KA.CSAR.red = ai
  return true
end

function KA.CSAR.Init()
  local okBlue = startBlue()
  local okRed = startRed()
  return okBlue and okRed
end
