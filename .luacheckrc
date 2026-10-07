-- luacheck-Konfiguration fuer die Mission (nur eigene Skripte, nicht libs/)
std = "lua51"
max_line_length = false
files["scripts"] = {}
globals = { "TRN", "ctld" }                -- TRN: eigener Namespace; ctld: Tabellen werden in 60_ctld.lua ueberschrieben
read_globals = {
  -- DCS Scripting Engine
  "env", "coord", "trigger", "timer", "world", "coalition", "land", "atmosphere", "missionCommands",
  "Group", "Unit", "Weapon", "StaticObject", "Airbase", "Object", "country", "AI", "Controller",
  -- MIST / CTLD
  "mist",
  -- Moose
  "BASE", "UTILS", "SPAWN", "ZONE", "ZONE_RADIUS", "GROUP", "UNIT", "COORDINATE", "SET_CLIENT", "SCHEDULER",
  "MENU_GROUP", "MENU_GROUP_COMMAND", "AIRBOSS", "RANGE", "CSAR", "RAT", "EVENT",
}
-- 'self' ungenutzt in Callbacks ist normal
ignore = { "212/self", "212/_.*" }
