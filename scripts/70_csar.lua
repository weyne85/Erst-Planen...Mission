-- 70_csar.lua
-- Zone 7: Zufaellige CSAR-Einsaetze (Moose CSAR). In zufaelligen Abstaenden stuerzt ein (KI-)Pilot in einer der
-- Zonen TRN_CSAR_1..4 ab, mit Funkfeuer. Rettungshubschrauber (Chinook, Mi-8, Apache) suchen ihn, nehmen ihn auf und
-- bringen ihn zu einer MASH-Zone (TRN_MASH_*) oder auf einen Flugplatz. Das F10-Menue "CSAR" legt Moose selbst an.
-- Ejektionen von Spielern erzeugen ebenfalls automatisch einen CSAR-Einsatz (Moose-Standardverhalten).

TRN = TRN or {}
local CFG = TRN.CFG
local C = CFG.CSAR

local def = { id = C.id, title = C.title, cfg = C, startable = false }

TRN.Csar = nil
local state = { nextAt = nil, spawnedAt = nil }

local function isRescueHelicopter(dcsUnit)
  return CSAR and CSAR.AircraftType and CSAR.AircraftType[dcsUnit:getTypeName()] ~= nil
end

local function helicopterPlayerCount()
  local n = 0
  for _, p in pairs(TRN.PlayerGroups()) do
    if isRescueHelicopter(p.unit) then n = n + 1 end
  end
  return n
end

local function activeEntries()
  local list = {}
  if TRN.Csar and TRN.Csar.downedPilots then
    for _, entry in pairs(TRN.Csar.downedPilots) do list[#list + 1] = entry end
  end
  return list
end

-- Erzeugt einen Einsatz. Rueckgabe: true oder false, Grund
local function spawnMission()
  local csar = TRN.Csar
  if not csar then return false, "CSAR is not running" end

  local zones = {}
  for _, name in ipairs(C.zones) do
    if TRN.ZoneInfo(name) then zones[#zones + 1] = name end
  end
  if #zones == 0 then return false, "No CSAR trigger zones found in the mission" end

  local zoneName = TRN.Pick(zones)
  local callsign = string.format("%s %d-%d", TRN.Pick(C.callsigns), math.random(1, 4), math.random(1, 4))
  local ok, err = pcall(function()
    csar:SpawnCSARAtZone(zoneName, CFG.SIDE, callsign, true, false, callsign, TRN.Pick(C.aircraft))
  end)
  if not ok then
    TRN.Error("CSAR spawn failed: %s", tostring(err))
    return false, tostring(err)
  end
  state.spawnedAt = timer.getTime()
  TRN.Log("CSAR: %s down near zone %s", callsign, zoneName)
  return true
end

local function tick()
  if not TRN.Csar then return false end
  local now = timer.getTime()
  local entries = activeEntries()

  if #entries == 0 then state.spawnedAt = nil end

  -- Offener Einsatz verfaellt
  if #entries > 0 and state.spawnedAt and now - state.spawnedAt > C.expireSec then
    for _, entry in ipairs(entries) do
      pcall(function() if entry.group and entry.group.Destroy then entry.group:Destroy() end end)
    end
    state.spawnedAt = nil
    state.nextAt = now + TRN.RandomIn(C.intervalSec)
    TRN.Audio.TextAll("CSAR: The downed pilot could not be reached in time. Mission closed.")
    return
  end

  if not state.nextAt then state.nextAt = now + TRN.RandomIn(C.firstDelaySec) end

  if now >= state.nextAt and #entries < C.maxActive then
    if (not C.onlyWithHelicopter) or helicopterPlayerCount() > 0 then
      spawnMission()
      state.nextAt = now + TRN.RandomIn(C.intervalSec)
    end
  end
end

function def.info()
  local lines = { "CSAR - RANDOM RESCUE MISSIONS",
    "A downed pilot appears at random in the area, with a radio beacon. Helicopters (Chinook, Mi-8, Apache) only.",
    "Find the pilot (F10 > CSAR > List Active CSAR, smoke, flare), land close or hover, wait until he boards,",
    "then bring him to a MASH zone or an airfield." }
  for _, name in ipairs(C.mashZones) do
    local z = TRN.ZoneInfo(name)
    lines[#lines + 1] = string.format("MASH %s: MGRS %s", name, z and TRN.MGRS(z.point, 3) or "missing in mission")
  end
  lines[#lines + 1] = "A new mission appears every " .. math.floor(C.intervalSec[1] / 60) .. "-" .. math.floor(C.intervalSec[2] / 60) ..
    " min while a helicopter is on the ramp or in the air."
  return table.concat(lines, "\n")
end

def.extras = {
  { text = "Request CSAR mission now", fn = function(groupName)
      local p = TRN.PlayerGroups()[groupName]
      if not p or not isRescueHelicopter(p.unit) then
        TRN.Audio.Text(groupName, "CSAR missions are for rescue helicopters (Chinook, Mi-8, Apache).")
        return
      end
      if #activeEntries() >= C.maxActive then
        TRN.Audio.Text(groupName, "A CSAR mission is already active. F10 > CSAR > List Active CSAR.")
        return
      end
      local ok, err = spawnMission()
      if ok then
        state.nextAt = timer.getTime() + TRN.RandomIn(C.intervalSec)
      else
        TRN.Audio.Text(groupName, "CSAR could not start: " .. tostring(err))
      end
    end },
}

-- Wird von 99_init.lua aufgerufen
function TRN.Csar_Init()
  if not C.enabled then return false end
  local ok, err = pcall(function()
    local csar = CSAR:New(CFG.SIDE, C.pilotTemplate, "CSAR")
    csar.useprefix = false                 -- alle Hubschrauber der Typenliste (CSAR.AircraftType), nicht nur Gruppen mit Praefix
    csar.mashprefix = { C.mashPrefix }     -- MASH = Triggerzonen mit diesem Praefix
    csar.radioSound = C.beaconSound        -- Datei in l10n/DEFAULT der .miz
    csar.coordtype = 2                     -- MGRS
    csar.messageTime = 25
    csar.immortalcrew = true

    function csar:OnAfterRescued()
      TRN.Audio.TextAll("CSAR: Pilot rescued and safe. Well done.")
    end

    csar:__Start(5)
    TRN.Csar = csar
  end)
  if not ok then
    TRN.Error("CSAR setup failed: %s", tostring(err))
    return false
  end
  TRN.Every(30, tick, 30)
  TRN.Log("CSAR started (zones: %d, MASH: %s*)", #C.zones, C.mashPrefix)
  return true
end

TRN.RegisterZone(def)
