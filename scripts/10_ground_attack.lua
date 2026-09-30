-- 10_ground_attack.lua
-- Zone 1: Bodenangriff. Zufaellige Bodenziele in TRN_GA_ZONE, Trefferauswertung per Ansage,
-- nach Zerstoerung aller Ziele startet automatisch eine neue Runde.

TRN = TRN or {}
local CFG = TRN.CFG
local C = CFG.GA

local def = { id = C.id, title = C.title, cfg = C }

local function targetType(groupName)
  local units = TRN.GroupAliveUnits(groupName)
  if units[1] then return units[1]:getTypeName() end
  return "unknown"
end

function def.info()
  local z = TRN.ZoneInfo(C.zone)
  if not z then return "Zone '" .. C.zone .. "' is missing in the mission." end
  return string.format(
    "GROUND ATTACK\nTarget area (MGRS): %s\nRadius: %.1f nm\nTargets: soft vehicles and armour.\n" ..
    "MEDIUM: more targets. HARD: adds AAA and short-range air defence.\nA new round starts automatically.",
    TRN.MGRS(z.point, 3), TRN.ToNm(z.radius))
end

function def.OnRound(s)
  local lv = C.levels[s.level]
  if not lv then return false, "Unknown difficulty " .. tostring(s.level) end

  s.data.targets = {}
  s.data.dead = {}
  local lines = { "TARGETS:" }

  for i = 1, lv.count do
    local vec2 = TRN.RandomPointInZone(C.zone)
    if not vec2 then return false, "Trigger zone '" .. C.zone .. "' is missing" end
    local name, err = TRN.Spawn(TRN.Pick(lv.pool), vec2)
    if not name then return false, err end
    s:Track(name)
    s.data.targets[#s.data.targets + 1] = name
    lines[#lines + 1] = string.format("Target %d: %s, MGRS %s", i, targetType(name),
      TRN.MGRS({ x = vec2.x, y = 0, z = vec2.y }, 4))
  end

  for _, tpl in ipairs(lv.defenders or {}) do
    local vec2 = TRN.RandomPointInZone(C.zone)
    if vec2 then
      local name = TRN.Spawn(tpl, vec2)
      if name then s:Track(name) end   -- Verteidiger sind optional, kein Ziel
    end
  end

  s:Say("ga_briefing", (s.rounds > 1 and ("Round " .. s.rounds .. ". ") or "") .. table.concat(lines, "\n"))
  return true
end

function def.OnTick(s)
  local remaining = 0
  for _, name in ipairs(s.data.targets) do
    if #TRN.GroupAliveUnits(name) == 0 then
      if not s.data.dead[name] then
        s.data.dead[name] = true
        local left = 0
        for _, n in ipairs(s.data.targets) do
          if not s.data.dead[n] then left = left + 1 end
        end
        if left > 0 then s:Say("ga_hit", "Targets remaining: " .. left .. ".") end
      end
    else
      remaining = remaining + 1
    end
  end
  if remaining == 0 then
    s:Say("ga_complete", string.format("Round %d finished in %d min %02d s.", s.rounds, math.floor(s:Elapsed() / 60), math.floor(s:Elapsed() % 60)))
    return "done"
  end
end

TRN.RegisterZone(def)
