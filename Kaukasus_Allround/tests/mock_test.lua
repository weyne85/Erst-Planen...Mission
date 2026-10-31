-- =====================================================================
-- Kaukasus Allround Training - logic test without DCS.
-- Stubs the DCS scripting engine and the Moose classes the scripts use,
-- loads all scripts in mission order and plays through the scenarios.
-- Run from the mission folder:  lua5.1 tests/mock_test.lua
-- Prints one line per check and ends with the number of errors.
-- =====================================================================

local SCRIPTS = {
  "scripts/00_config.lua", "scripts/01_core.lua", "scripts/02_menu.lua",
  "scripts/10_range.lua", "scripts/11_cas.lua", "scripts/12_sead.lua", "scripts/13_strike.lua",
  "scripts/14_antiship.lua", "scripts/20_bfm.lua", "scripts/21_fox.lua", "scripts/30_carrier.lua",
  "scripts/31_tanker_awacs.lua", "scripts/32_atis_nav.lua", "scripts/40_ctld.lua", "scripts/41_csar.lua",
  "scripts/50_campaign.lua", "scripts/60_ambient.lua", "scripts/99_init.lua",
}

local errors, checks = 0, 0
local function check(name, cond, info)
  checks = checks + 1
  if cond then
    print("OK    " .. name)
  else
    errors = errors + 1
    print("FAIL  " .. name .. (info and ("  (" .. tostring(info) .. ")") or ""))
  end
end

-- ---------------------------------------------------------------------
-- World state (reset per run)
-- ---------------------------------------------------------------------
local W

local function contains(list, value)
  for _, v in ipairs(list) do if v == value then return true end end
  return false
end

local function countKeys(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end

-- ---------------------------------------------------------------------
-- Coordinates and zones
-- ---------------------------------------------------------------------
local Coord = {}
Coord.__index = Coord
local function coord(x, z, y) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, Coord) end
function Coord:HeadingTo(o) return (math.deg(math.atan2(o.z - self.z, o.x - self.x)) + 360) % 360 end
function Coord:Get2DDistance(o) return math.sqrt((o.x - self.x) ^ 2 + (o.z - self.z) ^ 2) end
function Coord:ToStringMGRS() return "MGRS 38T KM 12345 67890" end
function Coord:ToStringLLDDM() return "N 42 10.000 E 042 30.000" end
function Coord:GetLandHeight() return 100 end
function Coord:SetAltitude(alt) self.y = alt; return self end
function Coord:Translate(d, a, keep)
  local r = math.rad(a or 0)
  return coord(self.x + d * math.cos(r), self.z + d * math.sin(r), keep and self.y or 100)
end
function Coord:GetRandomCoordinateInRadius(outer) return coord(self.x + (outer or 0) / 2, self.z, self.y) end
function Coord:MarkToGroup() W.marks = W.marks + 1; return W.marks end
function Coord:RemoveMark() W.marks = W.marks - 1 end
function Coord:IsSurfaceTypeWater() return true end
function Coord:GetVec2() return { x = self.x, y = self.z } end

local Zone = {}
Zone.__index = Zone
local zoneIndex = 0
local function makeZone(name)
  zoneIndex = zoneIndex + 1
  return setmetatable({ name = name, c = coord(zoneIndex * 20000, 0) }, Zone)
end
function Zone:GetName() return self.name end
function Zone:GetVec2() return { x = self.c.x, y = self.c.z } end
function Zone:GetCoordinate() return self.c end
function Zone:GetRandomCoordinate() return coord(self.c.x + 100, self.c.z + 100) end
function Zone:IsCoordinateInZone(c) return self.c:Get2DDistance(c) < 1000 end

-- ---------------------------------------------------------------------
-- Units, groups, statics
-- ---------------------------------------------------------------------
local Unit_ = {}
Unit_.__index = Unit_
function Unit_:GetName() return self.name end
function Unit_:IsAlive() return self.group:IsAlive() end
function Unit_:GetPlayerName() return self.player end
function Unit_:GetGroup() return self.group end
function Unit_:GetCoordinate() return self.group.pos end
function Unit_:GetHeading() return self.group.heading or 90 end
function Unit_:InAir() return self.group.inAir end
function Unit_:GetAltitude() return self.group.pos.y end
function Unit_:GetVelocityKNOTS() return 350 end
function Unit_:GetCoalition() return self.group.side end
function Unit_:GetDesc() return { category = 0 } end
function Unit_:GetDCSObject() return {} end
function Unit_:IsInZone(z) return z:IsCoordinateInZone(self.group.pos) end

