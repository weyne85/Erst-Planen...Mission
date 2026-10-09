-- =====================================================================
-- Kaukasus Allround Training - 01_core.lua
-- Helpers (log, messages, geometry, spawning), mission object checks,
-- player tracking and the session framework for training scenarios.
-- =====================================================================

KA = KA or {}
local CFG = KA.CFG

-- ---------------------------------------------------------------------
-- Logging and protected calls
-- ---------------------------------------------------------------------
function KA.Log(fmt, ...)   env.info("[KA] " .. string.format(fmt, ...)) end
function KA.Warn(fmt, ...)  env.warning("[KA] " .. string.format(fmt, ...)) end
function KA.Error(fmt, ...) env.error("[KA] " .. string.format(fmt, ...)) end

-- Calls fn(...) protected. Returns ok, result.
function KA.Try(label, fn, ...)
  local ok, res = pcall(fn, ...)
  if not ok then KA.Error("%s failed: %s", label, tostring(res)) end
  return ok, res
end

-- ---------------------------------------------------------------------
-- Messages (text only, no SRS)
-- ---------------------------------------------------------------------
function KA.MsgGroup(group, text, duration)
  if group and group:IsAlive() then
    MESSAGE:New(text, duration or CFG.msgTime):ToGroup(group)
  end
end

function KA.MsgBlue(text, duration) MESSAGE:New(text, duration or CFG.msgTime):ToBlue() end
function KA.MsgAll(text, duration)  MESSAGE:New(text, duration or CFG.msgTime):ToAll() end

-- ---------------------------------------------------------------------
-- Mission editor object checks. Missing objects are collected and shown
-- in the start report so the mission builder sees what is missing.
-- ---------------------------------------------------------------------
KA.Missing = {}

local finders = {
  group   = function(n) return GROUP:FindByName(n) end,
  unit    = function(n) return UNIT:FindByName(n) end,
  static  = function(n) return STATIC:FindByName(n, false) end,
  zone    = function(n) return ZONE:FindByName(n) end,
  airbase = function(n) return AIRBASE:FindByName(n) end,
  -- static object or unit (range targets, NDB host)
  target  = function(n) return STATIC:FindByName(n, false) or UNIT:FindByName(n) end,
}

