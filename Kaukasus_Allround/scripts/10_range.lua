-- =====================================================================
-- Kaukasus Allround Training - 10_range.lua
-- Bombing and strafing range (Moose Functional.Range), open for all.
-- Voice via "Range Soundfiles/" inside the .miz (no SRS).
-- =====================================================================

KA = KA or {}
KA.Range = {}

function KA.Range.Init()
  local C = KA.CFG.range
  local zone = KA.Need("zone", C.zone, "Range")
  local bombs = {}
  for _, n in ipairs(C.bombTargets) do
    if KA.Need("target", n, "Range bomb target") then
      bombs[#bombs + 1] = n
    end
  end
  local pits = {}
  for _, pit in ipairs(C.strafePits) do
    if KA.NeedAll("target", pit, "Range strafe pit") then pits[#pits + 1] = pit end
  end
  if #bombs == 0 and #pits == 0 then return false end

  local range = RANGE:New(C.name, coalition.side.BLUE)
  if zone then range:SetRangeZone(zone) end
  if #bombs > 0 then range:AddBombingTargets(bombs, C.goodHit, false) end
  for _, pit in ipairs(pits) do
    range:AddStrafePit(pit, C.strafeBoxLength, C.strafeBoxWidth, nil, false, C.strafeGoodPass, C.strafeFoulLine)
  end
  range:SetSoundfilesPath(C.soundPath)
  range:SetRangeControl(C.controlFreq)
  range:SetInstructorRadio(C.instructorFreq)
  range:SetDefaultPlayerSmokeBomb(true)
  range:Start()
  KA.Range.obj = range

  KA.Players.OnJoin(function(unitName, _, playerName, replayed)
    if replayed then KA.Players.ReplayBirth(range, unitName, playerName) end
  end)

  KA.Menu.Add({ "Info" }, "Range", function(group)
    local coord = zone and KA.ZoneCoord(zone) or nil
    local from = group:GetCoordinate()
    KA.MsgGroup(group, string.format("%s\n%s\nRange control %.3f AM, instructor %.3f AM.\nUse F10 > On the Range for results.",
      C.name, (coord and from) and KA.BRText(from, coord) or "", C.controlFreq, C.instructorFreq), 30)
  end)
  return true
end
