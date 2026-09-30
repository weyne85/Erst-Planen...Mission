-- 40_intercept.lua
-- Zone 4: Air Intercept. Gegnerische Luftziele starten in zufaelliger Richtung auf einem Ring um TRN_INT_ZONE
-- und fliegen die im Template (Late Activation) hinterlegte Route. AWACS gibt regelmaessig "Bogey Dope"
-- (BRAA relativ zum Spieler). Nach dem Abschuss aller Ziele startet eine neue Welle.

TRN = TRN or {}
local CFG = TRN.CFG
local C = CFG.INT

local def = { id = C.id, title = C.title, cfg = C }

function def.info()
  local z = TRN.ZoneInfo(C.zone)
  if not z then return "Zone '" .. C.zone .. "' is missing in the mission." end
  return string.format(
    "AIR INTERCEPT\nAWACS: %s. Area centre (MGRS): %s.\nHostiles start about %d km from the centre.\n" ..
    "EASY: single fighter. MEDIUM: modern fighters. HARD: two groups plus a bomber.\n" ..
    "Bearings are %s. A new wave starts after each intercept.",
    C.awacsCallsign, TRN.MGRS(z.point, 3), C.spawnRingKm, (CFG.MAG_VAR == 0) and "true" or "corrected by MAG_VAR")
end

local function spawnBandit(s, template, center)
  local ring = C.spawnRingKm * 1000
  local vec2 = mist.getRandPointInCircle(center, ring, ring * 0.85)
  local name, err = TRN.Spawn(template, vec2, C.spawnAltM[1], C.spawnAltM[2])
  if not name then return nil, err end
  s:Track(name)
  s.data.bandits[#s.data.bandits + 1] = name
  return name
end

function def.OnRound(s)
  local lv = C.levels[s.level]
  if not lv then return false, "Unknown difficulty " .. tostring(s.level) end
  local z = TRN.ZoneInfo(C.zone)
  if not z then return false, "Trigger zone '" .. C.zone .. "' is missing" end

  s.data.bandits = {}
  s.data.dead = {}
  s.data.lastCall = 0

  for i = 1, lv.groups do
    local _, err = spawnBandit(s, TRN.Pick(lv.pool), z.point)
    if err then return false, err end
  end
  for _, tpl in ipairs(lv.extra or {}) do
    local _, err = spawnBandit(s, tpl, z.point)
    if err then return false, err end
  end

  s:Say("int_briefing", (s.rounds > 1 and ("Wave " .. s.rounds .. ". ") or "") ..
    string.format("%s has %d hostile group(s) inbound.", C.awacsCallsign, #s.data.bandits))
  return true
end

-- Naechster lebender Gegner relativ zum Spieler -> BRAA-Text
local function braa(s)
  local player = TRN.PlayerUnit(s.group)
  if not player then return nil end
  local pp = player:getPoint()

  local best, bestDist, contacts = nil, math.huge, 0
  for _, name in ipairs(s.data.bandits) do
    for _, u in ipairs(TRN.GroupAliveUnits(name)) do
      contacts = contacts + 1
      local d = TRN.Dist2D(pp, u:getPoint())
      if d < bestDist then best, bestDist = u, d end
    end
  end
  if not best then return nil end

  local bp = best:getPoint()
  local vel = best:getVelocity()
  local toPlayer = { x = pp.x - bp.x, z = pp.z - bp.z }
  local closing = (vel.x * toPlayer.x + vel.z * toPlayer.z) > 0
  return string.format("%s, bandit BRAA %03d, %d, %d thousand, %s, %d contact%s.",
    C.awacsCallsign, TRN.Bearing(pp, bp), math.floor(TRN.ToNm(bestDist) + 0.5),
    math.floor(TRN.ToFt(bp.y) / 1000 + 0.5), closing and "hot" or "cold", contacts, contacts == 1 and "" or "s")
end

function def.OnTick(s)
  local alive = 0
  for _, name in ipairs(s.data.bandits) do
    if #TRN.GroupAliveUnits(name) == 0 then
      if not s.data.dead[name] then
        s.data.dead[name] = true
        local left = 0
        for _, n in ipairs(s.data.bandits) do
          if not s.data.dead[n] then left = left + 1 end
        end
        if left > 0 then s:Say("int_splash", "Groups remaining: " .. left .. ".") end
      end
    else
      alive = alive + 1
    end
  end

  if alive == 0 then
    s:Say("int_complete", string.format("Wave %d cleared in %d min %02d s.", s.rounds,
      math.floor(s:Elapsed() / 60), math.floor(s:Elapsed() % 60)))
    return "done"
  end

  local now = timer.getTime()
  if now - s.data.lastCall >= C.awacsInterval then
    local text = braa(s)
    if text then
      s.data.lastCall = now
      TRN.Audio.Text(s.group, text, "int_bogey")
    end
  end
end

TRN.RegisterZone(def)
