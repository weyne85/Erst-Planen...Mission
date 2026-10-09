-- =====================================================================
-- Kaukasus Allround Training - 11_cas.lua
-- CAS against moving targets with an AI JTAC drone.
-- Moose: AUTOLASE, SUPPRESSION, ARMYGROUP + AUFTRAG (patrol),
--        FLIGHTGROUP + AUFTRAG (orbit), SPAWN.
-- =====================================================================

KA = KA or {}
KA.CAS = {}

-- Group name prefixes of every BLUE lasing drone (CAS zone and front).
KA.CAS.reccePrefixes = { "BLUE JTAC", "BLUE Recce JTAC" }

local def = KA.RegisterScenario({
  id = "cas", title = "CAS / JTAC", restart = true,
  timeout = KA.CFG.cas.timeout,
})

-- Spawns the JTAC drone orbiting over the target area.
local function spawnJtac(s, zone)
  local C = KA.CFG.cas
  local coord = KA.ZoneCoord(zone):SetAltitude(UTILS.FeetToMeters(C.jtacAltFt), true)
  local drone = KA.SpawnAt(C.jtacTemplate, C.jtacAlias, coord)
  if not drone then return nil end
  s:Track(drone)
  local fg = FLIGHTGROUP:New(drone)
  fg:AddMission(AUFTRAG:NewORBIT(KA.ZoneCoord(zone), C.jtacAltFt, C.jtacSpeedKts))
  local unit = drone:GetUnit(1)
  if KA.Autolase and unit then KA.Autolase:SetRecceLaserCode(unit:GetName(), C.laserCode) end
  return drone
end

function def.OnStart(s)
  local C = KA.CFG.cas
  local zone = ZONE:FindByName(C.zone)
  if not zone then s:Msg("CAS zone missing in the mission."); return false end

  s.data.targets = {}
  for i, template in ipairs(KA.PickN(C.targets, C.groupsPerRound)) do
    local g = KA.SpawnAt(template, "RED CAS " .. i, KA.RandomLandCoord(zone), math.random(0, 359))
    if g then
      s:Track(g)
      table.insert(s.data.targets, g)
      local army = ARMYGROUP:New(g)
      army:AddMission(AUFTRAG:NewPATROLZONE(zone, 12))
      local supp = SUPPRESSION:New(g)
      if supp then supp:Start(); s:TrackFsm(supp) end
    end
  end
  if #s.data.targets == 0 then s:Msg("CAS: no target templates found."); return false end

  local drone = spawnJtac(s, zone)
  local from = s.group:GetCoordinate()
  s:Msg(string.format(
    "CAS: enemy forces moving in the target area.\n%s\n%s\nJTAC: %s, laser code %d. Targets are lased automatically, see F10 > Autolase.",
    from and KA.BRText(from, KA.ZoneCoord(zone)) or "", KA.CoordText(KA.ZoneCoord(zone)),
    drone and "MQ-9 overhead" or "not available", C.laserCode), 45)
  return true
end

local function aliveUnits(s)
  local n = 0
  for _, g in ipairs(s.data.targets) do
    if g:IsAlive() then n = n + g:CountAliveUnits() end
  end
  return n
end

function def.OnTick(s)
  if aliveUnits(s) == 0 then return "done" end
end

function def.Status(s)
  return string.format("Enemy vehicles remaining: %d\nLaser code %d", aliveUnits(s), KA.CFG.cas.laserCode)
end

function KA.CAS.Init()
  local C = KA.CFG.cas
  KA.Need("zone", C.zone, "CAS")
  KA.NeedAll("group", C.targets, "CAS targets")
  KA.Need("group", C.jtacTemplate, "CAS JTAC")

  -- One AUTOLASE for all BLUE drones (CAS zone and front recce).
  local recce = SET_GROUP:New():FilterPrefixes(KA.CAS.reccePrefixes):FilterCoalitions("blue"):FilterStart()
  KA.Autolase = AUTOLASE:New(recce, coalition.side.BLUE, "JTAC")
  KA.Autolase:SetNotifyPilots(true)

  KA.Menu.AddSession({ "CAS (JTAC)" }, def)
  return true
end
