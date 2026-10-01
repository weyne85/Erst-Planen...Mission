-- 10_ground_attack.lua
-- Zone 1: Bodenangriff. Zwei Teile:
--   a) Moose RANGE: feste Bomben-Ziele und Strafing-Pit mit Range-Control-Stimme und Bewertung
--      (Sounds aus dem Moose-Paket "Range Soundfiles"; eigenes F10-Menue "On the Range").
--   b) Dynamische Bodenziele in TRN_GA_ZONE (Text-Ansagen), nach Zerstoerung startet eine neue Runde.

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
  local R = C.range
  local rangeText = ""
  if R and R.enabled then
    local rz = TRN.ZoneInfo(R.zone)
    rangeText = string.format("\nRANGE (bombing and strafing, scored): MGRS %s, Range Control %.1f MHz, instructor %.1f MHz. " ..
      "Use F10 > On the Range.", rz and TRN.MGRS(rz.point, 3) or "n/a", R.rangeControlMHz, R.instructorMHz)
  end
  return string.format(
    "GROUND ATTACK\nDynamic targets area (MGRS): %s, radius %.1f nm.\nTargets: soft vehicles and armour.\n" ..
    "MEDIUM: more targets. HARD: adds AAA and short-range air defence.\nA new round starts automatically.%s",
    TRN.MGRS(z.point, 3), TRN.ToNm(z.radius), rangeText)
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

-- Moose RANGE (Wird von 99_init.lua aufgerufen)
TRN.Range = nil

function TRN.Range_Init()
  local R = C.range
  if not (R and R.enabled) then return false end
  local ok, err = pcall(function()
    local range = RANGE:New(R.name)
    range:SetSoundfilesPath(CFG.RANGE_SOUND_FOLDER)
    if TRN.ZoneInfo(R.zone) then range:SetRangeZone(R.zone) end
    range:SetRangeControl(R.rangeControlMHz)
    range:SetInstructorRadio(R.instructorMHz)
    range:AddBombingTargets(R.bombTargets, R.goodHitM)
    for _, pit in ipairs(R.strafePits) do
      range:AddStrafePit(pit.targets, pit.boxLength, pit.boxWidth, nil, false, pit.goodPass, pit.foulLine)
    end
    range:Start()
    TRN.Range = range

    -- RANGE legt sein F10-Menue nur beim Birth-Ereignis an (siehe 03_menu.lua): fuer Spieler, die schon
    -- im Flugzeug sitzen, nachtraeglich. _AddF10Commands ist pro Gruppe einmalig.
    TRN.Menu.OnNewPlayer(function(groupName, dcsUnit)
      if TRN.Range then TRN.Range:_AddF10Commands(dcsUnit:getName()) end
    end)
  end)
  if not ok then
    TRN.Error("Range setup failed: %s", tostring(err))
    return false
  end
  TRN.Log("Range '%s' started (%d bombing targets, %d strafe pits)", R.name, #R.bombTargets, #R.strafePits)
  return true
end

TRN.RegisterZone(def)
