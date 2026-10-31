-- =====================================================================
-- Kaukasus Allround Training - 50_campaign.lua
-- Endless ground war between Senaki (BLUE) and Sukhumi (RED).
-- Moose: CHIEF (+COMMANDER, INTEL), OPSZONE, BRIGADE/PLATOON,
--        AIRWING/SQUADRON (BLUE transport helos, RED attack helos),
--        AUFTRAG resources, OPSTRANSPORT (via CHIEF transport resources),
--        PLAYERTASKCONTROLLER (BLUE player tasks), SEAD (red front SAMs),
--        AMMOTRUCK, FLIGHTGROUP + AUFTRAG (front drone).
-- How it works: a CHIEF only sends ground troops into EMPTY zones. Enemy
-- held zones get artillery (and red attack helos) first - and the BLUE
-- players via PLAYERTASK (CAS/BAI/SEAD) and CTLD troops.
-- When one side holds every front zone, the front is reset.
-- =====================================================================

KA = KA or {}
KA.Campaign = { fronts = {}, legions = {} }

local Camp = KA.Campaign

local function sideOf(name) return name == "blue" and coalition.side.BLUE or coalition.side.RED end
local function nameOf(side) return side == coalition.side.BLUE and "BLUE" or (side == coalition.side.RED and "RED" or "NEUTRAL") end

local CAPS = {
  infantry  = { AUFTRAG.Type.ONGUARD, AUFTRAG.Type.PATROLZONE, AUFTRAG.Type.CAPTUREZONE, AUFTRAG.Type.GROUNDATTACK },
  armor     = { AUFTRAG.Type.ONGUARD, AUFTRAG.Type.PATROLZONE, AUFTRAG.Type.CAPTUREZONE, AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ARMORATTACK },
  arty      = { AUFTRAG.Type.ARTY, AUFTRAG.Type.BARRAGE },
  transport = { AUFTRAG.Type.OPSTRANSPORT },
  cas       = { AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI },
}

-- ---------------------------------------------------------------------
-- Legions
-- ---------------------------------------------------------------------
local function buildBrigade(B)
  if not KA.Need("static", B.warehouse, B.name) then return nil end
  local brigade = BRIGADE:New(B.warehouse, B.name)
  for _, p in ipairs(B.platoons) do
    if KA.Need("group", p.template, B.name) then
      local platoon = PLATOON:New(p.template, p.n, p.name)
      platoon:AddMissionCapability(CAPS[p.types], 80)
      brigade:AddPlatoon(platoon)
      table.insert(Camp.legions, { legion = brigade, cohort = platoon, n = p.n, kind = "platoon" })
    end
  end
  return brigade
end

local function buildAirwing(A)
  if not KA.Need("static", A.warehouse, A.name) then return nil end
  local wing = AIRWING:New(A.warehouse, A.name)
  for _, q in ipairs(A.squadrons) do
    if KA.Need("group", q.template, A.name) then
      local sq = SQUADRON:New(q.template, q.n, q.name)
      sq:AddMissionCapability(CAPS[q.types], 80)
      wing:AddSquadron(sq)
      wing:NewPayload(q.template, -1, CAPS[q.types], 80)
      table.insert(Camp.legions, { legion = wing, cohort = sq, n = q.n, kind = "squadron" })
    end
  end
  return wing
end

-- Keeps every platoon/squadron at its configured size (endless war).
local function replenish()
  for _, l in ipairs(Camp.legions) do
    local missing = l.n - l.cohort:CountAssets()
    if missing > 0 then
      if l.kind == "platoon" then l.legion:AddAssetToPlatoon(l.cohort, missing)
      else l.legion:AddAssetToSquadron(l.cohort, missing) end
      KA.Log("Campaign: refilled %s with %d asset(s)", l.cohort:GetName(), missing)
    end
  end
end

