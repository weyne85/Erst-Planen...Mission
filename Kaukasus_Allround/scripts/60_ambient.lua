-- =====================================================================
-- Kaukasus Allround Training - 60_ambient.lua
-- Background traffic and airfield housekeeping.
-- Moose: RAT + RATMANAGER (AI traffic far from the front),
--        CLEANUP_AIRBASE (debris), ATC_GROUND_UNIVERSAL (taxi speed).
-- TIRESIAS is not used: in Moose 2.9.18 its type strings (" Vehicle")
-- never match the switch-on check ("Vehicle"), units would stay frozen.
-- =====================================================================

KA = KA or {}
KA.Ambient = {}

local function startRat()
  local R = KA.CFG.ambient.rat
  local manager = RATMANAGER:New(R.total)
  local n = 0
  for _, f in ipairs(R.flights) do
    if KA.Need("group", f.template, "RAT") then
      local rat = RAT:New(f.template, f.alias)
      rat:SetDeparture(f.airports)
      rat:SetDestination(f.airports)
      rat:SetTakeoffColdOrHot()
      rat:ContinueJourney()
      manager:Add(rat, f.min)
      n = n + 1
    end
  end
  if n > 0 then
    manager:Start(60)
    KA.Ambient.rat = manager
  end
  return n > 0
end

local function startAirfields()
  local A = KA.CFG.ambient
  local bases = {}
  for _, b in ipairs(A.cleanupAirbases) do
    if KA.Need("airbase", b, "Cleanup") then bases[#bases + 1] = b end
  end
  if #bases > 0 then KA.Ambient.cleanup = CLEANUP_AIRBASE:New(bases) end

  local G = A.atcGround
  local atcBases = {}
  for _, b in ipairs(G.airbases) do
    if KA.Need("airbase", b, "ATC ground") then atcBases[#atcBases + 1] = b end
  end
  if #atcBases > 0 then
    local atc = ATC_GROUND_UNIVERSAL:New(atcBases)
    atc:SetKickSpeed(UTILS.KnotsToMps(G.kickSpeedKts))
    atc:SetMaximumKickSpeed(UTILS.KnotsToMps(G.maxKickSpeedKts))
    atc:Start()
    KA.Ambient.atc = atc
  end
end

function KA.Ambient.Init()
  startAirfields()
  return startRat()
end
