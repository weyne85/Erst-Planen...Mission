-- =====================================================================
-- Kaukasus Allround Training - 12_sead.lua
-- SEAD/DEAD against an integrated air defense.
-- Moose: MANTIS (IADS, uses SEAD internally), SHORAD, SPAWN.
-- Spawned group names contain the MANTIS prefix and the SAM type, e.g.
-- "RED SEAD SAM SA-6#001", so MANTIS auto mode knows the system.
-- =====================================================================

KA = KA or {}
KA.SEAD = {}

local def = KA.RegisterScenario({
  id = "sead", title = "SEAD / DEAD", restart = true,
  timeout = KA.CFG.sead.timeout,
})

local function spawn(entry, coord, s)
  local g = KA.SpawnAt(entry.template, entry.alias, coord, math.random(0, 359))
  if g then s:Track(g) end
  return g
end

function def.OnStart(s)
  local C = KA.CFG.sead
  local zone = ZONE:FindByName(C.zone)
  if not zone then s:Msg("SEAD zone missing in the mission."); return false end

  s.data.sams, s.data.shorad, s.data.types = {}, {}, {}
  for _, sam in ipairs(KA.PickN(C.sams, C.samsPerRound)) do
    local g = spawn(sam, KA.RandomLandCoord(zone), s)
    if g then
      table.insert(s.data.sams, g)
      table.insert(s.data.types, sam.alias:sub(#C.samPrefix + 2))
    end
  end
  if #s.data.sams == 0 then s:Msg("SEAD: no SAM templates found."); return false end

  for i = 1, C.shoradPerRound do
    local site = s.data.sams[(i - 1) % #s.data.sams + 1]:GetCoordinate()
    local entry = KA.Pick(C.shorad)
    local g = spawn(entry, site:GetRandomCoordinateInRadius(2500, 800), s)
    if g then
      table.insert(s.data.shorad, g)
      table.insert(s.data.types, entry.alias:sub(#C.shoradPrefix + 2))
    end
  end
  spawn(C.ewr, KA.RandomLandCoord(zone), s)

  local center = KA.ZoneCoord(zone)
  local from = s.group:GetCoordinate()
  s:Msg(string.format(
    "SEAD/DEAD: enemy IADS active.\nArea: %s\nExpected threats: %s + early warning radar.\nTask: destroy all SAM sites. F10 > Training > SEAD / DEAD > Reveal threats marks them.",
    from and KA.BRText(from, center) or "?", table.concat(s.data.types, ", ")), 45)
  return true
end

local function countAlive(list)
  local n = 0
  for _, g in ipairs(list) do if KA.IsAliveGroup(g) then n = n + 1 end end
  return n
end

function def.OnTick(s)
  if countAlive(s.data.sams) == 0 then return "done" end
end

function def.Status(s)
  return string.format("SAM sites alive: %d of %d\nSHORAD groups alive: %d of %d",
    countAlive(s.data.sams), #s.data.sams, countAlive(s.data.shorad), #s.data.shorad)
end

-- F10 help: mark all live SAM and SHORAD sites for the requesting group only.
local function reveal(group)
  local s = KA.GetSession(def, group)
  if not s or s.group:GetName() ~= group:GetName() then
    KA.MsgGroup(group, "SEAD / DEAD: nothing running for you.")
    return
  end
  for _, list in ipairs({ s.data.sams, s.data.shorad }) do
    for _, g in ipairs(list) do
      if KA.IsAliveGroup(g) then
        local label = g:GetName():gsub("#.*", "")
        local id = g:GetCoordinate():MarkToGroup(label, group, true)
        s:OnCleanup(function() COORDINATE:RemoveMark(id) end)
      end
    end
  end
  KA.MsgGroup(group, "SEAD / DEAD: threats marked on your F10 map.")
end

function KA.SEAD.Init()
  local C = KA.CFG.sead
  local zone = KA.Need("zone", C.zone, "SEAD")
  for _, list in ipairs({ C.sams, C.shorad, { C.ewr } }) do
    for _, e in ipairs(list) do KA.Need("group", e.template, "SEAD") end
  end
  if not zone then return false end

  -- IADS: dynamic MANTIS (picks up groups spawned later), EMCON on/off, only this zone.
  local mantis = MANTIS:New("SEAD Training", C.samPrefix, C.ewrPrefix, nil, "red", true, nil, true, nil, { zone })
  local samSet = SET_GROUP:New():FilterPrefixes(C.samPrefix):FilterCoalitions("red"):FilterStart()
  local shorad = SHORAD:New("SEAD Training SHORAD", C.shoradPrefix, samSet, 25000, 600, "red", true)
  mantis:AddShorad(shorad, 600)
  mantis:Start()
  KA.SEAD.mantis, KA.SEAD.shorad = mantis, shorad

  KA.Menu.AddSession({ "SEAD / DEAD" }, def)
  KA.Menu.Add({ "SEAD / DEAD" }, "Reveal threats", reveal)
  return true
end