local Group_ = {}
Group_.__index = Group_
local function makeGroup(name, opts)
  opts = opts or {}
  local g = setmetatable({ name = name, alive = opts.alive ~= false, size = opts.size or 4, pos = opts.pos or coord(0, 0),
    side = opts.side or 1, player = opts.player, inAir = opts.inAir, ClassName = "GROUP" }, Group_)
  g.unit = setmetatable({ name = name .. "-1", group = g, player = opts.player }, Unit_)
  W.groups[name] = g
  return g
end
function Group_:GetName() return self.name end
function Group_:IsAlive() return self.alive end
function Group_:CountAliveUnits() return self.alive and self.size or 0 end
function Group_:GetSize() return self.size end
function Group_:GetCoordinate() return self.alive and self.pos or nil end
function Group_:GetPlayerNames() if self.alive and self.player then return { self.player } end return nil end
function Group_:GetFirstUnitAlive() return self.alive and self.unit or nil end
function Group_:GetUnit() return self.unit end
function Group_:Destroy() self.alive = false; W.destroyed[#W.destroyed + 1] = self.name end
function Group_:GetID() return 1 end

local Static_ = {}
Static_.__index = Static_
function Static_:IsAlive() return self.alive end
function Static_:GetName() return self.name end
function Static_:GetCountry() return 0 end
function Static_:GetCoordinate() return coord(1000, 1000) end
function Static_:ReSpawn() self.alive = true; W.respawned = W.respawned + 1 end
function Static_:Destroy() self.alive = false end

-- ---------------------------------------------------------------------
-- Generic Moose class mock: constructors create instances, every unknown
-- method is recorded and returns self (chainable).
-- ---------------------------------------------------------------------
local function record(cls, method) W.calls[cls .. ":" .. method] = (W.calls[cls .. ":" .. method] or 0) + 1 end

local function mockClass(name, methods)
  methods = methods or {}
  local instMt = { __index = function(_, key)
    if methods[key] ~= nil then return methods[key] end
    return function(self) record(name, key); return self end
  end }
  local cls = { ClassName = name }
  setmetatable(cls, { __index = function(_, key)
    if methods[key] ~= nil then return methods[key] end
    if type(key) == "string" and key:match("^New") then
      return function(_, ...)
        record(name, key)
        local o = setmetatable({ ClassName = name, args = { ... } }, instMt)
        if methods._init then methods._init(o, ...) end
        W.instances[name] = W.instances[name] or {}
        table.insert(W.instances[name], o)
        return o
      end
    end
    return function() record(name, key) end
  end })
  return cls
end

local function lastInstance(name) local l = W.instances[name]; return l and l[#l] end

-- ---------------------------------------------------------------------
-- Scheduler (TIMER)
-- ---------------------------------------------------------------------
local function advance(seconds)
  for _ = 1, seconds do
    W.now = W.now + 1
    for _, t in ipairs(W.timers) do
      if t.active and W.now >= t.next then
        if t.dt then t.next = W.now + t.dt else t.active = false end
        local ok, err = pcall(t.fn, unpack(t.args))
        if not ok then W.timerErrors[#W.timerErrors + 1] = err end
      end
    end
  end
end

-- ---------------------------------------------------------------------
-- Install stubs
-- ---------------------------------------------------------------------
local function installStubs()
  env = {
    info = function(m) W.log[#W.log + 1] = m end,
    warning = function(m) W.log[#W.log + 1] = "WARN " .. m end,
    error = function(m) W.log[#W.log + 1] = "ERROR " .. m; W.envErrors[#W.envErrors + 1] = m end,
  }
  timer = { getTime = function() return W.now end, getAbsTime = function() return 43200 + W.now end }
  trigger = { action = { outText = function(t) W.outText[#W.outText + 1] = t end } }
  world = { event = { S_EVENT_BIRTH = 15 } }
  coalition = { side = { NEUTRAL = 0, RED = 1, BLUE = 2 },
    getPlayers = function() return W.preSeated end }
  land = { SurfaceType = { LAND = 1, SHALLOW_WATER = 2, WATER = 3, ROAD = 4, RUNWAY = 5 } }
  radio = { modulation = { AM = 0, FM = 1 } }
  Unit = { RefuelingSystem = { BOOM_AND_RECEPTACLE = 0, PROBE_AND_DROGUE = 1 } }
  Object = { Category = { UNIT = 1 } }
  country = { id = {} }
  SMOKECOLOR = { Blue = 4, Orange = 3, Red = 1 }

  UTILS = {
    GetMagneticDeclination = function() return 6 end,
    MetersToFeet = function(m) return m * 3.28084 end,
    FeetToMeters = function(f) return f / 3.28084 end,
    KnotsToMps = function(k) return k * 0.514444 end,
    SecondsToClock = function(s) return string.format("%02d:%02d", math.floor(s / 60), math.floor(s % 60)) end,
  }

  MESSAGE = mockClass("MESSAGE", {
    ToGroup = function(self, g) W.msgs[#W.msgs + 1] = { to = g:GetName(), text = self.args[1] }; return self end,
    ToBlue  = function(self) W.msgs[#W.msgs + 1] = { to = "BLUE", text = self.args[1] }; return self end,
    ToAll   = function(self) W.msgs[#W.msgs + 1] = { to = "ALL", text = self.args[1] }; return self end,
  })

  TIMER = mockClass("TIMER", {
    _init = function(o, fn, ...) o.fn, o.fargs = fn, { ... } end,
    Start = function(self, t0, dt)
      local t = { fn = self.fn, args = self.fargs, next = W.now + (t0 or 0), dt = dt, active = true }
      self.entry = t
      W.timers[#W.timers + 1] = t
      return self
    end,
    Stop = function(self) if self.entry then self.entry.active = false end; return self end,
  })

  GROUP = mockClass("GROUP", {
    FindByName = function(_, n) if W.missing[n] then return nil end; return W.groups[n] or makeGroup(n, { alive = false }) end,
    Attribute = { GROUND_INFANTRY = "inf", GROUND_TANK = "tank", GROUND_IFV = "ifv", AIR_TRANSPORTHELO = "helo", GROUND_TRUCK = "truck" },
  })
  UNIT = mockClass("UNIT", {
    FindByName = function(_, n)
      if W.missing[n] then return nil end
      for _, g in pairs(W.groups) do if g.unit.name == n then return g.unit end end
      return setmetatable({ name = n, group = makeGroup(n .. "_grp") }, Unit_)
    end,
  })
  STATIC = mockClass("STATIC", {
    FindByName = function(_, n)
      if W.missing[n] then return nil end
      W.statics[n] = W.statics[n] or setmetatable({ name = n, alive = true }, Static_)
      return W.statics[n]
    end,
  })
  ZONE = mockClass("ZONE", {
    FindByName = function(_, n)
      if W.missing[n] then return nil end
      W.zones[n] = W.zones[n] or makeZone(n)
      return W.zones[n]
    end,
  })
  AIRBASE = mockClass("AIRBASE", { FindByName = function(_, n) if W.missing[n] then return nil end; return { name = n } end })
  COORDINATE = mockClass("COORDINATE", {
    NewFromVec2 = function(_, v) return coord(v.x, v.y) end,
    RemoveMark = function() W.marks = W.marks - 1 end,
  })

  SPAWN = mockClass("SPAWN", {
    _init = function(o, template, alias) o.template, o.alias, o.count = template, alias or template, 0 end,
    SpawnFromCoordinate = function(self, c)
      self.count = self.count + 1
      local g = makeGroup(string.format("%s#%03d", self.alias, self.count), { pos = c })
      W.spawned[#W.spawned + 1] = g.name
      return g
    end,
  })

  local function setMock(name)
    return mockClass(name, {
      _init = function(o) o.filters = {} end,
      FilterZones = function(self, z) self.zonesF = z; return self end,
      FilterPrefixes = function(self, p) self.prefixes = p; return self end,
      Count = function() return 0 end,
      ForEachStatic = function(self, fn)
        for _, z in ipairs(self.zonesF or {}) do
          for i = 1, 3 do fn(STATIC:FindByName(z:GetName() .. "_Static" .. i)) end
        end
      end,
      ForEachGroup = function(_, fn)
        for _, g in pairs(W.groups) do if g.alive and not g.player then fn(g) end end
      end,
    })
  end
  SET_GROUP, SET_CLIENT, SET_STATIC = setMock("SET_GROUP"), setMock("SET_CLIENT"), setMock("SET_STATIC")

  CLIENTMENUMANAGER = mockClass("CLIENTMENUMANAGER", {
    NewEntry = function(_, text, parent, fn, ...)
      local e = { text = text, parent = parent, fn = fn, args = { ... } }
      e.path = (parent and parent.path .. "/" or "") .. text
      W.menu[e.path] = e
      return e
    end,
  })
  CLIENTWATCH = mockClass("CLIENTWATCH", {})

  AUFTRAG = mockClass("AUFTRAG", {})
  AUFTRAG.Type = { TANKER = "Tanker", AWACS = "AWACS", ONGUARD = "On Guard", PATROLZONE = "Patrol Zone",
    CAPTUREZONE = "Capture Zone", GROUNDATTACK = "Ground Attack", ARMORATTACK = "Armor Attack", ARTY = "Fire At Point",
    BARRAGE = "Barrage", OPSTRANSPORT = "Ops Transport", CAS = "CAS", CASENHANCED = "CAS Enhanced", BAI = "BAI" }
  CHIEF = mockClass("CHIEF", {
    CreateResource = function() record("CHIEF", "CreateResource"); return {}, {} end,
    AddToResource = function() return {} end,
    Strategy = { OFFENSIVE = "Offensive" },
  })
  OPSZONE = mockClass("OPSZONE", {
    _init = function(o, zone, owner) o.zone, o.owner = zone, owner end,
    GetOwner = function(self) return self.owner end,
    Captured = function(self, side) self.owner = side; record("OPSZONE", "Captured") end,
    GetState = function() return "Guarded" end,
  })
  local function cohortMock(name)
    return mockClass(name, {
      _init = function(o, _, n, cname) o.n, o.cname, o.assets = n, cname, n end,
      CountAssets = function(self) return self.assets end,
      GetName = function(self) return self.cname end,
    })
  end
  PLATOON, SQUADRON = cohortMock("PLATOON"), cohortMock("SQUADRON")
  BRIGADE = mockClass("BRIGADE", {
    AddAssetToPlatoon = function(_, p, n) p.assets = p.assets + n; record("BRIGADE", "AddAssetToPlatoon") end,
  })
  AIRWING = mockClass("AIRWING", {
    AddAssetToSquadron = function(_, s, n) s.assets = s.assets + n; record("AIRWING", "AddAssetToSquadron") end,
  })
  PLAYERTASKCONTROLLER = mockClass("PLAYERTASKCONTROLLER", {})
  PLAYERTASKCONTROLLER.Type = { A2G = "Air-To-Ground" }
  CTLD = mockClass("CTLD", {})
  CTLD.CargoZoneType = { LOAD = "load", MOVE = "move" }
  CTLD_CARGO = { Enum = { TROOPS = "Troops", ENGINEERS = "Engineers", VEHICLE = "Vehicle", FOB = "FOB" } }
  AIRBOSS = mockClass("AIRBOSS", {})
  AIRBOSS.Difficulty = { NORMAL = "Naval Aviator" }
  TARGET = mockClass("TARGET", { GetLife = function() return 50 end, GetLife0 = function() return 100 end })
  BASE = mockClass("BASE", {})

  for _, n in ipairs({ "RANGE", "AUTOLASE", "SUPPRESSION", "ARMYGROUP", "NAVYGROUP", "FLIGHTGROUP", "MANTIS",
    "SHORAD", "SEAD", "FOX", "RECOVERYTANKER", "RESCUEHELO", "AMMOTRUCK", "ATIS", "BEACON", "CSAR", "AICSAR",
    "RAT", "RATMANAGER", "CLEANUP_AIRBASE", "ATC_GROUND_UNIVERSAL" }) do
    _G[n] = mockClass(n, {})
  end
end

-- ---------------------------------------------------------------------
-- Run the mission scripts
-- ---------------------------------------------------------------------
local function newWorld(missing)
  W = { now = 0, calls = {}, instances = {}, timers = {}, timerErrors = {}, msgs = {}, log = {}, envErrors = {},
    outText = {}, groups = {}, statics = {}, zones = {}, spawned = {}, destroyed = {}, menu = {}, marks = 0,
    respawned = 0, preSeated = {}, missing = {} }
  for _, n in ipairs(missing or {}) do W.missing[n] = true end
  KA = nil
  installStubs()
end

local function loadMission()
  for _, f in ipairs(SCRIPTS) do
    local chunk, err = loadfile(f)
    if not chunk then return false, err end
    local ok, rerr = pcall(chunk)
    if not ok then return false, f .. ": " .. tostring(rerr) end
  end
  return true
end

local function press(path, group)
  local e = W.menu["Training/" .. path]
  if not e then return false end
  local args = { unpack(e.args) }
  args[#args + 1] = group
  e.fn(unpack(args))
  return true
end

local function lastMsg(to)
  for i = #W.msgs, 1, -1 do
    if W.msgs[i].to == to then return W.msgs[i].text end
  end
  return ""
end

local function anyMsg(to, pattern)
  for _, m in ipairs(W.msgs) do
    if (to == nil or m.to == to) and m.text:find(pattern) then return true end
  end
  return false
end

-- =====================================================================
-- Run 1: complete mission
-- =====================================================================
newWorld()
local okLoad, loadErr = loadMission()
check("all scripts load and init without error", okLoad, loadErr)
check("no env.error during start", #W.envErrors == 0, W.envErrors[1])
check("no missing mission editor objects", #KA.Missing == 0, KA.Missing[1])

-- frequencies unique
local seen, dup = {}, nil
for _, f in ipairs(KA.CFG.AllFrequencies()) do
  if seen[f[2]] then dup = f[1] .. " = " .. seen[f[2]] end
  seen[f[2]] = f[1]
end
check("radio frequencies do not collide", dup == nil, dup)
local tacans = { KA.CFG.carrier.tacan.channel, KA.CFG.carrier.tanker.tacan }
for _, t in ipairs(KA.CFG.support.tankers) do tacans[#tacans + 1] = t.tacan end
local tseen, tdup = {}, false
for _, t in ipairs(tacans) do if tseen[t] then tdup = true end; tseen[t] = true end
check("TACAN channels do not collide", not tdup)

advance(11)
check("start report shown to all", anyMsg("ALL", "ready"))
check("start report lists no failed module", not anyMsg("ALL", "NOT running"), lastMsg("ALL"))

-- menu structure
for _, p in ipairs({ "CAS (JTAC)/Start", "SEAD / DEAD/Start", "SEAD / DEAD/Reveal threats", "Strike/Start",
  "Anti-Ship/Start", "BFM/MiG-29/Head-on (6 nm)", "BFM/Knock it off", "Navigation/Start route (jet)",
  "Info/Frequencies, TACAN, laser codes", "Info/Front status", "Info/Tankers and AWACS", "Info/Range" }) do
  check("menu entry Training/" .. p, W.menu["Training/" .. p] ~= nil)
end
check("menu manager propagated", (W.calls["CLIENTMENUMANAGER:InitAutoPropagation"] or 0) == 1)

-- Moose modules in use
for _, n in ipairs({ "RANGE:New", "AUTOLASE:New", "MANTIS:New", "SHORAD:New", "FOX:New", "AIRBOSS:New",
  "RECOVERYTANKER:New", "RESCUEHELO:New", "AIRWING:New", "SQUADRON:New", "AUFTRAG:NewTANKER", "AUFTRAG:NewAWACS",
  "ATIS:New", "BEACON:New", "CTLD:New", "CSAR:New", "AICSAR:New", "CHIEF:New", "OPSZONE:New", "BRIGADE:New",
  "PLATOON:New", "PLAYERTASKCONTROLLER:New", "SEAD:New", "RAT:New", "RATMANAGER:New", "CLEANUP_AIRBASE:New",
  "ATC_GROUND_UNIVERSAL:New", "CLIENTWATCH:New", "CLIENTMENUMANAGER:New", "FLIGHTGROUP:New" }) do
  check("uses " .. n, (W.calls[n] or 0) > 0)
end
check("4 tanker/AWACS squadrons have payloads", (W.calls["AIRWING:NewPayload"] or 0) == 3 + 2)
check("tanker TACAN set", (W.calls["AUFTRAG:SetTACAN"] or 0) == 2)
check("chiefs started", (W.calls["CHIEF:Start"] or 0) == 2)
check("4 strategic zones per chief", (W.calls["CHIEF:AddStrategicZone"] or 0) == 8)
check("CTLD MOVE zones = front zones", (W.calls["CTLD:AddCTLDZone"] or 0) == 2 + 4)

-- ---------------------------------------------------------------------
-- Players
-- ---------------------------------------------------------------------
local hornet = makeGroup("Hornet 1", { side = 2, player = "Pilot1", inAir = true, pos = coord(0, 0, 3000) })
local viper  = makeGroup("Viper 1",  { side = 2, player = "Pilot2", inAir = true, pos = coord(500, 0, 3000) })

-- pre-seated player replay (single player)
newWorld()
local heli = makeGroup("BLUE Heli 1", { side = 2, player = "HeloPilot" })
W.preSeated = { { getName = function() return heli.unit.name end, getGroup = function() return { getName = function() return heli.name end } end,
  getPlayerName = function() return "HeloPilot" end } }
loadMission()
advance(3)
check("pre-seated player: RANGE birth replayed", (W.calls["RANGE:OnEventBirth"] or 0) == 1)
check("pre-seated player: AIRBOSS birth replayed", (W.calls["AIRBOSS:OnEventBirth"] or 0) == 1)
check("pre-seated player: FOX birth replayed", (W.calls["FOX:OnEventBirth"] or 0) == 1)
local watch = lastInstance("CLIENTWATCH")
watch:OnAfterSpawn("", "", "", { UnitName = "X-1", GroupName = "X", PlayerName = "P" })
check("normal birth is not replayed", (W.calls["RANGE:OnEventBirth"] or 0) == 1)

-- fresh mission for the scenario tests
newWorld()
loadMission()
advance(11)
hornet = makeGroup("Hornet 1", { side = 2, player = "Pilot1", inAir = true, pos = coord(0, 0, 3000) })
viper  = makeGroup("Viper 1",  { side = 2, player = "Pilot2", inAir = true, pos = coord(500, 0, 3000) })

-- ---------------------------------------------------------------------
-- CAS
-- ---------------------------------------------------------------------
local n0 = #W.spawned
press("CAS (JTAC)/Start", hornet)
local cas = KA.Sessions["cas"]
check("CAS session started", cas ~= nil)
check("CAS spawned 2 target groups + JTAC", #W.spawned - n0 == 3, #W.spawned - n0)
check("CAS briefing sent", lastMsg("Hornet 1"):find("laser code 1688") ~= nil, lastMsg("Hornet 1"))
check("CAS laser code set on drone", (W.calls["AUTOLASE:SetRecceLaserCode"] or 0) >= 1)
press("CAS (JTAC)/Start", viper)
check("CAS busy for second group", lastMsg("Viper 1"):find("busy") ~= nil)
press("CAS (JTAC)/Status", hornet)
check("CAS status lists remaining vehicles", lastMsg("Hornet 1"):find("remaining: 8") ~= nil, lastMsg("Hornet 1"))
for _, g in ipairs(cas.data.targets) do g:Destroy() end
advance(5)
check("CAS complete after all targets dead", anyMsg("Hornet 1", "CAS / JTAC: COMPLETE"))
check("CAS cleaned up (session removed)", KA.Sessions["cas"] == nil)
advance(31)
check("CAS restarts automatically", KA.Sessions["cas"] ~= nil)
press("CAS (JTAC)/Stop", hornet)
check("CAS stop by player", KA.Sessions["cas"] == nil)

-- ---------------------------------------------------------------------
-- SEAD
-- ---------------------------------------------------------------------
press("SEAD / DEAD/Start", hornet)
local sead = KA.Sessions["sead"]
check("SEAD session started", sead ~= nil)
check("SEAD spawned 2 SAM sites", sead and #sead.data.sams == 2)
local namesOk = true
for _, g in ipairs(sead.data.sams) do if not g:GetName():find("^RED SEAD SAM SA%-") then namesOk = false end end
check("SAM group names carry MANTIS prefix and type", namesOk)
press("SEAD / DEAD/Reveal threats", hornet)
check("SEAD reveal marks threats", W.marks == 4, W.marks)
for _, g in ipairs(sead.data.sams) do g:Destroy() end
advance(5)
check("SEAD complete when SAM sites dead", anyMsg("Hornet 1", "SEAD / DEAD: COMPLETE"))
check("SEAD marks removed", W.marks == 0, W.marks)
press("SEAD / DEAD/Stop", hornet)
advance(31)
if KA.Sessions["sead"] then KA.StopSession(KA.Sessions["sead"], "test") end

-- ---------------------------------------------------------------------
-- Strike
-- ---------------------------------------------------------------------
press("Strike/Start", hornet)
local strike = KA.Sessions["strike"]
check("Strike session started", strike ~= nil)
check("Strike found 3 statics in the site zone", strike and #strike.data.statics == 3)
for _, st in ipairs(strike.data.statics) do st.obj:Destroy() end
advance(5)
check("Strike complete when statics destroyed", anyMsg("Hornet 1", "Strike: COMPLETE"))
check("Strike statics respawned", W.respawned == 3, W.respawned)
advance(31)
if KA.Sessions["strike"] then KA.StopSession(KA.Sessions["strike"], "test") end

-- ---------------------------------------------------------------------
-- Anti-ship
-- ---------------------------------------------------------------------
press("Anti-Ship/Start", hornet)
local ship = KA.Sessions["antiship"]
check("Anti-ship session started", ship ~= nil)
check("NAVYGROUP patrol set", (W.calls["NAVYGROUP:SetPatrolAdInfinitum"] or 0) == 1)
ship.data.ships:Destroy()
advance(5)
check("Anti-ship complete", anyMsg("Hornet 1", "Anti%-Ship: COMPLETE"))
advance(31)
if KA.Sessions["antiship"] then KA.StopSession(KA.Sessions["antiship"], "test") end

-- ---------------------------------------------------------------------
-- BFM (parallel)
-- ---------------------------------------------------------------------
local ground = makeGroup("Ground 1", { side = 2, player = "Pilot3", inAir = false, pos = coord(0, 0, 0) })
press("BFM/MiG-29/Head-on (6 nm)", ground)
check("BFM refused on the ground", lastMsg("Ground 1"):find("get airborne") ~= nil)
check("no BFM session on the ground", KA.Sessions["bfm|Ground 1"] == nil)
press("BFM/MiG-29/Head-on (6 nm)", hornet)
press("BFM/Su-27/Defensive (bandit at your 6)", viper)
check("BFM parallel sessions", KA.Sessions["bfm|Hornet 1"] ~= nil and KA.Sessions["bfm|Viper 1"] ~= nil)
local b1 = KA.Sessions["bfm|Hornet 1"].data.bandit
local d = b1.pos:Get2DDistance(hornet.pos)
check("head-on bandit about 6 nm away", d > 11000 and d < 11300, d)
press("BFM/MiG-21/Offensive (bandit 1.2 nm ahead)", hornet)
check("new BFM setup replaces the old bandit", not b1:IsAlive() and KA.Sessions["bfm|Hornet 1"].data.name == "MiG-21")
KA.Sessions["bfm|Hornet 1"].data.bandit:Destroy()
advance(5)
check("BFM splash message", anyMsg("Hornet 1", "Splash one MiG%-21"))
press("BFM/Knock it off", viper)
check("BFM knock it off", KA.Sessions["bfm|Viper 1"] == nil)

-- ---------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------
press("Navigation/Start route (jet)", hornet)
local nav = KA.Sessions["nav|Hornet 1"]
check("navigation route has 4 checkpoints", nav and #nav.data.route == 4)
for _, cp in ipairs(nav.data.route) do
  hornet.pos = coord(cp.zone.c.x, cp.zone.c.z, 3000)
  advance(5)
end
check("navigation checkpoints reported", anyMsg("Hornet 1", "CP4 reached"))
check("navigation complete", anyMsg("Hornet 1", "Navigation: COMPLETE"))

-- ---------------------------------------------------------------------
-- Session ends when the player leaves
-- ---------------------------------------------------------------------
press("CAS (JTAC)/Start", viper)
local cas2 = KA.Sessions["cas"]
local tgt = cas2 and cas2.data.targets[1]
viper.alive = false
advance(5)
check("session stops when player leaves", KA.Sessions["cas"] == nil)
check("session objects destroyed when player leaves", tgt and not tgt:IsAlive())

-- script error inside a session is contained
viper.alive = true
press("CAS (JTAC)/Start", viper)
KA.Sessions["cas"].data.targets = nil
advance(5)
check("session error stops the session with a message", KA.Sessions["cas"] == nil and anyMsg("Viper 1", "script error"))

-- ---------------------------------------------------------------------
-- Campaign: victory and reset, replenish
-- ---------------------------------------------------------------------
check("4 front zones", #KA.Campaign.fronts == 4)
for _, f in ipairs(KA.Campaign.fronts) do f.opszone.owner = coalition.side.BLUE end
advance(61)
check("victory announced", anyMsg("ALL", "BLUE holds the whole front"))
local captured0 = W.calls["OPSZONE:Captured"] or 0
advance(KA.CFG.campaign.resetDelay + 1)
check("front reset announced", anyMsg("ALL", "front has been reset"))
check("zone owners restored", (W.calls["OPSZONE:Captured"] or 0) - captured0 == 4)
check("initial owners back", KA.Campaign.fronts[1].opszone.owner == coalition.side.BLUE and KA.Campaign.fronts[2].opszone.owner == coalition.side.RED)
local l = KA.Campaign.legions[1]
l.cohort.assets = 1
advance(KA.CFG.campaign.replenish + 1)
check("platoon refilled", l.cohort.assets == l.n, l.cohort.assets)
press("Info/Front status", hornet)
check("front status message", lastMsg("Hornet 1"):find("Zugdidi") ~= nil)
check("no timer errors", #W.timerErrors == 0, W.timerErrors[1])

-- =====================================================================
-- Run 2: mission editor objects missing
-- =====================================================================
newWorld({ "BLUE_Carrier", "RED_CAS_Zone1", "BLUE_Airwing_Kutaisi_Warehouse", "RED_SEAD_SA-6_Template" })
local ok2, err2 = loadMission()
check("incomplete mission still starts", ok2, err2)
advance(11)
check("missing objects collected", #KA.Missing == 4, #KA.Missing)
check("start report names failed modules", anyMsg("ALL", "NOT running: .*Carrier"))
check("start report mentions missing objects", anyMsg("ALL", "4 mission editor objects are missing"))
local p = makeGroup("Hornet 2", { side = 2, player = "P", inAir = true, pos = coord(0, 0, 3000) })
press("CAS (JTAC)/Start", p)
check("CAS with missing zone fails gracefully", KA.Sessions["cas"] == nil and anyMsg("Hornet 2", "CAS zone missing"))

-- =====================================================================
-- Run 3: Moose not loaded
-- =====================================================================
newWorld()
CHIEF = nil
loadMission()
check("missing Moose is reported", W.outText[1] and W.outText[1]:find("Moose is not loaded") ~= nil)

-- =====================================================================
-- Documentation: every mission editor name of the config is in the README
-- =====================================================================
local f = io.open("README.md", "r")
local readme = f and f:read("*a") or ""
if f then f:close() end
newWorld()
loadMission()
local names = {}
local function collect(t)
  for k, v in pairs(t) do
    if type(v) == "table" then collect(v)
    elseif type(v) == "string" and (v:find("_Template$") or v:find("_Zone%d*$") or v:find("_Warehouse$")
      or v:find("^FRONT_") or v:find("^BLUE_") or v:find("^RED_") or v:find("^NEUTRAL_")) and k ~= "alias" then
      names[v] = true
    end
  end
end
collect(KA.CFG)
local undocumented = {}
for n in pairs(names) do
  if not readme:find(n, 1, true) then undocumented[#undocumented + 1] = n end
end
table.sort(undocumented)
check(string.format("all %d mission editor names documented in README.md", countKeys(names)), #undocumented == 0,
  table.concat(undocumented, ", "))

print(string.format("\n%d checks, %d errors", checks, errors))
os.exit(errors == 0 and 0 or 1)
