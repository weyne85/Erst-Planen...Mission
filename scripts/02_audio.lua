-- 02_audio.lua
-- Einzige Stelle, die Sounds und Bildschirmmeldungen ausgibt.
-- Ansagen gehen nur an die betroffene Spielergruppe. Ueberlappende Ansagen an dieselbe Gruppe werden
-- nacheinander abgespielt. Fehlt eine Sounddatei, wird trotzdem der englische Text angezeigt.

TRN = TRN or {}
local CFG = TRN.CFG

TRN.Audio = {}
local nextFree = {}   -- Gruppenname -> Zeitpunkt, ab dem die naechste Ansage moeglich ist

local function groupId(groupName)
  local p = TRN.PlayerGroups()[groupName]
  return p and p.id or nil
end

local function output(groupName, text, soundFile)
  local id = groupId(groupName)
  if not id then return end
  if soundFile then
    trigger.action.outSoundForGroup(id, CFG.SOUND_FOLDER .. soundFile)
  end
  if text and text ~= "" then
    local secs = math.max(8, math.min(30, math.floor(#text / 12) + 4))
    trigger.action.outTextForGroup(id, text, secs, false)
  end
end

-- Reiht eine Ausgabe fuer eine Gruppe ein.
local function enqueue(groupName, text, soundFile, dur)
  local now = timer.getTime()
  local at = math.max(now, nextFree[groupName] or 0)
  nextFree[groupName] = at + (dur or 3) + 0.5
  if at <= now then
    output(groupName, text, soundFile)
  else
    TRN.After(at - now, function() output(groupName, text, soundFile) end)
  end
end

-- Ereignis-Ansage. extra: optionaler dynamischer Text, wird an den festen Text angehaengt.
function TRN.Audio.Say(groupName, key, extra)
  local def = CFG.SOUNDS[key]
  if not def then
    TRN.Error("Unknown sound key '%s'", tostring(key))
    return
  end
  local text = def.text
  if extra and extra ~= "" then text = text .. " " .. extra end
  enqueue(groupName, text, def.file, def.dur)
end

-- Nur Text (dynamische Werte wie BRAA, 9-Line), optional mit Sound-Ereignis als akustischem Signal.
function TRN.Audio.Text(groupName, text, cueKey)
  local def = cueKey and CFG.SOUNDS[cueKey] or nil
  enqueue(groupName, text, def and def.file or nil, def and def.dur or 3)
end

-- Ansage an alle Spielergruppen (z. B. Begruessung)
function TRN.Audio.SayAll(key, extra)
  for name in pairs(TRN.PlayerGroups()) do
    TRN.Audio.Say(name, key, extra)
  end
end