-- Returns the Moose object or nil (and records it as missing).
function KA.Need(kind, name, owner)
  local finder = finders[kind]
  local ok, obj = pcall(finder, name)
  if ok and obj then return obj end
  KA.Missing[#KA.Missing + 1] = string.format("%s '%s' (%s)", kind, tostring(name), owner or "?")
  KA.Warn("Missing %s '%s' needed by %s", kind, tostring(name), owner or "?")
  return nil
end

-- Checks a list of names, returns true if all exist.
function KA.NeedAll(kind, names, owner)
  local all = true
  for _, n in ipairs(names) do
    if not KA.Need(kind, n, owner) then all = false end
  end
  return all
end

-- ---------------------------------------------------------------------
-- Random and table helpers
-- ---------------------------------------------------------------------
function KA.Pick(list) return list[math.random(#list)] end

-- Returns n distinct random entries (or all, shuffled, if n >= #list).
function KA.PickN(list, n)
  local copy = {}
  for i, v in ipairs(list) do copy[i] = v end
  for i = #copy, 2, -1 do
    local j = math.random(i)
    copy[i], copy[j] = copy[j], copy[i]
  end
  local out = {}
  for i = 1, math.min(n, #copy) do out[i] = copy[i] end
  return out
end

-- ---------------------------------------------------------------------
-- Geometry
-- ---------------------------------------------------------------------
local declination
local function magVar()
  if declination == nil then
    local ok, d = pcall(UTILS.GetMagneticDeclination)
    declination = (ok and type(d) == "number") and d or 0
  end
  return declination
end

-- Bearing (deg) from -> to, magnetic if configured.
function KA.Bearing(fromCoord, toCoord)
  local brg = fromCoord:HeadingTo(toCoord)
  if CFG.magneticBrg then brg = brg - magVar() end
  return math.floor((brg % 360) + 0.5) % 360
end

function KA.DistNm(fromCoord, toCoord) return fromCoord:Get2DDistance(toCoord) / 1852 end

-- "BRG 045M / 23 nm"
function KA.BRText(fromCoord, toCoord)
  return string.format("BRG %03d%s / %d nm", KA.Bearing(fromCoord, toCoord),
    CFG.magneticBrg and "M" or "T", math.floor(KA.DistNm(fromCoord, toCoord) + 0.5))
end

-- Target description: MGRS, LL and elevation for weapon programming.
function KA.CoordText(coord)
  local elevFt = math.floor(UTILS.MetersToFeet(coord:GetLandHeight()) + 0.5)
  return string.format("%s\n%s\nElevation %d ft", coord:ToStringMGRS(), coord:ToStringLLDDM(), elevFt)
end

-- New COORDINATE at the zone center (ZONE:GetCoordinate returns a shared, cached object).
function KA.ZoneCoord(zone) return COORDINATE:NewFromVec2(zone:GetVec2()) end

-- Random land coordinate inside a (circular) zone.
function KA.RandomLandCoord(zone)
  return zone:GetRandomCoordinate(0, nil, { land.SurfaceType.LAND, land.SurfaceType.ROAD })
end

-- ---------------------------------------------------------------------
-- Spawning
-- ---------------------------------------------------------------------
local spawners = {}

-- Cached SPAWN object per template/alias (SPAWN keeps its own index).
-- Returns nil (and logs) if the template group does not exist.
function KA.Spawner(template, alias)
  local key = template .. "|" .. (alias or "")
  local sp = spawners[key]
  if not sp then
    if not GROUP:FindByName(template) then
      KA.Warn("Template '%s' not found", template)
      return nil
    end
    if alias then sp = SPAWN:NewWithAlias(template, alias) else sp = SPAWN:New(template) end
    spawners[key] = sp
  end
  return sp
end

-- Spawn a group (ground, ship or air) at a coordinate. Returns GROUP or nil.
function KA.SpawnAt(template, alias, coord, heading)
  local sp = KA.Spawner(template, alias)
  if not sp then return nil end
  if heading then sp:InitHeading(heading) end
  return sp:SpawnFromCoordinate(coord)
end

-- Group helpers
function KA.IsAliveGroup(g) return g ~= nil and g:IsAlive() and g:CountAliveUnits() > 0 end

function KA.HasPlayer(g)
  if not KA.IsAliveGroup(g) then return false end
  local names = g:GetPlayerNames()
  return names ~= nil and #names > 0
end

function KA.Destroy(obj)
  if obj and obj.IsAlive and obj:IsAlive() then
    KA.Try("destroy " .. tostring(obj.GetName and obj:GetName() or "?"), function() obj:Destroy() end)
  end
end

-- ---------------------------------------------------------------------
-- Player tracking.
-- CLIENTWATCH reports every client birth. Players who were already seated
-- before the scripts ran (single player) missed their birth event; the
-- start scan replays it for Moose classes that build menus on birth.
-- ---------------------------------------------------------------------
KA.Players = { hooks = {}, seen = {} }

-- fn(unitName, groupName, playerName, replayed)
function KA.Players.OnJoin(fn) table.insert(KA.Players.hooks, fn) end

local function fireJoin(unitName, groupName, playerName, replayed)
  for _, fn in ipairs(KA.Players.hooks) do
    KA.Try("player join hook", fn, unitName, groupName, playerName, replayed)
  end
end

function KA.Players.Start()
  local watch = CLIENTWATCH:New()
  watch:FilterByCoalition("blue")
  function watch:OnAfterSpawn(_, _, _, client)
    KA.Players.seen[client.UnitName] = true
    fireJoin(client.UnitName, client.GroupName, client.PlayerName, false)
    client.OnAfterDespawn = function()
      KA.Players.seen[client.UnitName] = nil
    end
  end
  KA.Players.watch = watch

  -- Replay for players seated before the handlers existed.
  TIMER:New(function()
    for _, dcsUnit in ipairs(coalition.getPlayers(coalition.side.BLUE) or {}) do
      local unitName = dcsUnit:getName()
      if not KA.Players.seen[unitName] then
        KA.Players.seen[unitName] = true
        fireJoin(unitName, dcsUnit:getGroup():getName(), dcsUnit:getPlayerName(), true)
      end
    end
  end):Start(2)
end

-- Fake birth event for Moose classes that set up players in OnEventBirth.
function KA.Players.ReplayBirth(obj, unitName, playerName)
  local unit = UNIT:FindByName(unitName)
  if not (obj and unit and unit:IsAlive()) then return end
  local grp = unit:GetGroup()
  obj:OnEventBirth({
    id = world.event.S_EVENT_BIRTH,
    IniUnit = unit, IniUnitName = unitName, IniDCSUnit = unit:GetDCSObject(),
    IniGroup = grp, IniGroupName = grp and grp:GetName() or nil,
    IniPlayerName = playerName, IniCoalition = unit:GetCoalition(),
    IniObjectCategory = Object.Category.UNIT, IniCategory = unit:GetDesc().category,
  })
end

-- ---------------------------------------------------------------------
-- Session framework
-- A scenario def:
--   id, title, parallel (bool), timeout (s), restart (bool),
--   replace (bool: a new start by the same group replaces its running session)
--   OnStart(s, opts) -> true/false   spawn everything, use s:Track()
--   OnTick(s)        -> "done", "failed" or nil
--   OnStop(s, reason)                optional extra cleanup
--   Status(s)        -> text         optional status line
-- ---------------------------------------------------------------------
KA.Scenarios = {}
KA.Sessions  = {}   -- key -> session

local Session = {}
Session.__index = Session

-- Track(obj): GROUP, STATIC or OPSGROUP, destroyed at the end of the session.
-- TrackFsm(obj): Moose FSM object (SUPPRESSION, TARGET, ...), stopped at the end.
function Session:Track(obj)      if obj then table.insert(self.objects, obj) end; return obj end
function Session:TrackFsm(obj)   if obj then table.insert(self.fsms, obj) end; return obj end
function Session:OnCleanup(fn)   table.insert(self.cleanups, fn) end
function Session:Msg(text, dur)  KA.MsgGroup(self.group, text, dur) end
function Session:Elapsed()       return timer.getTime() - self.t0 end

function KA.RegisterScenario(def)
  KA.Scenarios[def.id] = def
  return def
end

local function sessionKey(def, group)
  if def.parallel then return def.id .. "|" .. group:GetName() end
  return def.id
end

function KA.GetSession(def, group)
  return KA.Sessions[sessionKey(def, group)]
end

local function cleanup(s)
  for _, fn in ipairs(s.cleanups) do KA.Try(s.def.id .. " cleanup", fn) end
  for _, fsm in ipairs(s.fsms) do
    KA.Try(s.def.id .. " stop " .. tostring(fsm.ClassName), function() fsm:Stop() end)
  end
  for _, obj in ipairs(s.objects) do KA.Destroy(obj) end
  s.objects, s.fsms, s.cleanups = {}, {}, {}
end

function KA.StopSession(s, reason, silent)
  if not s or s.stopped then return end
  s.stopped = true
  if s.timer then s.timer:Stop() end
  if s.def.OnStop then KA.Try(s.def.id .. " OnStop", s.def.OnStop, s, reason) end
  cleanup(s)
  KA.Sessions[s.key] = nil
  if not silent then s:Msg(string.format("%s: stopped (%s).", s.def.title, reason)) end
  KA.Log("Session %s stopped: %s", s.key, reason)
end

local function tick(s)
  if s.stopped then return end
  if not KA.HasPlayer(s.group) then
    KA.StopSession(s, "player left", true)
    return
  end
  if s.def.timeout and s:Elapsed() > s.def.timeout then
    KA.StopSession(s, "time limit reached")
    return
  end
  local ok, res = KA.Try(s.def.id .. " OnTick", s.def.OnTick, s)
  if not ok then
    KA.StopSession(s, "script error, see dcs.log")
  elseif res == "done" or res == "failed" then
    local group, opts, def = s.group, s.opts, s.def
    s:Msg(string.format("%s: %s after %s.", def.title, res == "done" and "COMPLETE" or "FAILED",
      UTILS.SecondsToClock(s:Elapsed(), true)), 30)
    KA.StopSession(s, res, true)
    if def.restart and res == "done" then
      KA.MsgGroup(group, string.format("%s: next round in %d s.", def.title, CFG.session.restartDelay))
      TIMER:New(function()
        if KA.HasPlayer(group) and not KA.GetSession(def, group) then KA.StartSession(def, group, opts) end
      end):Start(CFG.session.restartDelay)
    end
  end
end

function KA.StartSession(def, group, opts)
  if not KA.HasPlayer(group) then return end
  local key = sessionKey(def, group)
  local running = KA.Sessions[key]
  if running then
    if running.group:GetName() ~= group:GetName() then
      KA.MsgGroup(group, string.format("%s: busy (in use by %s).", def.title, running.group:GetName()))
      return
    elseif def.replace then
      KA.StopSession(running, "replaced", true)
    else
      KA.MsgGroup(group, def.title .. ": already running for you. Use Stop first.")
      return
    end
  end
  local s = setmetatable({ def = def, group = group, opts = opts or {}, key = key,
    objects = {}, fsms = {}, cleanups = {}, data = {}, t0 = timer.getTime() }, Session)
  KA.Sessions[key] = s
  local ok, res = KA.Try(def.id .. " OnStart", def.OnStart, s, s.opts)
  if not ok then
    KA.StopSession(s, "script error, see dcs.log")
    return
  elseif res == false then
    KA.StopSession(s, "could not start", true)   -- OnStart told the player why
    return
  end
  s.timer = TIMER:New(tick, s)
  s.timer:Start(CFG.session.tick, CFG.session.tick)
  KA.Log("Session %s started by %s", key, group:GetName())
  return s
end

-- Menu helpers used by the scenario files
function KA.MenuStart(def, opts)
  return function(group) KA.StartSession(def, group, opts) end
end

function KA.MenuStop(def)
  return function(group)
    local s = KA.GetSession(def, group)
    if s and s.group:GetName() == group:GetName() then
      KA.StopSession(s, "stopped by player")
    else
      KA.MsgGroup(group, def.title .. ": nothing running for you.")
    end
  end
end

function KA.MenuStatus(def)
  return function(group)
    local s = KA.GetSession(def, group)
    if not s then
      KA.MsgGroup(group, def.title .. ": free.")
    elseif s.group:GetName() ~= group:GetName() then
      KA.MsgGroup(group, string.format("%s: in use by %s.", def.title, s.group:GetName()))
    else
      local txt = def.Status and select(2, KA.Try(def.id .. " Status", def.Status, s)) or "running"
      KA.MsgGroup(group, string.format("%s (%s):\n%s", def.title, UTILS.SecondsToClock(s:Elapsed(), true), tostring(txt)), 30)
    end
  end
end
