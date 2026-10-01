-- 99_init.lua
-- Wird als LETZTES geladen: prueft die Abhaengigkeiten, initialisiert Range, Carrier und CTLD und startet das Menue.

TRN = TRN or {}
local CFG = TRN.CFG

local function fatal(msg)
  TRN.Error("%s", msg)
  trigger.action.outText("TRAINING MISSION: " .. msg, 30)
end

if not mist then
  fatal("MIST not loaded (load mist.lua first).")
elseif not (SPAWN and MENU_GROUP and AIRBOSS and RANGE and GROUP and COORDINATE) then
  fatal("Moose not loaded (load Moose.lua before the scripts).")
elseif not TRN.RegisterZone or not TRN.Audio or not TRN.Menu then
  fatal("Script order wrong: 00_config, 01_core, 02_audio, 03_menu, zones, 99_init.")
else
  -- Zufallsgenerator: In der DCS-Mission-Sandbox fehlen os und (je nach Version) math.randomseed.
  -- Deshalb nur wenn vorhanden seeden, sonst die Folge um eine zeitabhaengige Anzahl Werte weiterdrehen.
  if math.randomseed then
    math.randomseed(math.floor(timer.getTime() * 1000) + math.floor(timer.getAbsTime()))
  end
  for _ = 1, 5 + (math.floor(timer.getAbsTime()) % 89) do math.random() end

  local ok, err = pcall(TRN.Range_Init)
  if not ok then TRN.Error("Range init: %s", tostring(err)) end

  ok, err = pcall(TRN.Carrier_Init)
  if not ok then TRN.Error("Carrier init: %s", tostring(err)) end

  ok, err = pcall(TRN.Ctld_Init)
  if not ok then TRN.Error("CTLD init: %s", tostring(err)) end

  TRN.Menu.Start()
  TRN.Log("Training mission v%s ready (%d zones)", CFG.VERSION, #TRN.ZoneOrder)
end
