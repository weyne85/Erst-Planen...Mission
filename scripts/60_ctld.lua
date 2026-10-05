-- 60_ctld.lua
-- Zone 6: CTLD (Lasttransport). Die eigentliche Transport-Mechanik (Kisten, Truppen, F10-Menue der Helikopter)
-- liefert CTLD (ciribob). Dieses Skript
--   * traegt Lager, Logistik-Objekte und Einsatzorte aus 00_config.lua in die CTLD-Tabellen ein,
--   * vergibt zufaellige Aufgaben ("Truppen liefern", "Verteidigung bauen", "FOB bauen"),
--   * wertet die CTLD-Ereignisse (Callback) aus und meldet den Erfolg.
-- CTLD erkennt Transporter nach Flugzeugtyp (Chinook CH-47Fbl1, Mi-8MT, ...). Der Apache kann keine Lasten tragen
-- und sichert stattdessen.

TRN = TRN or {}
local CFG = TRN.CFG
local C = CFG.CTLD

local def = { id = C.id, title = C.title, cfg = C }

local function zonesToText(list)
  local out = {}
  for _, name in ipairs(list) do
    local z = TRN.ZoneInfo(name)
    out[#out + 1] = string.format("%s: MGRS %s", name, z and TRN.MGRS(z.point, 3) or "missing in mission")
  end
  return table.concat(out, "\n")
end

function def.info()
  return "CTLD TRANSPORT\nPick up crates/troops at the logistics zones, deliver them to the task zone.\n" ..
    "Use the CTLD F10 menu in your helicopter (Chinook, Mi-8) for crates, troops, unpacking and FOB.\n" ..
    "EASY: deliver troops. MEDIUM: deliver crates and unpack a defence. HARD: build a FOB.\n" ..
    "Pickup zones:\n" .. zonesToText(C.pickupZones)
end

function def.OnRound(s)
  local lv = s.lv
  if not ctld then return false, "CTLD is not loaded" end

  local candidates = {}
  for _, name in ipairs(C.taskZones) do
    if TRN.ZoneInfo(name) then candidates[#candidates + 1] = name end
  end
  if #candidates == 0 then return false, "No CTLD task zones found in mission" end

  s.data.zone = TRN.Pick(candidates)
  s.data.task = lv.task
  s.data.done = false

  local z = TRN.ZoneInfo(s.data.zone)
  s:Say("ctld_briefing", string.format("%s%s at %s, MGRS %s.\nPickup:\n%s",
    s:RoundTag("Task"), lv.text, s.data.zone, TRN.MGRS(z.point, 4), zonesToText(C.pickupZones)))
  return true
end

function def.OnTick(s)
  if s.data.done then
    s:Say("ctld_complete", string.format("Task %d finished in %s.", s.rounds, s:ElapsedText()))
    return "done"
  end
end

def.extras = {
  { text = "Repeat task", fn = function(groupName)
      local zone = TRN.Zones[C.id]
      local s = zone and zone.session
      if not s or s.group ~= groupName or s.state ~= "RUN" then
        TRN.Audio.Text(groupName, "No active CTLD task. Start one first.")
        return
      end
      local z = TRN.ZoneInfo(s.data.zone)
      TRN.Audio.Text(groupName, string.format("Task: %s at %s, MGRS %s.", C.levels[s.level].text, s.data.zone, z and TRN.MGRS(z.point, 4) or "n/a"))
    end },
}

-- CTLD-Konfiguration -------------------------------------------------
local function configureCtld()
  if not ctld then
    TRN.Error("CTLD is not loaded - zone 6 disabled")
    return false
  end
  -- WICHTIG: CTLD wandelt diese Tabellen beim Laden um (Rauchfarbe "blue" -> Zahl, "yes" -> 1, Limit -1 -> 10000).
  -- Weil wir die Tabellen NACH dem CTLD-Start ersetzen, muessen wir direkt das umgewandelte Format liefern,
  -- sonst bricht ctld.refreshSmoke mit "attempt to compare number with string" ab.
  local smoke = trigger.smokeColor
  local pickups = {}
  for _, name in ipairs(C.pickupZones) do
    pickups[#pickups + 1] = { name, smoke.Blue, 10000, 1, 2 }   -- blauer Rauch, unbegrenzt, aktiv, nur BLUE
  end
  local drops = {}
  for _, name in ipairs(C.taskZones) do
    drops[#drops + 1] = { name, smoke.Green, 2, 1 }             -- gruener Rauch, BLUE, aktiv
  end
  ctld.pickupZones = pickups
  ctld.dropOffZones = drops
  ctld.wpZones = {}
  ctld.logisticUnits = { unpack(C.logisticUnits) }
  ctld.addPlayerAircraftByType = true
  return true
end

-- CTLD-Callback: prueft, ob die Aufgabe der laufenden Session erfuellt wurde
local function onCtldEvent(args)
  local zone = TRN.Zones[C.id]
  local s = zone and zone.session
  if not s or s.state ~= "RUN" or s.data.done then return end
  if not args or not args.unit or not args.unit.getGroup then return end

  local ok, err = pcall(function()
    local heli = args.unit
    if heli:getGroup():getName() ~= s.group then return end
    local pos = args.position or heli:getPoint()
    if not TRN.InZone(pos, s.data.zone) then return end

    local task = s.data.task
    if (task == "TROOPS" and args.action == "dropped_troops")
        or (task == "UNPACK" and args.action == "unpack")
        or (task == "FOB" and args.action == "fob") then
      s.data.done = true
    end
  end)
  if not ok then TRN.Error("CTLD callback: %s", tostring(err)) end
end

function TRN.Ctld_Init()
  if configureCtld() then
    ctld.addCallback(onCtldEvent)
    TRN.Log("CTLD configured: %d pickup zones, %d task zones", #C.pickupZones, #C.taskZones)
  end
end

TRN.RegisterZone(def)
