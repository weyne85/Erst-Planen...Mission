-- =====================================================================
-- Kaukasus Allround Training - 31_tanker_awacs.lua
-- Air-to-air refueling (boom and drogue) and an AI AWACS (no voice).
-- Moose: AIRWING (warehouse at Kutaisi), SQUADRON, AUFTRAG (TANKER, AWACS)
--        with fixed TACAN/radio and repeat, FLIGHTGROUP (created by the wing).
-- =====================================================================

KA = KA or {}
KA.Support = {}

local function refuelSystem(system)
  if system == "boom" then return Unit.RefuelingSystem.BOOM_AND_RECEPTACLE end
  return Unit.RefuelingSystem.PROBE_AND_DROGUE
end

local function addSquadron(wing, entry, missionType)
  local sq = SQUADRON:New(entry.template, 2, "BLUE " .. entry.name)
  sq:AddMissionCapability({ missionType }, 100)
  sq:SetRadio(entry.freq)
  sq:SetTakeoffAir()
  wing:AddSquadron(sq)
  wing:NewPayload(entry.template, -1, { missionType }, 100)
end

function KA.Support.Init()
  local C = KA.CFG.support
  if not KA.Need("static", C.warehouse, "Support airwing") then return false end

  local wing = AIRWING:New(C.warehouse, C.name)
  KA.Support.lines = {}

  for _, t in ipairs(C.tankers) do
    local zone = KA.Need("zone", t.zone, "Tanker " .. t.name)
    if KA.Need("group", t.template, "Tanker " .. t.name) and zone then
      addSquadron(wing, t, AUFTRAG.Type.TANKER)
      local m = AUFTRAG:NewTANKER(KA.ZoneCoord(zone), t.altFt, t.speedKts, t.heading, t.legNm, refuelSystem(t.system))
      m:SetName("Tanker " .. t.name)
      m:SetTACAN(t.tacan, t.morse, nil, t.band)
      m:SetRadio(t.freq)
      m:SetRepeat(C.repeats)
      wing:AddMission(m)
      table.insert(KA.Support.lines, { name = t.name, zone = zone, text = string.format(
        "%s (%s): TACAN %d%s %s, %.3f AM, FL%03d, %d kts", t.name, t.system == "boom" and "boom" or "drogue",
        t.tacan, t.band, t.morse, t.freq, math.floor(t.altFt / 100), t.speedKts) })
    end
  end

  local a = C.awacs
  local azone = KA.Need("zone", a.zone, "AWACS")
  if KA.Need("group", a.template, "AWACS") and azone then
    addSquadron(wing, a, AUFTRAG.Type.AWACS)
    local m = AUFTRAG:NewAWACS(KA.ZoneCoord(azone), a.altFt, a.speedKts, a.heading, a.legNm)
    m:SetName("AWACS " .. a.name)
    m:SetRadio(a.freq)
    m:SetRepeat(C.repeats)
    wing:AddMission(m)
    table.insert(KA.Support.lines, { name = a.name, zone = azone, text = string.format(
      "AWACS %s: %.3f AM (datalink picture only, no voice)", a.name, a.freq) })
  end

  wing:Start()
  KA.Support.wing = wing

  KA.Menu.Add({ "Info" }, "Tankers and AWACS", function(group)
    local from = group:GetCoordinate()
    local out = {}
    for _, l in ipairs(KA.Support.lines) do
      out[#out + 1] = l.text .. (from and ("\n   track " .. KA.BRText(from, KA.ZoneCoord(l.zone))) or "")
    end
    KA.MsgGroup(group, #out > 0 and table.concat(out, "\n") or "No tankers configured.", 30)
  end)
  return true
end
