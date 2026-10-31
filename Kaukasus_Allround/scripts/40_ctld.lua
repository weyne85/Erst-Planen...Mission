-- =====================================================================
-- Kaukasus Allround Training - 40_ctld.lua
-- Helicopter logistics with Moose Ops.CTLD (no MiST, no ciribob CTLD).
-- Only BLUE helicopter groups whose name starts with KA.CFG.blueHeliPrefix
-- get the CTLD menu (CH-47F, Mi-24P; AH-64D can carry 2 troops).
-- Coupling with the campaign: the front zones are CTLD MOVE zones, so
-- dropped troops walk into the nearest front zone and help capture it.
-- =====================================================================

KA = KA or {}
KA.CTLD = {}

function KA.CTLD.Init()
  local C = KA.CFG.ctld
  local ctld = CTLD:New(coalition.side.BLUE, { KA.CFG.blueHeliPrefix }, C.alias)
  ctld.useprefix = true
  ctld.locale = "en"
  ctld.dropcratesanywhere = true       -- build anywhere outside LOAD zones
  ctld.nobuildinloadzones = true
  ctld.enableslingload = true
  ctld.onestepmenu = true              -- recommended for the CH-47F
  ctld.enableChinookGCLoading = true
  ctld.CrateDistance = 65
  ctld.PackDistance = 65
  ctld.buildtime = 120
  ctld.movetroopstowpzone = true
  ctld.movetroopsdistance = 8000
  ctld.RadioSound = C.beaconSound
  ctld.RadioSoundFC3 = C.beaconSound

  for _, t in ipairs(C.troops) do
    if KA.Need("group", t.template, "CTLD troops") then
      ctld:AddTroopsCargo(t.name, { t.template }, t.engineers and CTLD_CARGO.Enum.ENGINEERS or CTLD_CARGO.Enum.TROOPS, t.size)
    end
  end
  for _, c in ipairs(C.crates) do
    if KA.Need("group", c.template, "CTLD crates") then
      ctld:AddCratesCargo(c.name, { c.template }, c.fob and CTLD_CARGO.Enum.FOB or CTLD_CARGO.Enum.VEHICLE, c.crates, c.mass)
    end
  end

  local nload = 0
  for _, z in ipairs(C.loadZones) do
    if KA.Need("zone", z, "CTLD load zone") then
      ctld:AddCTLDZone(z, CTLD.CargoZoneType.LOAD, SMOKECOLOR.Blue, true, true)
      nload = nload + 1
    end
  end
  for _, fz in ipairs(KA.CFG.campaign.zones) do
    if ZONE:FindByName(fz.name) then
      ctld:AddCTLDZone(fz.name, CTLD.CargoZoneType.MOVE, SMOKECOLOR.Orange, true, false)
    end
  end
  if nload == 0 then return false end

  -- Troops is the deployed GROUP, Unit the helicopter.
  function ctld:OnAfterTroopsDeployed(_, _, _, _, unit, troops)
    if not (troops and troops:IsAlive()) then return end
    local pilot = unit and unit:GetPlayerName() or "AI"
    local name = troops:GetName():gsub("#.*", "")
    KA.Log("CTLD: %s deployed %s", tostring(pilot), name)
    KA.MsgBlue(string.format("%s deployed %s at %s.", pilot, name, troops:GetCoordinate():ToStringMGRS()), 15)
  end

  ctld:__Start(5)
  KA.CTLD.obj = ctld
  return true
end
