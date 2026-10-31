-- =====================================================================
-- Kaukasus Allround Training - 99_init.lua
-- Must be the last script. Checks dependencies, starts every part in a
-- protected call and shows a start report (missing mission editor
-- objects are listed in dcs.log).
-- =====================================================================

KA = KA or {}

local MODULES = {
  { "Range",          "Range" },
  { "CAS",            "CAS" },
  { "SEAD",           "SEAD" },
  { "Strike",         "Strike" },
  { "AntiShip",       "Anti-ship" },
  { "BFM",            "BFM" },
  { "Fox",            "FOX" },
  { "Carrier",        "Carrier" },
  { "Support",        "Tankers/AWACS" },
  { "Nav",            "ATIS/Navigation" },
  { "CTLD",           "CTLD" },
  { "CSAR",           "CSAR" },
  { "Campaign",       "Campaign" },
  { "Ambient",        "Ambient traffic" },
}

local function dependenciesOk()
  local needed = { "BASE", "SPAWN", "CLIENTMENUMANAGER", "CLIENTWATCH", "RANGE", "AIRBOSS", "CHIEF", "CTLD", "CSAR", "FOX" }
  local missing = {}
  for _, name in ipairs(needed) do
    if _G[name] == nil then missing[#missing + 1] = name end
  end
  if #missing > 0 then
    env.error("[KA] Moose not loaded or too old, missing: " .. table.concat(missing, ", "))
    trigger.action.outText("Kaukasus Allround: Moose is not loaded (see dcs.log). Load libs/Moose_.lua first.", 60)
    return false
  end
  return true
end

local function start()
  -- os is not available and math.randomseed may be nil in the DCS sandbox.
  if math.randomseed then
    pcall(math.randomseed, timer.getTime() * 1000 + timer.getAbsTime())
    for _ = 1, 3 do math.random() end
  end

  KA.Players.Start()

  local ok, failed = {}, {}
  for _, m in ipairs(MODULES) do
    local mod = KA[m[1]]
    if mod and mod.Init then
      local success, result = KA.Try(m[2] .. " init", mod.Init)
      if success and result ~= false then ok[#ok + 1] = m[2] else failed[#failed + 1] = m[2] end
    else
      failed[#failed + 1] = m[2] .. " (script not loaded)"
    end
  end

  KA.Menu.Start()

  local report = string.format("Kaukasus Allround Training %s ready.\nRunning: %s", KA.CFG.version, table.concat(ok, ", "))
  if #failed > 0 then report = report .. "\nNOT running: " .. table.concat(failed, ", ") end
  if #KA.Missing > 0 then
    report = report .. string.format("\n%d mission editor objects are missing, see dcs.log ([KA] Missing ...).", #KA.Missing)
    for _, m in ipairs(KA.Missing) do KA.Warn("Missing: %s", m) end
  end
  report = report .. "\nF10 > Training for all exercises."
  KA.Log("%s", report)
  TIMER:New(function() KA.MsgAll(report, 30) end):Start(10)
end

if dependenciesOk() then
  local okStart, err = pcall(start)
  if not okStart then
    env.error("[KA] Start failed: " .. tostring(err))
    trigger.action.outText("Kaukasus Allround: start failed, see dcs.log.", 60)
  end
end
