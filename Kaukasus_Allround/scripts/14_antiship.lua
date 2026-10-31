-- =====================================================================
-- Kaukasus Allround Training - 14_antiship.lua
-- Anti-ship strike against a moving naval group in the Black Sea.
-- Moose: NAVYGROUP (patrol through the zone), TARGET (damage report), SPAWN.
-- =====================================================================

KA = KA or {}
KA.AntiShip = {}

local def = KA.RegisterScenario({
  id = "antiship", title = "Anti-Ship", restart = true,
  timeout = KA.CFG.antiship.timeout,
})

-- Random water coordinate inside the zone (falls back to the zone center).
local function waterCoord(zone)
  for _ = 1, 20 do
    local c = zone:GetRandomCoordinate()
    if c:IsSurfaceTypeWater() then return c end
  end
  return KA.ZoneCoord(zone)
end

function def.OnStart(s)
  local C = KA.CFG.antiship
  local zone = ZONE:FindByName(C.zone)
  if not zone then s:Msg("Anti-ship zone missing in the mission."); return false end

  local template = KA.Pick(C.templates)
  local start = waterCoord(zone)
  local ships = KA.SpawnAt(template, "RED Ships", start, math.random(0, 359))
  if not ships then s:Msg("Anti-ship: template missing: " .. template); return false end
  s:Track(ships)
  s.data.ships = ships

  -- Patrol between random points of the zone for the whole round.
  local navy = NAVYGROUP:New(ships)
  for _ = 1, 4 do navy:AddWaypoint(waterCoord(zone), C.speedKts) end
  navy:SetPatrolAdInfinitum(true)
  s.data.target = s:TrackFsm(TARGET:New(ships))

  local from = s.group:GetCoordinate()
  s:Msg(string.format("ANTI-SHIP: enemy naval group (%d ships) at sea.\nLast known position: %s\n%s\nCourse unknown, speed about %d kts. Expect naval air defense.",
    ships:GetSize(), from and KA.BRText(from, start) or "", start:ToStringMGRS(), C.speedKts), 45)
  return true
end

function def.OnTick(s)
  if not KA.IsAliveGroup(s.data.ships) then return "done" end
end

function def.Status(s)
  local g = s.data.ships
  local alive = KA.IsAliveGroup(g) and g:CountAliveUnits() or 0
  local pos = (alive > 0) and g:GetCoordinate() or nil
  local from = s.group:GetCoordinate()
  return string.format("Ships afloat: %d\nGroup position: %s", alive,
    (pos and from) and KA.BRText(from, pos) or "-")
end

function KA.AntiShip.Init()
  local C = KA.CFG.antiship
  local ok = KA.Need("zone", C.zone, "Anti-ship") ~= nil
  KA.NeedAll("group", C.templates, "Anti-ship")
  KA.Menu.AddSession({ "Anti-Ship" }, def)
  return ok
end
