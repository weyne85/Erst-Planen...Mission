-- 20_carrier.lua
-- Zone 2: Carrier-Landung. Der Traeger wird vom Moose-AIRBOSS gefuehrt (Marshal, Case I/II/III, LSO, Grading).
-- Sprache und Menue (F10 > Airboss) kommen vom Airboss. Dieses Skript konfiguriert ihn und plant
-- automatische Recovery-Fenster ein (Traeger dreht dann in den Wind).

TRN = TRN or {}
local CFG = TRN.CFG
local C = CFG.CARRIER

local def = { id = C.id, title = C.title, cfg = C, startable = false }

TRN.Airboss = nil

function def.info()
  local z = Unit.getByName(C.unit)
  local pos = "n/a"
  if z and z:isExist() then pos = TRN.MGRS(z:getPoint(), 3) end
  return string.format(
    "CARRIER RECOVERY\nCarrier (%s) position (MGRS): %s\nTACAN %d%s %s | ICLS %d %s\nMarshal %.3f AM | LSO %.3f AM\n" ..
    "Use F10 > Airboss to request Marshal, recovery or to check your grades.",
    C.alias, pos, C.tacan.channel, C.tacan.mode, C.tacan.morse, C.icls.channel, C.icls.morse,
    C.marshalRadio, C.lsoRadio)
end

-- Wird von 99_init.lua aufgerufen
function TRN.Carrier_Init()
  local unit = Unit.getByName(C.unit)
  if not unit then
    TRN.Error("Carrier unit '%s' not found - carrier zone disabled", C.unit)
    return false
  end

  local ok, err = pcall(function()
    local ab = AIRBOSS:New(C.unit, C.alias)
    ab:SetTACAN(C.tacan.channel, C.tacan.mode, C.tacan.morse)
    ab:SetICLS(C.icls.channel, C.icls.morse)
    ab:SetMarshalRadio(C.marshalRadio, "AM")
    ab:SetLSORadio(C.lsoRadio, "AM")
    ab:SetSoundfilesFolder(CFG.AIRBOSS_SOUND_FOLDER)
    ab:SetCarrierControlledArea(C.controlledAreaNm)
    ab:SetMenuSingleCarrier(true)
    ab:SetMenuRecovery(C.menuRecovery.minutes, C.menuRecovery.windOnDeck, C.menuRecovery.uturn)
    ab:Start()
    TRN.Airboss = ab
  end)
  if not ok then
    TRN.Error("Airboss setup failed: %s", tostring(err))
    return false
  end

  -- Automatische Recovery-Fenster (dynamisch: Traeger dreht in den Wind, Case wechselt)
  local auto = C.autoRecovery
  if auto and auto.enabled then
    local cycle = (auto.lengthMin + auto.pauseMin) * 60
    TRN.Every(cycle, function()
      local case = TRN.Pick(auto.cases) or 1
      TRN.Airboss:AddRecoveryWindow(60, 60 + auto.lengthMin * 60, case, nil, true, C.menuRecovery.windOnDeck, C.menuRecovery.uturn)
      TRN.Log("Carrier: auto recovery window, case %d, %d min", case, auto.lengthMin)
    end, auto.firstDelayMin * 60)
  end

  TRN.Log("Airboss started on %s", C.unit)
  return true
end

TRN.RegisterZone(def)
