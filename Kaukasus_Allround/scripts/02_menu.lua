-- =====================================================================
-- Kaukasus Allround Training - 02_menu.lua
-- F10 menu "Training" for every BLUE client, built with Moose
-- CLIENTMENUMANAGER (Core.ClientMenu). Scenario files register entries
-- at load time with KA.Menu.Add(); KA.Menu.Start() pushes the tree.
-- Recommendation: one client per group (single-ship groups).
-- =====================================================================

KA = KA or {}
KA.Menu = { handlers = {}, nodes = {}, count = 0 }

local Menu = KA.Menu
local ROOT = "Training"

local function manager()
  if not Menu.mgr then
    local clients = SET_CLIENT:New():FilterCoalitions("blue"):FilterStart()
    Menu.mgr = CLIENTMENUMANAGER:New(clients, "KA Training", coalition.side.BLUE)
    Menu.nodes[""] = Menu.mgr:NewEntry(ROOT)
  end
  return Menu.mgr
end

-- CLIENTMENU appends GROUP and CLIENT to the arguments.
function Menu._Dispatch(id, group, client)
  local fn = Menu.handlers[id]
  if fn and group then
    KA.Try("menu " .. id, fn, group, client)
  end
end

-- Returns the submenu node for a path like {"BFM", "MiG-29"}.
local function node(path)
  local mgr = manager()
  local key, parent = "", Menu.nodes[""]
  for _, name in ipairs(path) do
    key = key .. "/" .. name
    if not Menu.nodes[key] then
      Menu.nodes[key] = mgr:NewEntry(name, parent)
    end
    parent = Menu.nodes[key]
  end
  return parent
end

-- Adds a command. fn(group, client) runs when a player selects it.
function Menu.Add(path, text, fn)
  Menu.count = Menu.count + 1
  local id = "cmd" .. Menu.count
  Menu.handlers[id] = fn
  manager():NewEntry(text, node(path), Menu._Dispatch, id)
end

-- Standard Start/Stop/Status entries for a session scenario.
function Menu.AddSession(path, def, opts)
  Menu.Add(path, "Start", KA.MenuStart(def, opts))
  Menu.Add(path, "Stop", KA.MenuStop(def))
  Menu.Add(path, "Status", KA.MenuStatus(def))
end

function Menu.Start()
  local mgr = manager()
  mgr:InitAutoPropagation()
  -- players already seated before the event handler existed
  TIMER:New(function() mgr:Propagate() end):Start(3)
  KA.Log("Training menu ready (%d commands)", Menu.count)
end
