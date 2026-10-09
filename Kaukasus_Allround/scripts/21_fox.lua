-- =====================================================================
-- Kaukasus Allround Training - 21_fox.lua
-- Missile trainer (Moose Functional.Fox): missiles aimed at players are
-- destroyed shortly before impact. No safe zones = active everywhere.
-- Every player can switch it off for himself: F10 > FOX.
-- =====================================================================

KA = KA or {}
KA.Fox = {}

function KA.Fox.Init()
  local C = KA.CFG.fox
  local fox = FOX:New()
  fox:SetDefaultMissileDestruction(C.destroyMissiles)
  fox:SetDefaultLaunchAlerts(C.launchAlerts)
  fox:SetDefaultLaunchMarks(C.launchMarks)
  fox:SetEnableF10Menu()
  fox:Start()
  KA.Fox.obj = fox

  KA.Players.OnJoin(function(unitName, _, playerName, replayed)
    if replayed then KA.Players.ReplayBirth(fox, unitName, playerName) end
  end)
  return true
end
