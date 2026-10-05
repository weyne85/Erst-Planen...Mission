-- 80_ambient.lua
-- Belebt die Mission: KI-Flugverkehr zwischen den Flugplaetzen (Moose RAT) und Militaerkonvois auf Strassen.
--   * BLUE-Konvois: freundlicher Nachschub, nur Leben auf der Karte.
--   * RED-Konvois: feindliche Gelegenheitsziele. Sie werden allen Spielern mit Position angesagt.
-- Konvois starten nur, solange mindestens ein Spieler da ist, und verschwinden bei Ankunft oder nach Zeitablauf.
-- Schiffsverkehr und Flugplatz-Kulisse (parkende Flugzeuge, Fahrzeuge) stehen direkt in der .miz.

TRN = TRN or {}
local CFG = TRN.CFG
local A = CFG.AMBIENT

local def = { id = A.id, title = A.title, cfg = A, startable = false }

TRN.Ambient = { rats = {}, convoys = {} }

local nextAt = {}      -- Konvoi-Definition -> Zeitpunkt des naechsten Starts
local active = {}      -- laufende Konvois: { def =, group =, dest = vec3, started = time }

local function sideName(d)
  return d.side == "RED" and "hostile" or "friendly"
end

-- ----------------------------------------------------------------------
-- KI-Flugverkehr (Moose RAT)
-- ----------------------------------------------------------------------
function TRN.Ambient_InitRat()
  local R = A.rat
  if not (R and R.enabled) then return false end
  local started = 0
  for _, f in ipairs(R.flights) do
    local ok, err = pcall(function()
      local rat = RAT:New(f.template, f.alias)
      if not rat then error("template '" .. f.template .. "' not found in mission") end
      rat:SetCoalition("sameonly")           -- nur Flugplaetze der eigenen Koalition
      rat:SetDeparture(R.airfields)
      rat:SetDestination(R.airfields)
      rat:SetTakeoffRunway()                 -- Start von der Piste: kein Konflikt mit Spieler-Parkplaetzen
      rat:ATC_Messages(false)                -- keine Funkmeldungen an die Spieler
      rat:SetSpawnInterval(f.intervalSec)
      rat:SetSpawnDelay(f.delaySec)
      rat:Spawn(f.count)
      TRN.Ambient.rats[#TRN.Ambient.rats + 1] = rat
    end)
    if ok then
      started = started + 1
    else
      TRN.Error("RAT '%s' failed: %s", tostring(f.template), tostring(err))
    end
  end
  TRN.Log("Ambient: %d of %d RAT flights started", started, #R.flights)
  return started > 0
end

-- ----------------------------------------------------------------------
-- Konvois
-- ----------------------------------------------------------------------
local function existingZones(list)
  local out = {}
  for _, name in ipairs(list) do
    if TRN.ZoneInfo(name) then out[#out + 1] = name end
  end
  return out
end

local function countActive(d)
  local n = 0
  for _, c in ipairs(active) do
    if c.def == d then n = n + 1 end
  end
  return n
end

local function spawnConvoy(d)
  local zones = existingZones(d.zones)
  if #zones < 2 then
    TRN.Error("Convoy '%s': fewer than 2 existing zones", d.id)
    return false
  end

  local from = TRN.Pick(zones)
  local to = from
  for _ = 1, 10 do
    to = TRN.Pick(zones)
    if to ~= from then break end
  end
  if to == from then return false end

  local svec = TRN.RandomPointInZone(from)
  local evec = TRN.RandomPointInZone(to)
  local name, err = TRN.Spawn(TRN.Pick(d.templates), svec)
  if not name then
    TRN.Error("Convoy '%s' spawn failed: %s", d.id, tostring(err))
    return false
  end

  local grp = GROUP:FindByName(name)
  if not grp then return false end
  grp:RouteGroundOnRoad(COORDINATE:NewFromVec2(evec), TRN.RandomIn(d.speedKmh), 1)

  active[#active + 1] = { def = d, group = name, dest = { x = evec.x, y = 0, z = evec.y }, started = timer.getTime() }
  TRN.Log("Convoy '%s' started: %s from %s to %s", d.id, name, from, to)

  if d.announce then
    local n = #TRN.GroupAliveUnits(name)
    TRN.Audio.TextAll(string.format("INTEL: %s convoy (%d vehicles) spotted at MGRS %s, heading to MGRS %s.",
      sideName(d), n, TRN.MGRS({ x = svec.x, y = 0, z = svec.y }, 3), TRN.MGRS({ x = evec.x, y = 0, z = evec.y }, 3)))
  end
  return true
end

local function tick()
  local now = timer.getTime()

  -- laufende Konvois pruefen
  for i = #active, 1, -1 do
    local c = active[i]
    local units = TRN.GroupAliveUnits(c.group)
    local remove = false
    if #units == 0 then
      remove = true
      if c.def.announce then TRN.Audio.TextAll("INTEL: " .. sideName(c.def) .. " convoy destroyed.") end
    elseif TRN.Dist2D(units[1]:getPoint(), c.dest) < 400 then
      remove = true                                  -- angekommen
      TRN.DestroyGroup(c.group)
    elseif now - c.started > c.def.ttlSec then
      remove = true                                  -- Zeit abgelaufen
      TRN.DestroyGroup(c.group)
    end
    if remove then table.remove(active, i) end
  end

  -- neue Konvois starten, solange Spieler da sind
  if next(TRN.PlayerGroups()) == nil then return end
  for _, d in ipairs(A.convoys) do
    if not nextAt[d] then nextAt[d] = now + TRN.RandomIn(d.firstDelaySec) end
    if now >= nextAt[d] and countActive(d) < d.maxActive then
      spawnConvoy(d)
      nextAt[d] = now + TRN.RandomIn(d.intervalSec)
    end
  end
end

function TRN.Ambient_InitConvoys()
  if not (A.convoys and #A.convoys > 0) then return false end
  TRN.Every(20, tick, 20)
  TRN.Log("Ambient: convoy manager started (%d definitions)", #A.convoys)
  return true
end

-- ----------------------------------------------------------------------
-- Info und Menue
-- ----------------------------------------------------------------------
function def.info()
  return "CONVOYS AND TRAFFIC\nAI transports fly between the airfields. Friendly supply convoys drive on the roads.\n" ..
    "Hostile convoys appear now and then as targets of opportunity; a short INTEL message gives the position.\n" ..
    "Use 'Report hostile convoys' for the current position."
end

def.extras = {
  { text = "Report hostile convoys", fn = function(groupName)
      local lines = {}
      for _, c in ipairs(active) do
        if c.def.side == "RED" then
          local units = TRN.GroupAliveUnits(c.group)
          if units[1] then
            lines[#lines + 1] = string.format("Hostile convoy, %d vehicles, MGRS %s, heading to MGRS %s.", #units,
              TRN.MGRS(units[1]:getPoint(), 4), TRN.MGRS(c.dest, 3))
          end
        end
      end
      if #lines == 0 then lines[1] = "No hostile convoys reported at this time." end
      TRN.Audio.Text(groupName, "INTEL:\n" .. table.concat(lines, "\n"))
    end },
}

TRN.RegisterZone(def)
