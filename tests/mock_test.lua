-- tests/mock_test.lua
-- Logik-Test der Skripte OHNE DCS: DCS-, Moose-, MIST- und CTLD-Funktionen werden durch einfache Attrappen ersetzt.
-- Pruefen laesst sich damit der Ablauf (Menue, Zonen-Sessions, Ansagen, Auto-Restart, Aufraeumen),
-- NICHT das Verhalten im Spiel.
-- Start (im Repo-Hauptverzeichnis):  lua5.1 tests/mock_test.lua

local failures, checks = 0, 0
local function check(cond, label)
  checks = checks + 1
  if cond then
    print("  ok   " .. label)
  else
    failures = failures + 1
    print("  FAIL " .. label)
  end
end

-- ------------------------------------------------------------------ Uhr / Timer
local clock, jobs = 100, {}
timer = {
  getTime = function() return clock end,
  getAbsTime = function() return 30000 + clock end,
  scheduleFunction = function(fn, arg, t) jobs[#jobs + 1] = { fn = fn, arg = arg, t = t } end,
}
local function advance(seconds)
  local target = clock + seconds
  while true do
    local idx, best
    for i, j in ipairs(jobs) do
      if j.t <= target and (not best or j.t < best.t) then idx, best = i, j end
    end
    if not best then break end
    table.remove(jobs, idx)
    clock = math.max(clock, best.t)
    local nextT = best.fn(best.arg, clock)
    if nextT then jobs[#jobs + 1] = { fn = best.fn, arg = best.arg, t = nextT } end
  end
  clock = target
end

-- ------------------------------------------------------------------ Welt-Modell
local units, groups = {}, {}
local outputs = {}          -- Ansagen: { id=, text=, sound= }
local logs = {}
env = { info = function(m) logs[#logs + 1] = m end, error = function(m) logs[#logs + 1] = "ERROR " .. m; print("  [env.error] " .. m) end }
local function lastText() return outputs[#outputs] and outputs[#outputs].text or "" end
local function outputCount() return #outputs end

local nextGroupId = 100
local function newGroup(name)
  nextGroupId = nextGroupId + 1
  local g = { name = name, id = nextGroupId, units = {}, alive = true }
  groups[name] = g
  return g
end
local function newUnit(g, name, typeName, pos, attrs)
  local u = { name = name, type = typeName, life = 100, point = pos, vel = { x = 0, y = 0, z = 0 }, group = g, attrs = attrs or {} }
  g.units[#g.units + 1] = u
  units[name] = u
  return u
end
local function kill(u) u.life = 0 end
local function killGroup(name) for _, u in ipairs(groups[name].units) do kill(u) end end

local UnitMT = {}
UnitMT.__index = {
  isExist = function(u) return u.life > 0 end,
  getLife = function(u) return u.life end,
  getPoint = function(u) return u.point end,
  getVelocity = function(u) return u.vel end,
  getTypeName = function(u) return u.type end,
  getName = function(u) return u.name end,
  getGroup = function(u) return setmetatable(u.group, { __index = nil }) and u.group.api end,
  hasAttribute = function(u, a) return u.attrs[a] == true end,
}
local function wrapUnit(u) return setmetatable(u, UnitMT) end

local function groupApi(g)
  g.api = {
    getName = function() return g.name end,
    getID = function() return g.id end,
    isExist = function() return g.alive end,
    getSize = function() local n = 0 for _, u in ipairs(g.units) do if u.life > 0 then n = n + 1 end end return n end,
    getUnits = function() local out = {} for _, u in ipairs(g.units) do out[#out + 1] = wrapUnit(u) end return out end,
    destroy = function() g.alive = false for _, u in ipairs(g.units) do u.life = 0 end end,
  }
  return g.api
end

Unit = { getByName = function(n) return units[n] and wrapUnit(units[n]) or nil end }
Group = { getByName = function(n) return groups[n] and groups[n].alive and (groups[n].api or groupApi(groups[n])) or nil end }

-- Spieler
local playerGroup = newGroup("Player-F18")
groupApi(playerGroup)
local playerUnit = newUnit(playerGroup, "Player-F18-1", "FA-18C_hornet", { x = 0, y = 5000, z = 0 })
playerUnit.vel = { x = 200, y = 0, z = 0 }

coalition = { side = { RED = 1, BLUE = 2 }, getPlayers = function(side)
  if side ~= 2 then return {} end
  local out = {}
  for _, g in pairs(groups) do
    if g.isPlayer and g.alive then
      for _, u in ipairs(g.units) do if u.life > 0 then out[#out + 1] = wrapUnit(u) end end
    end
  end
  return out
end }
playerGroup.isPlayer = true
-- getGroup der Spieler-Unit liefert die API-Sicht
UnitMT.__index.getGroup = function(u) return u.group.api or groupApi(u.group) end

-- Zonen
local zones = {}
local function addZone(name, x, z, r) zones[name] = { point = { x = x, y = 0, z = z }, radius = r } end
trigger = {
  misc = { getZone = function(n) return zones[n] end },
  action = {
    outTextForGroup = function(id, text) outputs[#outputs + 1] = { id = id, text = text } end,
    outSoundForGroup = function(id, file) outputs[#outputs + 1] = { id = id, sound = file, text = "" } end,
    outText = function(text) outputs[#outputs + 1] = { id = 0, text = text } end,
  },
}
for _, n in ipairs({ "TRN_GA_ZONE", "TRN_SEAD_ZONE", "TRN_INT_ZONE", "TRN_JTAC_POS", "TRN_JTAC_IP", "TRN_JTAC_START", "TRN_JTAC_END",
  "TRN_CTLD_PICKUP_1", "TRN_CTLD_PICKUP_2", "TRN_CTLD_TASK_1", "TRN_CTLD_TASK_2", "TRN_CTLD_TASK_3" }) do
  addZone(n, math.random(1000, 90000), math.random(1000, 90000), 3000)
end
addZone("TRN_CTLD_TASK_1", 50000, 50000, 500)

land = { getHeight = function() return 120 end }
coord = { LOtoLL = function(p) return p end, LLtoMGRS = function() return { UTMZone = "38T", MGRSDigraph = "KM", Easting = 12345, Northing = 67890 } end }
mist = {
  getRandPointInCircle = function(p, r, inner)
    local a = math.random() * 2 * math.pi
    local rad = (inner or 0) + math.random() * (r - (inner or 0))
    local px = p.x
    local pz = p.z or p.y
    return { x = px + math.cos(a) * rad, y = pz + math.sin(a) * rad }
  end,
  tostringMGRS = function(m, acc) return m.UTMZone .. " " .. m.MGRSDigraph .. " 123 456" end,
}

-- Events
local eventHandlers = {}
world = { event = { S_EVENT_SHOT = 1 }, addEventHandler = function(h) eventHandlers[#eventHandlers + 1] = h end }
Weapon = { Category = { MISSILE = 1, SHELL = 0 } }
local function fireEvent(e) for _, h in ipairs(eventHandlers) do h:onEvent(e) end end

-- ------------------------------------------------------------------ Moose-Attrappen
local templates = {}
local routed = {}
SPAWN = {}
SPAWN.__index = SPAWN
function SPAWN:New(template)
  if not templates[template] then error("SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. template .. "'") end
  return setmetatable({ template = template, n = 0 }, SPAWN)
end
function SPAWN:SpawnFromVec2(vec2, minH, maxH)
  self.n = self.n + 1
  local name = string.format("%s#%03d", self.template, self.n)
  local g = newGroup(name)
  local spec = templates[self.template]
  local alt = (minH and maxH) and minH or 0
  for i = 1, spec.count or 2 do
    newUnit(g, name .. "-" .. i, spec.type or "BMP-2", { x = vec2.x + i * 10, y = alt, z = vec2.y }, spec.attrs)
  end
  return { GetName = function() return name end }
end
GROUP = { FindByName = function(_, n)
  if not groups[n] then return nil end
  return { RouteGroundOnRoad = function(_, dest, speed, delay) routed[n] = { dest = dest, speed = speed } end }
end }
COORDINATE = { NewFromVec2 = function(_, v) return { vec2 = v } end }

local menuCommands, menuCount = {}, 0
MENU_GROUP = { New = function(_, g, text, parent) menuCount = menuCount + 1; return { text = text, parent = parent, path = (parent and parent.path .. "/" or "") .. text } end }
MENU_GROUP_COMMAND = { New = function(_, g, text, parent, fn, ...)
  menuCommands[(parent and parent.path .. "/" or "") .. text] = { fn = fn, args = { ... } }
  return {}
end }
-- Aufruf-Syntax "Klasse:New(...)" -> Tabelle mit New(self, ...)
local airbossCalls = {}
AIRBOSS = { New = function(self, unitName, alias)
  airbossCalls.new = unitName
  return setmetatable({}, { __index = function(t, k)
    return function(s, ...) airbossCalls[k] = { ... }; return s end
  end })
end }

-- CTLD-Attrappen
ctld = { callbacks = {}, addCallback = function(f) ctld.callbacks[#ctld.callbacks + 1] = f end,
  JTACStart = function(...) ctld.jtacArgs = { ... } end, cleanupJTAC = function(n) ctld.cleaned = n end }

-- Menue-Aufruf-Helfer
local function menu(path)
  local c = menuCommands[path]
  if not c then print("  (menu entry missing: " .. path .. ")") end
  return c
end
local function press(path)
  local c = menu(path)
  if c then c.fn(unpack(c.args)) end
  return c ~= nil
end

-- ------------------------------------------------------------------ Templates der "Mission"
local function tpl(name, spec) templates[name] = spec or {} end
for _, n in ipairs({ "TRN_GA_VEH_1", "TRN_GA_VEH_2", "TRN_GA_VEH_3", "TRN_GA_ARM_1", "TRN_GA_ARM_2", "TRN_GA_AAA_1", "TRN_GA_SHORAD_1" }) do tpl(n) end
tpl("TRN_SAM_SA2", { count = 4, type = "S-75", attrs = { ["SAM SR"] = true } })
tpl("TRN_SAM_SA3", { count = 3, type = "S-125" })
tpl("TRN_SAM_SA6", { count = 4, type = "Kub", attrs = { ["SAM TR"] = true } })
tpl("TRN_SAM_SA11", { count = 4, type = "SA-11", attrs = { ["SAM SR"] = true } })
tpl("TRN_SAM_SA10", { count = 4, type = "S-300", attrs = { ["SAM SR"] = true, ["SAM TR"] = true } })
tpl("TRN_SAM_SA15", {}) tpl("TRN_SAM_ZSU23", {})
tpl("TRN_BANDIT_MIG21", { count = 1, type = "MiG-21Bis" }) tpl("TRN_BANDIT_MIG29", { count = 2, type = "MiG-29S" })
tpl("TRN_BANDIT_SU27", { count = 2, type = "Su-27" }) tpl("TRN_BANDIT_MIG23", { count = 2 }) tpl("TRN_BANDIT_TU22", { count = 1 })
tpl("TRN_JTAC", { count = 1, type = "Soldier M4" })
tpl("TRN_JTAC_TGT_1", { count = 3, type = "Ural-375" }) tpl("TRN_JTAC_TGT_2", { count = 4, type = "BTR-80" }) tpl("TRN_JTAC_TGT_3", { count = 5 })
tpl("TRN_JTAC_ESC_1", { count = 1, type = "ZSU-23-4 Shilka" })
-- Traeger
local carrierGroup = newGroup("TRN_CARRIER_GRP")
newUnit(carrierGroup, "TRN_CARRIER", "Stennis", { x = 5000, y = 0, z = 5000 })

-- ------------------------------------------------------------------ Skripte laden
local base = arg and arg[0] and arg[0]:match("^(.*)/tests/") or "."
local order = { "00_config", "01_core", "02_audio", "03_menu", "10_ground_attack", "20_carrier", "30_sead_dead",
  "40_intercept", "50_jtac", "60_ctld", "99_init" }
for _, f in ipairs(order) do
  local chunk, err = loadfile(base .. "/scripts/" .. f .. ".lua")
  if not chunk then error(err) end
  chunk()
end

local CFG = TRN.CFG
local ROOT = CFG.MENU_ROOT
-- Ansage-Dauer im Test auf 0: die Warteschlange (Ueberlappungsschutz) soll die Pruefungen nicht verzoegern
for _, d in pairs(CFG.SOUNDS) do d.dur = 0 end

print("== Initialisierung")
check(#TRN.ZoneOrder == 6, "6 Zonen registriert")
check(airbossCalls.new == "TRN_CARRIER", "Airboss auf TRN_CARRIER erstellt")
check(airbossCalls.SetTACAN ~= nil and airbossCalls.Start ~= nil, "Airboss: TACAN gesetzt und gestartet")
check(#ctld.callbacks == 1 and #ctld.pickupZones == 2 and #ctld.logisticUnits == 2, "CTLD konfiguriert (Callback, 2 Pickup, 2 Logistik)")

print("== Menue")
advance(CFG.MENU_SCAN + 1)
check(menu(ROOT .. "/Help") ~= nil, "Hilfe-Menue vorhanden")
check(menu(ROOT .. "/1 Ground Attack/Start EASY") ~= nil, "GA: Start EASY vorhanden")
check(menu(ROOT .. "/3 SEAD/DEAD/Start HARD/DEAD") ~= nil, "SEAD: Start HARD > DEAD vorhanden")
check(menu(ROOT .. "/5 JTAC Moving Targets/3 In hot") ~= nil, "JTAC: In hot vorhanden")
check(menuCommands[ROOT .. "/2 Carrier Landing/Start EASY"] == nil, "Carrier: kein Start-Eintrag")
check(menu(ROOT .. "/2 Carrier Landing/Info") ~= nil, "Carrier: Info vorhanden")
check(outputs[#outputs - 0] and outputs[1].sound == CFG.SOUND_FOLDER .. "gen_welcome.ogg", "Begruessung mit Sounddatei ausgegeben")
local mcount = menuCount
advance(10)
check(menuCount == mcount, "Menue wird nicht doppelt aufgebaut")

print("== Zone 1: Bodenangriff")
press(ROOT .. "/1 Ground Attack/Start MEDIUM")
local ga = TRN.Zones.GA
check(ga:IsBusy() and ga:Owner() == "Player-F18", "GA-Session laeuft")
check(#ga.session.data.targets == 3, "MEDIUM: 3 Zielgruppen")
check(lastText():find("Target 1"), "Briefing nennt Ziele mit MGRS")
local before = outputCount()
killGroup(ga.session.data.targets[1])
advance(CFG.TICK + 1)
check(lastText():find("Targets remaining: 2"), "Trefferansage nach erstem Ziel")
killGroup(ga.session.data.targets[2]); killGroup(ga.session.data.targets[3])
advance(CFG.TICK + 1)
check(lastText():find("Round 1 finished"), "Abschlussmeldung nach allen Zielen")
local oldTargets = ga.session.data.targets[1]
advance(CFG.RESTART_DELAY + CFG.TICK + 1)
check(ga.session.rounds == 2 and ga.session.data.targets[1] ~= oldTargets, "Neue Runde startet automatisch")
check(not groups[oldTargets].alive, "Alte Ziele wurden aufgeraeumt")
press(ROOT .. "/1 Ground Attack/Stop / Reset")
check(not ga:IsBusy(), "Stop beendet die Session")

print("== Zone 1: Besetzt-Meldung")
press(ROOT .. "/1 Ground Attack/Start EASY")
local other = newGroup("Other-F16"); groupApi(other); other.isPlayer = true
newUnit(other, "Other-F16-1", "F-16C_50", { x = 0, y = 4000, z = 100 })
local mark = outputCount()
local started = ga:Start("Other-F16", "EASY")
advance(2)
local busyMsg = false
for i = mark + 1, outputCount() do
  if outputs[i].id == other.id and (outputs[i].text or ""):find("busy") then busyMsg = true end
end
check(started == false and busyMsg and ga:Owner() == "Player-F18", "Zweite Gruppe erhaelt 'Zone is busy', Besitzer bleibt")
ga:Stop(true)
other.alive = false; for _, u in ipairs(other.units) do u.life = 0 end

print("== Zone 3: SEAD/DEAD")
press(ROOT .. "/3 SEAD/DEAD/Start MEDIUM/SEAD")
local sead = TRN.Zones.SEAD
check(sead:IsBusy() and sead.session.data.mode == "SEAD", "SEAD-Session laeuft im Modus SEAD")
check(#sead.session.data.radars > 0, "Radar-Units erkannt")
-- Spieler in die Naehe des SAM setzen -> Radarwarnung
local main = TRN.GroupAliveUnits(sead.session.data.main)[1]
playerUnit.point = { x = main.point.x - 20000, y = 5000, z = main.point.z }
advance(CFG.TICK + 1)
check(lastText():find("Bearing"), "Radarwarnung mit Peilung")
-- Raketenstart
local shooter = groups[sead.session.data.main].units[1]
fireEvent({ id = 1, initiator = shooter and wrapUnit(shooter) or nil, weapon = { getDesc = function() return { category = Weapon.Category.MISSILE } end } })
check(lastText():find("Missile launch"), "Raketenstart-Warnung")
-- SEAD-Erfolg: nur Radare zerstoeren
for _, n in ipairs(sead.session.data.radars) do kill(units[n]) end
advance(CFG.TICK + 1)
check(lastText():find("finished") and sead.session.state == "WAIT", "SEAD: Erfolg nach Radar-Zerstoerung (Launcher leben noch)")
sead:Stop(true)
press(ROOT .. "/3 SEAD/DEAD/Start EASY/DEAD")
local aliveSam = #TRN.GroupAliveUnits(sead.session.data.main)
for _, u in ipairs(groups[sead.session.data.main].units) do kill(u) end
advance(CFG.TICK + 1)
check(aliveSam > 0 and sead.session.state == "WAIT", "DEAD: Erfolg erst nach Zerstoerung der gesamten Gruppe")
sead:Stop(true)

print("== Zone 4: Intercept")
playerUnit.point = { x = 0, y = 6000, z = 0 }
press(ROOT .. "/4 Air Intercept/Start HARD")
local int = TRN.Zones.INT
check(int:IsBusy() and #int.session.data.bandits == 3, "HARD: 2 Gruppen + Bomber")
advance(CFG.INT.awacsInterval + CFG.TICK)
check(lastText():find("bandit BRAA"), "AWACS-BRAA-Ansage")
for _, n in ipairs(int.session.data.bandits) do killGroup(n) end
advance(CFG.TICK + 1)
check(lastText():find("cleared"), "Welle abgeschlossen")
int:Stop(true)

print("== Zone 5: JTAC")
local jt = TRN.Zones.JTAC
press(ROOT .. "/5 JTAC Moving Targets/2 Request 9-line")
advance(6)
check(lastText():find("Start the JTAC exercise first"), "9-Line ohne Session wird abgelehnt")
press(ROOT .. "/5 JTAC Moving Targets/Start MEDIUM")
check(jt:IsBusy() and routed[jt.session.data.target] and routed[jt.session.data.target].speed == 35, "Ziel faehrt mit 35 km/h auf Strasse")
press(ROOT .. "/5 JTAC Moving Targets/2 Request 9-line")
advance(6)
check(outputs[#outputs].sound == nil and lastText():find("Follow the sequence"), "9-Line vor Check-in wird abgelehnt")
press(ROOT .. "/5 JTAC Moving Targets/1 Check in")
advance(6)
press(ROOT .. "/5 JTAC Moving Targets/2 Request 9-line")
advance(6)
local nl = ""
for i = #outputs, math.max(1, #outputs - 3), -1 do nl = nl .. (outputs[i].text or "") end
check(nl:find("9-LINE") and nl:find("Heading IP to target") and nl:find("laser code"), "9-Line enthaelt alle Zeilen")
press(ROOT .. "/5 JTAC Moving Targets/3 In hot")
check(ctld.jtacArgs and ctld.jtacArgs[2] == 1688, "Laser (ctld.JTACStart) mit Code 1688 gestartet")
killGroup(jt.session.data.target)
advance(CFG.TICK + 3)
check(lastText():find("finished"), "BDA nach Zerstoerung des Ziels")
jt:Stop(true)

print("== Zone 6: CTLD")
press(ROOT .. "/6 CTLD Transport/Start EASY")
local ct = TRN.Zones.CTLD
check(ct:IsBusy() and ct.session.data.task == "TROOPS", "EASY: Aufgabe Truppen")
local zone = trigger.misc.getZone(ct.session.data.zone)
-- falscher Ort
playerUnit.point = { x = zone.point.x + 9000, y = 100, z = zone.point.z }
ctld.callbacks[1]({ unit = wrapUnit(playerUnit), action = "dropped_troops" })
advance(CFG.TICK + 1)
check(ct.session.state == "RUN", "Abwurf ausserhalb der Zone zaehlt nicht")
playerUnit.point = { x = zone.point.x + 10, y = 100, z = zone.point.z }
ctld.callbacks[1]({ unit = wrapUnit(playerUnit), action = "unpack" })
advance(CFG.TICK + 1)
check(ct.session.state == "RUN", "Falsche Aktion zaehlt nicht")
ctld.callbacks[1]({ unit = wrapUnit(playerUnit), action = "dropped_troops" })
advance(CFG.TICK + 1)
advance(6)
check(ct.session.state == "WAIT" and lastText():find("finished"), "Abwurf in der Zone schliesst die Aufgabe ab")
ct:Stop(true)

print("== Fehlerfaelle")
templates.TRN_GA_VEH_1, templates.TRN_GA_VEH_2, templates.TRN_GA_VEH_3 = nil, nil, nil
local ok = pcall(function() press(ROOT .. "/1 Ground Attack/Start EASY") end)
check(ok, "Fehlendes Template wirft keinen Fehler nach aussen")
advance(1)
check(lastText():find("Setup error"), "Spieler erhaelt Setup-Fehlermeldung")
check(not TRN.Zones.GA:IsBusy(), "Nach Setup-Fehler ist die Zone wieder frei")
TRN.Zones.GA:Stop(true)

print("== Spieler verschwindet")
press(ROOT .. "/4 Air Intercept/Start EASY")
check(TRN.Zones.INT:IsBusy(), "INT laeuft")
playerGroup.alive = false; kill(playerUnit)
advance(CFG.TICK + 1)
check(not TRN.Zones.INT:IsBusy(), "Session endet, wenn die Spielergruppe weg ist")
check(#TRN.GroupAliveUnits("TRN_BANDIT_MIG23#001") == 0, "Gegner wurden aufgeraeumt")

print(string.format("\n%d Pruefungen, %d Fehler", checks, failures))
os.exit(failures == 0 and 0 or 1)
