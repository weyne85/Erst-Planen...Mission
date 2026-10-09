-- =====================================================================
-- Kaukasus Allround Training - 13_strike.lua
-- Strike against fixed targets. Each site is a trigger zone with static
-- objects placed in the mission editor (buildings, bunkers, depots).
-- Destroyed statics are respawned when the round ends.
-- Moose: TARGET, SET_STATIC, STATIC (ReSpawn), SPAWN (AAA).
-- =====================================================================

KA = KA or {}
KA.Strike = {}

local def = KA.RegisterScenario({
  id = "strike", title = "Strike", restart = true,
  timeout = KA.CFG.strike.timeout,
})

local function aliveCount(list)
  local n = 0
  for _, st in ipairs(list) do if st.obj:IsAlive() then n = n + 1 end end
  return n
end

function def.OnStart(s)
  local C = KA.CFG.strike
  local siteName = KA.Pick(C.sites)
  local zone = ZONE:FindByName(siteName)
  if not zone then s:Msg("Strike site zone missing: " .. siteName); return false end

  local set = SET_STATIC:New():FilterZones({ zone }):FilterOnce()
  s.data.statics = {}
  set:ForEachStatic(function(st)
    if st:IsAlive() then
      table.insert(s.data.statics, { obj = st, name = st:GetName(), country = st:GetCountry() })
    end
  end)
  if #s.data.statics == 0 then s:Msg("Strike: no static objects inside " .. siteName); return false end

  -- Respawn whatever was destroyed when the session ends.
  s:OnCleanup(function()
    for _, st in ipairs(s.data.statics) do
      if not st.obj:IsAlive() then st.obj:ReSpawn(st.country) end
    end
  end)

  s.data.target = s:TrackFsm(TARGET:New(set))

  local center = KA.ZoneCoord(zone)
  for _ = 1, C.aaaPerRound do
    local g = KA.SpawnAt(C.aaaTemplate, "RED Strike AAA", center:GetRandomCoordinateInRadius(3000, 800), math.random(0, 359))
    if g then s:Track(g) end
  end

  local lines = {}
  for i, st in ipairs(s.data.statics) do
    if i > 6 then lines[#lines + 1] = string.format("... and %d more", #s.data.statics - 6); break end
    local c = st.obj:GetCoordinate()
    lines[#lines + 1] = string.format("T%d %s, %d ft", i, c:ToStringMGRS(), math.floor(UTILS.MetersToFeet(c:GetLandHeight()) + 0.5))
  end
  local from = s.group:GetCoordinate()
  s:Msg(string.format("STRIKE: destroy all targets at site %s.\n%s\n%s\nTargets:\n%s\nExpect AAA.",
    siteName, from and KA.BRText(from, center) or "", KA.CoordText(center), table.concat(lines, "\n")), 60)
  return true
end

function def.OnTick(s)
  if aliveCount(s.data.statics) == 0 then return "done" end
end

function def.Status(s)
  local life = ""
  if s.data.target and s.data.target.GetLife and s.data.target:GetLife0() > 0 then
    life = string.format("\nRemaining structure: %d %%", math.floor(100 * s.data.target:GetLife() / s.data.target:GetLife0()))
  end
  return string.format("Targets standing: %d of %d%s", aliveCount(s.data.statics), #s.data.statics, life)
end

function KA.Strike.Init()
  local C = KA.CFG.strike
  local ok = KA.NeedAll("zone", C.sites, "Strike")
  KA.Need("group", C.aaaTemplate, "Strike AAA")
  KA.Menu.AddSession({ "Strike" }, def)
  return ok
end
