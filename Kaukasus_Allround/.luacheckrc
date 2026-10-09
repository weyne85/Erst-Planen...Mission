-- luacheck configuration for Kaukasus Allround (own scripts only, not libs/)
std = "lua51"
max_line_length = false
globals = { "KA" }
read_globals = {
  -- DCS scripting engine
  "env", "timer", "trigger", "world", "coalition", "land", "radio", "Unit", "Object", "country",
  -- Moose (2.9.18)
  "UTILS", "MESSAGE", "TIMER", "SPAWN", "GROUP", "UNIT", "STATIC", "ZONE", "AIRBASE", "COORDINATE",
  "SET_GROUP", "SET_CLIENT", "SET_STATIC", "CLIENTMENUMANAGER", "CLIENTWATCH", "SMOKECOLOR",
  "RANGE", "AUTOLASE", "SUPPRESSION", "ARMYGROUP", "NAVYGROUP", "FLIGHTGROUP", "AUFTRAG", "TARGET",
  "MANTIS", "SHORAD", "SEAD", "FOX", "AIRBOSS", "RECOVERYTANKER", "RESCUEHELO",
  "AIRWING", "SQUADRON", "BRIGADE", "PLATOON", "CHIEF", "OPSZONE", "PLAYERTASKCONTROLLER", "AMMOTRUCK",
  "ATIS", "BEACON", "CTLD", "CTLD_CARGO", "CSAR", "AICSAR", "RAT", "RATMANAGER", "CLEANUP_AIRBASE",
  "ATC_GROUND_UNIVERSAL",
}
-- unused 'self' and '_' arguments in callbacks are normal
ignore = { "212/self", "212/_.*" }