-- ---------------------------------------------------------------------
-- Chiefs
-- ---------------------------------------------------------------------
local function buildChief(sideName, S, prios)
  local side = sideOf(sideName)
  local agents = SET_GROUP:New():FilterCoalitions(sideName):FilterPrefixes(S.agentPrefixes):FilterStart()
  local chief = CHIEF:New(side, agents, S.chief)
  chief:SetStrategy(CHIEF.Strategy.OFFENSIVE)
  chief:SetTacticalOverviewOff()

  local brigade = buildBrigade(S.brigade)
  if brigade then chief:AddBrigade(brigade) end
  local wing = buildAirwing(S.airwing)
  if wing then chief:AddAirwing(wing) end

  for _, f in ipairs(Camp.fronts) do
    -- Enemy present: artillery, CAS helos (if any), armor capture.
    local occupied = chief:CreateResource(AUFTRAG.Type.ARTY, 1, 1)
    chief:AddToResource(occupied, AUFTRAG.Type.CASENHANCED, 0, 1)
    chief:AddToResource(occupied, AUFTRAG.Type.CAPTUREZONE, 0, 1, { GROUP.Attribute.GROUND_TANK, GROUP.Attribute.GROUND_IFV })
    -- Empty: infantry on guard (transported if possible), armor support.
    local empty, infantry = chief:CreateResource(AUFTRAG.Type.ONGUARD, 1, 2, GROUP.Attribute.GROUND_INFANTRY)
    chief:AddToResource(empty, AUFTRAG.Type.ONGUARD, 0, 1, { GROUP.Attribute.GROUND_TANK, GROUP.Attribute.GROUND_IFV })
    chief:AddTransportToResource(infantry, 0, 1, { GROUP.Attribute.AIR_TRANSPORTHELO, GROUP.Attribute.GROUND_TRUCK })
    chief:AddStrategicZone(f.opszone, prios[f.name] or 50, nil, occupied, empty)
  end
  return chief
end

-- ---------------------------------------------------------------------
-- Front zones, garrisons, reset
-- ---------------------------------------------------------------------
local function spawnGarrison(f)
  local C = KA.CFG.campaign
  local template = C.garrison[f.owner0name]
  local g = KA.SpawnAt(template, f.owner0name:upper() .. " Garrison", KA.RandomLandCoord(f.zone), math.random(0, 359))
  if f.owner0name == "red" then
    KA.SpawnAt(C.redFrontShorad, C.redFrontShoradAlias, KA.RandomLandCoord(f.zone), math.random(0, 359))
  end
  return g
end

local function frontStatus()
  local blue, red = 0, 0
  for _, f in ipairs(Camp.fronts) do
    local owner = f.opszone:GetOwner()
    if owner == coalition.side.BLUE then blue = blue + 1 elseif owner == coalition.side.RED then red = red + 1 end
  end
  return blue, red
end

