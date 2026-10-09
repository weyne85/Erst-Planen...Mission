-- =====================================================================
-- Kaukasus Allround Training - 32_atis_nav.lua
-- ATIS with Moose sound files ("ATIS Soundfiles/", no SRS), an NDB at the
-- FARP Senaki for ADF homing, and a navigation exercise (session per group):
-- fly a random route of checkpoints, ETAs are checked at each checkpoint.
-- Moose: ATIS, BEACON, MARKER via COORDINATE marks, ZONE.
-- =====================================================================

KA = KA or {}
KA.Nav = {}

local def = KA.RegisterScenario({
  id = "nav", title = "Navigation", parallel = true, restart = false, replace = true,
  timeout = KA.CFG.nav.timeout,
})

function def.OnStart(s, opts)
  local C = KA.CFG.nav
  local unit = s.group:GetFirstUnitAlive()
  if not unit then return false end
  local speed = opts.helo and C.heloSpeedKts or C.speedKts

  s.data.route, s.data.next = {}, 1
  local prev = unit:GetCoordinate()
  local eta = 0
  local lines = {}
  for i, name in ipairs(KA.PickN(C.checkpoints, C.legs)) do
    local zone = ZONE:FindByName(name)
    if zone then
      local c = KA.ZoneCoord(zone)
      local dist = KA.DistNm(prev, c)
      eta = eta + dist / speed * 3600
      s.data.route[#s.data.route + 1] = { zone = zone, eta = eta, name = "CP" .. i }
      lines[#lines + 1] = string.format("CP%d: %s, ETA +%s", i, KA.BRText(prev, c) .. " from previous", UTILS.SecondsToClock(eta, true))
      local id = c:MarkToGroup(string.format("CP%d (ETA +%s)", i, UTILS.SecondsToClock(eta, true)), s.group, true)
      s:OnCleanup(function() COORDINATE:RemoveMark(id) end)
      prev = c
    end
  end
  if #s.data.route == 0 then s:Msg("Navigation: no checkpoint zones found."); return false end

  s:Msg(string.format("NAVIGATION: fly the route at %d kts ground speed. Clock starts now.\n%s\nCheckpoints are marked on your F10 map.",
    speed, table.concat(lines, "\n")), 60)
  return true
end

function def.OnTick(s)
  local cp = s.data.route[s.data.next]
  local unit = s.group:GetFirstUnitAlive()
  if not (cp and unit) then return end
  if unit:IsInZone(cp.zone) then
    local t = s:Elapsed()
    local delta = t - cp.eta
    s:Msg(string.format("%s reached at +%s (planned +%s, %s%d s).", cp.name, UTILS.SecondsToClock(t, true),
      UTILS.SecondsToClock(cp.eta, true), delta >= 0 and "late " or "early ", math.floor(math.abs(delta) + 0.5)), 20)
    s.data.next = s.data.next + 1
    if s.data.next > #s.data.route then return "done" end
  end
end

function def.Status(s)
  local cp = s.data.route[s.data.next]
  local from = s.group:GetCoordinate()
  if not (cp and from) then return "route finished" end
  return string.format("Next: %s, %s, planned +%s", cp.name, KA.BRText(from, KA.ZoneCoord(cp.zone)), UTILS.SecondsToClock(cp.eta, true))
end

local function startAtis()
  local C = KA.CFG.atis
  KA.Nav.atis = {}
  for _, st in ipairs(C.stations) do
    if KA.Need("airbase", st.airbase, "ATIS") then
      local atis = ATIS:New(st.airbase, st.freq)
      atis:SetSoundfilesPath(C.soundPath)
      atis:SetImperialUnits()
      atis:SetTransmitOnlyWithPlayers(true)
      atis:Start()
      table.insert(KA.Nav.atis, atis)
    end
  end
end

local function startNdb()
  local N = KA.CFG.nav.ndb
  local host = KA.Need("target", N.object, "NDB")
  if not host then return end
  KA.Nav.ndb = BEACON:New(host)
  if KA.Nav.ndb then KA.Nav.ndb:RadioBeacon(N.file, N.freqMHz, radio.modulation.AM, N.powerW) end
end

-- One overview of every frequency in the mission.
local function frequencies(group)
  local CFG = KA.CFG
  local t = {}
  for _, f in ipairs(CFG.AllFrequencies()) do t[#t + 1] = string.format("%-18s %.3f AM", f[1], f[2]) end
  t[#t + 1] = string.format("%-18s %d kHz (ADF)", "NDB FARP Senaki", math.floor(CFG.nav.ndb.freqMHz * 1000 + 0.5))
  t[#t + 1] = string.format("Carrier TACAN %d%s %s, ICLS %d", CFG.carrier.tacan.channel, CFG.carrier.tacan.mode,
    CFG.carrier.tacan.morse, CFG.carrier.icls.channel)
  t[#t + 1] = string.format("Recovery tanker TACAN %dY %s", CFG.carrier.tanker.tacan, CFG.carrier.tanker.morse)
  for _, tk in ipairs(CFG.support.tankers) do
    t[#t + 1] = string.format("%s TACAN %d%s %s", tk.name, tk.tacan, tk.band, tk.morse)
  end
  t[#t + 1] = string.format("Laser codes: CAS JTAC %d, front drone %d", CFG.cas.laserCode, CFG.campaign.blue.recce.laserCode)
  KA.MsgGroup(group, table.concat(t, "\n"), 45)
end

function KA.Nav.Init()
  startAtis()
  startNdb()
  KA.NeedAll("zone", KA.CFG.nav.checkpoints, "Navigation")
  KA.Menu.Add({ "Navigation" }, "Start route (jet)", KA.MenuStart(def, { helo = false }))
  KA.Menu.Add({ "Navigation" }, "Start route (helicopter)", KA.MenuStart(def, { helo = true }))
  KA.Menu.Add({ "Navigation" }, "Next checkpoint", KA.MenuStatus(def))
  KA.Menu.Add({ "Navigation" }, "Stop", KA.MenuStop(def))
  KA.Menu.Add({ "Info" }, "Frequencies, TACAN, laser codes", frequencies)
  return true
end
