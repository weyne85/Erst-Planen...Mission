-- 50_jtac.lua
-- Zone 5: JTAC gegen bewegliche Bodenziele.
-- Ablauf (per F10-Menue): Start -> Check in -> Request 9-line -> In hot (JTAC lasert + Rauch) -> BDA -> neue Aufgabe.
-- Das Lasern uebernimmt der JTAC-Automat aus CTLD (ctld.JTACStart). Die Ziele fahren auf Strassen von
-- TRN_JTAC_START nach TRN_JTAC_END.

TRN = TRN or {}
local CFG = TRN.CFG
local C = CFG.JTAC

local function say(groupName, text, cue)
  TRN.Audio.Text(groupName, text, cue)
end

local function needSession(groupName)
  local z = TRN.Zones[C.id]
  local s = z and z.session
  if not s or s.group ~= groupName then
    say(groupName, "Start the JTAC exercise first: F10 > Training Zones > " .. C.title .. " > Start ...")
    return nil
  end
  if s.state ~= "RUN" then
    say(groupName, "Standby for next tasking.")
    return nil
  end
  return s
end

local function targetInfo(s)
  local units = TRN.GroupAliveUnits(s.data.target)
  local u = units[1]
  if not u then return nil end
  local vel = u:getVelocity()
  local speedKmh = math.sqrt(vel.x * vel.x + vel.z * vel.z) * 3.6
  local heading = 0
  if speedKmh > 1 then
    heading = (math.floor(math.deg(math.atan2(vel.z, vel.x)) + (CFG.MAG_VAR or 0) + 0.5)) % 360
  end
  return { unit = u, count = #units, point = u:getPoint(), speedKmh = speedKmh, heading = heading, type = u:getTypeName() }
end

local function nineLine(s)
  local t = targetInfo(s)
  if not t then return nil end
  local jt = Unit.getByName(s.data.jtacUnit)
  local jp = (jt and jt:isExist()) and jt:getPoint() or t.point
  local ipInfo = TRN.ZoneInfo(C.ipZone) or TRN.ZoneInfo(C.startZone)
  local ip = ipInfo.point
  local elevFt = TRN.ToFt(land.getHeight({ x = t.point.x, y = t.point.z }))

  local lines = {
    string.format("%s 9-LINE (round %d)", C.callsign, s.rounds),
    string.format("1. IP: MGRS %s", TRN.MGRS(ip, 3)),
    string.format("2. Heading IP to target: %03d", TRN.Bearing(ip, t.point)),
    string.format("3. Distance IP to target: %.1f nm", TRN.ToNm(TRN.Dist2D(ip, t.point))),
    string.format("4. Target elevation: %d ft", math.floor(elevFt + 0.5)),
    string.format("5. Target: %d x %s and vehicles, moving heading %03d at %d km/h", t.count, t.type, t.heading, math.floor(t.speedKmh + 0.5)),
    string.format("6. Location: MGRS %s (moving - updated when you are in hot)", TRN.MGRS(t.point, 4)),
    string.format("7. Mark: laser code %d, smoke", C.laserCode),
    string.format("8. Friendlies: JTAC at MGRS %s, bearing %03d, %.1f nm from target", TRN.MGRS(jp, 3), TRN.Bearing(t.point, jp), TRN.ToNm(TRN.Dist2D(t.point, jp))),
    string.format("9. Egress: towards IP, heading %03d", TRN.Bearing(t.point, ip)),
    "Remarks: type 2 control, no danger close." .. (s.level == "HARD" and " Short-range air defence possible." or ""),
  }
  return table.concat(lines, "\n")
end

local function checkIn(groupName)
  local s = needSession(groupName)
  if not s then return end
  if s.data.step >= 1 then say(groupName, C.callsign .. ": You are already checked in.") return end
  s.data.step = 1
  s:Say("jtac_checkin", C.callsign .. " has you loud and clear.")
end

local function request9Line(groupName)
  local s = needSession(groupName)
  if not s then return end
  if s.data.step < 1 then s:Say("jtac_negative") return end
  local text = nineLine(s)
  if not text then say(groupName, C.callsign .. ": No target visible right now.") return end
  s.data.step = math.max(s.data.step, 2)
  TRN.Audio.Text(groupName, text, "jtac_nineline")
end

local function inHot(groupName)
  local s = needSession(groupName)
  if not s then return end
  if s.data.step < 2 then s:Say("jtac_negative") return end
  local t = targetInfo(s)
  if not t then return end
  if s.data.step < 3 then
    s.data.step = 3
    local ok, err = pcall(ctld.JTACStart, s.data.jtac, C.laserCode, true, "vehicle")
    if not ok then TRN.Error("ctld.JTACStart failed: %s", tostring(err)) end
  end
  s:Say("jtac_hot", string.format("Laser code %d. Target now MGRS %s, heading %03d, %d km/h.", C.laserCode,
    TRN.MGRS(t.point, 4), t.heading, math.floor(t.speedKmh + 0.5)))
end

local function requestBda(groupName)
  local s = needSession(groupName)
  if not s then return end
  local t = targetInfo(s)
  if not t then return end
  say(groupName, string.format("%s: %d vehicle(s) still alive, last seen MGRS %s.", C.callsign, t.count, TRN.MGRS(t.point, 4)))
end

local def = {
  id = C.id, title = C.title, cfg = C,
  extras = {
    { text = "1 Check in",       fn = checkIn },
    { text = "2 Request 9-line", fn = request9Line },
    { text = "3 In hot",         fn = inHot },
    { text = "4 Request BDA",    fn = requestBda },
  },
}

function def.info()
  local z = TRN.ZoneInfo(C.jtacZone)
  return string.format(
    "JTAC - MOVING TARGETS\nCallsign: %s. JTAC position (MGRS): %s.\nLaser code %d, target marked with smoke.\n" ..
    "Sequence: 1 Check in > 2 Request 9-line > 3 In hot > 4 BDA. Targets drive along roads.\n" ..
    "EASY: slow single vehicle group. MEDIUM: faster, mixed. HARD: fast convoy with escort.",
    C.callsign, z and TRN.MGRS(z.point, 3) or "n/a", C.laserCode)
end

function def.OnRound(s)
  local lv = C.levels[s.level]
  if not lv then return false, "Unknown difficulty " .. tostring(s.level) end
  if not TRN.ZoneInfo(C.endZone) then return false, "Trigger zone '" .. C.endZone .. "' is missing" end

  local jvec = TRN.RandomPointInZone(C.jtacZone)
  local svec = TRN.RandomPointInZone(C.startZone)
  local evec = TRN.RandomPointInZone(C.endZone)
  if not (jvec and svec and evec) then return false, "JTAC trigger zones missing (" .. C.jtacZone .. ", " .. C.startZone .. ", " .. C.endZone .. ")" end

  local jtac, err = TRN.Spawn(C.jtacTemplate, jvec)
  if not jtac then return false, err end
  s:Track(jtac)
  s.data.jtac = jtac
  local ju = TRN.GroupAliveUnits(jtac)[1]
  s.data.jtacUnit = ju and ju:getName() or nil

  local target, err2 = TRN.Spawn(TRN.Pick(lv.pool), svec)
  if not target then return false, err2 end
  s:Track(target)
  s.data.target = target

  local dest = COORDINATE:NewFromVec2(evec)
  GROUP:FindByName(target):RouteGroundOnRoad(dest, lv.speedKmh, 1)

  for _, tpl in ipairs(lv.escorts or {}) do
    local esc = TRN.Spawn(tpl, svec)
    if esc then
      s:Track(esc)
      GROUP:FindByName(esc):RouteGroundOnRoad(dest, lv.speedKmh, 1)
    end
  end

  s.data.step = 0
  TRN.Audio.Text(s.group, string.format("%s: Tasking received (round %d). Check in when ready.\nF10 > Training Zones > %s.", C.callsign, s.rounds, C.title))
  return true
end

function def.OnTick(s)
  -- JTAC verloren?
  if #TRN.GroupAliveUnits(s.data.jtac) == 0 then
    TRN.Audio.Text(s.group, C.callsign .. " is down. Exercise resets shortly.")
    return "done"
  end
  -- Ziel zerstoert?
  if #TRN.GroupAliveUnits(s.data.target) == 0 then
    s:Say("jtac_bda", string.format("Round %d finished in %d min %02d s.", s.rounds,
      math.floor(s:Elapsed() / 60), math.floor(s:Elapsed() % 60)))
    return "done"
  end
end

function def.OnStop(s)
  if s.data and s.data.jtac and ctld and ctld.cleanupJTAC then
    pcall(ctld.cleanupJTAC, s.data.jtac)
  end
end

TRN.RegisterZone(def)
