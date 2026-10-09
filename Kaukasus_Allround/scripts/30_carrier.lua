-- =====================================================================
-- Kaukasus Allround Training - 30_carrier.lua
-- Carrier operations on a Supercarrier (CVN-71..75).
-- Moose: AIRBOSS (LSO grading, Marshal, F10 recovery request),
--        RECOVERYTANKER (S-3B), RESCUEHELO.
-- Voice via "Airboss Soundfiles/" inside the .miz (no SRS).
-- =====================================================================

KA = KA or {}
KA.Carrier = {}

function KA.Carrier.Init()
  local C = KA.CFG.carrier
  local carrier = KA.Need("unit", C.unit, "Carrier")
  if not carrier then return false end

  local boss = AIRBOSS:New(C.unit, C.alias)
  boss:SetSoundfilesFolder(C.soundFolder)
  boss:SetTACAN(C.tacan.channel, C.tacan.mode, C.tacan.morse)
  boss:SetICLS(C.icls.channel, C.icls.morse)
  boss:SetLSORadio(C.lsoFreq)
  boss:SetMarshalRadio(C.marshalFreq)
  -- Players open a recovery window from F10 (carrier turns into the wind).
  boss:SetMenuRecovery(C.recoveryMin, C.windOnDeck, true, 30)
  boss:SetDespawnOnEngineShutdown(true)
  boss:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)

  if KA.Need("group", C.tanker.template, "Carrier recovery tanker") then
    local tanker = RECOVERYTANKER:New(C.unit, C.tanker.template)
    tanker:SetTACAN(C.tanker.tacan, C.tanker.morse)
    tanker:SetRadio(C.tanker.freq)
    tanker:SetTakeoffAir()
    tanker:SetRespawnOn()
    tanker:Start()
    boss:SetRecoveryTanker(tanker)
    KA.Carrier.tanker = tanker
  end

  if KA.Need("group", C.rescueHelo.template, "Carrier rescue helo") then
    local helo = RESCUEHELO:New(C.unit, C.rescueHelo.template)
    helo:SetTakeoffAir()
    helo:SetRespawnOn()
    helo:Start()
    KA.Carrier.helo = helo
  end

  boss:Start()
  KA.Carrier.boss = boss

  KA.Players.OnJoin(function(unitName, _, playerName, replayed)
    if replayed then KA.Players.ReplayBirth(boss, unitName, playerName) end
  end)
  return true
end