-- Removes all ground units inside the front zones, restores the initial
-- owners and garrisons. Brigade assets lost here are refilled by replenish().
local function resetFront()
  local zones = {}
  for _, f in ipairs(Camp.fronts) do zones[#zones + 1] = f.zone end
  local set = SET_GROUP:New():FilterCategoryGround():FilterZones(zones):FilterOnce()
  set:ForEachGroup(function(g)
    if not KA.HasPlayer(g) then KA.Destroy(g) end
  end)
  for _, f in ipairs(Camp.fronts) do
    f.opszone:Captured(f.owner0)
    spawnGarrison(f)
  end
  replenish()
  Camp.resetPending = false
  KA.MsgAll("CAMPAIGN: the front has been reset. Senaki - Sukhumi is contested again.", 30)
  KA.Log("Campaign: front reset")
end

local function checkVictory()
  if Camp.resetPending then return end
  local blue, red = frontStatus()
  local n = #Camp.fronts
  if n == 0 or (blue < n and red < n) then return end
  Camp.resetPending = true
  local winner = blue == n and "BLUE" or "RED"
  KA.MsgAll(string.format("CAMPAIGN: %s holds the whole front! The front resets in %d s.", winner,
    KA.CFG.campaign.resetDelay), 30)
  TIMER:New(function() KA.Try("campaign reset", resetFront) end):Start(KA.CFG.campaign.resetDelay)
end

-- ---------------------------------------------------------------------
-- BLUE front drone (detection for PLAYERTASK + AUTOLASE lasing)
-- ---------------------------------------------------------------------
local function keepRecce()
  local R = KA.CFG.campaign.blue.recce
  if KA.IsAliveGroup(Camp.recce) then return end
  local zone = ZONE:FindByName(R.zone)
  if not zone then return end
  local coord = KA.ZoneCoord(zone):SetAltitude(UTILS.FeetToMeters(R.altFt), true)
  local g = KA.SpawnAt(R.template, R.alias, coord)
  if not g then return end
  Camp.recce = g
  FLIGHTGROUP:New(g):AddMission(AUFTRAG:NewORBIT(KA.ZoneCoord(zone), R.altFt, R.speedKts))
  local unit = g:GetUnit(1)
  if KA.Autolase and unit then KA.Autolase:SetRecceLaserCode(unit:GetName(), R.laserCode) end
end

-- ---------------------------------------------------------------------
-- Player tasking (BLUE A2G): targets detected by the drone and the brigade
-- ---------------------------------------------------------------------
local function startPlayerTasks()
  local C = KA.CFG.campaign
  local ptc = PLAYERTASKCONTROLLER:New(C.playerTask.name, coalition.side.BLUE, PLAYERTASKCONTROLLER.Type.A2G)
  ptc:SetLocale("en")
  ptc:SetMenuName(C.playerTask.menu)
  -- SetupIntel passes the name(s) to SET_GROUP:FilterPrefixes (accepts a table) with
  -- FilterStart, so brigade groups spawned later become detection agents too.
  -- (AddAgentSet would only take a snapshot of the groups alive now.)
  ptc:SetupIntel(C.blue.agentPrefixes)
  local area = ZONE:FindByName(C.blue.recce.zone)
  if area then ptc:AddAcceptZone(area) end
  ptc:SetInfoShowsCoordinate(true)
  Camp.ptc = ptc
end

-- ---------------------------------------------------------------------
-- Info menu
-- ---------------------------------------------------------------------
local function statusText(group)
  local from = group and group:GetCoordinate()
  local lines = {}
  for _, f in ipairs(Camp.fronts) do
    lines[#lines + 1] = string.format("%-12s %-7s %-9s %s", f.label, nameOf(f.opszone:GetOwner()), f.opszone:GetState(),
      from and KA.BRText(from, KA.ZoneCoord(f.zone)) or "")
  end
  local blue, red = frontStatus()
  lines[#lines + 1] = string.format("Front: BLUE %d, RED %d of %d zones.", blue, red, #Camp.fronts)
  return table.concat(lines, "\n")
end

function KA.Campaign.Init()
  local C = KA.CFG.campaign

  for _, z in ipairs(C.zones) do
    local zone = KA.Need("zone", z.name, "Campaign front")
    if zone then
      local oz = OPSZONE:New(zone, sideOf(z.owner))
      oz:SetCaptureTime(C.captureTime)
      oz:SetDrawZone(true)
      table.insert(Camp.fronts, { name = z.name, label = z.name:gsub("^FRONT_", ""), zone = zone, opszone = oz,
        owner0 = sideOf(z.owner), owner0name = z.owner })
    end
  end
  if #Camp.fronts == 0 then return false end
  KA.Need("group", C.garrison.blue, "Campaign garrison")
  KA.Need("group", C.garrison.red, "Campaign garrison")
  KA.Need("group", C.redFrontShorad, "Campaign red SHORAD")
  KA.Need("zone", C.blue.recce.zone, "Campaign front area")
  KA.Need("group", C.blue.recce.template, "Campaign front drone")

  for _, f in ipairs(Camp.fronts) do spawnGarrison(f) end

  -- Blue attacks Gali first; red goes for Zugdidi first (lower prio value = first).
  Camp.blue = buildChief("blue", C.blue, { FRONT_Zugdidi = 5, FRONT_Gali = 10, FRONT_Ochamchire = 20, FRONT_Tkvarcheli = 30 })
  Camp.red  = buildChief("red",  C.red,  { FRONT_Gali = 5, FRONT_Zugdidi = 10, FRONT_Ochamchire = 5, FRONT_Tkvarcheli = 5 })
  Camp.blue:Start()
  Camp.red:Start()

  -- Red front SAMs evade anti-radiation missiles.
  Camp.sead = SEAD:New({ C.redFrontShoradAlias })

  -- Ammunition trucks for the artillery of both sides (optional ME groups).
  for _, s in ipairs({ { "blue", C.blue }, { "red", C.red } }) do
    local trucks = SET_GROUP:New():FilterCoalitions(s[1]):FilterPrefixes(s[2].ammo.trucks):FilterStart()
    local home = ZONE:FindByName(s[2].ammo.home)
    if trucks:Count() > 0 and home then
      local arty = SET_GROUP:New():FilterCoalitions(s[1]):FilterPrefixes(s[2].brigade.name .. " Artillery"):FilterStart()
      Camp["ammo_" .. s[1]] = AMMOTRUCK:New(trucks, arty, sideOf(s[1]), s[1]:upper() .. " Ammo", home)
    end
  end

  startPlayerTasks()
  keepRecce()
  TIMER:New(function() KA.Try("front drone", keepRecce) end):Start(300, 300)
  TIMER:New(function() KA.Try("campaign replenish", replenish) end):Start(C.replenish, C.replenish)
  TIMER:New(function() KA.Try("campaign victory check", checkVictory) end):Start(C.checkVictory, C.checkVictory)

  KA.Menu.Add({ "Info" }, "Front status", function(group) KA.MsgGroup(group, statusText(group), 30) end)
  return true
end
